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
  <div class="relative flex flex-col sm:flex-row justify-between items-start sm:items-end gap-4 mb-4 p-6 rounded-3xl overflow-hidden shadow-sm" style="background: linear-gradient(135deg, #143d2e 0%, #0f2e22 100%);">
    <!-- LCP Background Pattern (Inline SVG) -->
    <svg class="absolute inset-0 w-full h-full object-cover opacity-10 pointer-events-none" xmlns="http://www.w3.org/2000/svg" width="100%" height="100%">
      <defs>
        <pattern id="pattern" width="40" height="40" patternUnits="userSpaceOnUse">
          <circle cx="2" cy="2" r="2" fill="#34d399"/>
        </pattern>
      </defs>
      <rect width="100%" height="100%" fill="url(#pattern)"/>
    </svg>

    <div class="relative z-10">
      <h2 class="text-3xl md:text-5xl font-black text-white tracking-tight mb-2" data-lcp="true">Dashboard Overview</h2>
      <p class="text-emerald-100/80 font-bold text-sm">Pemantauan real-time performa seluruh SPBU Habi Jaya</p>
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
