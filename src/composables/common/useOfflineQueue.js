import { ref, watch, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { toast } from 'vue3-toastify'
import { useNetworkStatus } from './useNetworkStatus'
import { fetchAndCacheRegionCodes } from '@/utils/plateValidation'
import { secureSetItem, secureGetItem, secureRemoveItem } from '@/utils/cryptoStorage'

const STORAGE_KEY_TRX = 'hj_offline_transactions_v1'
const STORAGE_KEY_OPERATORS = 'hj_cache_operators_v1'

const pendingCount = ref(0)
const isSyncing = ref(false)

let heartbeatTimer = null
let isGlobalListenerSetup = false

export function useOfflineQueue() {
  const { isOnline } = useNetworkStatus()

  // Ambil daftar transaksi lokal yang tertunda (Terenkripsi)
  const getPendingTransactions = () => {
    try {
      const data = secureGetItem(STORAGE_KEY_TRX)
      return Array.isArray(data) ? data : []
    } catch (e) {
      console.error('[useOfflineQueue] Error reading pending transactions:', e)
      return []
    }
  }

  // Update jumlah antrean reaktif
  const updatePendingCount = () => {
    const list = getPendingTransactions()
    pendingCount.value = list.length
  }

  // Simpan transaksi baru ke antrean lokal (Terenkripsi & Deduplikasi)
  const savePendingTransaction = (txData) => {
    try {
      const list = getPendingTransactions()

      // Deduplikasi: Abaikan transaksi dengan plat dan SPBU yang sama dalam kurun waktu 60 detik
      const isDuplicate = list.some(item =>
        item.platNomor === txData.platNomor &&
        item.spbuId === txData.spbuId &&
        (Date.now() - new Date(item.createdAt).getTime() < 60000)
      )

      if (isDuplicate) {
        return { success: true, duplicate: true }
      }

      const newItem = {
        id: 'off_' + Date.now() + '_' + Math.random().toString(36).substring(2, 7),
        platNomor: txData.platNomor,
        liter: txData.liter,
        operatorId: txData.operatorId,
        isOjol: !!txData.isOjol,
        spbuId: txData.spbuId,
        createdAt: new Date().toISOString()
      }

      list.push(newItem)
      secureSetItem(STORAGE_KEY_TRX, list)
      updatePendingCount()

      // Jika tiba-tiba online saat menyimpan, langsung jadwalkan sync instan
      if (isOnline.value) {
        setTimeout(() => syncPendingTransactions(), 300)
      }

      return { success: true, item: newItem }
    } catch (err) {
      console.error('[useOfflineQueue] Gagal menyimpan transaksi offline:', err)
      return { success: false, error: err.message }
    }
  }

  // Hapus transaksi yang berhasil di-sync dari antrean
  const removePendingTransaction = (id) => {
    try {
      let list = getPendingTransactions()
      list = list.filter(item => item.id !== id)
      secureSetItem(STORAGE_KEY_TRX, list)
      updatePendingCount()
    } catch (e) {
      console.error('[useOfflineQueue] Error removing tx:', e)
    }
  }

  // Sinkronkan seluruh transaksi lokal ke server Supabase secara otomatis & silent
  const syncPendingTransactions = async () => {
    if (isSyncing.value || !isOnline.value) return
    const list = getPendingTransactions()
    if (list.length === 0) return

    isSyncing.value = true

    for (const tx of list) {
      try {
        const { data, error } = await supabase.rpc('fn_safe_insert_transaction', {
          p_plat: tx.platNomor,
          p_liter: tx.liter,
          p_operator_id: tx.operatorId,
          p_is_ojol: tx.isOjol
        })

        if (error) {
          console.error('[syncPendingTransactions] RPC Error for item:', tx, error)
          continue
        }

        if (data && data.success) {
          removePendingTransaction(tx.id)
        } else {
          // Jika ditolak server (quota_exceeded / category_mismatch), database fn_safe_insert_transaction
          // sudah otomatis mencatatnya ke repeated_transaction_logs. Bersihkan dari antrean lokal.
          console.warn('[syncPendingTransactions] Transaksi ditolak server (dicatat ke audit log):', data?.message)
          removePendingTransaction(tx.id)
        }
      } catch (err) {
        console.error('[syncPendingTransactions] Network error during auto sync:', err)
      }
    }

    isSyncing.value = false
    updatePendingCount()
  }

  // Set up listeners global untuk auto-sync instan saat terhubung internet
  const setupAutoSyncListeners = () => {
    if (isGlobalListenerSetup || typeof window === 'undefined') return
    isGlobalListenerSetup = true

    const handleOnlineEvent = () => {
      fetchAndCacheRegionCodes()
      updatePendingCount()
      if (pendingCount.value > 0) {
        syncPendingTransactions()
      }
    }

    window.addEventListener('online', handleOnlineEvent)

    // Heartbeat check berkala setiap 15 detik jika ada antrean tertunda
    heartbeatTimer = setInterval(() => {
      updatePendingCount()
      if (navigator.onLine && pendingCount.value > 0 && !isSyncing.value) {
        syncPendingTransactions()
      }
    }, 15000)
  }

  // Cache lokal untuk operator profiles (Terenkripsi)
  const cacheOperators = (operators) => {
    if (Array.isArray(operators) && operators.length > 0) {
      secureSetItem(STORAGE_KEY_OPERATORS, operators)
    }
  }

  const getCachedOperators = () => {
    try {
      const data = secureGetItem(STORAGE_KEY_OPERATORS)
      return Array.isArray(data) ? data : []
    } catch (e) {
      return []
    }
  }

  // Watcher reaktif saat status isOnline berubah ke true
  watch(isOnline, (newVal) => {
    if (newVal) {
      fetchAndCacheRegionCodes()
      updatePendingCount()
      if (pendingCount.value > 0) {
        syncPendingTransactions()
      }
    }
  })

  onMounted(() => {
    setupAutoSyncListeners()
    fetchAndCacheRegionCodes()
    updatePendingCount()
    if (isOnline.value && pendingCount.value > 0) {
      syncPendingTransactions()
    }
  })

  return {
    pendingCount,
    isSyncing,
    getPendingTransactions,
    savePendingTransaction,
    syncPendingTransactions,
    cacheOperators,
    getCachedOperators
  }
}
