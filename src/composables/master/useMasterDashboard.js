import { ref, watch, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'

export function useMasterDashboard() {
  const filterTime = ref('today')
  const isLoading = ref(false)
  const searchQuery = ref('')

  const stats = ref({
    totalRevenue: 0,
    totalVolume: 0,
    activeSpbuCount: 0,
    todayTrxCount: 0
  })

  const spbuList = ref([])
  const weeklyVolumeByDay = ref([0, 0, 0, 0, 0, 0, 0])
  const alerts = ref([])
  const dataSource = ref('RPC Database (Server-side)')

  /**
   * Fetch data Master Dashboard via RPC get_master_dashboard_summary.
   * Seluruh agregasi per-SPBU, weekly volume, dan stats dihitung di PostgreSQL.
   */
  const fetchData = async () => {
    try {
      isLoading.value = true

      const { data, error } = await supabase.rpc('get_master_dashboard_summary', {
        p_filter: filterTime.value
      })

      if (error) {
        console.error('[useMasterDashboard] RPC error:', error)
        return
      }

      if (data) {
        stats.value = data.stats || stats.value
        spbuList.value = data.spbu_list || []
        weeklyVolumeByDay.value = data.weekly_volume || [0, 0, 0, 0, 0, 0, 0]
        alerts.value = data.alerts || []
      }
    } catch (err) {
      console.error('[useMasterDashboard] Error:', err)
    } finally {
      isLoading.value = false
    }
  }

  let intervalId
  onMounted(() => {
    fetchData()
    intervalId = setInterval(fetchData, 30000)
  })

  onUnmounted(() => {
    if (intervalId) clearInterval(intervalId)
  })

  watch(filterTime, () => {
    fetchData()
  })

  const setFilterTime = (val) => {
    filterTime.value = val
  }

  return {
    filterTime,
    setFilterTime,
    searchQuery,
    isLoading,
    stats,
    spbuList,
    weeklyVolumeByDay,
    alerts,
    dataSource,
    fetchData
  }
}
