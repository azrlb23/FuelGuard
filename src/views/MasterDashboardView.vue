<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabaseClient'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js'
import { Line, Pie, Bar } from 'vue-chartjs'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, BarElement, ArcElement, Title, Tooltip, Legend, Filler)

const router = useRouter()

// ─── Filter Time & Search State ─────────────────────────────────────────────
const filterTime = ref('today') // 'today', 'weekly', 'monthly', 'all-time'
const timeFilters = ['Today', 'Weekly', 'Monthly', 'All-Time']

const searchQuery = ref('')
const activeSpbuId = ref(null) // No accordion open by default

const spbuList = ref([])
const weeklyVolumeByDay = ref([0, 0, 0, 0, 0, 0, 0]) // Sen, Sel, Rab, Kam, Jum, Sab, Min

const dbStats = ref({
  totalRevenue: 0,
  totalVolume: 0,
  todayTrxCount: 0
})

const fetchRealDatabaseStats = async () => {
  try {
    // 1. Fetch SPBUs directly from Supabase
    const { data: dbSpbus, error: spbuError } = await supabase.from('spbu').select('*')

    if (spbuError) {
      console.warn('[MasterDashboard] Error fetching SPBU table:', spbuError.message)
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
      console.warn('[MasterDashboard] Error fetching transactions:', trxError.message)
    }

    const allTrxList = allTrx || []

    // Map transactions to SPBUs strictly when spbu_id exists
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

    // Process SPBU list directly from database rows
    spbuList.value = rawSpbus.map(s => {
      const sId = String(s.id)
      const stats = spbuDataMap[sId] || { revenue: 0, volume: 0, transactions: [] }

      const name = s.nama || s.name || s.nama_spbu || `SPBU ${sId}`
      const location = s.alamat || s.location || s.kota || '-'
      const manager = s.manager || s.manager_name || '-'

      return {
        id: sId,
        name: name,
        location: location,
        revenue: stats.revenue,
        volume: stats.volume,
        manager: manager,
        transactions: stats.transactions
      }
    })

    // Calculate totals directly from queried transactions
    const totalRev = allTrxList.reduce((sum, item) => sum + (Number(item.harga) || 0), 0)
    const totalVol = allTrxList.reduce((sum, item) => sum + (Number(item.liter) || 0), 0)

    dbStats.value.totalRevenue = totalRev
    dbStats.value.totalVolume = totalVol
    dbStats.value.todayTrxCount = allTrxList.length

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
    console.error('Error fetching real stats from Supabase:', err)
  }
}

watch(filterTime, () => {
  fetchRealDatabaseStats()
})

const isMounted = ref(false)

onMounted(() => {
  isMounted.value = true
  fetchRealDatabaseStats()
  const interval = setInterval(fetchRealDatabaseStats, 30000)
  return () => clearInterval(interval)
})

const filteredSpbuList = computed(() => {
  if (!searchQuery.value.trim()) return spbuList.value
  const q = searchQuery.value.toLowerCase()
  return spbuList.value.filter(s =>
    s.name.toLowerCase().includes(q) ||
    s.location.toLowerCase().includes(q) ||
    s.manager.toLowerCase().includes(q)
  )
})

const toggleSpbuAccordion = (id) => {
  activeSpbuId.value = activeSpbuId.value === id ? null : id
}

const getRecentTransactions = (spbuId) => {
  const spbu = spbuList.value.find(s => s.id === String(spbuId))
  if (spbu && spbu.transactions && spbu.transactions.length > 0) {
    return spbu.transactions.slice(0, 10).map((tx, idx) => {
      const date = new Date(tx.waktu_pencatatan)
      const timeFormatted = isNaN(date.getTime())
        ? '-'
        : date.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) + ' WIB'

      return {
        id: idx + 1,
        plat: tx.plat_nomor || '-',
        fuel: 'Pertalite',
        liter: `${(Number(tx.liter) || 0).toFixed(1)} L`,
        amount: new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(tx.harga || 0),
        time: timeFormatted
      }
    })
  }

  return []
}

const goToSpbuConsole = (spbu) => {
  router.push({ path: '/dashboard', query: { spbu_id: spbu.id, spbu_name: spbu.name } })
}

