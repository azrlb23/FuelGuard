import { ref, watch, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

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

      // If dateFilter is strictly "today" (Operator History default)
      if (options.dateFilter) {
        const now = new Date()
        const y = now.getFullYear()
        const m = String(now.getMonth() + 1).padStart(2, '0')
        const d = String(now.getDate()).padStart(2, '0')
        const todayStr = `${y}-${m}-${d}`
        rpcDateFrom = todayStr
        rpcDateTo = todayStr
      }

      const { data, error } = await supabase.rpc('get_master_history_paginated', {
        p_page: currentPage.value,
        p_page_size: itemsPerPage,
        p_search: searchQuery.value || '',
        p_spbu_id: spbuId,
        p_date_from: rpcDateFrom,
        p_date_to: rpcDateTo,
        p_sort_field: sortField.value || 'waktu_pencatatan',
        p_sort_dir: sortDir.value || 'desc'
      })

      if (error) throw error

      if (data) {
        let filteredTransactions = data.transactions || []
        
        // Filter is_ojol in JS as the current RPC signature doesn't take p_is_ojol yet
        if (vehicleFilter.value) {
           const isOjolTarget = vehicleFilter.value === 'ojol'
           filteredTransactions = filteredTransactions.filter(t => t.is_ojol === isOjolTarget)
        }

        transactions.value = filteredTransactions
        totalItems.value = data.total_count || 0
      }
    } catch (err) {
      console.error('Error fetching history:', err.message)
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

  onUnmounted(() => clearTimeout(searchDebounceTimer))

  watch(() => route.query.q, (newQuery) => {
    if (newQuery !== undefined) {
      searchQuery.value = newQuery
    }
  })

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
    fetchHistory()
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