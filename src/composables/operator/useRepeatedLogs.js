import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { useAuthStore } from '@/stores/auth'
import { toast } from 'vue3-toastify'

export function useRepeatedLogs(itemsPerPage = 50) {
  const logs = ref([])
  const loading = ref(false)
  const totalCount = ref(0)
  const currentPage = ref(1)
  const searchQuery = ref('')

  const authStore = useAuthStore()

  const fetchOperatorLogs = async () => {
    if (!authStore.isInitialized) {
      await authStore.initialize()
    }

    loading.value = true
    try {
      // Panggil RPC dengan p_spbu_id: null agar Cross-SPBU seluruh log hari ini
      const { data, error } = await supabase.rpc('get_operator_repeated_logs', {
        p_spbu_id: null,
        p_page: currentPage.value,
        p_page_size: itemsPerPage,
        p_search: searchQuery.value.trim()
      })

      if (error) {
        console.error('[useRepeatedLogs] RPC Error:', error)
        toast.error('Gagal mengambil data pengetap: ' + error.message)
        throw error
      }

      if (data) {
        logs.value = data.logs || []
        totalCount.value = data.total_count || 0
      }
    } catch (err) {
      console.error('[useRepeatedLogs] Exception:', err.message)
      logs.value = []
      totalCount.value = 0
    } finally {
      loading.value = false
    }
  }

  // Grouped logs: group flat log entries by plat_nomor for accordion UI
  const groupedLogs = computed(() => {
    const map = new Map()

    for (const item of logs.value) {
      if (!map.has(item.plat_nomor)) {
        map.set(item.plat_nomor, {
          plat_nomor: item.plat_nomor,
          is_ojol: item.is_ojol,
          attempt_count: 0,
          latest_waktu: item.waktu,
          latest_tanggal: item.tanggal,
          spbu_ids: new Set(),
          entries: []
        })
      }
      const group = map.get(item.plat_nomor)
      group.attempt_count++
      group.spbu_ids.add(item.attempt_spbu_id)
      // First item in sorted desc order = latest
      if (group.entries.length === 0) {
        group.latest_waktu = item.waktu
        group.latest_tanggal = item.tanggal
      }
      group.entries.push(item)
    }

    return Array.from(map.values()).map(g => ({
      ...g,
      spbu_ids: Array.from(g.spbu_ids)
    }))
  })

  // Debounce search (300ms) to avoid flooding RPC on every keystroke
  let searchDebounceTimer = null
  watch(searchQuery, () => {
    clearTimeout(searchDebounceTimer)
    searchDebounceTimer = setTimeout(() => {
      currentPage.value = 1
      fetchOperatorLogs()
    }, 300)
  })

  onUnmounted(() => clearTimeout(searchDebounceTimer))

  watch(currentPage, () => {
    fetchOperatorLogs()
  })

  watch(() => authStore.user, (newUser) => {
    if (newUser) fetchOperatorLogs()
  })

  const resetFilters = () => {
    searchQuery.value = ''
    currentPage.value = 1
    fetchOperatorLogs()
  }

  onMounted(() => {
    fetchOperatorLogs()
  })

  return {
    logs,
    groupedLogs,
    loading,
    totalCount,
    currentPage,
    searchQuery,
    fetchOperatorLogs,
    resetFilters
  }
}
