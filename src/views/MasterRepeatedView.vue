<script setup>
import { useMasterRepeated } from '@/composables/master/useMasterRepeated'
import MasterRepeatedTrxCard from '@/components/master/repeatedTransactions/MasterRepeatedTrxCard.vue'

const {
  repeatedLogs,
  totalAttempts,
  totalPlates,
  isLoading,
  searchQuery,
  selectedSpbu,
  dateFrom,
  dateTo,
  spbuList,
  resetFilters
} = useMasterRepeated()
</script>

<template>
  <div class="space-y-6 animate-enter">

    <!-- Page Header -->
    <div>
      <h1 class="text-3xl md:text-4xl font-extrabold text-[#143d2e] tracking-tight">
        Transaksi Berulang
      </h1>
    </div>

    <!-- Main Card Area with Embedded Filter Bar -->
    <div class="w-full">
      <MasterRepeatedTrxCard
        v-model:searchQuery="searchQuery"
        v-model:selectedSpbu="selectedSpbu"
        v-model:dateFrom="dateFrom"
        v-model:dateTo="dateTo"
        :spbuList="spbuList"
        :repeatedLogs="repeatedLogs"
        :totalCount="totalAttempts"
        :totalPlates="totalPlates"
        :loading="isLoading"
        @resetFilters="resetFilters"
      />
    </div>

  </div>
</template>
