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

    <div class="bg-[#143d2e] p-1.5 rounded-full flex w-full md:w-auto shadow-md self-stretch md:self-auto justify-between md:justify-start">
      <button
        v-for="filter in timeFilters"
        :key="filter.value"
        @click="$emit('update:filterTime', filter.value)"
        class="flex-1 md:flex-initial text-center px-2 py-2 md:px-5 md:py-2 rounded-full text-xs md:text-sm font-medium transition-all duration-200 cursor-pointer select-none"
        :class="filterTime === filter.value ? 'bg-white/20 border border-white/30 text-white shadow-sm font-bold' : 'text-white/70 hover:text-white border border-transparent'"
      >
        {{ filter.label }}
      </button>
    </div>
  </div>
</template>
