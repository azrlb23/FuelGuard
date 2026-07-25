<script setup>
defineProps({
  modelValue: String 
})
defineEmits(['update:modelValue'])

const filters = ['Today', 'Weekly', 'Monthly', 'All-Time']
</script>

<template>
  <div class="flex flex-col lg:flex-row justify-between items-start lg:items-end mb-8 gap-4">
    <div>
      <h2 class="text-3xl md:text-4xl font-extrabold text-black tracking-tight mb-1">Dashboard Analytics</h2>
      <p class="text-gray-500 font-bold text-sm">Overview performa penjualan</p>
    </div>

    <div class="bg-[#184e39] p-1.5 rounded-full flex shadow-lg shadow-green-900/10">
      <button 
        v-for="filter in filters" 
        :key="filter"
        @click="$emit('update:modelValue', filter.toLowerCase())"
        class="px-5 py-2 rounded-full text-sm font-medium transition-all duration-200"
        :class="modelValue === filter.toLowerCase() ? 'bg-[#34d399] text-[#064e3b] shadow-sm font-bold' : 'text-white/80 hover:text-white'"
      >
        {{ filter }}
      </button>
    </div>
  </div>
</template>