import { ref } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { toast } from 'vue3-toastify'
import { useAuthStore } from '@/stores/auth'
import { useNetworkStatus } from '@/composables/common/useNetworkStatus'
import { useOfflineQueue } from '@/composables/common/useOfflineQueue'
import { validatePlateFormat } from '@/utils/plateValidation'

import { secureGetItem } from '@/utils/cryptoStorage'

export function useTransactionAction() {
  const loading = ref(false)
  const checkingPlate = ref(false)
  const authStore = useAuthStore()
  const { isOnline } = useNetworkStatus()
  const { savePendingTransaction } = useOfflineQueue()

  const calculateOfflinePlateStatus = (platClean, isOjol, spbuId) => {
    let historyList = []
    try {
      const parsed = secureGetItem('hj_cache_daily_history_v1')
      if (parsed && Array.isArray(parsed.transactions)) {
        historyList = parsed.transactions
      }
    } catch (e) {}

    let pendingList = []
    try {
      const rawPending = secureGetItem('hj_offline_transactions_v1')
      if (Array.isArray(rawPending)) {
        pendingList = rawPending
      }
    } catch (e) {}

    const matchingHistory = historyList.filter(t => (t.plat_nomor === platClean || t.plat === platClean))
    const matchingPending = pendingList.filter(p => p.platNomor === platClean)

    let firstIsOjol = null
    let totalHargaToday = 0
    let totalLiterToday = 0
    let countToday = 0

    for (const h of matchingHistory) {
      if (firstIsOjol === null && h.is_ojol !== undefined) {
        firstIsOjol = !!h.is_ojol
      }
      totalHargaToday += Number(h.harga || (h.liter * 10000) || 0)
      totalLiterToday += Number(h.liter || 0)
      countToday++
    }

    for (const p of matchingPending) {
      if (firstIsOjol === null && p.isOjol !== undefined) {
        firstIsOjol = !!p.isOjol
      }
      totalHargaToday += Number((p.liter * 10000) || 0)
      totalLiterToday += Number(p.liter || 0)
      countToday++
    }

    if (firstIsOjol !== null && firstIsOjol !== isOjol) {
      return {
        success: false,
        reason: 'category_mismatch',
        message: `Kendaraan ${platClean} hari ini sudah terdaftar sebagai ${firstIsOjol ? 'Motor Ojol' : 'Motor Biasa'}! Tidak dapat bertransaksi sebagai ${isOjol ? 'Motor Ojol' : 'Motor Biasa'}.`
      }
    }

    const effectiveIsOjol = firstIsOjol !== null ? firstIsOjol : isOjol
    const maxQuota = effectiveIsOjol ? 100000 : 50000
    const remainingQuota = Math.max(0, maxQuota - totalHargaToday)
    const hasRefueled = totalHargaToday >= maxQuota

    return {
      success: true,
      plat: platClean,
      plat_nomor: platClean,
      total_liter_today: totalLiterToday,
      total_harga_today: totalHargaToday,
      remainingQuota,
      hasRefueledToday: hasRefueled,
      count_today: countToday,
      max_quota: maxQuota,
      is_ojol_locked: firstIsOjol !== null,
      locked_is_ojol: firstIsOjol,
      isOfflineFallback: true
    }
  }

  /**
   * Mengecek status kuota pengisian BBM kendaraan hari ini via RPC Backend.
   * Melakukan validasi format & kode wilayah presisi di Frontend terlebih dahulu.
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

    // Validasi Format Plat & Kode Wilayah Presisi Frontend (100% Sejalur dengan PostgreSQL)
    const valResult = validatePlateFormat(platNomor)
    if (!valResult.isValid) {
      // Log perulangan jika format / region tidak valid saat online (tanpa toast duplikat)
      if (isOnline.value) {
        recordRepeatedLog(platNomor, isOjol, valResult.reason, 0)
      }
      return {
        success: false,
        reason: valResult.reason,
        message: valResult.message
      }
    }

    const platClean = valResult.platClean
    checkingPlate.value = true

    try {
      if (!isOnline.value) {
        return calculateOfflinePlateStatus(platClean, isOjol, authStore.spbuId)
      }

      // READ-ONLY: Panggil RPC fn_check_plate_status
      const { data, error } = await supabase.rpc('fn_check_plate_status', {
        p_plat: platClean,
        p_is_ojol: isOjol,
        p_spbu_id: authStore.spbuId
      })

      if (error) throw error

      return data || { success: false, reason: 'no_data' }
    } catch (err) {
      console.error("[checkPlateStatus] Error:", err)
      // Fallback kalkulasi kuota offline presisi jika terjadi error koneksi ke RPC
      return calculateOfflinePlateStatus(platClean, isOjol, authStore.spbuId)
    } finally {
      checkingPlate.value = false
    }
  }

  /**
   * CATAT LOG PERULANGAN EKSPLISIT
   */
  const recordRepeatedLog = async (platNomor, isOjol, reason, totalHargaToday = 0) => {
    if (!platNomor || !authStore.spbuId || !authStore.activeKasirId || !isOnline.value) return

    try {
      await supabase.from('repeated_transaction_logs').insert({
        plat_nomor: platNomor.trim().toUpperCase(),
        attempt_spbu_id: authStore.spbuId,
        attempt_operator_id: authStore.activeKasirId,
        is_ojol: isOjol,
        attempted_liter: 0,
        total_harga_today: totalHargaToday,
        reason: reason || 'quota_exceeded',
        created_at: new Date().toISOString()
      })
    } catch (err) {
      console.error('[recordRepeatedLog] Gagal mencatat log perulangan:', err)
    }
  }

  /**
   * Mengirim transaksi BBM ke Supabase via RPC Backend (atau disimpan ke Local Queue jika offline).
   */
  const submitTransaction = async (platOrForm, literOrVehicle, isOjolParam) => {
    let plat = ''
    let liter = 0
    let isOjol = false

    if (typeof platOrForm === 'object' && platOrForm !== null) {
      plat = platOrForm.platNomor || platOrForm.plat_nomor || platOrForm.plat || ''
      liter = platOrForm.liter
      isOjol = platOrForm.isOjol !== undefined ? !!platOrForm.isOjol : (literOrVehicle === true || literOrVehicle === 'Ojol')
    } else {
      plat = platOrForm || ''
      liter = literOrVehicle
      isOjol = isOjolParam === true || isOjolParam === 'Ojol'
    }

    const numLiter = parseFloat(liter)

    if (isNaN(numLiter) || numLiter <= 0) {
      toast.warn("Mohon masukkan jumlah liter yang valid!")
      return false
    }

    const valResult = validatePlateFormat(plat)
    if (!valResult.isValid) {
      return { success: false, reason: valResult.reason, message: valResult.message }
    }

    const platClean = valResult.platClean

    if (!authStore.activeKasirId) {
      return { success: false, reason: 'no_kasir', message: 'Silakan pilih Kasir terlebih dahulu!' }
    }

    loading.value = true

    // Jika perangkat sedang offline, langsung simpan ke queue lokal secara silent & instan
    if (!isOnline.value) {
      const res = savePendingTransaction({
        platNomor: platClean,
        liter: numLiter,
        operatorId: authStore.activeKasirId,
        isOjol: isOjol,
        spbuId: authStore.spbuId
      })

      loading.value = false
      if (res.success) {
        return { success: true, offline: true }
      } else {
        return { success: false, reason: 'offline_save_failed', message: 'Gagal menyimpan transaksi secara offline.' }
      }
    }

    try {
      const { data, error } = await supabase.rpc('fn_safe_insert_transaction', {
        p_plat: platClean,
        p_liter: numLiter,
        p_operator_id: authStore.activeKasirId,
        p_is_ojol: isOjol
      })

      if (error) throw error

      if (data && !data.success) {
        return { success: false, reason: data.reason, message: data.message }
      }

      return { success: true }

    } catch (err) {
      console.error("[submitTransaction] Error:", err)
      if (err.message?.includes('Failed to fetch') || err.name === 'TypeError') {
        const res = savePendingTransaction({
          platNomor: platClean,
          liter: numLiter,
          operatorId: authStore.activeKasirId,
          isOjol: isOjol,
          spbuId: authStore.spbuId
        })
        if (res.success) {
          return { success: true, offline: true }
        }
      }

    } finally {
      loading.value = false
    }
  }

  return {
    loading,
    checkingPlate,
    checkPlateStatus,
    recordRepeatedLog,
    submitTransaction
  }
}
