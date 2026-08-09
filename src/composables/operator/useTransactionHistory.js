import { ref, watch, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

import { secureSetItem, secureGetItem, secureRemoveItem } from '@/utils/cryptoStorage'

const STORAGE_KEY_DAILY_HISTORY = 'hj_cache_daily_history_v1'

const getTodayStr = () => {
  try {
    const formatter = new Intl.DateTimeFormat('sv-SE', { timeZone: 'Asia/Makassar' })
    return formatter.format(new Date())
  } catch (e) {
    const now = new Date()
    const y = now.getFullYear()
    const m = String(now.getMonth() + 1).padStart(2, '0')
    const d = String(now.getDate()).padStart(2, '0')
    return `${y}-${m}-${d}`
  }
}

const getCachedDailyHistory = (spbuId) => {
  try {
    const parsed = secureGetItem(STORAGE_KEY_DAILY_HISTORY)
    if (!parsed) return []
    const today = getTodayStr()
    // Reset otomatis jika pergantian hari (tanggal kemarin) atau beda SPBU
    if (parsed.cacheDate !== today || parsed.spbuId !== spbuId) {
      secureRemoveItem(STORAGE_KEY_DAILY_HISTORY)
      return []
    }
    return Array.isArray(parsed.transactions) ? parsed.transactions : []
  } catch (e) {
    return []
  }
}

const saveDailyHistoryCache = (spbuId, transactionsList) => {
  try {
    if (Array.isArray(transactionsList)) {
      secureSetItem(STORAGE_KEY_DAILY_HISTORY, {
        cacheDate: getTodayStr(),
        spbuId: spbuId,
        transactions: transactionsList
      })
    }
  } catch (e) {}
}

export function useTransactionHistory(itemsPerPage = 10, options = {}) {

  const transactions = ref([])
  const loading = ref(false)
  const totalItems = ref(0)
  const currentPage = ref(1)

  const searchQuery = ref('')
  const vehicleFilter = ref('')
  const dateFrom = ref('')
  const dateTo = ref('')
  const sortField = ref('waktu_pencatatan')
  const sortDir = ref('desc')

  const route = useRoute()
  const authStore = useAuthStore()

  const fetchHistory = async () => {
    const spbuId = authStore.spbuId
    if (!spbuId) {
      console.warn('[TransactionHistory] spbuId belum tersedia, skip fetch.')
      return
    }

    loading.value = true
    try {
      let rpcDateFrom = dateFrom.value || ''
      let rpcDateTo = dateTo.value || ''

      const todayStr = getTodayStr()

      // If dateFilter is strictly "today" (Operator History default)
      if (options.dateFilter) {
        rpcDateFrom = todayStr
        rpcDateTo = todayStr
      }

      // Offline Fallback: Jika perangkat sedang offline, tampilkan data cache harian dengan filter lokal
      if (typeof navigator !== 'undefined' && !navigator.onLine) {
        let cachedList = getCachedDailyHistory(spbuId)
        if (vehicleFilter.value) {
          const isOjolTarget = vehicleFilter.value === 'ojol'
          cachedList = cachedList.filter(t => t.is_ojol === isOjolTarget)
        }
        if (searchQuery.value.trim()) {
          const q = searchQuery.value.trim().toLowerCase()
          cachedList = cachedList.filter(t => {
            const platMatch = (t.plat_nomor && t.plat_nomor.toLowerCase().includes(q)) || (t.plat && t.plat.toLowerCase().includes(q))
            const opMatch = (t.operator_name && t.operator_name.toLowerCase().includes(q)) || (t.nama_operator && t.nama_operator.toLowerCase().includes(q))
            return platMatch || opMatch
          })
        }
        transactions.value = cachedList
        totalItems.value = cachedList.length
        loading.value = false
        return
      }

      const isSearching = !!searchQuery.value.trim()
      const rpcPageSize = isSearching ? 500 : itemsPerPage
      const rpcPage = isSearching ? 1 : currentPage.value

      const { data, error } = await supabase.rpc('get_master_history_paginated', {
        p_page: rpcPage,
        p_page_size: rpcPageSize,
        p_search: '',
        p_spbu_id: spbuId,
        p_date_from: rpcDateFrom,
        p_date_to: rpcDateTo,
        p_sort_field: sortField.value || 'waktu_pencatatan',
        p_sort_dir: sortDir.value || 'desc'
      })

      if (error) throw error

      if (data) {
        let filteredTransactions = data.transactions || []
        
        // Filter is_ojol in JS
        if (vehicleFilter.value) {
           const isOjolTarget = vehicleFilter.value === 'ojol'
           filteredTransactions = filteredTransactions.filter(t => t.is_ojol === isOjolTarget)
        }

        // Cache hasil query harian jika tanpa pencarian
        if (!isSearching && options.dateFilter) {
          saveDailyHistoryCache(spbuId, filteredTransactions)
        }

        // Multi-field search filtering for plat, operator, spbu, and time (17:54 / 14:30)
        if (isSearching) {
          const q = searchQuery.value.trim().toLowerCase()
          filteredTransactions = filteredTransactions.filter(t => {
            const platMatch = t.plat_nomor && t.plat_nomor.toLowerCase().includes(q)
            const opMatch = (t.operator_name && t.operator_name.toLowerCase().includes(q)) || 
                            (t.nama_operator && t.nama_operator.toLowerCase().includes(q))
            const spbuMatch = (t.spbu_name && t.spbu_name.toLowerCase().includes(q)) ||
                              (t.spbu_id && String(t.spbu_id).toLowerCase().includes(q))
            let timeMatch = false
            if (t.waktu_pencatatan) {
              const d = new Date(t.waktu_pencatatan)
              const timeStr = d.toLocaleTimeString('id-ID', {
                hour: '2-digit',
                minute: '2-digit',
                hour12: false
              }).replace('.', ':')
              timeMatch = timeStr.includes(q) || timeStr.replace(':', '.').includes(q)
            }
            return platMatch || opMatch || spbuMatch || timeMatch
          })
          totalItems.value = filteredTransactions.length
          const startIdx = (currentPage.value - 1) * itemsPerPage
          transactions.value = filteredTransactions.slice(startIdx, startIdx + itemsPerPage)
        } else {
          transactions.value = filteredTransactions
          totalItems.value = vehicleFilter.value ? filteredTransactions.length : (data.total_count || 0)
        }
      }
    } catch (err) {
      console.warn('Error fetching history from network, fallback to daily cache:', err.message)
      const cachedList = getCachedDailyHistory(spbuId)
      transactions.value = cachedList
      totalItems.value = cachedList.length
    } finally {
      loading.value = false
    }
  }

  // Debounce for search text (300ms) — prevents RPC flood while typing
  let searchDebounceTimer = null
  watch(searchQuery, () => {
    clearTimeout(searchDebounceTimer)
    searchDebounceTimer = setTimeout(() => {
      currentPage.value = 1
      fetchHistory()
    }, 300)
  })

  // Other filters (vehicle, date, sort) reset immediately
  watch([vehicleFilter, dateFrom, dateTo, sortField, sortDir], () => {
    currentPage.value = 1
    fetchHistory()
  })

  watch(currentPage, () => {
    fetchHistory()
  })

  const handleOnlineReconnect = () => {
    fetchHistory()
  }

  const resetFilters = () => {
    searchQuery.value = ''
    vehicleFilter.value = ''
    dateFrom.value = ''
    dateTo.value = ''
    sortField.value = 'waktu_pencatatan'
    sortDir.value = 'desc'
    currentPage.value = 1
  }

  onMounted(() => {
    if (route.query.q) {
      searchQuery.value = route.query.q
    }
    if (typeof window !== 'undefined') {
      window.addEventListener('online', handleOnlineReconnect)
    }
    fetchHistory()
  })

  onUnmounted(() => {
    clearTimeout(searchDebounceTimer)
    if (typeof window !== 'undefined') {
      window.removeEventListener('online', handleOnlineReconnect)
    }
  })

  return {
    transactions,
    loading,
    totalItems,
    currentPage,
    searchQuery,
    vehicleFilter,
    dateFrom,
    dateTo,
    sortField,
    sortDir,
    fetchHistory,
    resetFilters
  }
}