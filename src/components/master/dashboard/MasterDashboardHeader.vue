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
  <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
    <div>
      <h2 class="text-3xl md:text-4xl font-extrabold text-[#143d2e] tracking-tight" data-lcp="true">Dashboard</h2>
    </div>

    <div class="bg-[#143d2e] p-1.5 rounded-full flex shadow-md self-start md:self-auto">
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
