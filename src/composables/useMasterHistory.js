import { ref, watch, onMounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { useRoute } from 'vue-router'

export function useMasterHistory(itemsPerPage = 10) {
  const transactions = ref([])
  const loading = ref(false)
  const currentPage = ref(1)
  const totalItems = ref(0)

  // Filter state
  const searchQuery = ref('')
  const selectedSpbu = ref('')
  const dateFrom = ref('')
  const dateTo = ref('')
  const sortField = ref('waktu_pencatatan')
  const sortDir = ref('desc')
  const spbuList = ref([])

  const route = useRoute()

  // ─── Fetch SPBU Dropdown Options ───────────────────────────────────────────
  const fetchSpbuOptions = async () => {
    try {
      const { data } = await supabase.from('spbu').select('id, nama, alamat, manajer_id')
      if (data && data.length > 0) {
        spbuList.value = data.map(s => ({
          id: String(s.id),
          nama: s.nama || `SPBU #${s.id}`
        }))
      }
    } catch (err) {
      console.warn('[useMasterHistory] Failed to fetch SPBU options:', err)
    }
  }

  /**
   * Fetch riwayat transaksi terpaginasi via RPC get_master_history_paginated.
   * Search, filtering, sorting, dan pagination semuanya dieksekusi di PostgreSQL.
   */
  const fetchHistory = async () => {
    loading.value = true
    try {
      const { data, error } = await supabase.rpc('get_master_history_paginated', {
        p_search: searchQuery.value.trim(),
        p_date_from: dateFrom.value,
        p_date_to: dateTo.value,
        p_sort_field: sortField.value,
        p_sort_dir: sortDir.value,
        p_page: currentPage.value,
        p_page_size: itemsPerPage
      })

      if (error) throw error

      if (data) {
        transactions.value = data.transactions || []
        totalItems.value = data.total_count || 0
      }
    } catch (err) {
      console.error('[useMasterHistory] Error:', err.message)
    } finally {
      loading.value = false
    }
  }

  // Reset to page 1 and re-fetch when any filter changes
  watch([searchQuery, selectedSpbu, dateFrom, dateTo, sortField, sortDir], () => {
    currentPage.value = 1
    fetchHistory()
  })

  // Re-fetch when page changes
  watch(currentPage, () => {
    fetchHistory()
  })

  // Sync search from URL query param
  watch(() => route.query.q, (newQuery) => {
    if (newQuery !== undefined) {
      searchQuery.value = newQuery
    }
  })

  const resetFilters = () => {
    searchQuery.value = ''
    selectedSpbu.value = ''
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
    fetchSpbuOptions()
    fetchHistory()
  })

  return {
    transactions,
    loading,
    totalItems,
    currentPage,
    searchQuery,
    selectedSpbu,
    spbuList,
    dateFrom,
    dateTo,
    sortField,
    sortDir,
    fetchHistory,
    resetFilters
  }
}
