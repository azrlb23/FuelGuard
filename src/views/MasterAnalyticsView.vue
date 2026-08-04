<script setup>
import { computed } from 'vue'
import { useMasterAnalytics } from '@/composables/master/useMasterAnalytics'
import MasterAnalyticsFilterPanel from '@/components/master/report/MasterAnalyticsFilterPanel.vue'
import MasterAnalyticsKpiCards from '@/components/master/report/MasterAnalyticsKpiCards.vue'
import MasterAnalyticsChartsSection from '@/components/master/report/MasterAnalyticsChartsSection.vue'
import MasterAnalyticsLeaderboard from '@/components/master/report/MasterAnalyticsLeaderboard.vue'
import MasterAnalyticsExportBar from '@/components/master/report/MasterAnalyticsExportBar.vue'

const {
  loading,
  dateFrom,
  dateTo,
  selectedSpbuId,
  selectedSpbuName,
  spbuOptions,
  kpi,
  trendData,
  leaderboard,
  spbuShares,
  topPlates,
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
      beginAtZero: true,
      grid: { color: '#f3f4f6' },
      ticks: {
        font: { size: 11, weight: '600' },
        color: '#9ca3af',
        callback: (val) => `Rp ${val} Jt`
      }
    }
  }
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
    legend: { display: false },
    tooltip: {
      backgroundColor: '#0f2e23',
      padding: 10,
      cornerRadius: 10,
      callbacks: {
        label: (ctx) => `${ctx.label}: ${ctx.raw}%`
      }
    }
  },
  cutout: '72%'
}
</script>

<template>
  <div class="space-y-6 animate-enter">

    <!-- Header Section: Title & Popover Filter Button -->
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
      <div>
        <h2 class="text-3xl md:text-4xl font-extrabold text-[#143d2e] tracking-tight" data-lcp="true">Laporan</h2>
      </div>

      <!-- Filter Controls Component -->
      <MasterAnalyticsFilterPanel
        v-model:dateFrom="dateFrom"
        v-model:dateTo="dateTo"
        v-model:selectedSpbuId="selectedSpbuId"
        :spbuOptions="spbuOptions"
        :loading="loading"
      />
    </div>

    <!-- Row 1: KPI Summary Cards -->
    <MasterAnalyticsKpiCards
      :loading="loading"
      :kpi="kpi"
      :formatRupiah="formatRupiah"
      :formatVolume="formatVolume"
    />

    <!-- Row 2: Charts Grid / Ranking Plat per SPBU -->
    <MasterAnalyticsChartsSection
      :trendChartData="trendChartData"
      :trendChartOptions="trendChartOptions"
      :doughnutChartData="doughnutChartData"
      :doughnutChartOptions="doughnutChartOptions"
      :spbuShares="spbuShares"
      :topPlates="topPlates"
      :selectedSpbuId="selectedSpbuId"
      :selectedSpbuName="selectedSpbuName"
      :formatRupiah="formatRupiah"
      :formatVolume="formatVolume"
    />

    <!-- Row 3: Leaderboard SPBU Benchmark Table & Mobile Cards -->
    <MasterAnalyticsLeaderboard
      :loading="loading"
      :leaderboard="leaderboard"
      :formatRupiah="formatRupiah"
      :formatVolume="formatVolume"
    />

    <!-- Row 4: Export Action Buttons -->
    <MasterAnalyticsExportBar
      @exportExcel="exportToExcel"
      @exportPdf="exportToPDF"
    />

  </div>
</template>
