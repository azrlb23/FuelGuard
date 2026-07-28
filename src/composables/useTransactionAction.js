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
  const checkPlateStatus = async (platNomor, vehicleType = 'Motor') => {
    if (!platNomor || !platNomor.trim()) {
      toast.warn("Mohon masukkan nomor plat terlebih dahulu!")
      return { success: false, reason: 'empty' }
    }

    if (!authStore.spbuId) {
      toast.error("Data SPBU belum tersedia. Silakan login ulang.")
      return { success: false, reason: 'no_spbu' }
    }

    checkingPlate.value = true

    try {
      const { data, error } = await supabase.rpc('fn_check_plate_status', {
        p_plat: platNomor.trim().toUpperCase(),
        p_jenis: vehicleType,
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
  const submitTransaction = async (platOrForm, literOrVehicle, vehicleTypeParam) => {
    let plat = ''
    let liter = 0
    let jenisKendaraan = ''

    if (typeof platOrForm === 'object' && platOrForm !== null) {
      plat = platOrForm.plat_nomor || platOrForm.plat || ''
      liter = platOrForm.liter
      jenisKendaraan = literOrVehicle || 'Motor'
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

    // ── Logika Shift Otomatis Berdasarkan Jam System ──
    const hours = new Date().getHours()
    let shiftSaatIni = 3
    if (hours >= 6 && hours <= 13) {
      shiftSaatIni = 1
    } else if (hours >= 14 && hours <= 21) {
      shiftSaatIni = 2
    }

    loading.value = true

    try {
      const { data, error } = await supabase.rpc('fn_safe_insert_transaction', {
        p_plat: platClean,
        p_liter: numLiter,
        p_jenis: jenisKendaraan,
        p_shift: shiftSaatIni
      })

      if (error) throw error

      // Handle response dari RPC
      if (data && !data.success) {
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

    } catch (err) {
      console.error("[submitTransaction] Error:", err)
      toast.error("Gagal: " + (err.message || err))
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
