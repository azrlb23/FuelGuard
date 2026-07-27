<script setup>
import { ref, computed } from 'vue'
import { useMasterAnalytics } from '@/composables/useMasterAnalytics'
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
import { Bar, Doughnut } from 'vue-chartjs'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, BarElement, ArcElement, Title, Tooltip, Legend, Filler)

const dateFromRef = ref(null)
const dateToRef = ref(null)

const triggerDateFrom = () => {
  if (dateFromRef.value) {
    if (typeof dateFromRef.value.showPicker === 'function') dateFromRef.value.showPicker()
    else dateFromRef.value.focus()
  }
}

const triggerDateTo = () => {
  if (dateToRef.value) {
    if (typeof dateToRef.value.showPicker === 'function') dateToRef.value.showPicker()
    else dateToRef.value.focus()
  }
}

const {
  loading,
  dateFrom,
  dateTo,
  selectedSpbuId,
  spbuOptions,
  kpi,
  trendData,
  leaderboard,
  exportToExcel,
  exportToPDF
} = useMasterAnalytics()

// ─── Formatters ──────────────────────────────────────────────────────────────
const formatRupiah = (val) => {
  if (!val || val === 0) return 'Rp 0'
  if (val >= 1000000000) return `Rp ${(val / 1000000000).toFixed(2)} M`
  if (val >= 1000000) return `Rp ${(val / 1000000).toFixed(1)} Jt`
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val)
}

const formatVolume = (val) => {
  if (!val || val === 0) return '0 L'
  return val >= 1000 ? `${(val / 1000).toFixed(1)}K L` : `${val.toFixed(1)} L`
}

// ─── Chart Data Configurations ────────────────────────────────────────────────
const trendChartData = computed(() => {
  const labels = trendData.value.map(t => t.date)
  const salesData = trendData.value.map(t => Number((t.sales / 1000000).toFixed(2)))

  return {
    labels: labels.length > 0 ? labels : ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
    datasets: [
      {
        label: 'Revenue (Juta Rp)',
        data: salesData.length > 0 ? salesData : [0, 0, 0, 0, 0, 0, 0],
        backgroundColor: '#22c55e',
        borderRadius: 8,
        barThickness: 20
      }
    ]
  }
})

const trendChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: {
      backgroundColor: '#0f2e23',
      titleFont: { size: 12, weight: 'bold' },
      bodyFont: { size: 12 },
      padding: 12,
      cornerRadius: 12,
      callbacks: {
        label: (ctx) => `Revenue: Rp ${ctx.raw} Jt`
      }
    }
  },
  scales: {
    x: {
      grid: { display: false },
      ticks: { font: { size: 11, weight: '600' }, color: '#9ca3af' }
    },
    y: {
      grid: { color: '#f3f4f6' },
      ticks: { font: { size: 11, weight: '600' }, color: '#9ca3af' }
    }
  }
}

const doughnutChartData = computed(() => {
  const labels = leaderboard.value.map(l => l.spbu_name)
  const shares = leaderboard.value.map(l => l.share_pct)

  const palette = ['#143d2e', '#22c55e', '#10b981', '#34d399', '#6ee7b7', '#a7f3d0']

  return {
    labels: labels.length > 0 ? labels : ['No Data'],
    datasets: [
      {
        data: shares.length > 0 ? shares : [100],
        backgroundColor: palette.slice(0, Math.max(labels.length, 1)),
        borderWidth: 0,
        hoverOffset: 6
      }
    ]
  }
})

const doughnutChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'bottom',
      labels: { font: { size: 11, weight: 'bold' }, padding: 14, usePointStyle: true, pointStyle: 'circle' }
    },
    tooltip: {
      backgroundColor: '#0f2e23',
      padding: 10,
      cornerRadius: 10,
      callbacks: {
        label: (ctx) => `${ctx.label}: ${ctx.raw}%`
      }
    }
  },
  cutout: '70%'
}
</script>

