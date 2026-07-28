<script setup>
defineProps({
  searchQuery: {
    type: String,
    default: ''
  }
})

defineEmits(['update:searchQuery'])
</script>

<template>
  <div class="flex flex-col md:flex-row justify-between items-start md:items-end gap-4">
    <div>
      <h2 class="text-3xl md:text-4xl font-extrabold text-black tracking-tight mb-1">Transaction History</h2>
      <p class="text-gray-500 text-sm font-bold">Rekapitulasi seluruh transaksi operasional</p>
    </div>

    <!-- Search Input -->
    <div class="relative w-full md:w-72">
      <input 
        :value="searchQuery"
        @input="$emit('update:searchQuery', $event.target.value)"
        type="text" 
        placeholder="Cari Plat Nomor..." 
        class="w-full pl-10 pr-4 py-2.5 rounded-full bg-white border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#143d2e] focus:border-transparent shadow-sm text-xs md:text-sm font-medium transition-all"
      />
      <span class="absolute left-3.5 top-2.5 text-gray-400">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
          <path stroke-linecap="round" stroke-linejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" />
        </svg>
      </span>
    </div>
  </div>
</template>
