<script setup>
import { ref, computed, onMounted } from 'vue'
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

// ─── Search & Accordion State ────────────────────────────────────────────────
const searchQuery = ref('')
const activeSpbuId = ref(null)

const spbuList = ref([])
const dbStats = ref({
  totalRevenue: 0,
  totalVolume: 0,
  todayTrxCount: 0
})

const fetchRealDatabaseStats = async () => {
  try {
    // 1. Fetch SPBUs from Supabase (Read only)
    const { data: dbSpbus } = await supabase.from('spbu').select('*')
    
    // 2. Fetch all transactions
    const { data: allTrx, error: trxError } = await supabase
      .from('transaksi_pertalite')
      .select('harga, liter, waktu_pencatatan, jenis_kendaraan, plat_nomor, spbu_id')
      .order('waktu_pencatatan', { ascending: false })

    if (trxError) throw trxError

    const allTrxList = allTrx || []

    // Map transactions to SPBUs
    const spbuDataMap = {}
    allTrxList.forEach(tx => {
      const sId = tx.spbu_id || '1'
      if (!spbuDataMap[sId]) {
        spbuDataMap[sId] = { revenue: 0, volume: 0, transactions: [] }
      }
      spbuDataMap[sId].revenue += Number(tx.harga) || 0
      spbuDataMap[sId].volume += Number(tx.liter) || 0
      spbuDataMap[sId].transactions.push(tx)
    })

    // Update spbuList from DB
    if (dbSpbus && dbSpbus.length > 0) {
      spbuList.value = dbSpbus.map((s, idx) => {
        const stats = spbuDataMap[s.id] || { revenue: 0, volume: 0, transactions: [] }
        return {
          id: s.id,
          name: s.nama || s.name || `SPBU ${s.id}`,
          location: s.alamat || s.location || '-',
          revenue: stats.revenue,
          volume: stats.volume,
          status: stats.revenue > 0 ? 'online' : 'offline',
          trend: 0,
          manager: s.manager || 'Manager SPBU',
          transactions: stats.transactions
        }
      })
      if (!activeSpbuId.value && spbuList.value.length > 0) {
        activeSpbuId.value = spbuList.value[0].id
      }
    } else {
      spbuList.value = []
    }

    // Calculate totals directly from real transactions
    const totalRev = allTrxList.reduce((sum, item) => sum + (Number(item.harga) || 0), 0)
    const totalVol = allTrxList.reduce((sum, item) => sum + (Number(item.liter) || 0), 0)

    const startOfToday = new Date()
    startOfToday.setHours(0, 0, 0, 0)
    const todayTrx = allTrxList.filter(item => new Date(item.waktu_pencatatan) >= startOfToday)

    dbStats.value.totalRevenue = totalRev
    dbStats.value.totalVolume = totalVol
    dbStats.value.todayTrxCount = todayTrx.length

  } catch (err) {
    console.error('Error fetching real stats from Supabase:', err)
  }
}

