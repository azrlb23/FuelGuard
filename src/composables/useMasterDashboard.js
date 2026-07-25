import { ref, watch, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'

export function useMasterDashboard() {
  const filterTime = ref('today') // 'today' | 'weekly' | 'monthly' | 'all-time'
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

  // ─── Fallback Direct Table Fetch (jika RPC belum dipasang di Supabase) ───────
  const fetchDirectTableData = async () => {
    try {
      // 1. Fetch SPBUs directly from Supabase
      const { data: dbSpbus, error: spbuError } = await supabase.from('spbu').select('*')
      if (spbuError) {
        console.warn('[useMasterDashboard Direct Fetch] Error fetching SPBU table:', spbuError.message)
      }
      const rawSpbus = dbSpbus || []

      // 2. Build date query based on filterTime
      const now = new Date()
      let query = supabase
        .from('transaksi_pertalite')
        .select('harga, liter, waktu_pencatatan, jenis_kendaraan, plat_nomor, spbu_id')
        .order('waktu_pencatatan', { ascending: false })

      if (filterTime.value === 'today') {
        const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0).toISOString()
        query = query.gte('waktu_pencatatan', startOfDay)
      } else if (filterTime.value === 'weekly') {
        const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString()
        query = query.gte('waktu_pencatatan', weekAgo)
      } else if (filterTime.value === 'monthly') {
        const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString()
        query = query.gte('waktu_pencatatan', monthAgo)
      }

      const { data: allTrx, error: trxError } = await query
      if (trxError) {
        console.warn('[useMasterDashboard Direct Fetch] Error fetching transactions:', trxError.message)
      }
      const allTrxList = allTrx || []

      // Map transactions to SPBUs
      const spbuDataMap = {}
      allTrxList.forEach(tx => {
        if (!tx.spbu_id) return
        const sId = String(tx.spbu_id)
        if (!spbuDataMap[sId]) {
          spbuDataMap[sId] = { revenue: 0, volume: 0, transactions: [] }
        }
        spbuDataMap[sId].revenue += Number(tx.harga) || 0
        spbuDataMap[sId].volume += Number(tx.liter) || 0
        spbuDataMap[sId].transactions.push(tx)
      })

      // Process SPBU list
      spbuList.value = rawSpbus.map(s => {
        const sId = String(s.id)
        const sStats = spbuDataMap[sId] || { revenue: 0, volume: 0, transactions: [] }

        return {
          id: sId,
          name: s.nama || s.name || s.nama_spbu || `SPBU ${sId}`,
          location: s.alamat || s.location || s.kota || '-',
          revenue: sStats.revenue,
          volume: sStats.volume,
          manager: s.manager || s.manager_name || '-',
          transactions: sStats.transactions
        }
      })

      // Calculate totals
      const totalRev = allTrxList.reduce((sum, item) => sum + (Number(item.harga) || 0), 0)
      const totalVol = allTrxList.reduce((sum, item) => sum + (Number(item.liter) || 0), 0)

      stats.value = {
        totalRevenue: totalRev,
        totalVolume: totalVol,
        activeSpbuCount: rawSpbus.length,
        todayTrxCount: allTrxList.length
      }

      // 3. Fetch real 7-day volume per day for Bar Chart
      const sevenDaysAgo = new Date()
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6)
      sevenDaysAgo.setHours(0, 0, 0, 0)

      const { data: weeklyTrx } = await supabase
        .from('transaksi_pertalite')
        .select('liter, waktu_pencatatan')
        .gte('waktu_pencatatan', sevenDaysAgo.toISOString())

      const dayVolumes = [0, 0, 0, 0, 0, 0, 0] // Sen, Sel, Rab, Kam, Jum, Sab, Min
      if (weeklyTrx && weeklyTrx.length > 0) {
        weeklyTrx.forEach(tx => {
          const d = new Date(tx.waktu_pencatatan)
          if (!isNaN(d.getTime())) {
            const day = d.getDay() // 0 = Sun, 1 = Mon ...
            const idx = day === 0 ? 6 : day - 1
            dayVolumes[idx] += Number(tx.liter) || 0
          }
        })
      }
      weeklyVolumeByDay.value = dayVolumes

    } catch (err) {
      console.error('[useMasterDashboard Direct Fetch] Error:', err)
    }
  }

  // ─── Main Fetch (Prioritas RPC Database -> Fallback Direct Fetch) ─────────────
  const fetchData = async () => {
    try {
      isLoading.value = true
      let rpcSuccess = false

      try {
        const { data, error } = await supabase.rpc('get_master_dashboard_summary', {
          p_filter: filterTime.value
        })

        if (!error && data) {
          stats.value = data.stats || stats.value
          spbuList.value = data.spbu_list || []
          weeklyVolumeByDay.value = data.weekly_volume || [0, 0, 0, 0, 0, 0, 0]
          alerts.value = data.alerts || []
          rpcSuccess = true
          console.log('[useMasterDashboard] RPC data loaded successfully.')
        }
      } catch (err) {
        console.warn('[useMasterDashboard] RPC failed, falling back to direct query:', err)
      }

      if (!rpcSuccess) {
        await fetchDirectTableData()
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
    fetchData
  }
}
