<script setup>
import LazyLineChart from '@/components/common/LazyLineChart.vue'
import LazyDoughnutChart from '@/components/common/LazyDoughnutChart.vue'

defineProps({
  trendChartData: {
    type: Object,
    required: true
  },
  trendChartOptions: {
    type: Object,
    required: true
  },
  doughnutChartData: {
    type: Object,
    required: true
  },
  doughnutChartOptions: {
    type: Object,
    required: true
  },
  spbuShares: {
    type: Array,
    default: () => []
  },
  formatRupiah: {
    type: Function,
    required: true
  }
})
</script>

<template>
  <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

    <!-- Chart 1: Line Combined Trend (2 Cols) -->
    <div class="lg:col-span-2 bg-white rounded-3xl p-6 border border-gray-100 shadow-sm flex flex-col hover:shadow-md transition-all duration-300">
      <div class="flex items-center justify-between mb-3 pb-3 border-b border-gray-100 shrink-0">
        <div>
          <h4 class="text-base font-extrabold text-[#143d2e]">Grafik Penjualan</h4>
        </div>
      </div>

      <div class="flex-1 min-h-[260px] relative w-full pt-2">
        <LazyLineChart v-if="trendChartData.labels.length" :data="trendChartData" :options="trendChartOptions" />
      </div>
    </div>

    <!-- Chart 2: Donut Contribution Share (1 Col) -->
    <div class="bg-white rounded-3xl p-6 border border-gray-100 shadow-sm flex flex-col hover:shadow-md transition-all duration-300">
      <div class="mb-3 pb-3 border-b border-gray-100 shrink-0">
        <h4 class="text-base font-extrabold text-[#143d2e]">Kontribusi Penjualan</h4>
      </div>

      <!-- Doughnut Chart Container with Center Badge -->
      <div class="h-44 relative flex items-center justify-center my-1 shrink-0">
        <LazyDoughnutChart v-if="doughnutChartData.labels.length" :data="doughnutChartData" :options="doughnutChartOptions" class="relative z-10" />
        <!-- Center Stat Badge -->
        <div class="absolute inset-0 flex flex-col items-center justify-center pointer-events-none z-0">
          <span class="text-[10px] font-extrabold text-gray-400 uppercase tracking-widest">TOTAL</span>
          <span class="text-base font-black text-[#143d2e]">{{ spbuShares.length }} SPBU</span>
        </div>
      </div>

      <!-- Modernized Legend List -->
      <div class="space-y-1.5 max-h-[190px] overflow-y-auto pr-1 custom-scrollbar mt-2 pt-2 border-t border-gray-100">
        <div
          v-for="(item, idx) in spbuShares"
          :key="item.spbu_id"
          class="flex items-center justify-between p-2 rounded-xl hover:bg-gray-50/80 transition-all duration-200 border border-transparent hover:border-gray-100 text-xs"
        >
          <div class="flex items-center gap-2.5 min-w-0">
            <div
              class="w-3 h-3 rounded-full shrink-0 shadow-xs"
              :style="{ backgroundColor: ['#143d2e', '#22c55e', '#10b981', '#34d399', '#6ee7b7', '#a7f3d0'][idx % 6] }"
            ></div>
            <div class="min-w-0">
              <div class="font-bold text-gray-800 truncate">{{ item.name }}</div>
              <div class="text-[10px] text-gray-400 font-semibold">{{ formatRupiah(item.sales) }}</div>
            </div>
          </div>
          <div class="text-right shrink-0">
            <span class="text-xs font-black text-[#143d2e]">
              {{ item.value }}%
            </span>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>
