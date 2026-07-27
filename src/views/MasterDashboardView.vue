<script setup>
import { ref, computed, onMounted } from 'vue'

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
import { Bar } from 'vue-chartjs'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, BarElement, ArcElement, Title, Tooltip, Legend, Filler)

import { useMasterDashboard } from '@/composables/useMasterDashboard'

// ─── Master Dashboard State via Composable ──────────────────────────────────
const timeFilters = ['Today', 'Weekly', 'Monthly', 'All-Time']
const activeSpbuId = ref(null)

const {
  filterTime,
  searchQuery,
  stats,
  spbuList,
  weeklyVolumeByDay,
} = useMasterDashboard()

const isMounted = ref(false)

onMounted(() => {
  isMounted.value = true
})

const filteredSpbuList = computed(() => {
  if (!searchQuery.value.trim()) return spbuList.value
  const q = searchQuery.value.toLowerCase()
  return spbuList.value.filter(s =>
    (s.name && s.name.toLowerCase().includes(q)) ||
    (s.location && s.location.toLowerCase().includes(q)) ||
    (s.manager && s.manager.toLowerCase().includes(q))
  )
})

const toggleSpbuAccordion = (id) => {
  activeSpbuId.value = activeSpbuId.value === id ? null : id
}

const getRecentTransactions = (spbuId) => {
  const spbu = spbuList.value.find(s => String(s.id) === String(spbuId))
  if (spbu && spbu.transactions && spbu.transactions.length > 0) {
    return spbu.transactions.slice(0, 10).map((tx, idx) => {
      const date = new Date(tx.waktu_pencatatan)
      const isValid = !isNaN(date.getTime())
      const dateFormatted = isValid
        ? date.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })
        : '-'
      const timeFormatted = isValid
        ? date.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
        : '-'

      return {
        id: idx + 1,
        plat: tx.plat_nomor || '-',
        fuel: 'Pertalite',
        liter: `${(Number(tx.liter) || 0).toFixed(1)} L`,
        amount: new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(tx.harga || 0),
        date: dateFormatted,
        time: timeFormatted
      }
    })
  }

  return []
}

// ─── Network Statistics Computed Properties ──────────────────────────────────
const totalNetworkRevenue = computed(() => {
  const sum = stats.value.totalRevenue
  if (sum === 0) return 'Rp 0'
  if (sum >= 1000000000) return `Rp ${(sum / 1000000000).toFixed(2)} M`
  if (sum >= 1000000) return `Rp ${(sum / 1000000).toFixed(1)} Jt`
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(sum)
})

const totalNetworkVolume = computed(() => {
  const sum = stats.value.totalVolume
  if (sum === 0) return '0 L'
  return sum >= 1000 ? `${(sum / 1000).toFixed(1)}K L` : `${sum.toFixed(1)} L`
})

const totalTransactionsCount = computed(() => {
  return (stats.value.todayTrxCount || 0).toLocaleString('id-ID')
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
          <p class="text-gray-400 text-xs font-medium mb-4">Total volume BBM terjual per hari dalam 7 hari terakhir</p>
        </div>
        <div class="h-44 w-full">
          <Bar :data="barChartData" :options="barChartOptions" />
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
            class="w-full p-3.5 text-left transition-colors cursor-pointer select-none space-y-2.5 sm:space-y-0 sm:flex sm:items-center sm:gap-3"
          >
            <!-- Top section (Mobile full width / Desktop flex left) -->
            <div class="flex items-center gap-3 flex-1 min-w-0">
              <!-- Sequential Index Badge (1, 2, 3...) -->
              <div
                class="w-8 h-8 rounded-xl flex-shrink-0 flex items-center justify-center text-xs font-black text-white shadow-sm"
                style="background: linear-gradient(135deg, #143d2e, #258f62)"
              >
                {{ index + 1 }}
              </div>

              <div class="flex-1 min-w-0">
                <p class="text-gray-900 font-bold text-sm leading-tight break-words sm:truncate">{{ spbu.name }}</p>
                <div class="flex items-center gap-1.5 mt-0.5 text-gray-400">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="w-3 h-3 flex-shrink-0"><path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" /><path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" /></svg>
                  <p class="text-[11px] truncate">{{ spbu.location || '-' }}</p>
                </div>
              </div>

              <!-- Chevron Toggle Button (Mobile Top-Right) -->
              <div
                class="w-7 h-7 rounded-full flex-shrink-0 flex sm:hidden items-center justify-center transition-transform duration-200"
                :class="[
                  activeSpbuId === spbu.id ? 'bg-[#143d2e] text-white rotate-180' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
                ]"
              >
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5"><path stroke-linecap="round" stroke-linejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" /></svg>
              </div>
            </div>

            <!-- Bottom section (Mobile stacked metrics bar / Desktop right side) -->
            <div class="flex items-center justify-between sm:justify-end gap-3 pt-2 sm:pt-0 border-t border-gray-100 sm:border-t-0 pl-11 sm:pl-0 pr-0 sm:pr-2">
              <div class="flex items-center gap-4 sm:gap-3 w-full sm:w-auto justify-between sm:justify-start">
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

              <!-- Chevron Toggle Button (Desktop Right) -->
              <div
                class="w-7 h-7 rounded-full flex-shrink-0 hidden sm:flex items-center justify-center transition-transform duration-200"
                :class="[
                  activeSpbuId === spbu.id ? 'bg-[#143d2e] text-white rotate-180' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
                ]"
              >
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5"><path stroke-linecap="round" stroke-linejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" /></svg>
              </div>
            </div>
          </button>

          <!-- Accordion Expanded Content -->
          <div
            v-if="activeSpbuId === spbu.id"
            class="px-4 pb-5 pt-3 border-t border-gray-100/80 space-y-4 animate-enter"
          >
            <!-- 10 Transaksi Terakhir SPBU Ini -->
            <div class="bg-white rounded-2xl p-4 border border-gray-100 shadow-sm">
              <div class="flex items-center justify-between mb-3">
                <div class="flex items-center gap-2">
                  <h5 class="text-xs font-black text-[#143d2e] uppercase tracking-wider">10 Transaksi Terakhir ({{ periodLabel }})</h5>
                </div>
              </div>

              <div class="space-y-2 max-h-64 overflow-y-auto pr-1 hide-scrollbar">
                <div v-if="getRecentTransactions(spbu.id).length === 0" class="py-6 text-center text-gray-400 text-xs font-medium">
                  Belum ada transaksi tercatat pada periode ({{ periodLabel }}) untuk SPBU ini.
                </div>
                <div
                  v-for="tx in getRecentTransactions(spbu.id)"
                  :key="tx.id"
                  class="flex items-center justify-between p-2.5 rounded-xl bg-gray-50 hover:bg-green-50/40 border border-gray-100 transition-colors gap-2"
                >
                  <div class="flex items-center gap-2.5 sm:gap-3 min-w-0">
                    <div class="px-2.5 py-1 bg-[#143d2e] text-white rounded-lg text-xs font-mono font-black tracking-wider shadow-xs shrink-0">
                      {{ tx.plat }}
                    </div>
                    <div class="min-w-0">
                      <div class="flex flex-col sm:flex-row sm:items-center sm:gap-1.5 leading-tight">
                        <span class="text-xs font-bold text-gray-800 truncate">{{ tx.date }}</span>
                        <span class="text-[10px] sm:text-xs font-semibold text-gray-400 sm:text-gray-500 flex items-center gap-1">
                          <span class="hidden sm:inline text-gray-300">•</span>
                          {{ tx.time }}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div class="text-right shrink-0">
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
