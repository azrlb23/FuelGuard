import { ref, watch, onMounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { useAuthStore } from '@/stores/auth'
import { toast } from 'vue3-toastify'

export function useRepeatedLogs(itemsPerPage = 10) {
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

    const spbuId = authStore.spbuId
    if (!spbuId) {
      console.warn('[useRepeatedLogs] SPBU ID belum tersedia, skip fetch.')
      return
    }

    loading.value = true
    try {
      const { data, error } = await supabase.rpc('get_operator_repeated_logs', {
        p_spbu_id: spbuId,
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

  watch([searchQuery], () => {
    currentPage.value = 1
    fetchOperatorLogs()
  })

  watch(currentPage, () => {
    fetchOperatorLogs()
  })

  watch(() => authStore.user, (newUser) => {
    if (newUser) {
      fetchOperatorLogs()
    }
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
    loading,
    totalCount,
    currentPage,
    searchQuery,
    fetchOperatorLogs,
    resetFilters
  }
}
