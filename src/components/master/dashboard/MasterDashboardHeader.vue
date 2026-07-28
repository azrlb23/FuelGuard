<script setup>
defineProps({
  filterTime: {
    type: String,
    required: true
  },
  timeFilters: {
    type: Array,
    default: () => ['Today', 'Weekly', 'Monthly', 'All-Time']
  }
})

defineEmits(['update:filterTime'])
</script>

<template>
  <div class="flex flex-col sm:flex-row justify-between items-start sm:items-end gap-4 mb-4">
    <div>
      <h2 class="text-3xl md:text-4xl font-extrabold text-black tracking-tight mb-1">Dashboard Analytics</h2>
      <p class="text-gray-500 font-bold text-sm">Overview performa penjualan</p>
    </div>

    <div class="bg-[#184e39] p-1.5 rounded-full flex shadow-lg shadow-green-900/10 self-start sm:self-auto">
      <button
        v-for="filter in timeFilters"
        :key="filter"
        @click="$emit('update:filterTime', filter.toLowerCase())"
        class="px-4 py-2 md:px-5 md:py-2 rounded-full text-xs md:text-sm font-medium transition-all duration-200 cursor-pointer select-none"
        :class="filterTime === filter.toLowerCase() ? 'bg-[#34d399] text-[#064e3b] shadow-sm font-bold' : 'text-white/80 hover:text-white'"
      >
        {{ filter }}
      </button>
    </div>
  </div>
</template>
