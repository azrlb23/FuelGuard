<script setup>
import { computed } from 'vue'
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
    <div class="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
      <div>
        <h2 class="text-3xl md:text-4xl font-extrabold text-black tracking-tight mb-1">Analisis & Laporan</h2>
        <p class="text-gray-500 text-sm font-bold">Benchmarking performa jaringan SPBU & rekapitulasi operasional eksekutif</p>
      </div>

      <!-- Export Action Buttons -->
      <div class="flex items-center gap-2.5 w-full sm:w-auto">
        <button
          @click="exportToExcel"
          class="flex-1 sm:flex-none flex items-center justify-center gap-2 px-4 py-2.5 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-700 hover:bg-emerald-100 text-xs font-bold transition-all shadow-xs cursor-pointer"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-emerald-600">
            <path stroke-linecap="round" stroke-linejoin="round" d="M3.375 19.5h17.25m-17.25 0a1.125 1.125 0 0 1-1.125-1.125M3.375 19.5h7.5c.621 0 1.125-.504 1.125-1.125m-8.625 1.125L12 10.5m0 0 4.5 4.5M12 10.5V3" />
          </svg>
          Export Excel (.csv)
        </button>

        <button
          @click="exportToPDF"
          class="flex-1 sm:flex-none flex items-center justify-center gap-2 px-5 py-2.5 rounded-full bg-[#143d2e] hover:bg-[#1e5c45] text-white text-xs font-bold transition-all shadow-md shadow-green-900/10 cursor-pointer"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-green-300">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6.72 13.829c-.24.03-.48.062-.72.096m.72-.096a42.415 42.415 0 0 1 10.56 0m-10.56 0L6.34 18m10.94-4.171c.24.03.48.062.72.096m-.72-.096L17.66 18m0 0 .229 2.523a1.125 1.125 0 0 1-1.12 1.227H7.231a1.125 1.125 0 0 1-1.12-1.227L6.34 18m11.318 0h1.091A2.25 2.25 0 0 0 21 15.75V9.456c0-1.081-.768-2.015-1.837-2.175a48.055 48.055 0 0 0-1.913-.247M3 9.456c0-1.081.768-2.015 1.837-2.175a48.087 48.087 0 0 1 1.913-.247m0 0a48.1 48.1 0 0 1 10.5 0" />
          </svg>
          Export Laporan PDF
        </button>
      </div>
    </div>

    <!-- Filter Bar: Date Range + SPBU Select -->
    <div class="bg-white rounded-2xl p-4 border border-gray-200 shadow-xs flex flex-wrap items-center gap-3">
      
      <!-- Date From -->
      <div class="flex items-center gap-2 bg-gray-50 border border-gray-200 rounded-full px-4 py-2 text-xs font-bold text-gray-700">
        <span class="text-gray-400">Dari:</span>
        <input
          v-model="dateFrom"
          type="date"
          class="bg-transparent outline-none text-gray-800 font-bold cursor-pointer"
        />
      </div>

      <!-- Date To -->
      <div class="flex items-center gap-2 bg-gray-50 border border-gray-200 rounded-full px-4 py-2 text-xs font-bold text-gray-700">
        <span class="text-gray-400">Sampai:</span>
        <input
          v-model="dateTo"
          type="date"
          class="bg-transparent outline-none text-gray-800 font-bold cursor-pointer"
        />
      </div>

      <!-- SPBU Select Dropdown -->
      <div class="flex items-center gap-2 bg-gray-50 border border-gray-200 rounded-full px-4 py-2 text-xs font-bold text-gray-700 min-w-[200px]">
        <span class="text-gray-400">SPBU:</span>
        <select
          v-model="selectedSpbuId"
          class="bg-transparent outline-none text-gray-800 font-bold cursor-pointer w-full"
        >
          <option value="">Semua SPBU Jaringan</option>
          <option v-for="s in spbuOptions" :key="s.id" :value="s.id">{{ s.name }}</option>
        </select>
      </div>

      <div class="ml-auto text-xs font-bold text-gray-400">
        <span v-if="loading" class="animate-pulse text-emerald-600">Memuat data...</span>
        <span v-else>Filter Aktif</span>
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

    <!-- Row 3: Leaderboard SPBU Benchmark Table -->
    <div class="bg-white rounded-3xl p-6 md:p-8 border border-gray-200 shadow-sm space-y-4">
      <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-2 border-b border-gray-100 pb-4">
        <div>
          <h3 class="text-xl font-extrabold text-[#143d2e]">Leaderboard & Benchmarking SPBU</h3>
          <p class="text-xs font-semibold text-gray-400">Perbandingan kineja omzet, volume, dan transaksi seluruh unit SPBU</p>
        </div>
        <span class="text-xs font-bold text-gray-500 bg-gray-100 px-3 py-1 rounded-full">
          Total Unit: {{ leaderboard.length }} SPBU
        </span>
      </div>

      <!-- Table View -->
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="text-gray-400 text-xs font-bold uppercase tracking-wider border-b border-gray-100 pb-3">
              <th class="pb-3 pl-3 text-center">RANK</th>
              <th class="pb-3">NAMA SPBU</th>
              <th class="pb-3 text-right">REVENUE</th>
              <th class="pb-3 text-right">VOLUME</th>
              <th class="pb-3 text-center">TOTAL TRX</th>
              <th class="pb-3 text-right">SHARE (%)</th>
              <th class="pb-3 pr-3 text-right">STATUS PERFORMA</th>
            </tr>
          </thead>
          <tbody class="text-sm">
            <template v-if="loading">
              <tr v-for="n in 3" :key="n" class="border-b border-gray-50">
                <td class="py-4 text-center"><div class="skeleton h-6 w-6 bg-gray-200 rounded-full mx-auto"></div></td>
                <td class="py-4"><div class="skeleton h-4 w-36 bg-gray-200 rounded"></div></td>
                <td class="py-4 text-right"><div class="skeleton h-4 w-24 bg-gray-200 rounded ml-auto"></div></td>
                <td class="py-4 text-right"><div class="skeleton h-4 w-16 bg-gray-200 rounded ml-auto"></div></td>
                <td class="py-4 text-center"><div class="skeleton h-4 w-12 bg-gray-200 rounded mx-auto"></div></td>
                <td class="py-4 text-right"><div class="skeleton h-4 w-12 bg-gray-200 rounded ml-auto"></div></td>
                <td class="py-4 pr-3 text-right"><div class="skeleton h-6 w-20 bg-gray-200 rounded-full ml-auto"></div></td>
              </tr>
            </template>

            <template v-else-if="leaderboard.length > 0">
              <tr
                v-for="item in leaderboard"
                :key="item.spbu_id"
                class="hover:bg-gray-50/80 transition-colors border-b border-gray-100 last:border-0"
              >
                <!-- Rank Badge -->
                <td class="py-4 pl-3 text-center">
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
                <td class="py-4 font-bold text-[#143d2e]">
                  {{ item.spbu_name }}
                </td>

                <!-- Revenue -->
                <td class="py-4 text-right font-black text-[#143d2e]">
                  {{ formatRupiah(item.sales) }}
                </td>

                <!-- Volume -->
                <td class="py-4 text-right font-bold text-gray-700">
                  {{ formatVolume(item.volume) }}
                </td>

                <!-- Total Trx -->
                <td class="py-4 text-center font-semibold text-gray-600">
                  {{ item.total_trx }}
                </td>

                <!-- Share % -->
                <td class="py-4 text-right font-black text-emerald-600">
                  {{ item.share_pct }}%
                </td>

                <!-- Status Badge -->
                <td class="py-4 pr-3 text-right">
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

  </div>
</template>
