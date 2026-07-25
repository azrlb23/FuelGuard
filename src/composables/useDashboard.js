import { ref, watch, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'

export function useDashboard() {
  const filter = ref('today')
  const isLoading = ref(false)

  const stats = ref({ volume: 0, revenue: 0, vehicle: 0 })
  const feed = ref([])
  const shiftStats = ref([])
  const vehicleStats = ref([])
  const peakHourStats = ref([])
  const loyalStats = ref([])
  const trendStats = ref([])
  const ticketSizeStats = ref([])
  const revenueShareStats = ref([])

  const fetchDirectTableData = async () => {
    try {
      const now = new Date()
      let query = supabase
        .from('transaksi_pertalite')
        .select('*')
        .order('waktu_pencatatan', { ascending: false })

      if (filter.value === 'today') {
        const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0).toISOString()
        query = query.gte('waktu_pencatatan', startOfDay)
      } else if (filter.value === 'weekly') {
        const weekStart = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
        query = query.gte('waktu_pencatatan', weekStart.toISOString())
      } else if (filter.value === 'monthly') {
        const monthStart = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)
        query = query.gte('waktu_pencatatan', monthStart.toISOString())
      }

      const { data: rows, error } = await query

      if (error) {
        console.error('[Dashboard Direct Fetch] Error:', error)
        return
      }

      const list = rows || []

      // Hitung ringkasan statistik
      const volume = list.reduce((sum, r) => sum + (Number(r.liter) || 0), 0)
      const revenue = list.reduce((sum, r) => sum + (Number(r.harga) || 0), 0)
      const vehicle = list.length

      stats.value = {
        volume,
        revenue,
        vehicle,
        volume_growth: 0,
        revenue_growth: 0
      }

      // Live Feed
      let feedSource = list
      if (list.length === 0 && filter.value === 'today') {
        // Jika belum ada transaksi hari ini, ambil 10 transaksi terakhir secara umum untuk feed
        const { data: fallbackFeed } = await supabase
          .from('transaksi_pertalite')
          .select('*')
          .order('waktu_pencatatan', { ascending: false })
          .limit(10)
        feedSource = fallbackFeed || []
      }
      feed.value = feedSource.slice(0, 10)

      // Vehicle Chart
      const vehicleMap = {}
      list.forEach(r => {
        const type = r.jenis_kendaraan || 'Umum'
        vehicleMap[type] = (vehicleMap[type] || 0) + 1
      })
      vehicleStats.value = Object.keys(vehicleMap).map(type => ({
        label: type,
        count: vehicleMap[type]
      }))

      // Shift Chart (Shift 1: 06-14, Shift 2: 14-22, Shift 3: 22-06)
      const shifts = { 1: 0, 2: 0, 3: 0 }
      list.forEach(r => {
        const d = new Date(r.waktu_pencatatan || r.created_at)
        const hour = d.getHours()
        if (hour >= 6 && hour < 14) shifts[1]++
        else if (hour >= 14 && hour < 22) shifts[2]++
        else shifts[3]++
      })
      shiftStats.value = [
        { shift: 1, count: shifts[1] },
        { shift: 2, count: shifts[2] },
        { shift: 3, count: shifts[3] }
      ]

      // Peak Hours
      const hoursMap = {}
      list.forEach(r => {
        const d = new Date(r.waktu_pencatatan || r.created_at)
        const h = d.getHours()
        hoursMap[h] = (hoursMap[h] || 0) + 1
      })
      peakHourStats.value = Object.keys(hoursMap).map(h => ({
        hour: Number(h),
        count: hoursMap[h]
      }))

      // Loyal Customers
      const custMap = {}
      list.forEach(r => {
        const plat = r.plat_nomor
        if (!plat) return
        if (!custMap[plat]) custMap[plat] = { plat_nomor: plat, total_trx: 0, total_liter: 0 }
        custMap[plat].total_trx++
        custMap[plat].total_liter += Number(r.liter) || 0
      })
      loyalStats.value = Object.values(custMap)
        .sort((a, b) => b.total_liter - a.total_liter)
        .slice(0, 5)

      // Trend 7 hari (Query independen 7 hari terakhir agar grafik selalu lengkap)
      const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
      sevenDaysAgo.setHours(0, 0, 0, 0)

      const { data: trendRows } = await supabase
        .from('transaksi_pertalite')
        .select('harga, waktu_pencatatan, created_at')
        .gte('waktu_pencatatan', sevenDaysAgo.toISOString())

      const getLocalDateKey = (dateInput) => {
        const d = new Date(dateInput)
        if (isNaN(d.getTime())) return ''
        const year = d.getFullYear()
        const month = String(d.getMonth() + 1).padStart(2, '0')
        const day = String(d.getDate()).padStart(2, '0')
        return `${year}-${month}-${day}`
      }

      const trendMap = {}
      for (let i = 6; i >= 0; i--) {
        const d = new Date()
        d.setDate(d.getDate() - i)
        const key = getLocalDateKey(d)
        const label = d.toLocaleDateString('id-ID', { weekday: 'short', day: 'numeric' })
        trendMap[key] = { label, total: 0 }
      }

      (trendRows || list).forEach(r => {
        const rawDate = r.waktu_pencatatan || r.created_at
        if (!rawDate) return
        const key = getLocalDateKey(rawDate)
        if (trendMap[key]) {
          trendMap[key].total += Number(r.harga) || 0
        }
      })

      trendStats.value = Object.values(trendMap)

      // Revenue Share
      const revMap = {}
      list.forEach(r => {
        const type = r.jenis_kendaraan || 'Umum'
        revMap[type] = (revMap[type] || 0) + (Number(r.harga) || 0)
      })
      revenueShareStats.value = Object.keys(revMap).map(type => ({
        label: type,
        total: revMap[type]
      }))

      console.log(`[Dashboard Direct Fetch] Data processed successfully. Total vehicle: ${vehicle}`)
    } catch (err) {
      console.error('[Dashboard Direct Fetch] Error:', err)
    }
  }

  const fetchData = async () => {
    try {
      isLoading.value = true
      console.log(`[Dashboard] Fetching data for filter: ${filter.value}...`)

      let rpcSuccess = false
      try {
        const { data, error } = await supabase.rpc('get_dashboard_summary', {
          p_filter: filter.value
        })

        if (!error && data && (data.stats?.vehicle > 0 || (data.feed && data.feed.length > 0))) {
          stats.value = data.stats || { volume: 0, revenue: 0, vehicle: 0 }
          feed.value = data.feed || []
          shiftStats.value = data.shift_chart || []
          vehicleStats.value = data.vehicle_chart || []
          peakHourStats.value = data.peak_hours || []
          loyalStats.value = data.loyal_customers || []
          trendStats.value = data.trend_7_days || []
          ticketSizeStats.value = data.ticket_size || []
          revenueShareStats.value = data.revenue_share || []
          rpcSuccess = true
          console.log('[Dashboard] RPC data loaded successfully.')
        }
      } catch (err) {
        console.warn('[Dashboard] RPC failed, falling back to direct table query:', err)
      }

      if (!rpcSuccess) {
        console.log('[Dashboard] Executing direct table query fallback...')
        await fetchDirectTableData()
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
    shiftStats, vehicleStats, peakHourStats, loyalStats,
    trendStats, ticketSizeStats, revenueShareStats
  }
}