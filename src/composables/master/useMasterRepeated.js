import { ref, onMounted, onUnmounted, watch } from 'vue'
import { supabase } from '@/lib/supabaseClient'

export function useMasterRepeated(itemsPerPage = 10) {
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
  const currentPage = ref(1)
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
      const offset = (currentPage.value - 1) * itemsPerPage
      const { data, error } = await supabase.rpc('get_master_repeated_transactions', {
        p_spbu_id: selectedSpbu.value || null,
        p_date_from: dateFrom.value || null,
        p_date_to: dateTo.value || null,
        p_limit: itemsPerPage,
        p_offset: offset
      })

      if (error) {
        console.error('[useMasterRepeated] RPC error:', error)
        return
      }

      if (data && data.success) {
        let logs = data.data || []
        totalAttempts.value = data.total_attempts || 0
        totalPlates.value = data.total_plates || 0

        // Filter by search query if provided (Plat Nomor, Operator, SPBU, Reason, atau Jam HH:mm)
        if (searchQuery.value.trim()) {
          const q = searchQuery.value.trim().toLowerCase()
          logs = logs.filter(item => {
            const platMatch = item.plat_nomor && item.plat_nomor.toLowerCase().includes(q)
            const attempts = item.attempts || []
            const attemptMatch = attempts.some(att => {
              const operatorMatch = att.operator_nama && att.operator_nama.toLowerCase().includes(q)
              const spbuMatch = (att.spbu_nama && att.spbu_nama.toLowerCase().includes(q)) || (att.spbu_id && String(att.spbu_id).toLowerCase().includes(q))
              const reasonMatch = att.reason && att.reason.toLowerCase().includes(q)
              let timeMatch = false
              if (att.created_at) {
                const d = new Date(att.created_at)
                const timeStr = d.toLocaleTimeString('id-ID', {
                  timeZone: 'Asia/Makassar',
                  hour: '2-digit',
                  minute: '2-digit',
                  hour12: false
                }).replace('.', ':')
                timeMatch = timeStr.includes(q) || timeStr.replace(':', '.').includes(q)
              }
              return operatorMatch || spbuMatch || reasonMatch || timeMatch
            })
            return platMatch || attemptMatch
          })
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

  // Watch currentPage untuk refetch data saat halaman berubah
  watch(currentPage, () => {
    fetchRepeatedLogs()
  })

  // Reset currentPage ke 1 saat filter selain searchQuery berubah secara instan
  watch([selectedSpbu, dateFrom, dateTo], () => {
    currentPage.value = 1
    fetchRepeatedLogs()
  })

  // Watch searchQuery dengan Debounce (500ms)
  let searchDebounceTimer = null
  watch(searchQuery, () => {
    clearTimeout(searchDebounceTimer)
    searchDebounceTimer = setTimeout(() => {
      currentPage.value = 1
      fetchRepeatedLogs()
    }, 500)
  })

  const resetFilters = () => {
    searchQuery.value = ''
    selectedSpbu.value = ''
    dateFrom.value = ''
    dateTo.value = ''
    currentPage.value = 1
    fetchRepeatedLogs()
  }

  return {
    repeatedLogs,
    totalAttempts,
    totalPlates,
    currentPage,
    itemsPerPage,
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
