import { ref, watch, onMounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { useRoute } from 'vue-router'

export function useMasterHistory(itemsPerPage = 10) {
  const transactions = ref([])
  const loading = ref(false)
  const totalItems = ref(0)
  const currentPage = ref(1)

  // Filter state
  const searchQuery = ref('')
  const dateFrom = ref('')
  const dateTo = ref('')
  const sortField = ref('waktu_pencatatan')
  const sortDir = ref('desc') // 'asc' | 'desc'
  const dataSource = ref('Checking...')
  const spbuMap = ref({})

  const route = useRoute()

  // ─── Fetch SPBUs for Fallback Mapping ──────────────────────────────────────
  const fetchSpbus = async () => {
    try {
      const { data } = await supabase.from('spbu').select('id, nama, alamat, manajer_id')
      if (data && data.length > 0) {
        const map = {}
        data.forEach(s => {
          map[s.id] = s.nama || `SPBU #${s.id}`
        })
        spbuMap.value = map
      }
    } catch (err) {
      console.warn('[useMasterHistory] Error loading SPBUs map:', err)
    }
  }

  // ─── Direct Fallback Query (Jika RPC belum ada di Supabase) ──────────────────
  const fetchDirectTableData = async () => {
    try {
      if (Object.keys(spbuMap.value).length === 0) {
        await fetchSpbus()
      }

      const from = (currentPage.value - 1) * itemsPerPage
      const to = from + itemsPerPage - 1

      let query = supabase
        .from('transaksi_pertalite')
        .select('*', { count: 'exact' })
        .order(sortField.value, { ascending: sortDir.value === 'asc' })
        .range(from, to)

      if (searchQuery.value.trim()) {
        query = query.ilike('plat_nomor', `%${searchQuery.value.trim()}%`)
      }

      if (dateFrom.value) {
        query = query.gte('waktu_pencatatan', `${dateFrom.value}T00:00:00`)
      }
      if (dateTo.value) {
        query = query.lte('waktu_pencatatan', `${dateTo.value}T23:59:59`)
      }

      const { data, count, error } = await query

      if (error) throw error

      transactions.value = (data || []).map(trx => ({
        ...trx,
        spbu_name: trx.spbu_name || spbuMap.value[trx.spbu_id] || 'SPBU 64.7501'
      }))
      totalItems.value = count || 0
    } catch (err) {
      console.error('[useMasterHistory Direct Query] Error:', err.message)
    }
  }

  // ─── Main Fetch (Prioritas RPC Database -> Fallback Direct Fetch) ─────────────
  const fetchHistory = async () => {
    loading.value = true
    let rpcSuccess = false

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

      if (!error && data) {
        transactions.value = data.transactions || []
        totalItems.value = data.total_count || 0
        rpcSuccess = true
        dataSource.value = 'RPC Database (Server-side)'
      }
    } catch (err) {
      // RPC failed or function not created yet
    }

    if (!rpcSuccess) {
      dataSource.value = 'Fallback Direct Query (Frontend)'
      await fetchDirectTableData()
    }

    loading.value = false
  }

  // Watchers to reset page & refetch
  watch([searchQuery, dateFrom, dateTo, sortField, sortDir], () => {
    currentPage.value = 1
    fetchHistory()
  })

  watch(currentPage, () => {
    fetchHistory()
  })

  watch(() => route.query.q, (newQuery) => {
    if (newQuery !== undefined) {
      searchQuery.value = newQuery
    }
  })

  const resetFilters = () => {
    searchQuery.value = ''
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
    dateFrom,
    dateTo,
    sortField,
    sortDir,
    dataSource,
    fetchHistory,
    resetFilters
  }
}
