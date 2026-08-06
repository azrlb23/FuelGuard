<script setup>
import { computed } from 'vue'
import { useMasterDashboard } from '@/composables/master/useMasterDashboard'

import MasterDashboardHeader from '@/components/master/dashboard/MasterDashboardHeader.vue'
import MasterKpiCards from '@/components/master/dashboard/MasterKpiCards.vue'
import MasterSpbuAccordion from '@/components/master/dashboard/MasterSpbuAccordion.vue'

// ─── Master Dashboard State via Composable ──────────────────────────────────
const timeFilters = ['Today', 'Weekly', 'Monthly', 'All-Time']

const {
  filterTime,
  searchQuery,
  isLoading,
  stats,
  spbuList,
} = useMasterDashboard()

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
</script>

<template>
  <div class="space-y-6 animate-enter">

    <!-- Header Section: Title & Time Filter Toggle -->
    <MasterDashboardHeader
      v-model:filterTime="filterTime"
      :timeFilters="timeFilters"
    />

    <!-- Top KPI Stat Cards -->
    <MasterKpiCards
      :loading="isLoading"
      :totalNetworkRevenue="totalNetworkRevenue"
      :totalNetworkVolume="totalNetworkVolume"
      :activeSpbuCountText="activeSpbuCountText"
      :totalTransactionsCount="totalTransactionsCount"
      :periodLabel="periodLabel"
      :transactionCardTitle="transactionCardTitle"
      :spbuCount="spbuList.length"
    />

    <MasterSpbuAccordion
      :spbuList="spbuList"
      v-model:searchQuery="searchQuery"
      :periodLabel="periodLabel"
    />

  </div>
</template>
