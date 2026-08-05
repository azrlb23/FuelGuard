<script setup>
defineProps({
  filterTime: {
    type: String,
    required: true
  }
})

defineEmits(['update:filterTime'])

const timeFilters = [
  { label: 'Harian', value: 'today' },
  { label: 'Mingguan', value: 'weekly' },
  { label: 'Bulanan', value: 'monthly' },
  { label: 'Semua', value: 'all-time' }
]
</script>

<template>
  <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
    <div>
      <h2 class="text-3xl md:text-4xl font-extrabold text-[#143d2e] tracking-tight" data-lcp="true">Dashboard</h2>
    </div>

    <div class="bg-gradient-to-r from-[#143d2e] via-[#1b4d3a] to-[#256a50] border border-white/20 backdrop-blur-xl p-1.5 rounded-full flex w-full md:w-auto shadow-lg shadow-green-900/10 self-stretch md:self-auto justify-between md:justify-start">
      <button
        v-for="filter in timeFilters"
        :key="filter.value"
        @click="$emit('update:filterTime', filter.value)"
        class="flex-1 md:flex-initial text-center px-2 py-2 md:px-5 md:py-2 rounded-full text-xs md:text-sm font-medium transition-all duration-200 cursor-pointer select-none"
        :class="filterTime === filter.value ? 'bg-white/25 border border-white/40 text-white shadow-sm font-bold backdrop-blur-md' : 'text-white/80 hover:text-white border border-transparent'"
      >
        {{ filter.label }}
      </button>
    </div>
  </div>
</template>
