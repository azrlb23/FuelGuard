<script setup>
import HistoryHeader from '@/components/history/HistoryHeader.vue'
import HistoryTable from '@/components/history/HistoryTable.vue'
import { useTransactionHistory } from '@/composables/useTransactionHistory'

const { 
  transactions, 
  loading, 
  searchQuery, 
  vehicleFilter,
  dateFrom,
  dateTo,
  sortField,
  sortDir,
  currentPage, 
  totalItems,
  resetFilters
} = useTransactionHistory(10)
</script>

<template>
  <div class="flex flex-col gap-4 animate-enter pb-24">
    
    <div class="flex-none pt-2 px-1">
      <HistoryHeader 
        v-model="searchQuery"
        :vehicle-filter="vehicleFilter"
        :date-from="dateFrom"
        :date-to="dateTo"
        :sort-field="sortField"
        :sort-dir="sortDir"
        @update:vehicleFilter="vehicleFilter = $event"
        @update:dateFrom="dateFrom = $event"
        @update:dateTo="dateTo = $event"
        @update:sortField="sortField = $event"
        @update:sortDir="sortDir = $event"
        @reset="resetFilters"
      />
    </div>

    <div class="rounded-4xl relative">
      <HistoryTable 
        :transactions="transactions"
        :loading="loading"
        :current-page="currentPage"
        :total-items="totalItems"
        :items-per-page="10"
        @change-page="(newPage) => currentPage = newPage"
      />
    </div>

  </div>
</template>