<template>
  <div class="space-y-6 animate-enter">

    <!-- Header Section: Title & Controls -->
    <div>
      <h2 class="text-2xl sm:text-3xl md:text-4xl font-extrabold text-black tracking-tight mb-1">Analisis & Laporan</h2>
      <p class="text-gray-500 text-xs sm:text-sm font-bold">Benchmarking performa jaringan SPBU & rekapitulasi operasional eksekutif</p>
    </div>

    <!-- Filter Bar: Date Range + SPBU Select -->
    <div class="bg-white rounded-2xl p-3.5 sm:p-4 border border-gray-200/90 shadow-xs flex flex-col sm:flex-row sm:flex-wrap items-stretch sm:items-center gap-3">
      
      <!-- Date From -->
      <div
        @click="triggerDateFrom"
        class="group relative flex items-center gap-2.5 bg-gray-50/90 hover:bg-gray-100/90 border border-gray-200/90 focus-within:border-[#143d2e] focus-within:ring-2 focus-within:ring-[#143d2e]/15 focus-within:bg-white rounded-full px-4 py-2 text-xs font-bold text-gray-700 flex-1 min-w-[150px] transition-all cursor-pointer shadow-2xs"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-[#143d2e] group-hover:scale-110 transition-transform shrink-0">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
        </svg>
        <span class="text-[#143d2e]/60 uppercase text-[10px] tracking-wider font-extrabold shrink-0">Dari</span>
        <input
          ref="dateFromRef"
          v-model="dateFrom"
          type="date"
          class="bg-transparent outline-none text-gray-800 font-bold text-xs sm:text-sm cursor-pointer w-full"
          @click.stop
        />
      </div>

      <!-- Date To -->
      <div
        @click="triggerDateTo"
        class="group relative flex items-center gap-2.5 bg-gray-50/90 hover:bg-gray-100/90 border border-gray-200/90 focus-within:border-[#143d2e] focus-within:ring-2 focus-within:ring-[#143d2e]/15 focus-within:bg-white rounded-full px-4 py-2 text-xs font-bold text-gray-700 flex-1 min-w-[150px] transition-all cursor-pointer shadow-2xs"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-[#143d2e] group-hover:scale-110 transition-transform shrink-0">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
        </svg>
        <span class="text-[#143d2e]/60 uppercase text-[10px] tracking-wider font-extrabold shrink-0">Sampai</span>
        <input
          ref="dateToRef"
          v-model="dateTo"
          type="date"
          class="bg-transparent outline-none text-gray-800 font-bold text-xs sm:text-sm cursor-pointer w-full"
          @click.stop
        />
      </div>

      <!-- SPBU Select Dropdown -->
      <div class="group relative flex items-center gap-2 bg-gray-50/90 hover:bg-gray-100/90 border border-gray-200/90 focus-within:border-[#143d2e] focus-within:ring-2 focus-within:ring-[#143d2e]/15 focus-within:bg-white rounded-full px-4 py-2 text-xs font-bold text-gray-700 flex-1 min-w-[200px] transition-all shadow-2xs">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-[#143d2e] group-hover:scale-110 transition-transform shrink-0">
          <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 21v-7.5a.75.75 0 0 1 .75-.75h3a.75.75 0 0 1 .75.75V21m-4.5 0H2.25a.75.75 0 0 1-.75-.75V4.5a.75.75 0 0 1 .75-.75h19.5a.75.75 0 0 1 .75.75v15.75a.75.75 0 0 1-.75.75H18m-4.5 0v-7.5" />
        </svg>
        <span class="text-[#143d2e]/60 uppercase text-[10px] tracking-wider font-extrabold shrink-0">SPBU</span>
        <select
          v-model="selectedSpbuId"
          class="appearance-none bg-transparent outline-none text-gray-800 font-bold text-xs sm:text-sm cursor-pointer w-full pr-6 truncate z-10"
        >
          <option value="">Semua SPBU Jaringan</option>
          <option v-for="s in spbuOptions" :key="s.id" :value="s.id">{{ s.name }}</option>
        </select>
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5 text-gray-400 absolute right-4 pointer-events-none group-hover:text-[#143d2e] transition-colors">
          <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
        </svg>
      </div>

      <div class="sm:ml-auto text-xs font-bold self-end sm:self-center">
        <span v-if="loading" class="animate-pulse text-emerald-600">Memuat data...</span>
        <span v-else class="text-emerald-700 bg-emerald-50 px-3 py-1 rounded-full border border-emerald-100 inline-block font-bold">Filter Aktif</span>
      </div>
    </div>

    <!-- Row 1: KPI Summary Cards (Rich Dark Green Palette) -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      
      <!-- Card 1: Total Revenue -->
      <div class="bg-gradient-to-br from-[#143d2e] to-[#1e5c45] rounded-3xl p-6 shadow-xl shadow-green-900/10 text-white relative overflow-hidden">
        <div class="flex justify-between items-start mb-4">
          <span class="text-xs font-bold text-green-200/80 uppercase tracking-wider">TOTAL GROSS SALES</span>
          <div class="w-10 h-10 rounded-2xl bg-white/10 flex items-center justify-center">
            <span class="text-lg">💰</span>
          </div>
        </div>
        <div class="text-2xl lg:text-3xl font-black text-white tracking-tight mb-1">
          {{ formatRupiah(kpi.total_sales) }}
        </div>
        <p class="text-[11px] text-green-200/70 font-semibold">Total omzet penjualan BBM</p>
      </div>

      <!-- Card 2: Total Volume -->
      <div class="bg-gradient-to-br from-[#143d2e] to-[#1a4a38] rounded-3xl p-6 shadow-xl shadow-green-900/10 text-white relative overflow-hidden">
        <div class="flex justify-between items-start mb-4">
          <span class="text-xs font-bold text-green-200/80 uppercase tracking-wider">TOTAL VOLUME BBM</span>
          <div class="w-10 h-10 rounded-2xl bg-white/10 flex items-center justify-center">
            <span class="text-lg">⛽</span>
          </div>
        </div>
        <div class="text-2xl lg:text-3xl font-black text-white tracking-tight mb-1">
          {{ formatVolume(kpi.total_volume) }}
        </div>
        <p class="text-[11px] text-green-200/70 font-semibold">Total volume penyaluran</p>
      </div>

      <!-- Card 3: Total Transaksi -->
      <div class="bg-gradient-to-br from-[#143d2e] to-[#164433] rounded-3xl p-6 shadow-xl shadow-green-900/10 text-white relative overflow-hidden">
        <div class="flex justify-between items-start mb-4">
          <span class="text-xs font-bold text-green-200/80 uppercase tracking-wider">TOTAL TRANSAKSI</span>
          <div class="w-10 h-10 rounded-2xl bg-white/10 flex items-center justify-center">
            <span class="text-lg">🧾</span>
          </div>
        </div>
        <div class="text-2xl lg:text-3xl font-black text-white tracking-tight mb-1">
          {{ (kpi.total_trx || 0).toLocaleString('id-ID') }}
        </div>
        <p class="text-[11px] text-green-200/70 font-semibold">Jumlah struk tercatat</p>
      </div>

      <!-- Card 4: Avg Trx / Hari -->
      <div class="bg-gradient-to-br from-[#143d2e] to-[#0f2e23] rounded-3xl p-6 shadow-xl shadow-green-900/10 text-white relative overflow-hidden">
        <div class="flex justify-between items-start mb-4">
          <span class="text-xs font-bold text-green-200/80 uppercase tracking-wider">RERATA TRX / HARI</span>
          <div class="w-10 h-10 rounded-2xl bg-white/10 flex items-center justify-center">
            <span class="text-lg">📈</span>
          </div>
        </div>
        <div class="text-2xl lg:text-3xl font-black text-white tracking-tight mb-1">
          {{ kpi.avg_trx_per_day }}
        </div>
        <p class="text-[11px] text-green-200/70 font-semibold">Rata-rata frekuensi harian</p>
      </div>

    </div>

    <!-- Row 2: Charts Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

      <!-- Chart 1: Bar Combined Trend (2 Cols) -->
      <div class="lg:col-span-2 bg-white rounded-3xl p-6 border border-gray-200 shadow-sm flex flex-col justify-between">
        <div class="flex justify-between items-center mb-4">
          <div>
            <h4 class="text-base font-extrabold text-[#143d2e]">Tren Omzet Penjualan</h4>
            <p class="text-xs font-semibold text-gray-400">Grafik omzet harian pada periode terpilih</p>
          </div>
          <span class="text-xs font-bold px-3 py-1 bg-emerald-50 text-emerald-700 rounded-full border border-emerald-100">Revenue (Jt)</span>
        </div>

        <div class="h-64 relative">
          <Bar :data="trendChartData" :options="trendChartOptions" />
        </div>
      </div>

      <!-- Chart 2: Donut Contribution Share (1 Col) -->
      <div class="bg-white rounded-3xl p-6 border border-gray-200 shadow-sm flex flex-col justify-between">
        <div class="mb-4">
          <h4 class="text-base font-extrabold text-[#143d2e]">Kontribusi Penjualan</h4>
          <p class="text-xs font-semibold text-gray-400">Pangsa pasar omzet antar SPBU (%)</p>
        </div>

        <div class="h-64 relative flex items-center justify-center">
          <Doughnut :data="doughnutChartData" :options="doughnutChartOptions" />
        </div>
      </div>

    </div>

    <!-- Row 3: Leaderboard SPBU Benchmark Table & Mobile Cards -->
    <div class="bg-white rounded-3xl p-5 md:p-8 border border-gray-200 shadow-sm space-y-4">
      <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 border-b border-gray-100 pb-4">
        <div>
          <h3 class="text-lg sm:text-xl font-extrabold text-[#143d2e]">Leaderboard & Benchmarking SPBU</h3>
          <p class="text-xs font-semibold text-gray-400">Perbandingan kinerja omzet, volume, dan transaksi seluruh unit SPBU</p>
        </div>
        <span class="text-xs font-bold text-gray-500 bg-gray-100 px-3 py-1 rounded-full shrink-0">
          Total Unit: {{ leaderboard.length }} SPBU
        </span>
      </div>

      <!-- Mobile Card View -->
      <div class="block md:hidden space-y-3 pt-1">
        <template v-if="loading">
          <div v-for="n in 3" :key="n" class="bg-gray-50 rounded-2xl p-4 animate-pulse space-y-3 border border-gray-100">
            <div class="flex justify-between">
              <div class="h-5 w-28 bg-gray-200 rounded"></div>
              <div class="h-5 w-16 bg-gray-200 rounded"></div>
            </div>
            <div class="grid grid-cols-2 gap-2 pt-2">
              <div class="h-10 bg-gray-200 rounded-xl"></div>
              <div class="h-10 bg-gray-200 rounded-xl"></div>
            </div>
          </div>
        </template>

        <template v-else-if="leaderboard.length > 0">
          <div
            v-for="item in leaderboard"
            :key="item.spbu_id"
            class="bg-white rounded-2xl p-4 border border-gray-200 shadow-xs space-y-3 relative overflow-hidden"
          >
            <!-- Header: Rank + Name + Status -->
            <div class="flex items-center justify-between gap-2">
              <div class="flex items-center gap-2.5 min-w-0">
                <span
                  :class="[
                    'w-7 h-7 rounded-full text-xs font-black inline-flex items-center justify-center shrink-0 shadow-xs',
                    item.rank === 1 ? 'bg-amber-400 text-amber-950' : item.rank === 2 ? 'bg-slate-200 text-slate-800' : item.rank === 3 ? 'bg-amber-700/20 text-amber-800' : 'bg-gray-100 text-gray-600'
                  ]"
                >
                  #{{ item.rank }}
                </span>
                <h4 class="font-bold text-sm text-[#143d2e] truncate">
                  {{ item.spbu_name }}
                </h4>
              </div>

              <span
                :class="[
                  'inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold border shrink-0',
                  item.rank === 1 ? 'bg-amber-50 text-amber-700 border-amber-200' : item.sales === 0 ? 'bg-gray-100 text-gray-500 border-gray-200' : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                ]"
              >
                {{ item.status }}
              </span>
            </div>

            <!-- Metrics 2x2 Grid -->
            <div class="grid grid-cols-2 gap-2 bg-gray-50/80 p-3 rounded-xl border border-gray-100 text-xs">
              <div>
                <p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Revenue</p>
                <p class="font-black text-[#143d2e] mt-0.5">{{ formatRupiah(item.sales) }}</p>
              </div>
              <div>
                <p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Volume</p>
                <p class="font-bold text-gray-700 mt-0.5">{{ formatVolume(item.volume) }}</p>
              </div>
              <div class="pt-1.5 border-t border-gray-200/50">
                <p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Total Trx</p>
                <p class="font-semibold text-gray-600 mt-0.5">{{ item.total_trx }}</p>
              </div>
              <div class="pt-1.5 border-t border-gray-200/50">
                <p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Share (%)</p>
                <p class="font-black text-emerald-600 mt-0.5">{{ item.share_pct }}%</p>
              </div>
            </div>

            <!-- Share Progress bar -->
            <div class="w-full bg-gray-100 h-1.5 rounded-full overflow-hidden">
              <div
                class="bg-emerald-500 h-full rounded-full transition-all duration-500"
                :style="{ width: `${Math.min(100, Math.max(2, item.share_pct))}%` }"
              ></div>
            </div>
          </div>
        </template>

        <div v-else class="py-8 text-center text-gray-400 text-xs font-medium">
          Belum ada data untuk periode ini.
        </div>
      </div>

      <!-- Desktop Table View -->
      <div class="hidden md:block overflow-x-auto custom-scrollbar">
        <table class="w-full text-left border-collapse min-w-[700px]">
          <thead>
            <tr class="text-gray-400 text-[11px] font-bold uppercase tracking-wider border-b border-gray-100">
              <th class="py-3 px-3 text-center whitespace-nowrap">RANK</th>
              <th class="py-3 px-3 whitespace-nowrap">NAMA SPBU</th>
              <th class="py-3 px-3 text-right whitespace-nowrap">REVENUE</th>
              <th class="py-3 px-3 text-right whitespace-nowrap">VOLUME</th>
              <th class="py-3 px-3 text-center whitespace-nowrap">TOTAL TRX</th>
              <th class="py-3 px-3 text-right whitespace-nowrap">SHARE (%)</th>
              <th class="py-3 px-3 text-right whitespace-nowrap">STATUS PERFORMA</th>
            </tr>
          </thead>
          <tbody class="text-sm">
            <template v-if="loading">
              <tr v-for="n in 3" :key="n" class="border-b border-gray-50">
                <td class="py-4 px-3 text-center"><div class="skeleton h-6 w-6 bg-gray-200 rounded-full mx-auto"></div></td>
                <td class="py-4 px-3"><div class="skeleton h-4 w-36 bg-gray-200 rounded"></div></td>
                <td class="py-4 px-3 text-right"><div class="skeleton h-4 w-24 bg-gray-200 rounded ml-auto"></div></td>
                <td class="py-4 px-3 text-right"><div class="skeleton h-4 w-16 bg-gray-200 rounded ml-auto"></div></td>
                <td class="py-4 px-3 text-center"><div class="skeleton h-4 w-12 bg-gray-200 rounded mx-auto"></div></td>
                <td class="py-4 px-3 text-right"><div class="skeleton h-4 w-12 bg-gray-200 rounded ml-auto"></div></td>
                <td class="py-4 px-3 text-right"><div class="skeleton h-6 w-20 bg-gray-200 rounded-full ml-auto"></div></td>
              </tr>
            </template>

            <template v-else-if="leaderboard.length > 0">
              <tr
                v-for="item in leaderboard"
                :key="item.spbu_id"
                class="hover:bg-gray-50/80 transition-colors border-b border-gray-100 last:border-0"
              >
                <!-- Rank Badge -->
                <td class="py-4 px-3 text-center whitespace-nowrap">
                  <span
                    :class="[
                      'w-7 h-7 rounded-full text-xs font-black inline-flex items-center justify-center shadow-xs',
                      item.rank === 1 ? 'bg-amber-400 text-amber-950' : item.rank === 2 ? 'bg-slate-200 text-slate-800' : item.rank === 3 ? 'bg-amber-700/20 text-amber-800' : 'bg-gray-100 text-gray-600'
                    ]"
                  >
                    #{{ item.rank }}
                  </span>
                </td>

                <!-- SPBU Name -->
                <td class="py-4 px-3 font-bold text-[#143d2e] whitespace-nowrap">
                  {{ item.spbu_name }}
                </td>

                <!-- Revenue -->
                <td class="py-4 px-3 text-right font-black text-[#143d2e] whitespace-nowrap">
                  {{ formatRupiah(item.sales) }}
                </td>

                <!-- Volume -->
                <td class="py-4 px-3 text-right font-bold text-gray-700 whitespace-nowrap">
                  {{ formatVolume(item.volume) }}
                </td>

                <!-- Total Trx -->
                <td class="py-4 px-3 text-center font-semibold text-gray-600 whitespace-nowrap">
                  {{ item.total_trx }}
                </td>

                <!-- Share % -->
                <td class="py-4 px-3 text-right font-black text-emerald-600 whitespace-nowrap">
                  {{ item.share_pct }}%
                </td>

                <!-- Status Badge -->
                <td class="py-4 px-3 text-right whitespace-nowrap">
                  <span
                    :class="[
                      'inline-flex items-center px-3 py-1 rounded-full text-xs font-bold border',
                      item.rank === 1 ? 'bg-amber-50 text-amber-700 border-amber-200' : item.sales === 0 ? 'bg-gray-100 text-gray-500 border-gray-200' : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                    ]"
                  >
                    {{ item.status }}
                  </span>
                </td>
              </tr>
            </template>

            <tr v-else>
              <td colspan="7" class="py-12 text-center text-gray-400 font-medium">
                Belum ada data untuk periode ini.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Export Action Buttons (Paling Bawah) -->
    <div class="bg-white rounded-3xl p-5 md:p-6 border border-gray-200/90 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
      <div>
        <h4 class="text-base font-extrabold text-[#143d2e]">Unduh Laporan & Analytics</h4>
        <p class="text-xs font-semibold text-gray-400">Ekspor rekapitulasi data ke format Excel (.csv) atau Dokumen PDF</p>
      </div>

      <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 w-full sm:w-auto">
        <button
          @click="exportToExcel"
          class="flex-1 sm:flex-none flex items-center justify-center gap-2 px-5 py-3 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-700 hover:bg-emerald-100 text-xs font-bold transition-all shadow-xs cursor-pointer active:scale-95"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-emerald-600 shrink-0">
            <path stroke-linecap="round" stroke-linejoin="round" d="M3.375 19.5h17.25m-17.25 0a1.125 1.125 0 0 1-1.125-1.125M3.375 19.5h7.5c.621 0 1.125-.504 1.125-1.125m-8.625 1.125L12 10.5m0 0 4.5 4.5M12 10.5V3" />
          </svg>
          <span>Export Excel (.csv)</span>
        </button>

        <button
          @click="exportToPDF"
          class="flex-1 sm:flex-none flex items-center justify-center gap-2 px-6 py-3 rounded-full bg-[#143d2e] hover:bg-[#1e5c45] text-white text-xs font-bold transition-all shadow-md shadow-green-900/10 cursor-pointer active:scale-95"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-green-300 shrink-0">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6.72 13.829c-.24.03-.48.062-.72.096m.72-.096a42.415 42.415 0 0 1 10.56 0m-10.56 0L6.34 18m10.94-4.171c.24.03.48.062.72.096m-.72-.096L17.66 18m0 0 .229 2.523a1.125 1.125 0 0 1-1.12 1.227H7.231a1.125 1.125 0 0 1-1.12-1.227L6.34 18m11.318 0h1.091A2.25 2.25 0 0 0 21 15.75V9.456c0-1.081-.768-2.015-1.837-2.175a48.055 48.055 0 0 0-1.913-.247M3 9.456c0-1.081.768-2.015 1.837-2.175a48.087 48.087 0 0 1 1.913-.247m0 0a48.1 48.1 0 0 1 10.5 0" />
          </svg>
          <span>Export Laporan PDF</span>
        </button>
      </div>
    </div>

  </div>
</template>
