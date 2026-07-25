<script setup>
import { computed } from 'vue'

const props = defineProps({
  stats: Object,
  loading: Boolean
})

const formatRupiah = (number) => {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(number)
}
</script>

<template>
  <div class="grid grid-cols-2 lg:grid-cols-4 gap-px bg-gray-200 rounded-xl overflow-hidden border border-gray-200 shadow-sm">
    
    <div class="bg-white p-3 flex flex-col justify-center items-center">
      <p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest">Total Volume</p>
      <p class="text-lg font-black text-[#143d2e]">
        <span v-if="loading" class="loading loading-dots loading-xs"></span>
        <span v-else>{{ stats.volume.toLocaleString('id-ID') }} <span class="text-xs text-gray-400 font-medium">L</span></span>
      </p>
    </div>

    <div class="bg-white p-3 flex flex-col justify-center items-center">
      <p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest">Total Revenue</p>
      <p class="text-lg font-black text-[#143d2e]">
        <span v-if="loading" class="loading loading-dots loading-xs"></span>
        <span v-else>{{ formatRupiah(stats.revenue) }}</span>
      </p>
    </div>

    <div class="bg-white p-3 flex flex-col justify-center items-center">
      <p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest">Transaksi</p>
      <p class="text-lg font-black text-[#143d2e]">
        <span v-if="loading" class="loading loading-dots loading-xs"></span>
        <span v-else>{{ stats.vehicle }} <span class="text-xs text-gray-400 font-medium">Unit</span></span>
      </p>
    </div>

    <div class="bg-white p-3 flex flex-col justify-center items-center">
      <p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest">Avg. Volume</p>
      <p class="text-lg font-black text-[#143d2e]">
        <span v-if="loading" class="loading loading-dots loading-xs"></span>
        <span v-else>{{ stats.vehicle ? (stats.volume / stats.vehicle).toFixed(1) : 0 }} <span class="text-xs text-gray-400 font-medium">L/Trx</span></span>
      </p>
    </div>

  </div>
</template>