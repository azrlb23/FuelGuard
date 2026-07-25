<script setup>
defineProps({
  customers: { type: Array, default: () => [] }
})
</script>

<template>
  <div class="bg-white rounded-[2rem] p-6 shadow-sm border border-gray-200 flex flex-col h-full min-w-0 relative overflow-hidden">
    
    <div class="flex justify-between items-center mb-4 z-10">
      <h4 class="font-bold text-lg text-gray-800 tracking-tight">Pelanggan Setia</h4>
      <span class="bg-green-100 px-3 py-1 rounded-full text-[10px] font-bold text-green-800 uppercase tracking-wider">Top 5 Bulan Ini</span>
    </div>

    <div class="flex-1 overflow-y-auto pr-1 space-y-3 z-10">
      <div v-for="(c, i) in customers" :key="i" class="flex items-center justify-between p-3 bg-gray-50 rounded-xl hover:bg-green-50 transition-colors group">
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 rounded-full flex items-center justify-center font-black text-sm" 
               :class="i === 0 ? 'bg-yellow-100 text-yellow-700' : 'bg-gray-200 text-gray-500'">
            #{{ i + 1 }}
          </div>
          <div>
            <p class="font-bold text-gray-800 group-hover:text-[#143d2e]">{{ c.plat_nomor }}</p>
            <p class="text-xs text-gray-400">{{ c.total_trx }} Transaksi</p>
          </div>
        </div>
        <div class="text-right">
          <p class="font-bold text-[#143d2e]">{{ c.total_liter }} L</p>
        </div>
      </div>

      <div v-if="customers.length === 0" class="h-full flex flex-col items-center justify-center text-gray-400 text-sm">
        <p>Belum ada data loyalitas</p>
      </div>
    </div>
    
    <div class="absolute top-0 right-0 w-24 h-24 bg-green-50 rounded-full blur-3xl -translate-y-5 translate-x-5 pointer-events-none"></div>
  </div>
</template>

<style scoped>
.hide-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;  
}

.hide-scrollbar::-webkit-scrollbar {
  display: none; 
}
</style>