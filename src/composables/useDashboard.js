import { ref, watch, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { useAuthStore } from '@/stores/auth'

export function useDashboard() {
  const filter = ref('today')
  const isLoading = ref(false)
  const authStore = useAuthStore()

  const stats = ref({ volume: 0, revenue: 0, vehicle: 0 })
  const feed = ref([])
  const vehicleStats = ref([])
  const peakHourStats = ref([])
  const loyalStats = ref([])
  const trendStats = ref([])
  const revenueShareStats = ref([])

  /**
   * Fetch semua data dashboard via RPC get_dashboard_summary.
   * Seluruh agregasi (stats, shift, vehicle, peak hours, loyal, trend, revenue share)
   * dihitung di PostgreSQL dan dikembalikan sebagai 1 objek JSON.
   */
  const fetchData = async () => {
    if (!authStore.spbuId) return

    try {
      isLoading.value = true

      const { data, error } = await supabase.rpc('get_dashboard_summary', {
        p_filter: filter.value,
        p_spbu_id: authStore.spbuId
      })

      if (error) {
        console.error('[Dashboard] RPC error:', error)
        return
      }

      if (data) {
        stats.value = data.stats || { volume: 0, revenue: 0, vehicle: 0 }
        feed.value = data.feed || []
        vehicleStats.value = data.vehicle_chart || []
        peakHourStats.value = data.peak_hours || []
        loyalStats.value = data.loyal_customers || []
        trendStats.value = data.trend_7_days || []
        revenueShareStats.value = data.revenue_share || []
      }
    } catch (err) {
      console.error('[Dashboard] Error:', err)
    } finally {
      isLoading.value = false
    }
  }

  let intervalId
  onMounted(() => {
    fetchData()
    intervalId = setInterval(fetchData, 30000)
  })

  onUnmounted(() => clearInterval(intervalId))

  watch(filter, () => fetchData())

  const setFilter = (val) => {
    filter.value = val
  }

  return {
    filter, setFilter, isLoading, stats, feed,
    vehicleStats, peakHourStats, loyalStats,
    trendStats, revenueShareStats
  }
}
