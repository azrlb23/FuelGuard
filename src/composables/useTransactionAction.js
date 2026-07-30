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
   * Semua logika kuota (Motor max 5L, Mobil max 1x) dieksekusi di PostgreSQL.
   */
  const checkPlateStatus = async (platNomor, isOjol = false) => {
    if (!platNomor || !platNomor.trim()) {
      toast.warn("Mohon masukkan nomor plat terlebih dahulu!")
      return { success: false, reason: 'empty' }
    }

    if (!authStore.spbuId) {
      toast.error("Data SPBU belum tersedia. Silakan login ulang.")
      return { success: false, reason: 'no_spbu' }
    }

    if (!authStore.activeKasirId) {
      toast.warn("Silakan pilih Kasir terlebih dahulu!")
      return { success: false, reason: 'no_kasir' }
    }

    checkingPlate.value = true

    try {
      const { data, error } = await supabase.rpc('fn_check_plate_status', {
        p_plat: platNomor.trim().toUpperCase(),
        p_is_ojol: isOjol,
        p_spbu_id: authStore.spbuId
      })

      if (error) throw error

      return data || { success: false, reason: 'no_data' }
    } catch (err) {
      console.error("[checkPlateStatus] Error:", err)
      toast.error("Gagal memeriksa database: " + err.message)
      return { success: false, reason: 'error' }
    } finally {
      checkingPlate.value = false
    }
  }

  /**
   * Mengirim transaksi BBM ke Supabase via RPC Backend.
   * Harga dihitung di server-side berdasarkan tabel fuel_prices.
   * Kuota di-enforce secara atomis di PostgreSQL (anti race condition).
   */
  const submitTransaction = async (platOrForm, literOrVehicle, isOjolParam) => {
    let plat = ''
    let liter = 0
    let isOjol = false

    if (typeof platOrForm === 'object' && platOrForm !== null) {
      plat = platOrForm.plat_nomor || platOrForm.plat || ''
      liter = platOrForm.liter
      isOjol = literOrVehicle === true || literOrVehicle === 'Ojol'
    } else {
      plat = platOrForm || ''
      liter = literOrVehicle
      isOjol = isOjolParam === true || isOjolParam === 'Ojol'
    }

    const platClean = String(plat).trim().toUpperCase()
    const numLiter = parseFloat(liter)

    if (!platClean || isNaN(numLiter) || numLiter <= 0) {
      toast.warn("Mohon lengkapi data transaksi dengan benar!")
      return false
    }

    if (!authStore.activeKasirId) {
      toast.warn("Silakan pilih Kasir terlebih dahulu!")
      return false
    }

    loading.value = true

    try {
      const { data, error } = await supabase.rpc('fn_safe_insert_transaction', {
        p_plat: platClean,
        p_liter: numLiter,
        p_operator_id: authStore.activeKasirId,
        p_is_ojol: isOjol
      })

      if (error) throw error

      // Handle response dari RPC
      if (data && !data.success) {
        if (data.reason !== 'quota_exceeded' && data.reason !== 'already_refueled') {
          toast.error(data.message || "Transaksi ditolak oleh sistem!")
        }
        return { success: false, reason: data.reason, message: data.message }
      }

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
