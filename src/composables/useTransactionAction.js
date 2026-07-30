import { ref } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { toast } from 'vue3-toastify'
import { useAuthStore } from '@/stores/auth'

export function useTransactionAction() {
  const loading = ref(false)
  const checkingPlate = ref(false)
  const authStore = useAuthStore()

  /**
   * Mengecek status kuota pengisian BBM kendaraan hari ini via RPC Backend.
   */
  const checkPlateStatus = async (platNomor, vehicleType = 'Motor', isOjol = false) => {
    if (!platNomor || !platNomor.trim()) {
      toast.warn("Mohon masukkan nomor plat terlebih dahulu!")
      return { success: false, reason: 'empty' }
    }

    checkingPlate.value = true
    const platClean = platNomor.trim().toUpperCase()

    try {
      // 1. Coba panggil RPC fn_check_plate_status jika ada di DB
      let { data, error } = await supabase.rpc('fn_check_plate_status', {
        p_plat: platClean,
        p_is_ojol: isOjol
      })

      if (error && error.code === 'PGRST202') {
        const try2 = await supabase.rpc('fn_check_plate_status', {
          p_plat: platClean,
          p_spbu_id: authStore.spbuId || null,
          p_is_ojol: isOjol
        })
        data = try2.data
        error = try2.error
      }

      if (!error && data) {
        return data
      }

      // 2. Fallback: Query langsung ke tabel transaksi_pertalite jika RPC fn_check_plate_status belum dibuat/sesuai
      const todayStart = new Date()
      todayStart.setHours(0, 0, 0, 0)

      const { data: todayTrx, error: queryErr } = await supabase
        .from('transaksi_pertalite')
        .select('id, liter, harga, is_ojol, waktu_pencatatan')
        .eq('plat_nomor', platClean)
        .gte('waktu_pencatatan', todayStart.toISOString())

      if (queryErr) throw queryErr

      if (todayTrx && todayTrx.length > 0) {
        const totalHargaToday = todayTrx.reduce((sum, t) => sum + (Number(t.harga) || 0), 0)
        const maxQuota = 50000

        if (totalHargaToday >= maxQuota) {
          return {
            allowed: false,
            reason: 'quota_exceeded',
            message: `Kuota Harian (Rp ${maxQuota.toLocaleString('id-ID')}) untuk plat ${platClean} sudah habis. Total hari ini: Rp ${totalHargaToday.toLocaleString('id-ID')}`
          }
        }

        return {
          allowed: true,
          reason: 'ok',
          remainingQuota: maxQuota - totalHargaToday,
          totalToday: totalHargaToday,
          countToday: todayTrx.length,
          message: `Dapat mengisi BBM. Kuota tersisa: Rp ${(maxQuota - totalHargaToday).toLocaleString('id-ID')}`
        }
      }

      return {
        allowed: true,
        reason: 'ok',
        remainingQuota: 50000,
        totalToday: 0,
        countToday: 0,
        message: 'Plat nomor valid dan belum melakukan pengisian hari ini.'
      }

    } catch (err) {
      console.warn("[checkPlateStatus] Client Fallback Error:", err)
      return { allowed: true, reason: 'fallback', message: 'Gagal mengecek kuota otomatis, silakan lanjutkan.' }
    } finally {
      checkingPlate.value = false
    }
  }

  /**
   * Mengirim transaksi BBM ke Supabase (Mendukung RPC maupun Direct Insert 6 Kolom DB)
   */
  const submitTransaction = async (platOrForm, vehicleTypeParam = 'Motor', isOjolParam = false) => {
    let plat = ''
    let liter = 0
    let totalHarga = 0
    let isOjol = false

    if (typeof platOrForm === 'object' && platOrForm !== null) {
      plat = platOrForm.plat_nomor || platOrForm.plat || ''
      liter = parseFloat(platOrForm.liter) || 0
      totalHarga = parseFloat(String(platOrForm.totalHarga || platOrForm.harga || '').replace(/[^\d]/g, '')) || (liter * 10000)
      isOjol = typeof vehicleTypeParam === 'boolean' ? vehicleTypeParam : (isOjolParam || false)
    } else {
      plat = platOrForm || ''
      liter = parseFloat(vehicleTypeParam) || 0
      isOjol = isOjolParam || false
      totalHarga = liter * 10000
    }

    const platClean = String(plat).trim().toUpperCase()

    if (!platClean || isNaN(liter) || liter <= 0) {
      toast.warn("Mohon lengkapi data transaksi dengan benar!")
      return false
    }

    loading.value = true

    try {
      // 1. Coba lewat RPC fn_safe_insert_transaction terlebih dahulu
      const { data, error } = await supabase.rpc('fn_safe_insert_transaction', {
        p_plat: platClean,
        p_liter: liter,
        p_jenis: 'Motor',
        p_shift: 1,
        p_operator_name: null,
        p_is_ojol: isOjol
      })

      if (!error && data) {
        if (!data.success) {
          if (data.reason !== 'quota_exceeded' && data.reason !== 'already_refueled') {
            toast.error(data.message || "Transaksi ditolak oleh sistem!")
          }
          return { success: false, reason: data.reason, message: data.message }
        }
        toast.success("Transaksi Berhasil!")
        return { success: true }
      }

      // 2. Direct Insert Fallback jika RPC belum disesuaikan oleh backend (Hanya mengisi 6 kolom DB yang tersedia)
      const user = (await supabase.auth.getUser())?.data?.user
      const { error: insertErr } = await supabase
        .from('transaksi_pertalite')
        .insert({
          plat_nomor: platClean,
          liter: liter,
          harga: totalHarga,
          waktu_pencatatan: new Date().toISOString(),
          operator_id: user?.id || null,
          is_ojol: isOjol
        })

      if (insertErr) throw insertErr

      toast.success("Transaksi Berhasil!")
      return { success: true }

    } catch (err) {
      console.error("[submitTransaction] Error:", err)
      toast.error("Gagal: " + (err.message || err))
      return { success: false, reason: 'error', message: err.message || err }
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

