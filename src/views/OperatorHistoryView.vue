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
} = useTransactionHistory(10, { dateFilter: true })
</script>

<template>
  <div class="flex flex-col h-full gap-4 animate-enter overflow-hidden pb-2">
    
    <div class="flex-none flex flex-col gap-4 px-1">
      <div class="flex justify-between items-center">
        <router-link 
          to="/operator" 
          class="w-12 h-12 rounded-2xl bg-white hover:bg-green-50 border border-green-200 flex items-center justify-center text-[#143d2e] shadow-sm hover:shadow-md active:scale-95 transition-all"
          title="Kembali"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-6 h-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
          </svg>
        </router-link>
        
        <span class="text-xs font-bold text-[#143d2e] bg-white px-3.5 py-1.5 rounded-full border border-gray-100 shadow-2xs">
          Data Hari Ini
        </span>
      </div>
    </div>

    <!-- Unified Single Card for Filter & History Table -->
    <div class="flex-1 min-h-0 bg-white rounded-2xl border border-gray-100 shadow-sm flex flex-col overflow-hidden">
      <!-- Top Section: Filter Bar -->
      <div class="p-4 border-b border-gray-100 bg-white">
        <HistoryHeader 
          v-model="searchQuery" 
          v-model:vehicle-filter="vehicleFilter"
          v-model:date-from="dateFrom"
          v-model:date-to="dateTo"
          v-model:sort-field="sortField"
          v-model:sort-dir="sortDir"
          @reset="resetFilters"
        />
      </div>

      <!-- Bottom Section: History Table -->
      <div class="flex-1 overflow-y-auto p-4 bg-gray-50/50">
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

  </div>
</template>