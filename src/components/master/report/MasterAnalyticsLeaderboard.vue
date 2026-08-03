<script setup>
defineProps({
  loading: {
    type: Boolean,
    default: false
  },
  leaderboard: {
    type: Array,
    default: () => []
  },
  formatRupiah: {
    type: Function,
    required: true
  },
  formatVolume: {
    type: Function,
    required: true
  }
})
</script>

<template>
  <div class="bg-white rounded-3xl p-5 md:p-8 border border-gray-200 shadow-sm space-y-4">
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 border-b border-gray-100 pb-4">
      <div>
        <h3 class="text-lg sm:text-xl font-extrabold text-[#143d2e]">Peringkat SPBU Bedasarkan Penjualan</h3>
      </div>
    </div>

    <!-- Mobile Card View -->
    <div class="block md:hidden space-y-3 pt-1">
      <template v-if="loading">
        <div v-for="n in 3" :key="n" class="bg-gray-50 rounded-2xl p-4 animate-pulse space-y-3 border border-gray-100">
          <div class="flex justify-between">
            <div class="h-5 w-28 bg-gray-200 rounded"></div>
            <div class="h-5 w-16 bg-gray-200 rounded"></div>
          </div>
          <div class="grid grid-cols-2 gap-2 pt-2">
            <div class="h-10 bg-gray-200 rounded-xl"></div>
            <div class="h-10 bg-gray-200 rounded-xl"></div>
          </div>
        </div>
      </template>

      <template v-else-if="leaderboard.length > 0">
        <div
          v-for="item in leaderboard"
          :key="item.spbu_id"
          class="bg-white rounded-2xl p-4 border border-gray-200 shadow-xs space-y-3 relative overflow-hidden"
        >
          <!-- Header: Rank + Name -->
          <div class="flex items-center justify-between gap-2">
            <div class="flex items-center gap-2.5 min-w-0">
              <span
                class="w-7 h-7 rounded-full text-xs font-black inline-flex items-center justify-center shrink-0 bg-gray-100 text-gray-600 shadow-2xs"
              >
                #{{ item.rank }}
              </span>
              <h4 class="font-bold text-sm text-[#143d2e] truncate">
                {{ item.name }}
              </h4>
            </div>
          </div>

          <!-- Metrics 2x2 Grid -->
          <div class="grid grid-cols-2 gap-2 bg-gray-50/80 p-3 rounded-xl border border-gray-100 text-xs">
            <div>
              <p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Revenue</p>
              <p class="font-black text-[#143d2e] mt-0.5">{{ formatRupiah(item.revenue) }}</p>
            </div>
            <div>
              <p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Volume</p>
              <p class="font-bold text-gray-700 mt-0.5">{{ formatVolume(item.volume) }}</p>
            </div>
            <div class="pt-1.5 border-t border-gray-200/50">
              <p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Total Trx</p>
              <p class="font-semibold text-gray-600 mt-0.5">{{ item.trxCount }}</p>
            </div>
            <div class="pt-1.5 border-t border-gray-200/50">
              <p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">Share (%)</p>
              <p class="font-black text-emerald-600 mt-0.5">{{ item.sharePct }}%</p>
            </div>
          </div>

          <!-- Share Progress bar -->
          <div class="w-full bg-gray-100 h-1.5 rounded-full overflow-hidden">
            <div
              class="bg-emerald-500 h-full rounded-full transition-all duration-500"
              :style="{ width: `${Math.min(100, Math.max(2, item.sharePct))}%` }"
            ></div>
          </div>
        </div>
      </template>

      <div v-else class="py-8 text-center text-gray-400 text-xs font-medium">
        Belum ada data untuk periode ini.
      </div>
    </div>

    <!-- Desktop Table View -->
    <div class="hidden md:block overflow-x-auto custom-scrollbar">
      <table class="w-full text-left border-collapse min-w-[700px]">
        <thead>
          <tr class="text-gray-400 text-[11px] font-bold uppercase tracking-wider border-b border-gray-100">
            <th class="py-3 px-3 text-center whitespace-nowrap">RANK</th>
            <th class="py-3 px-3 whitespace-nowrap">NAMA SPBU</th>
            <th class="py-3 px-3 text-right whitespace-nowrap">REVENUE</th>
            <th class="py-3 px-3 text-right whitespace-nowrap">VOLUME</th>
            <th class="py-3 px-3 text-center whitespace-nowrap">TOTAL TRX</th>
            <th class="py-3 px-3 text-right whitespace-nowrap">SHARE (%)</th>
          </tr>
        </thead>
        <tbody class="text-sm">
          <template v-if="loading">
            <tr v-for="n in 3" :key="n" class="border-b border-gray-50">
              <td class="py-4 px-3 text-center"><div class="skeleton h-6 w-6 bg-gray-200 rounded-full mx-auto"></div></td>
              <td class="py-4 px-3"><div class="skeleton h-4 w-36 bg-gray-200 rounded"></div></td>
              <td class="py-4 px-3 text-right"><div class="skeleton h-4 w-24 bg-gray-200 rounded ml-auto"></div></td>
              <td class="py-4 px-3 text-right"><div class="skeleton h-4 w-16 bg-gray-200 rounded ml-auto"></div></td>
              <td class="py-4 px-3 text-center"><div class="skeleton h-4 w-12 bg-gray-200 rounded mx-auto"></div></td>
              <td class="py-4 px-3 text-right"><div class="skeleton h-4 w-12 bg-gray-200 rounded ml-auto"></div></td>
            </tr>
          </template>

          <template v-else-if="leaderboard.length > 0">
            <tr
              v-for="(item, index) in leaderboard"
              :key="item.id || item.spbu_id || index"
              class="hover:bg-gray-50/80 transition-colors border-b border-gray-100 last:border-0"
            >
              <!-- Rank Badge -->
              <td class="py-4 px-3 text-center whitespace-nowrap">
                <span
                  class="w-7 h-7 rounded-full text-xs font-black inline-flex items-center justify-center bg-gray-100 text-gray-600 shadow-2xs"
                >
                  #{{ index + 1 }}
                </span>
              </td>

              <!-- SPBU Name -->
              <td class="py-4 px-3 font-bold text-[#143d2e] whitespace-nowrap">
                {{ item.name }}
              </td>

              <!-- Revenue -->
              <td class="py-4 px-3 text-right font-black text-[#143d2e] whitespace-nowrap">
                {{ formatRupiah(item.revenue) }}
              </td>

              <!-- Volume -->
              <td class="py-4 px-3 text-right font-bold text-gray-700 whitespace-nowrap">
                {{ formatVolume(item.volume) }}
              </td>

              <!-- Total Trx -->
              <td class="py-4 px-3 text-center font-semibold text-gray-600 whitespace-nowrap">
                {{ item.trxCount }}
              </td>

              <!-- Share % -->
              <td class="py-4 px-3 text-right font-black text-emerald-600 whitespace-nowrap">
                {{ item.sharePct }}%
              </td>
            </tr>
          </template>

          <tr v-else>
            <td colspan="6" class="py-12 text-center text-gray-400 font-medium">
              Belum ada data untuk periode ini.
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