// ─── Network Statistics Computed Properties ──────────────────────────────────
const totalNetworkRevenue = computed(() => {
  const sum = dbStats.value.totalRevenue
  if (sum === 0) return 'Rp 0'
  if (sum >= 1000000000) return `Rp ${(sum / 1000000000).toFixed(2)} M`
  if (sum >= 1000000) return `Rp ${(sum / 1000000).toFixed(1)} Jt`
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(sum)
})

const totalNetworkVolume = computed(() => {
  const sum = dbStats.value.totalVolume
  if (sum === 0) return '0 L'
  return sum >= 1000 ? `${(sum / 1000).toFixed(1)}K L` : `${sum.toFixed(1)} L`
})

const totalTransactionsCount = computed(() => {
  return dbStats.value.todayTrxCount.toLocaleString('id-ID')
})

const activeSpbuCountText = computed(() => {
  const total = spbuList.value.length
  return `${total} SPBU`
})

const periodLabel = computed(() => {
  if (filterTime.value === 'today') return 'Hari Ini'
  if (filterTime.value === 'weekly') return '7 Hari Terakhir'
  if (filterTime.value === 'monthly') return '30 Hari Terakhir'
  return 'Semua Waktu'
})

const transactionCardTitle = computed(() => {
  if (filterTime.value === 'today') return 'Transaksi Hari Ini'
  if (filterTime.value === 'weekly') return 'Transaksi 7 Hari'
  if (filterTime.value === 'monthly') return 'Transaksi 30 Hari'
  return 'Total Transaksi'
})


// ─── Formatters ──────────────────────────────────────────────────────────────
const formatRupiah = (val) => {
  if (!val || val === 0) return 'Rp 0'
  if (val >= 1000000000) return `Rp ${(val / 1000000000).toFixed(2)} M`
  return `Rp ${(val / 1000000).toFixed(1)} Jt`
}

const formatVolume = (val) => {
  if (!val || val === 0) return '0 Liter'
  return val >= 1000 ? `${(val / 1000).toFixed(1)}K Liter` : `${val} Liter`
}

const alerts = ref([])

const barChartData = computed(() => {
  const volumes = weeklyVolumeByDay.value
  const maxVol = Math.max(...volumes)
  const isKLiter = maxVol >= 1000

  const dataValues = volumes.map(v =>
    isKLiter ? Number((v / 1000).toFixed(2)) : Number(v.toFixed(1))
  )

  const todayIdx = (new Date().getDay() + 6) % 7 // Current day index (0=Sen, 6=Min)

  return {
    labels: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
    datasets: [{
      label: isKLiter ? 'Volume (K Liters)' : 'Volume (Liters)',
      data: dataValues,
      backgroundColor: dataValues.map((_, i) => i === todayIdx ? '#258f62' : '#143d2e'),
      borderRadius: 6
    }]
  }
})

const barChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { display: false } },
  scales: {
    x: { grid: { display: false }, ticks: { font: { size: 10 } } },
    y: { grid: { color: '#f3f4f6' }, ticks: { font: { size: 10 } } }
  }
}
</script>

