<script setup>
import { computed } from 'vue'
import { useMasterHistory } from '@/composables/master/useMasterHistory'

import MasterHistoryHeader from '@/components/master/history/MasterHistoryHeader.vue'
import MasterHistoryTable from '@/components/master/history/MasterHistoryTable.vue'

// ─── Master History State via Composable ────────────────────────────────────
const itemsPerPage = 10

const {
  transactions,
  loading,
  isExporting,
  totalItems,
  currentPage,
  searchQuery,
  selectedSpbu,
  spbuList,
  dateFrom,
  dateTo,
  sortField,
  sortDir,
  exportToExcel,
  resetFilters
} = useMasterHistory(itemsPerPage)

const SORT_OPTIONS = [
  { label: 'Terbaru', field: 'waktu_pencatatan', dir: 'desc' },
  { label: 'Terlama', field: 'waktu_pencatatan', dir: 'asc' },
  { label: 'Harga ↑', field: 'harga', dir: 'asc' },
  { label: 'Harga ↓', field: 'harga', dir: 'desc' },
  { label: 'Liter ↑', field: 'liter', dir: 'asc' },
  { label: 'Liter ↓', field: 'liter', dir: 'desc' },
]

const currentSortLabel = computed(() => {
  const found = SORT_OPTIONS.find(o => o.field === sortField.value && o.dir === sortDir.value)
  return found ? found.label : 'Terbaru'
})

const selectedSpbuLabel = computed(() => {
  if (!selectedSpbu.value) return 'Semua SPBU'
  const found = spbuList.value.find(s => String(s.id) === String(selectedSpbu.value))
  return found ? found.nama : `SPBU #${selectedSpbu.value}`
})

const activeFilters = computed(() => {
  const filters = []
  if (searchQuery.value) filters.push({ key: 'search', label: `Plat: ${searchQuery.value.toUpperCase()}` })
  if (selectedSpbu.value) filters.push({ key: 'spbu', label: `SPBU: ${selectedSpbuLabel.value}` })
  if (dateFrom.value) filters.push({ key: 'dateFrom', label: `Dari: ${dateFrom.value}` })
  if (dateTo.value) filters.push({ key: 'dateTo', label: `Sampai: ${dateTo.value}` })
  if (sortField.value !== 'waktu_pencatatan' || sortDir.value !== 'desc') {
    filters.push({ key: 'sort', label: `Urut: ${currentSortLabel.value}` })
  }
  return filters
})

const removeFilter = (key) => {
  if (key === 'search') searchQuery.value = ''
  if (key === 'spbu') selectedSpbu.value = ''
  if (key === 'dateFrom') dateFrom.value = ''
  if (key === 'dateTo') dateTo.value = ''
  if (key === 'sort') {
    sortField.value = 'waktu_pencatatan'
    sortDir.value = 'desc'
  }
}

const onSortSelectChange = (sortValString) => {
  const [field, dir] = sortValString.split(':')
  sortField.value = field
  sortDir.value = dir
}

const totalPages = computed(() => Math.ceil(totalItems.value / itemsPerPage) || 1)
</script>

<template>
  <div class="space-y-6 animate-enter">

    <!-- Header Section: Title -->
    <MasterHistoryHeader />

    <!-- Single Unified History Table Container (Integrated Filters & Table) -->
    <MasterHistoryTable
      v-model:searchQuery="searchQuery"
      :loading="loading"
      :isExporting="isExporting"
      :transactions="transactions"
      v-model:currentPage="currentPage"
      :itemsPerPage="itemsPerPage"
      :totalItems="totalItems"
      :totalPages="totalPages"
      :spbuList="spbuList"
      v-model:selectedSpbu="selectedSpbu"
      :selectedSpbuLabel="selectedSpbuLabel"
      v-model:dateFrom="dateFrom"
      v-model:dateTo="dateTo"
      :sortField="sortField"
      :sortDir="sortDir"
      :currentSortLabel="currentSortLabel"
      :SORT_OPTIONS="SORT_OPTIONS"
      :activeFilters="activeFilters"
      @sortChange="onSortSelectChange"
      @resetFilters="resetFilters"
      @removeFilter="removeFilter"
      @exportExcel="exportToExcel"
    />

  </div>
</template>
