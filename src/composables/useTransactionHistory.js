import { ref, watch, onMounted } from 'vue'
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
      console.warn('[TransactionHistory] spbu_id belum tersedia, skip fetch.')
      return
    }

    loading.value = true
    try {
      const from = (currentPage.value - 1) * itemsPerPage
      const to = from + itemsPerPage - 1

      let query = supabase
        .from('transaksi_pertalite')
        .select('*', { count: 'exact' })
        .eq('spbu_id', spbuId)
        .order(sortField.value, { ascending: sortDir.value === 'asc' })
        .range(from, to)

      if (searchQuery.value) {
        query = query.ilike('plat_nomor', `%${searchQuery.value}%`)
      }

      if (vehicleFilter.value) {
        query = query.eq('jenis_kendaraan', vehicleFilter.value)
      }

      if (dateFrom.value) {
        query = query.gte('waktu_pencatatan', `${dateFrom.value}T00:00:00`)
      }
      if (dateTo.value) {
        query = query.lte('waktu_pencatatan', `${dateTo.value}T23:59:59`)
      }

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

  watch([searchQuery, vehicleFilter, dateFrom, dateTo, sortField, sortDir], () => {
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