<template>
  <div class="space-y-6 animate-enter">

    <!-- Header Section: Title on Left, Time Filter Toggle on Right -->
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-end gap-4 mb-4">
      <div>
        <h2 class="text-3xl md:text-4xl font-extrabold text-black tracking-tight mb-1">Dashboard Analytics</h2>
        <p class="text-gray-500 font-bold text-sm">Overview performa penjualan</p>
      </div>

      <div class="bg-[#184e39] p-1.5 rounded-full flex shadow-lg shadow-green-900/10 self-start sm:self-auto">
        <button
          v-for="filter in timeFilters"
          :key="filter"
          @click="filterTime = filter.toLowerCase()"
          class="px-4 py-2 md:px-5 md:py-2 rounded-full text-xs md:text-sm font-medium transition-all duration-200 cursor-pointer select-none"
          :class="filterTime === filter.toLowerCase() ? 'bg-[#34d399] text-[#064e3b] shadow-sm font-bold' : 'text-white/80 hover:text-white'"
        >
          {{ filter }}
        </button>
      </div>
    </div>

    <!-- Top KPI Stat Cards -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">

      <!-- Revenue Card -->
      <div class="relative overflow-hidden bg-gradient-to-br from-[#143d2e] to-[#258f62] rounded-[2rem] p-6 text-white shadow-xl shadow-green-900/10 hover:scale-[1.01] transition-transform">
        <div class="flex justify-between items-start mb-4">
          <p class="text-xs font-bold uppercase tracking-widest text-green-200">Total Revenue</p>
          <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center text-green-200">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" d="M2.25 18L9 11.25l4.306 4.307a11.95 11.95 0 005.814-5.519l2.74-1.22m0 0l-5.94-2.28m5.94 2.28l-2.28 5.941" /></svg>
          </div>
        </div>
        <h3 class="text-3xl lg:text-4xl font-black tracking-tight text-white mb-1">{{ totalNetworkRevenue }}</h3>
        <p class="text-xs text-green-200/80 mb-3 font-medium">{{ periodLabel }} · {{ spbuList.length }} SPBU</p>
        <div class="absolute -right-6 -bottom-10 w-32 h-32 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
      </div>

      <!-- Volume Card -->
      <div class="relative overflow-hidden bg-gradient-to-br from-[#143d2e] to-[#1e6b4a] rounded-[2rem] p-6 text-white shadow-xl shadow-green-900/10 hover:scale-[1.01] transition-transform">
        <div class="flex justify-between items-start mb-4">
          <p class="text-xs font-bold uppercase tracking-widest text-green-200">Volume BBM</p>
          <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center text-green-200">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" d="M12 21a9 9 0 100-18 9 9 0 000 18z" /></svg>
          </div>
        </div>
        <h3 class="text-3xl lg:text-4xl font-black tracking-tight text-white mb-1">{{ totalNetworkVolume }}</h3>
        <p class="text-xs text-green-200/80 mb-3 font-medium">Total liter terjual ({{ periodLabel }})</p>
        <div class="absolute -right-6 -bottom-10 w-32 h-32 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
      </div>

      <!-- Active SPBU Card -->
      <div class="relative overflow-hidden bg-gradient-to-br from-[#143d2e] to-[#2aa672] rounded-[2rem] p-6 text-white shadow-xl shadow-green-900/10 hover:scale-[1.01] transition-transform">
        <div class="flex justify-between items-start mb-4">
          <p class="text-xs font-bold uppercase tracking-widest text-green-200">Total SPBU</p>
          <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center text-green-200">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" /></svg>
          </div>
        </div>
        <h3 class="text-3xl lg:text-4xl font-black tracking-tight text-white mb-1">{{ activeSpbuCountText }}</h3>
        <p class="text-xs text-green-200/80 mb-3 font-medium">Total jaringan SPBU terhubung</p>
        <div class="absolute -right-6 -bottom-10 w-32 h-32 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
      </div>

      <!-- Transactions Card -->
      <div class="relative overflow-hidden bg-gradient-to-br from-[#143d2e] to-[#208358] rounded-[2rem] p-6 text-white shadow-xl shadow-green-900/10 hover:scale-[1.01] transition-transform">
        <div class="flex justify-between items-start mb-4">
          <p class="text-xs font-bold uppercase tracking-widest text-green-200">{{ transactionCardTitle }}</p>
          <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center text-green-200">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
          </div>
        </div>
        <h3 class="text-3xl lg:text-4xl font-black tracking-tight text-white mb-1">{{ totalTransactionsCount }}</h3>
        <p class="text-xs text-green-200/80 mb-3 font-medium">Total transaksi ({{ periodLabel }})</p>
        <div class="absolute -right-6 -bottom-10 w-32 h-32 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
      </div>

    </div>

    <!-- Row 2: Volume Mingguan & Notifikasi Sistem -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

      <!-- Weekly Volume Bar Chart -->
      <div class="lg:col-span-2 bg-white rounded-[2rem] p-6 shadow-xl shadow-green-900/5 border border-gray-100 flex flex-col justify-between">
        <div>
          <h4 class="text-[#143d2e] font-black text-lg mb-0.5">Volume Mingguan Jaringan</h4>
          <p class="text-gray-400 text-xs font-medium mb-4">Total volume BBM terjual per hari dalam 7 hari terakhir (Real-time Database)</p>
        </div>
        <div class="h-44 w-full">
          <Bar :data="barChartData" :options="barChartOptions" />
        </div>
      </div>

      <!-- System Alerts / Notifications -->
      <div class="bg-white rounded-[2rem] p-6 shadow-xl shadow-green-900/5 border border-gray-100 flex flex-col justify-between">
        <div class="flex items-center justify-between mb-4">
          <h4 class="text-[#143d2e] font-black text-base">Notifikasi Sistem</h4>
          <div class="flex items-center gap-1 px-2.5 py-1 rounded-full bg-green-500/10 text-green-600 text-[10px] font-black">
            ● {{ alerts.length }} Aktif
          </div>
        </div>

        <div class="space-y-2.5 max-h-48 overflow-y-auto pr-1 hide-scrollbar">
          <div v-if="alerts.length === 0" class="py-12 text-center text-gray-400 text-xs font-medium">
            Tidak ada notifikasi sistem aktif saat ini.
          </div>
          <div
            v-for="a in alerts"
            :key="a.id"
            class="p-3 rounded-2xl border transition-all"
            :class="[
              a.severity === 'critical' ? 'bg-red-50/50 border-red-100' :
              a.severity === 'warning' ? 'bg-amber-50/50 border-amber-100' :
              'bg-green-50/50 border-green-100'
            ]"
          >
            <div class="flex items-start gap-2.5">
              <div
                class="w-2 h-2 rounded-full mt-1.5 flex-shrink-0"
                :class="[
                  a.severity === 'critical' ? 'bg-red-500 animate-ping' :
                  a.severity === 'warning' ? 'bg-amber-400' : 'bg-green-500'
                ]"
              ></div>
              <div class="flex-1 min-w-0">
                <p class="text-gray-800 font-bold text-xs truncate">{{ a.spbu }}</p>
                <p class="text-gray-600 text-[11px] mt-0.5 leading-snug">{{ a.msg }}</p>
                <p class="text-gray-400 text-[10px] mt-1 font-medium">{{ a.time }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

    </div>

    <!-- Row 3: SPBU Interactive Expandable Accordion List -->
    <div class="bg-white rounded-[2rem] p-6 shadow-xl shadow-green-900/5 border border-gray-100">

      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-5">
        <div>
          <h4 class="text-[#143d2e] font-black text-lg">Performa SPBU Jaringan</h4>
          <p class="text-gray-400 text-xs font-medium mt-0.5">Daftar SPBU terhubung (Filter: {{ periodLabel }})</p>
        </div>

        <!-- Search Bar SPBU -->
        <div class="relative w-full sm:w-64">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Cari SPBU..."
            class="w-full pl-9 pr-4 py-2 rounded-full bg-gray-50 border border-gray-200 text-xs text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-transparent transition-all shadow-xs"
          />
        </div>
      </div>

      <div class="space-y-3">
        <!-- Empty State Filter -->
        <div v-if="filteredSpbuList.length === 0" class="py-12 text-center text-gray-400 text-xs font-medium border border-dashed border-gray-200 rounded-2xl">
          <p class="text-gray-500 font-bold text-sm mb-1">Belum ada data SPBU di database</p>
        </div>

        <div
          v-for="(spbu, index) in filteredSpbuList"
          :key="spbu.id"
          class="rounded-2xl transition-all duration-300 overflow-hidden border"
          :class="[
            activeSpbuId === spbu.id
              ? 'bg-gradient-to-b from-green-50/50 to-white border-[#143d2e]/20 shadow-md ring-1 ring-[#143d2e]/10'
              : 'bg-white hover:bg-gray-50/80 border-gray-100'
          ]"
        >
          <!-- Accordion Header Bar -->
          <button
            @click="toggleSpbuAccordion(spbu.id)"
            class="w-full flex items-center gap-3 p-3.5 text-left transition-colors cursor-pointer select-none"
          >
            <!-- Sequential Index Badge (1, 2, 3...) -->
            <div
              class="w-8 h-8 rounded-xl flex-shrink-0 flex items-center justify-center text-xs font-black text-white shadow-sm"
              style="background: linear-gradient(135deg, #143d2e, #258f62)"
            >
              {{ index + 1 }}
            </div>

            <div class="flex-1 min-w-0">
              <p class="text-gray-900 font-bold text-sm truncate">{{ spbu.name }}</p>
              <div class="flex items-center gap-1.5 mt-0.5 text-gray-400">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="w-3 h-3"><path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" /><path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" /></svg>
                <p class="text-[11px] truncate">{{ spbu.location }}</p>
              </div>
            </div>

            <div class="text-right flex items-center gap-3 pr-2">
              <div>
                <p class="text-[10px] text-gray-400 uppercase font-bold tracking-wider">Revenue</p>
                <p class="text-[#143d2e] font-black text-sm leading-tight">{{ formatRupiah(spbu.revenue) }}</p>
              </div>
              <div class="h-6 w-px bg-gray-200"></div>
              <div>
                <p class="text-[10px] text-gray-400 uppercase font-bold tracking-wider">Volume</p>
                <p class="text-gray-800 font-bold text-sm leading-tight">{{ formatVolume(spbu.volume) }}</p>
              </div>
            </div>

            <!-- Chevron Toggle Button -->
            <div
              class="w-7 h-7 rounded-full flex items-center justify-center transition-transform duration-200"
              :class="[
                activeSpbuId === spbu.id ? 'bg-[#143d2e] text-white rotate-180' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
              ]"
            >
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5"><path stroke-linecap="round" stroke-linejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" /></svg>
            </div>
          </button>

          <!-- Accordion Expanded Content -->
          <div
            v-if="activeSpbuId === spbu.id"
            class="px-4 pb-5 pt-3 border-t border-gray-100/80 space-y-4 animate-enter"
          >
            <div class="flex flex-col sm:flex-row items-center justify-between gap-3 p-3 rounded-2xl bg-gray-50/80 border border-gray-100">
              <div class="text-xs text-gray-600 font-medium">
                Manager Penanggung Jawab: <strong class="text-[#143d2e] font-bold">{{ spbu.manager }}</strong>
              </div>

              <div class="flex items-center gap-2 w-full sm:w-auto">
                <button class="flex-1 sm:flex-none px-3.5 py-2 rounded-xl bg-white hover:bg-gray-100 text-gray-700 text-xs font-bold transition-colors cursor-pointer border border-gray-200">
                  📞 Hubungi Manager
                </button>
                <button
                  @click="goToSpbuConsole(spbu)"
                  class="flex-1 sm:flex-none px-4 py-2 rounded-xl bg-[#143d2e] hover:bg-[#1e5c45] text-white text-xs font-bold transition-all shadow-md shadow-green-900/10 cursor-pointer flex items-center justify-center gap-1.5"
                >
                  🚀 Buka Console Manager SPBU →
                </button>
              </div>
            </div>

            <!-- 10 Transaksi Terakhir SPBU Ini -->
            <div class="bg-white rounded-2xl p-4 border border-gray-100 shadow-sm">
              <div class="flex items-center justify-between mb-3">
                <div class="flex items-center gap-2">
                  <h5 class="text-xs font-black text-[#143d2e] uppercase tracking-wider">10 Transaksi Terakhir ({{ periodLabel }})</h5>
                </div>
                <span class="text-[10px] text-gray-400 font-medium">Real-time Feed · {{ spbu.name }}</span>
              </div>

              <div class="space-y-2 max-h-64 overflow-y-auto pr-1 hide-scrollbar">
                <div v-if="getRecentTransactions(spbu.id).length === 0" class="py-6 text-center text-gray-400 text-xs font-medium">
                  Belum ada transaksi tercatat pada periode ({{ periodLabel }}) untuk SPBU ini.
                </div>
                <div
                  v-for="tx in getRecentTransactions(spbu.id)"
                  :key="tx.id"
                  class="flex items-center justify-between p-2.5 rounded-xl bg-gray-50 hover:bg-green-50/40 border border-gray-100 transition-colors"
                >
                  <div class="flex items-center gap-3">
                    <div class="px-2.5 py-1 bg-[#143d2e] text-white rounded-lg text-xs font-mono font-black tracking-wider shadow-xs">
                      {{ tx.plat }}
                    </div>
                    <div>
                      <p class="text-xs font-bold text-gray-800">{{ tx.time }}</p>
                    </div>
                  </div>

                  <div class="text-right">
                    <p class="text-xs font-black text-[#143d2e]">{{ tx.liter }}</p>
                    <p class="text-[10px] text-gray-500 font-semibold">{{ tx.amount }}</p>
                  </div>
                </div>
              </div>
            </div>

          </div>

        </div>
      </div>

    </div>

  </div>
</template>
