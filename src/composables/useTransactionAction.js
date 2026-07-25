import { ref } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { toast } from 'vue3-toastify'
import { useAuthStore } from '@/stores/auth'

export function useTransactionAction() {
  const loading = ref(false)
  const checkingPlate = ref(false)
  const authStore = useAuthStore()

  const checkPlateStatus = async (platNomor, vehicleType = 'Motor') => {
    if (!platNomor || !platNomor.trim()) {
      toast.warn("Mohon masukkan nomor plat terlebih dahulu!")
      return { success: false, reason: 'empty' }
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
        .eq('plat_nomor', platClean)
        .gte('waktu_pencatatan', startOfDay)
        .lte('waktu_pencatatan', endOfDay)
        .order('waktu_pencatatan', { ascending: false })

      if (error) throw error

      const totalLiterToday = duplicates ? duplicates.reduce((sum, r) => sum + (Number(r.liter) || 0), 0) : 0
      const isMotor = (vehicleType || '').toLowerCase() === 'motor'

      let hasRefueledToday = false
      if (isMotor) {
        // Motor dibatasi jika total liter hari ini sudah >= 5 Liter
        hasRefueledToday = totalLiterToday >= 5
      } else {
        // Mobil dibatasi jika sudah mengisi >= 1 kali hari ini
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

  const submitTransaction = async (formData, vehicleType) => {
    const { plat_nomor, liter } = formData
    const plat = plat_nomor ? plat_nomor.trim().toUpperCase() : ''
    const numLiter = parseFloat(liter)

    if (!plat || !numLiter || numLiter <= 0) {
      toast.warn("Mohon lengkapi data transaksi!")
      return false
    }

    loading.value = true

    try {
      // Panggil RPC fn_safe_insert_transaction
      const { data, error } = await supabase.rpc('fn_safe_insert_transaction', {
        p_plat: plat,
        p_liter: numLiter,
        p_jenis: vehicleType
      })

      // Jika RPC mengembalikan respon objek JSON
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

      // Fallback jika RPC fn_safe_insert_transaction belum terdaftar di Supabase
      const { error: insertError } = await supabase.from('transaksi_pertalite').insert({
        plat_nomor: plat,
        liter: numLiter,
        harga: formData.total_harga,
        jenis_kendaraan: vehicleType,
        operator_id: authStore.user?.id
      })

      if (insertError) throw insertError

      toast.success("Transaksi Berhasil!")
      return true

    } catch (err) {
      console.error("[submitTransaction] Error:", err)
      toast.error("Gagal: " + err.message)
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