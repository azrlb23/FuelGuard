import { ref, watch, onMounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { useRoute } from 'vue-router'

export function useTransactionHistory(itemsPerPage = 10, options = {}) {
  
  const transactions = ref([])
  const loading = ref(false)
  const totalItems = ref(0)
  const currentPage = ref(1)

  // Filter state
  const searchQuery = ref('')
  const vehicleFilter = ref('') // '' = Semua, 'Motor', 'Mobil'
  const dateFrom = ref('')
  const dateTo = ref('')
  const sortField = ref('waktu_pencatatan')
  const sortDir = ref('desc') // 'asc' | 'desc'

  const route = useRoute()

  const fetchHistory = async () => {
    loading.value = true
    try {
      const from = (currentPage.value - 1) * itemsPerPage
      const to = from + itemsPerPage - 1

      let query = supabase
        .from('transaksi_pertalite')
        .select('*', { count: 'exact' })
        .order(sortField.value, { ascending: sortDir.value === 'asc' })
        .range(from, to)

      // Search by plate
      if (searchQuery.value) {
        query = query.ilike('plat_nomor', `%${searchQuery.value}%`)
      }

      // Filter by vehicle type
      if (vehicleFilter.value) {
        query = query.eq('jenis_kendaraan', vehicleFilter.value)
      }

      // Filter by date range
      if (dateFrom.value) {
        query = query.gte('waktu_pencatatan', `${dateFrom.value}T00:00:00`)
      }
      if (dateTo.value) {
        query = query.lte('waktu_pencatatan', `${dateTo.value}T23:59:59`)
      }

      // Operator: restrict to today 06:00–23:59
      if (options.dateFilter) {
        const now = new Date()
        const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 6, 0, 0, 0).toISOString()
        const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999).toISOString()

        query = query.gte('waktu_pencatatan', startOfDay)
                     .lte('waktu_pencatatan', endOfDay)
      }

      const { data, count, error } = await query

      if (error) throw error
      
      transactions.value = data
      totalItems.value = count
    } catch (err) {
      console.error('Error fetching history:', err.message)
    } finally {
      loading.value = false
    }
  }

  // Reset to page 1 and re-fetch when any filter changes
  watch([searchQuery, vehicleFilter, dateFrom, dateTo, sortField, sortDir], () => {
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

  // Reset all filters
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