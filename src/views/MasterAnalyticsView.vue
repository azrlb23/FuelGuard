<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import CustomDatePicker from '@/components/common/CustomDatePicker.vue'
import { useMasterAnalytics } from '@/composables/useMasterAnalytics'

import LazyLineChart from '@/components/common/LazyLineChart.vue'
import LazyDoughnutChart from '@/components/common/LazyDoughnutChart.vue'

const analyticsContainerRef = ref(null)
const isSpbuDropdownOpen = ref(false)

const toggleSpbuDropdown = () => {
  isSpbuDropdownOpen.value = !isSpbuDropdownOpen.value
}

const selectSpbu = (id) => {
  selectedSpbuId.value = id
  isSpbuDropdownOpen.value = false
}

const handleClickOutside = (e) => {
  if (analyticsContainerRef.value && !analyticsContainerRef.value.contains(e.target)) {
    isSpbuDropdownOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})

const selectedSpbuName = computed(() => {
  if (!selectedSpbuId.value) return 'Semua SPBU Jaringan'
  const found = spbuOptions.value.find(s => String(s.id) === String(selectedSpbuId.value))
  return found ? found.name : `SPBU #${selectedSpbuId.value}`
})

const {
  loading,
  dateFrom,
  dateTo,
  selectedSpbuId,
  spbuOptions,
  kpi,
  trendData,
  leaderboard,
  spbuShares,
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
        borderColor: '#22c55e',
        backgroundColor: (context) => {
          const ctx = context.chart.ctx
          const gradient = ctx.createLinearGradient(0, 0, 0, 300)
          gradient.addColorStop(0, 'rgba(34, 197, 94, 0.25)')
          gradient.addColorStop(1, 'rgba(34, 197, 94, 0.0)')
          return gradient
        },
        borderWidth: 3,
        fill: true,
        tension: 0.35,
        pointRadius: labels.length > 30 ? 2 : 4,
        pointHoverRadius: 6,
        pointBackgroundColor: '#22c55e',
        pointBorderColor: '#ffffff',
        pointBorderWidth: 2
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

const formatDateLabel = (dateStr) => {
  if (!dateStr) return 'Pilih Tanggal'
  const d = new Date(dateStr)
  if (isNaN(d.getTime())) return dateStr
  return d.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
}

const doughnutChartData = computed(() => {
  const labels = spbuShares.value.map(s => s.name)
  const shares = spbuShares.value.map(s => s.value)

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

    <!-- Header Section: Title & Controls (LCP Target) -->
    <div class="relative p-6 md:p-8 rounded-3xl overflow-hidden shadow-sm mb-4" style="background: linear-gradient(135deg, #143d2e 0%, #0f2e22 100%);">
      <!-- LCP Background Pattern (Inline SVG) -->
      <svg class="absolute inset-0 w-full h-full object-cover opacity-10 pointer-events-none" xmlns="http://www.w3.org/2000/svg" width="100%" height="100%">
        <defs>
          <pattern id="patternAnalytics" width="40" height="40" patternUnits="userSpaceOnUse">
            <path d="M0 40L40 0H20L0 20M40 40V20L20 40" fill="#34d399"/>
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#patternAnalytics)"/>
      </svg>
      <div class="relative z-10">
        <h2 class="text-3xl sm:text-4xl md:text-5xl font-black text-white tracking-tight mb-2" data-lcp="true">Analisis & Laporan</h2>
        <p class="text-emerald-100/80 text-xs sm:text-sm font-bold">Benchmarking performa jaringan SPBU & rekapitulasi operasional eksekutif</p>
      </div>
    </div>

    <!-- Filter Bar: Date Range + SPBU Select -->
    <div ref="analyticsContainerRef" class="bg-white rounded-2xl p-3.5 sm:p-4 border border-gray-200/90 shadow-xs flex flex-col sm:flex-row sm:flex-wrap items-stretch sm:items-center gap-3">
      
      <!-- Custom Date From -->
      <CustomDatePicker
        v-model="dateFrom"
        label="Dari"
        placeholder="Pilih Tanggal"
        variant="light"
      />

      <!-- Custom Date To -->
      <CustomDatePicker
        v-model="dateTo"
        label="Sampai"
        placeholder="Pilih Tanggal"
        variant="light"
      />

      <!-- Custom SPBU Select Dropdown -->
      <div class="relative flex-1 min-w-[200px]">
        <button
          type="button"
          @click="toggleSpbuDropdown"
          class="w-full flex items-center justify-between gap-2.5 bg-gray-50/90 hover:bg-gray-100/90 border border-gray-200/90 focus-within:border-[#143d2e] focus-within:ring-2 focus-within:ring-[#143d2e]/15 rounded-full px-4 py-2 text-xs font-bold text-gray-700 transition-all cursor-pointer select-none shadow-2xs"
        >
          <div class="flex items-center gap-2 min-w-0">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-[#143d2e] shrink-0">
              <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 21v-7.5a.75.75 0 0 1 .75-.75h3a.75.75 0 0 1 .75.75V21m-4.5 0H2.25a.75.75 0 0 1-.75-.75V4.5a.75.75 0 0 1 .75-.75h19.5a.75.75 0 0 1 .75.75v15.75a.75.75 0 0 1-.75.75H18m-4.5 0v-7.5" />
            </svg>
            <span class="text-[#143d2e]/60 uppercase text-[10px] tracking-wider font-extrabold shrink-0">SPBU</span>
            <span class="text-gray-800 font-bold truncate">{{ selectedSpbuName }}</span>
          </div>
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" :class="['w-3.5 h-3.5 text-gray-400 transition-transform duration-200 shrink-0', isSpbuDropdownOpen ? 'rotate-180 text-[#143d2e]' : '']">
            <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
          </svg>
        </button>

        <!-- Custom Floating Dropdown Menu Card -->
        <div
          v-if="isSpbuDropdownOpen"
          class="absolute right-0 mt-2 w-full sm:w-64 bg-white rounded-2xl shadow-2xl border border-gray-100 p-1.5 z-50 animate-enter text-gray-800 text-xs font-bold space-y-0.5"
        >
          <button
            type="button"
            @click="selectSpbu('')"
            :class="[
              'w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl transition-all text-left cursor-pointer',
              selectedSpbuId === '' ? 'bg-[#143d2e]/10 text-[#143d2e] font-black' : 'hover:bg-gray-100 text-gray-700'
            ]"
          >
            <span>Semua SPBU Jaringan</span>
            <svg v-if="selectedSpbuId === ''" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="3" stroke="currentColor" class="w-3.5 h-3.5 text-[#143d2e]">
              <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
            </svg>
          </button>

          <button
            v-for="s in spbuOptions"
            :key="s.id"
            type="button"
            @click="selectSpbu(s.id)"
            :class="[
              'w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl transition-all text-left cursor-pointer',
              String(selectedSpbuId) === String(s.id) ? 'bg-[#143d2e]/10 text-[#143d2e] font-black' : 'hover:bg-gray-100 text-gray-700'
            ]"
          >
            <span class="truncate">{{ s.name }}</span>
            <svg v-if="String(selectedSpbuId) === String(s.id)" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="3" stroke="currentColor" class="w-3.5 h-3.5 text-[#143d2e] shrink-0">
              <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
            </svg>
          </button>
        </div>
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
          <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center text-white shadow-xs">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v12m-3-2.818l.879.659c1.171.879 3.07.879 4.242 0 1.172-.879 1.172-2.303 0-3.182C13.536 12.219 12.768 12 12 12c-.725 0-1.45-.22-2.003-.659-1.106-.879-1.106-2.303 0-3.182s2.9-.879 4.006 0l.415.33M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
            </svg>
          </div>
        </div>
        <div class="text-2xl lg:text-3xl font-black text-white tracking-tight mb-1">
          {{ formatRupiah(kpi.totalSales) }}
        </div>
        <p class="text-[11px] text-green-200/70 font-semibold">Total omzet penjualan BBM</p>
      </div>

      <!-- Card 2: Total Volume -->
      <div class="bg-gradient-to-br from-[#143d2e] to-[#1a4a38] rounded-3xl p-6 shadow-xl shadow-green-900/10 text-white relative overflow-hidden">
        <div class="flex justify-between items-start mb-4">
          <span class="text-xs font-bold text-green-200/80 uppercase tracking-wider">TOTAL VOLUME BBM</span>
          <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center text-white shadow-xs">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15.362 5.214A8.252 8.252 0 0 1 12 21 8.25 8.25 0 0 1 6.038 7.047 8.287 8.287 0 0 1 9 3.603e-7a8.287 8.287 0 0 1 6.362 5.214Z" />
            </svg>
          </div>
        </div>
        <div class="text-2xl lg:text-3xl font-black text-white tracking-tight mb-1">
          {{ formatVolume(kpi.totalVolume) }}
        </div>
        <p class="text-[11px] text-green-200/70 font-semibold">Total volume penyaluran</p>
      </div>

      <!-- Card 3: Total Transaksi -->
      <div class="bg-gradient-to-br from-[#143d2e] to-[#164433] rounded-3xl p-6 shadow-xl shadow-green-900/10 text-white relative overflow-hidden">
        <div class="flex justify-between items-start mb-4">
          <span class="text-xs font-bold text-green-200/80 uppercase tracking-wider">TOTAL TRANSAKSI</span>
          <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center text-white shadow-xs">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5.586a1 1 0 0 1 .707.293l5.414 5.414a1 1 0 0 1 .293.707V19a2 2 0 0 1-2 2Z" />
            </svg>
          </div>
        </div>
        <div class="text-2xl lg:text-3xl font-black text-white tracking-tight mb-1">
          {{ kpi.totalTransactions?.toLocaleString('id-ID') || 0 }}
        </div>
        <p class="text-[11px] text-green-200/70 font-semibold">Jumlah struk tercatat</p>
      </div>

      <!-- Card 4: Avg Trx / Hari -->
      <div class="bg-gradient-to-br from-[#143d2e] to-[#0f2e23] rounded-3xl p-6 shadow-xl shadow-green-900/10 text-white relative overflow-hidden">
        <div class="flex justify-between items-start mb-4">
          <span class="text-xs font-bold text-green-200/80 uppercase tracking-wider">RERATA TRX / HARI</span>
          <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center text-white shadow-xs">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 18 9 11.25l4.306 4.307a11.95 11.95 0 0 0 5.814-5.519l2.74-1.22m0 0-5.94-2.28m5.94 2.28-2.28 5.941" />
            </svg>
          </div>
        </div>
        <div class="text-2xl lg:text-3xl font-black text-white tracking-tight mb-1">
          {{ kpi.avgTrxPerDay }}
        </div>
        <p class="text-[11px] text-green-200/70 font-semibold">Rata-rata frekuensi harian</p>
      </div>

    </div>

    <!-- Row 2: Charts Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

      <!-- Chart 1: Line Combined Trend (2 Cols) -->
      <div class="lg:col-span-2 bg-white rounded-3xl p-6 border border-gray-200 shadow-sm flex flex-col justify-between">
        <div class="mb-4">
          <h4 class="text-base font-extrabold text-[#143d2e]">Tren Omzet Penjualan</h4>
          <p class="text-xs font-semibold text-gray-400">Grafik omzet harian pada periode terpilih</p>
        </div>

        <div class="h-64 relative w-full pt-4">
          <LazyLineChart v-if="trendChartData.labels.length" :data="trendChartData" :options="trendChartOptions" />
        </div>
      </div>

      <!-- Chart 2: Donut Contribution Share (1 Col) -->
      <div class="bg-white rounded-3xl p-6 border border-gray-200 shadow-sm flex flex-col justify-between">
        <div class="mb-4">
          <h4 class="text-base font-extrabold text-[#143d2e]">Kontribusi Penjualan</h4>
          <p class="text-xs font-semibold text-gray-400">Pangsa pasar omzet antar SPBU (%)</p>
        </div>

        <div class="h-64 relative flex items-center justify-center">
          <LazyDoughnutChart v-if="doughnutChartData.labels.length" :data="doughnutChartData" :options="doughnutChartOptions" />
        </div>

        <div class="space-y-4 max-h-[300px] overflow-y-auto pr-2 custom-scrollbar mt-6">
          <div v-for="(item, idx) in spbuShares" :key="item.spbu_id" class="flex items-center justify-between group">
            <div class="flex items-center gap-3">
              <div class="w-3 h-3 rounded-full" :style="{ backgroundColor: ['#143d2e', '#22c55e', '#10b981', '#34d399', '#6ee7b7', '#a7f3d0'][idx % 6] }"></div>
              <div>
                <div class="text-xs font-bold text-gray-800">{{ item.name }}</div>
                <div class="text-[10px] text-gray-500">{{ formatRupiah(item.sales) }}</div>
              </div>
            </div>
            <div class="text-right">
              <div class="text-sm font-black text-[#143d2e]">{{ item.value }}%</div>
            </div>
          </div>
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
            <!-- Header: Rank + Name -->
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
                  {{ item.name }}
                </h4>
              </div>
            </div>

            <!-- Metrics 2x2 Grid -->
            <div class="grid grid-cols-2 gap-2 bg-gray-50/80 p-3 rounded-xl border border-gray-100 text-xs">
              <div>
                <p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Revenue</p>
                <p class="font-black text-[#143d2e] mt-0.5">{{ formatRupiah(item.revenue) }}</p>
              </div>
              <div>
                <p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Volume</p>
                <p class="font-bold text-gray-700 mt-0.5">{{ formatVolume(item.volume) }}</p>
              </div>
              <div class="pt-1.5 border-t border-gray-200/50">
                <p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Total Trx</p>
                <p class="font-semibold text-gray-600 mt-0.5">{{ item.trxCount }}</p>
              </div>
              <div class="pt-1.5 border-t border-gray-200/50">
                <p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Share (%)</p>
                <p class="font-black text-emerald-600 mt-0.5">{{ item.sharePct }}%</p>
              </div>
            </div>

            <!-- Share Progress bar -->
            <div class="w-full bg-gray-100 h-1.5 rounded-full overflow-hidden">
              <div
                class="bg-emerald-500 h-full rounded-full transition-all duration-500"
                :style="{ width: `${Math.min(100, Math.max(2, item.sharePct))}%` }"
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
              </tr>
            </template>

            <template v-else-if="leaderboard.length > 0">
              <tr
                v-for="(item, index) in leaderboard"
                :key="item.id"
                class="hover:bg-gray-50/80 transition-colors border-b border-gray-100 last:border-0"
              >
                <!-- Rank Badge -->
                <td class="py-4 px-3 text-center whitespace-nowrap">
                  <span
                    :class="[
                      'w-7 h-7 rounded-full text-xs font-black inline-flex items-center justify-center shadow-xs',
                      index === 0 ? 'bg-amber-400 text-amber-950' : index === 1 ? 'bg-slate-200 text-slate-800' : index === 2 ? 'bg-amber-700/20 text-amber-800' : 'bg-gray-100 text-gray-600'
                    ]"
                  >
                    #{{ index + 1 }}
                  </span>
                </td>

                <!-- SPBU Name -->
                <td class="py-4 px-3 font-bold text-[#143d2e] whitespace-nowrap">
                  {{ item.name }}
                </td>

                <!-- Revenue -->
                <td class="py-4 px-3 text-right font-black text-[#143d2e] whitespace-nowrap">
                  {{ formatRupiah(item.revenue) }}
                </td>

                <!-- Volume -->
                <td class="py-4 px-3 text-right font-bold text-gray-700 whitespace-nowrap">
                  {{ formatVolume(item.volume) }}
                </td>

                <!-- Total Trx -->
                <td class="py-4 px-3 text-center font-semibold text-gray-600 whitespace-nowrap">
                  {{ item.trxCount }}
                </td>

                <!-- Share % -->
                <td class="py-4 px-3 text-right font-black text-emerald-600 whitespace-nowrap">
                  - %
                </td>
              </tr>
            </template>

            <tr v-else>
              <td colspan="6" class="py-12 text-center text-gray-400 font-medium">
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
