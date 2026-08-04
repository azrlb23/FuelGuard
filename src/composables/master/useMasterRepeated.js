import { ref, onMounted, onUnmounted, watch } from 'vue'
import { supabase } from '@/lib/supabaseClient'

export function useMasterRepeated() {
  const getTodayStr = () => {
    const d = new Date()
    const year = d.getFullYear()
    const month = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  const repeatedLogs = ref([])
  const totalAttempts = ref(0)
  const totalPlates = ref(0)
  const isLoading = ref(false)
  const searchQuery = ref('')
  const selectedSpbu = ref('')
  const dateFrom = ref(getTodayStr())
  const dateTo = ref(getTodayStr())
  const spbuList = ref([])

  const fetchSpbuList = async () => {
    try {
      const { data } = await supabase.from('spbu').select('id, nama').order('id')
      if (data) spbuList.value = data
    } catch (err) {
      console.error('[useMasterRepeated] fetchSpbuList error:', err)
    }
  }

  const fetchRepeatedLogs = async (isSilent = false) => {
    try {
      if (!isSilent && repeatedLogs.value.length === 0) {
        isLoading.value = true
      }
      const { data, error } = await supabase.rpc('get_master_repeated_transactions', {
        p_spbu_id: selectedSpbu.value || null,
        p_date_from: dateFrom.value || null,
        p_date_to: dateTo.value || null,
        p_limit: 50,
        p_offset: 0
      })

      if (error) {
        console.error('[useMasterRepeated] RPC error:', error)
        return
      }

      if (data && data.success) {
        let logs = data.data || []
        totalAttempts.value = data.total_attempts || 0
        totalPlates.value = data.total_plates || 0

        // Filter by search query if provided
        if (searchQuery.value.trim()) {
          const q = searchQuery.value.trim().toUpperCase()
          logs = logs.filter(item => item.plat_nomor.includes(q))
        }

        repeatedLogs.value = logs
      }
    } catch (err) {
      console.error('[useMasterRepeated] Error:', err)
    } finally {
      isLoading.value = false
    }
  }

  let intervalId
  onMounted(() => {
    fetchSpbuList()
    fetchRepeatedLogs()
    intervalId = setInterval(() => fetchRepeatedLogs(true), 30000)
  })

  onUnmounted(() => {
    if (intervalId) clearInterval(intervalId)
  })

  // Watch filter selain searchQuery secara instan
  watch([selectedSpbu, dateFrom, dateTo], () => {
    fetchRepeatedLogs()
  })

  // Watch searchQuery dengan Debounce (500ms)
  let searchDebounceTimer = null
  watch(searchQuery, () => {
    clearTimeout(searchDebounceTimer)
    searchDebounceTimer = setTimeout(() => {
      fetchRepeatedLogs()
    }, 500)
  })

  const resetFilters = () => {
    searchQuery.value = ''
    selectedSpbu.value = ''
    dateFrom.value = ''
    dateTo.value = ''
    fetchRepeatedLogs()
  }

  return {
    repeatedLogs,
    totalAttempts,
    totalPlates,
    isLoading,
    searchQuery,
    selectedSpbu,
    dateFrom,
    dateTo,
    spbuList,
    fetchRepeatedLogs,
    resetFilters
  }
}
