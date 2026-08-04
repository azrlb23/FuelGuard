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
  topPlates: {
    type: Array,
    default: () => []
  },
  selectedSpbuId: {
    type: [String, Number],
    default: ''
  },
  selectedSpbuName: {
    type: String,
    default: 'Semua SPBU'
  },
  formatRupiah: {
    type: Function,
    required: true
  },
  formatVolume: {
    type: Function,
    default: (val) => `${val || 0} L`
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

    <!-- Chart 2 OR Top Plates Ranking Card (1 Col) -->
    <!-- Case A: All SPBUs Selected -> Donut Chart Kontribusi Penjualan -->
    <div v-if="!selectedSpbuId" class="bg-white rounded-3xl p-6 border border-gray-100 shadow-sm flex flex-col hover:shadow-md transition-all duration-300">
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

    <!-- Case B: Single SPBU Selected -> Ranking Plat Pengisi SPBU -->
    <div v-else class="bg-white rounded-3xl p-6 border border-gray-100 shadow-sm flex flex-col hover:shadow-md transition-all duration-300">
      <div class="mb-3 pb-3 border-b border-gray-100 shrink-0 flex items-center justify-between">
        <div>
          <h4 class="text-base font-extrabold text-[#143d2e]">Ranking Plat Pengisi</h4>
          <p class="text-[11px] font-semibold text-emerald-700/80 mt-0.5 truncate max-w-[190px]" :title="selectedSpbuName">
            SPBU: {{ selectedSpbuName }}
          </p>
        </div>
        <span class="inline-flex items-center px-2.5 py-1 rounded-full text-[10px] font-extrabold  shrink-0">
          {{ topPlates.length }} Plat
        </span>
      </div>

      <!-- Ranking List -->
      <div v-if="topPlates.length > 0" class="space-y-2 max-h-[300px] overflow-y-auto pr-1 custom-scrollbar">
        <div
          v-for="(item, idx) in topPlates"
          :key="item.plat_nomor"
          class="flex items-center justify-between p-2.5 rounded-2xl bg-gray-50/80 hover:bg-emerald-50/70 border border-gray-100 hover:border-emerald-200 transition-all duration-200"
        >
          <div class="flex items-center gap-2.5 min-w-0">
            <!-- Rank Badge -->
            <div
              :class="[
                'w-7 h-7 rounded-xl flex items-center justify-center text-xs font-black shrink-0 shadow-2xs',
                idx === 0 ? 'bg-amber-400 text-amber-950' :
                idx === 1 ? 'bg-slate-300 text-slate-900' :
                idx === 2 ? 'bg-amber-700/30 text-amber-900' :
                'bg-emerald-900/10 text-emerald-900'
              ]"
            >
              #{{ idx + 1 }}
            </div>

            <div class="min-w-0">
              <div class="flex items-center gap-1.5">
                <span class="font-mono font-black text-xs text-gray-900 tracking-wider truncate">
                  {{ item.plat_nomor }}
                </span>
                <span
                  class="px-1.5 py-0.2 text-[9px] font-bold rounded-md uppercase shrink-0 border"
                  :class="item.is_ojol ? 'bg-green-100 text-green-800 border-green-200' : 'bg-gray-200/70 text-gray-700 border-gray-300/60'"
                >
                  {{ item.is_ojol ? 'Ojol' : 'Umum' }}
                </span>
              </div>
              <div class="text-[10px] text-gray-500 font-semibold mt-0.5">
                <span class="text-emerald-700 font-bold">{{ item.trx_count }}x Transaksi</span>
                <span class="mx-1">•</span>
                <span>{{ formatRupiah(item.total_harga) }}</span>
              </div>
            </div>
          </div>

          <div class="text-right shrink-0 pl-2">
            <div class="text-xs font-black text-[#143d2e]">
              {{ formatVolume(item.total_liter) }}
            </div>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div v-else class="flex-1 flex flex-col items-center justify-center py-10 text-center text-gray-400">
        <span class="text-3xl mb-1">🍃</span>
        <p class="text-xs font-semibold">Tidak ada transaksi ditemukan untuk SPBU ini.</p>
      </div>
    </div>

  </div>
</template>
