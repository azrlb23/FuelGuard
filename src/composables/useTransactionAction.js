import { ref } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { toast } from 'vue3-toastify'
import { useAuthStore } from '@/stores/auth'

export function useTransactionAction() {
  const loading = ref(false)
  const checkingPlate = ref(false)
  const authStore = useAuthStore()

  const getHargaPerLiter = async (spbuId) => {
    try {
      let query = supabase
        .from('fuel_prices')
        .select('price_per_liter')
        .ilike('fuel_type', '%pertalite%')
        .limit(1)

      if (spbuId) {
        query = query.eq('spbu_id', spbuId)
      }
      const { data } = await query
      if (data && data.length > 0 && Number(data[0].price_per_liter) > 0) {
        return Number(data[0].price_per_liter)
      }
    } catch (e) {
      console.warn("Gagal mengambil harga BBM dari database, menggunakan default 10.000:", e)
    }
    return 10000
  }

  const checkPlateStatus = async (platNomor, vehicleType = 'Motor') => {
    if (!platNomor || !platNomor.trim()) {
      toast.warn("Mohon masukkan nomor plat terlebih dahulu!")
      return { success: false, reason: 'empty' }
    }

    if (!authStore.spbuId) {
      toast.error("Data SPBU belum tersedia. Silakan login ulang.")
      return { success: false, reason: 'no_spbu' }
    }

    const platClean = platNomor.trim().toUpperCase()
    checkingPlate.value = true

    try {
      const now = new Date()
      const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0).toISOString()
      const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999).toISOString()

      const { data: duplicates, error } = await supabase
        .from('transaksi_pertalite')
        .select('id, liter, harga, waktu_pencatatan, jenis_kendaraan')
        .eq('spbu_id', authStore.spbuId)
        .eq('plat_nomor', platClean)
        .gte('waktu_pencatatan', startOfDay)
        .lte('waktu_pencatatan', endOfDay)
        .order('waktu_pencatatan', { ascending: false })

      if (error) throw error

      const totalLiterToday = duplicates ? duplicates.reduce((sum, r) => sum + (Number(r.liter) || 0), 0) : 0
      const isMotor = (vehicleType || '').toLowerCase() === 'motor'

      let hasRefueledToday = false
      if (isMotor) {
        hasRefueledToday = totalLiterToday >= 5
      } else {
        hasRefueledToday = duplicates && duplicates.length > 0
      }

      if (duplicates && duplicates.length > 0) {
        const last = duplicates[0]
        const dateObj = new Date(last.waktu_pencatatan)
        const timeFormatted = dateObj.toLocaleTimeString('id-ID', {
          hour: '2-digit',
          minute: '2-digit'
        })
        return {
          success: true,
          hasRefueledToday,
          totalLiterToday,
          remainingQuota: isMotor ? Math.max(0, 5 - totalLiterToday) : 0,
          countToday: duplicates.length,
          lastTransaction: last,
          timeFormatted,
          plat: platClean
        }
      } else {
        return {
          success: true,
          hasRefueledToday: false,
          totalLiterToday: 0,
          remainingQuota: isMotor ? 5 : 0,
          countToday: 0,
          lastTransaction: null,
          plat: platClean
        }
      }
    } catch (err) {
      console.error("[checkPlateStatus] Error:", err)
      toast.error("Gagal memeriksa database: " + err.message)
      return { success: false, reason: 'error' }
    } finally {
      checkingPlate.value = false
    }
  }

  /**
   * Menyiapkan dan mengirim data transaksi ke Supabase RPC / Fallback Direct Insert
   */
  const submitTransaction = async (platOrForm, literOrVehicle, vehicleTypeParam) => {
    let plat = ''
    let liter = 0
    let jenisKendaraan = ''
    let totalHarga = 0

    if (typeof platOrForm === 'object' && platOrForm !== null) {
      plat = platOrForm.plat_nomor || platOrForm.plat || ''
      liter = platOrForm.liter
      jenisKendaraan = literOrVehicle || 'Motor'
      totalHarga = parseFloat(platOrForm.total_harga || platOrForm.harga || 0)
    } else {
      plat = platOrForm || ''
      liter = literOrVehicle
      jenisKendaraan = vehicleTypeParam || 'Motor'
    }

    const platClean = String(plat).trim().toUpperCase()
    const numLiter = parseFloat(liter)

    if (!platClean || isNaN(numLiter) || numLiter <= 0) {
      toast.warn("Mohon lengkapi data transaksi dengan benar!")
      return false
    }

    // Pastikan totalHarga selalu bernilai angka positif valid (tidak pernah null / 0)
    if (!totalHarga || totalHarga <= 0) {
      const pricePerLiter = await getHargaPerLiter(authStore.spbuId)
      totalHarga = numLiter * pricePerLiter
    }

    // ── Logika Shift Otomatis Berdasarkan Jam System ──
    // Jam 06:00 - 13:59 -> Shift 1
    // Jam 14:00 - 21:59 -> Shift 2
    // Jam 22:00 - 05:59 -> Shift 3
    const hours = new Date().getHours()
    let shiftSaatIni = 3
    if (hours >= 6 && hours <= 13) {
      shiftSaatIni = 1
    } else if (hours >= 14 && hours <= 21) {
      shiftSaatIni = 2
    } else {
      shiftSaatIni = 3
    }

    loading.value = true

    try {
      // 1. Coba RPC dengan p_harga
      let { data, error } = await supabase.rpc('fn_safe_insert_transaction', {
        p_plat: platClean,
        p_liter: numLiter,
        p_jenis: jenisKendaraan,
        p_shift: shiftSaatIni,
        p_harga: totalHarga
      })

      // Jika RPC di database hanya menerima 4 parameter (p_plat, p_liter, p_jenis, p_shift), panggil ulang tanpa p_harga
      if (error && (error.code === 'PGRST202' || error.message?.includes('Could not find') || error.message?.includes('schema cache'))) {
        const res = await supabase.rpc('fn_safe_insert_transaction', {
          p_plat: platClean,
          p_liter: numLiter,
          p_jenis: jenisKendaraan,
          p_shift: shiftSaatIni
        })
        data = res.data
        error = res.error
      }

      // Handling respon dari RPC jika berhasil dieksekusi oleh PostgreSQL
      if (!error && data) {
        if (!data.success) {
          if (data.reason === 'quota_exceeded') {
            toast.warn(data.message || "Kuota maksimal Motor (5 Liter/hari) terlampaui!")
          } else if (data.reason === 'already_refueled') {
            toast.warn(data.message || "Mobil hanya boleh mengisi 1x per hari!")
          } else {
            toast.error(data.message || "Transaksi ditolak oleh sistem!")
          }
          return false
        }

        toast.success("Transaksi Berhasil!")
        return true
      }

      // 2. Fallback Direct Insert: Jika RPC SQL gagal (misal constraint error 23502 akibat kolom "harga" NULL pada fungsi SQL)
      if (error) {
        console.warn("[submitTransaction] RPC gagal (menggunakan fallback direct insert):", error)

        const { error: insertError } = await supabase.from('transaksi_pertalite').insert({
          plat_nomor: platClean,
          liter: numLiter,
          harga: totalHarga,
          jenis_kendaraan: jenisKendaraan,
          shift: shiftSaatIni,
          operator_id: authStore.user?.id,
          spbu_id: authStore.spbuId,
          operator_email: authStore.user?.email
        })

        if (insertError) {
          console.error("[submitTransaction] Direct Insert Error:", insertError)
          toast.error("Gagal menyimpan transaksi: " + insertError.message)
          return false
        }

        toast.success("Transaksi Berhasil!")
        return true
      }

    } catch (err) {
      console.error("[submitTransaction] Unexpected Error:", err)
      toast.error("Terjadi kesalahan: " + (err.message || err))
      return false
    } finally {
      loading.value = false
    }
  }

  return {
    loading,
    checkingPlate,
    checkPlateStatus,
    submitTransaction
  }
}