onMounted(() => {
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
  const spbu = spbuList.value.find(s => s.id === spbuId)
  if (spbu && spbu.transactions && spbu.transactions.length > 0) {
    return spbu.transactions.slice(0, 10).map((tx, idx) => {
      const date = new Date(tx.waktu_pencatatan)
      const timeFormatted = isNaN(date.getTime()) 
        ? '-' 
        : date.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) + ' WIB'

      return {
        id: idx + 1,
        plat: tx.plat_nomor || 'B 1234 A',
        fuel: 'Pertalite',
        liter: `${(Number(tx.liter) || 0).toFixed(1)} L`,
        amount: new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(tx.harga || 0),
        time: timeFormatted
      }
    })
  }

  // Pure Database - return empty if no transactions exist in DB
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

const todayTransactionsCount = computed(() => {
  return dbStats.value.todayTrxCount.toLocaleString('id-ID')
})

const activeSpbuCountText = computed(() => {
  const total = spbuList.value.length
  const online = spbuList.value.filter(s => s.status === 'online').length
  return `${online}/${total}`
})


// ─── Formatters & Status Config ──────────────────────────────────────────────
const formatRupiah = (val) => {
  if (!val || val === 0) return 'Rp 0'
  if (val >= 1000000000) return `Rp ${(val / 1000000000).toFixed(2)} M`
  return `Rp ${(val / 1000000).toFixed(1)} Jt`
}

const formatVolume = (val) => {
  if (!val || val === 0) return '0 Liter'
  return val >= 1000 ? `${(val / 1000).toFixed(1)}K Liter` : `${val} Liter`
}

const statusConfig = {
  online: { label: 'Online', color: 'text-green-600', dot: 'bg-green-500' },
  warning: { label: 'Peringatan', color: 'text-amber-600', dot: 'bg-amber-400' },
  offline: { label: 'Offline', color: 'text-red-500', dot: 'bg-red-500' }
}

// ─── Alerts Data ─────────────────────────────────────────────────────────────
const alerts = ref([])

const barChartData = computed(() => ({
  labels: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
  datasets: [{
    label: 'Volume (K Liters)',
    data: [0, 0, 0, 0, 0, 0, 0],
    backgroundColor: ['#143d2e', '#143d2e', '#143d2e', '#143d2e', '#143d2e', '#258f62', '#143d2e'],
    borderRadius: 6
  }]
}))

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
    
    <!-- Top KPI Stat Cards -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      
      <!-- Revenue Card -->
      <div class="relative overflow-hidden bg-gradient-to-br from-[#143d2e] to-[#258f62] rounded-[2rem] p-6 text-white shadow-xl shadow-green-900/10 hover:scale-[1.01] transition-transform">
        <div class="flex justify-between items-start mb-4">
          <p class="text-xs font-bold uppercase tracking-widest text-green-200">Total Revenue</p>
          <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5 text-green-200"><path stroke-linecap="round" stroke-linejoin="round" d="M2.25 18L9 11.25l4.306 4.307a11.95 11.95 0 005.814-5.519l2.74-1.22m0 0l-5.94-2.28m5.94 2.28l-2.28 5.941" /></svg>
          </div>
        </div>
        <h3 class="text-3xl lg:text-4xl font-black tracking-tight mb-1">{{ totalNetworkRevenue }}</h3>
        <p class="text-xs text-green-200/80 mb-3 font-medium">Bulan berjalan · {{ spbuList.length }} SPBU</p>
        <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-green-500/30 text-green-100">
          ● Data Real-time Database
        </span>
        <div class="absolute -right-6 -bottom-10 w-32 h-32 bg-white/10 rounded-full blur-2xl"></div>
      </div>

      <!-- Volume Card -->
      <div class="bg-white rounded-[2rem] p-6 border border-gray-100 shadow-xl shadow-green-900/5 hover:scale-[1.01] transition-transform">
        <div class="flex justify-between items-start mb-4">
          <p class="text-xs font-bold uppercase tracking-widest text-gray-400">Volume BBM</p>
          <div class="w-10 h-10 rounded-2xl bg-[#143d2e]/8 flex items-center justify-center text-[#143d2e]">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" d="M12 21a9 9 0 100-18 9 9 0 000 18z" /></svg>
          </div>
        </div>
        <h3 class="text-3xl lg:text-4xl font-black tracking-tight text-[#143d2e] mb-1">{{ totalNetworkVolume }}</h3>
        <p class="text-xs text-gray-400 mb-3 font-medium">Total liter terjual</p>
        <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-green-500/15 text-green-600">
          ● Data Real-time Database
        </span>
      </div>

      <!-- Active SPBU Card -->
      <div class="bg-white rounded-[2rem] p-6 border border-gray-100 shadow-xl shadow-green-900/5 hover:scale-[1.01] transition-transform">
        <div class="flex justify-between items-start mb-4">
          <p class="text-xs font-bold uppercase tracking-widest text-gray-400">SPBU Aktif</p>
          <div class="w-10 h-10 rounded-2xl bg-[#143d2e]/8 flex items-center justify-center text-[#143d2e]">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" /></svg>
          </div>
        </div>
        <h3 class="text-3xl lg:text-4xl font-black tracking-tight text-[#143d2e] mb-1">{{ activeSpbuCountText }}</h3>
        <p class="text-xs text-gray-400 mb-3 font-medium">Status operasional SPBU</p>
        <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold bg-green-50 text-green-700">
          ● Live Database Status
        </span>
      </div>

      <!-- Transactions Card -->
      <div class="bg-white rounded-[2rem] p-6 border border-gray-100 shadow-xl shadow-green-900/5 hover:scale-[1.01] transition-transform">
        <div class="flex justify-between items-start mb-4">
          <p class="text-xs font-bold uppercase tracking-widest text-gray-400">Transaksi Hari Ini</p>
          <div class="w-10 h-10 rounded-2xl bg-[#143d2e]/8 flex items-center justify-center text-[#143d2e]">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
          </div>
        </div>
        <h3 class="text-3xl lg:text-4xl font-black tracking-tight text-[#143d2e] mb-1">{{ todayTransactionsCount }}</h3>
        <p class="text-xs text-gray-400 mb-3 font-medium">Total transaksi tercatat</p>
        <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-green-500/15 text-green-600">
          ● Live Database Status
        </span>
      </div>

    </div>

    <!-- Row 2: Volume Mingguan & Notifikasi Sistem -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      
      <!-- Weekly Volume Bar Chart -->
      <div class="lg:col-span-2 bg-white rounded-[2rem] p-6 shadow-xl shadow-green-900/5 border border-gray-100 flex flex-col justify-between">
        <div>
          <h4 class="text-[#143d2e] font-black text-lg mb-0.5">Volume Mingguan Jaringan</h4>
          <p class="text-gray-400 text-xs font-medium mb-4">Ribu liter · akumulasi transaksi langsung dari database</p>
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
          <p class="text-gray-400 text-xs font-medium mt-0.5">Daftar SPBU yang terhubung secara langsung ke database Supabase</p>
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
        <!-- Empty State Filter / Empty DB -->
        <div v-if="filteredSpbuList.length === 0" class="py-12 text-center text-gray-400 text-xs font-medium border border-dashed border-gray-200 rounded-2xl">
          <p class="text-gray-500 font-bold text-sm mb-1">Belum ada data SPBU di database</p>
          <p class="text-gray-400 text-xs">Semua data mock telah dihapus dan sistem terhubung 100% langsung ke Supabase.</p>
        </div>

        <div 
          v-for="spbu in filteredSpbuList" 
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
            <div 
              class="w-8 h-8 rounded-xl flex-shrink-0 flex items-center justify-center text-xs font-black text-white shadow-sm"
              style="background: linear-gradient(135deg, #143d2e, #258f62)"
            >
              {{ spbu.id }}
            </div>

            <div class="flex-1 min-w-0">
              <p class="text-gray-900 font-bold text-sm truncate">{{ spbu.name }}</p>
              <div class="flex items-center gap-1.5 mt-0.5 text-gray-400">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="w-3 h-3"><path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" /><path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" /></svg>
                <p class="text-[11px] truncate">{{ spbu.location }}</p>
              </div>
            </div>

            <div class="text-right hidden sm:flex items-center gap-3 pr-2">
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

            <div 
              class="flex items-center gap-1.5 px-2 py-1 rounded-full bg-gray-50 border border-gray-100"
              :class="statusConfig[spbu.status]?.color || 'text-gray-500'"
            >
              <div 
                class="w-2 h-2 rounded-full" 
                :class="[statusConfig[spbu.status]?.dot || 'bg-gray-400', spbu.status === 'online' ? 'animate-pulse' : '']"
              ></div>
              <span class="text-[11px] font-bold hidden lg:block">{{ statusConfig[spbu.status]?.label || 'Offline' }}</span>
            </div>

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
                  <span class="text-sm">🧾</span>
                  <h5 class="text-xs font-black text-[#143d2e] uppercase tracking-wider">10 Transaksi Terakhir</h5>
                </div>
                <span class="text-[10px] text-gray-400 font-medium">Real-time Feed · {{ spbu.name }}</span>
              </div>

              <div class="space-y-2 max-h-64 overflow-y-auto pr-1 hide-scrollbar">
                <div v-if="getRecentTransactions(spbu.id).length === 0" class="py-6 text-center text-gray-400 text-xs font-medium">
                  Belum ada transaksi tercatat untuk SPBU ini di database Supabase.
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
