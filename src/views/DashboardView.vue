<script setup>
import DashboardHeader from '@/components/dashboard/DashboardHeader.vue'
import DashboardStats from '@/components/dashboard/DashboardStats.vue'
import DashboardLiveFeed from '@/components/dashboard/DashboardLiveFeed.vue'
import DashboardShift from '@/components/dashboard/DashboardShift.vue'
import DashboardVehicle from '@/components/dashboard/DashboardVehicle.vue'
import DashboardPeakHours from '@/components/dashboard/DashboardPeakHours.vue'
import DashboardLoyalty from '@/components/dashboard/DashboardLoyalty.vue'
import DashboardTrend from '@/components/dashboard/DashboardTrend.vue'
import DashboardRevenueShare from '@/components/dashboard/DashboardRevenueShare.vue'

import { useDashboard } from '@/composables/useDashboard'

const { 
  filter, setFilter, stats, feed, 
  vehicleStats, shiftStats, peakHourStats, loyalStats,
  trendStats, revenueShareStats,
  isLoading 
} = useDashboard()
</script>

<template>
  <div class="flex flex-col bg-[#f5f5f5] min-h-screen"> 
    
    <div class="flex-none flex flex-col gap-4 p-4 pb-0 md:p-6 md:pb-0 lg:p-8 lg:pb-0 z-10">
      <div class="animate-enter" style="animation-delay: 100ms">
        <DashboardHeader :model-value="filter" @update:model-value="setFilter" />
      </div>
      <div class="hidden md:block animate-enter" style="animation-delay: 200ms">
        <DashboardStats :stats="stats" :filter="filter" :loading="isLoading" />
      </div>
    </div>

    <div class="flex-1 p-4 md:p-6 lg:p-8 pt-4 md:pt-6">
      
      <div class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6 animate-enter w-full pb-12" style="animation-delay: 300ms">
        
        <div class="lg:col-span-2 xl:col-span-3 md:hidden w-full">
           <DashboardStats :stats="stats" :filter="filter" :loading="isLoading" />
        </div>
        
        <DashboardLiveFeed :items="feed" class="w-full xl:col-span-1" />

        <DashboardTrend :data="trendStats" class="w-full xl:col-span-2" />

        <DashboardRevenueShare :data="revenueShareStats" class="w-full xl:col-span-1" />

        <DashboardShift :data="shiftStats" class="w-full xl:col-span-1" />

        <DashboardVehicle :data="vehicleStats" class="w-full xl:col-span-1" />

        <DashboardPeakHours :data="peakHourStats" class="w-full xl:col-span-2" />

        <DashboardLoyalty :customers="loyalStats" class="w-full xl:col-span-1" />
        
      </div>
    </div>

  </div>
</template>
<style scoped>
.custom-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;  
}

.custom-scrollbar::-webkit-scrollbar {
  display: none; 
}
</style>