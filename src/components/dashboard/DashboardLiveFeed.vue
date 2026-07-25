<script setup>
import { defineProps } from 'vue'

const props = defineProps({
  items: {
    type: Array,
    default: () => [] 
  }
})


const formatTimeAgo = (dateString) => {
  
  const date = new Date(dateString)
  const now = new Date()
  const diffInMinutes = Math.floor((now - date) / (1000 * 60))
  
  if (diffInMinutes < 1) return 'Just now'
  if (diffInMinutes < 60) return `${diffInMinutes}m ago`
  
  const diffInHours = Math.floor(diffInMinutes / 60)
  if (diffInHours < 24) return `${diffInHours}h ago`
  
  
  return new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'short' }).format(date)
}

const formatRupiah = (val) => {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val)
}
</script>

<template>
  <div class="bg-white rounded-[2rem] p-6 shadow-sm border border-gray-200 flex flex-col h-full min-w-0 min-h-[350px] relative overflow-hidden">
    
    <div class="flex justify-between items-center mb-4 z-10">
      <h4 class="font-bold text-lg text-gray-800 tracking-tight">Live Transaction</h4>
      <span class="bg-green-100 px-3 py-1 rounded-full text-[10px] font-bold text-green-800 uppercase tracking-wider">
        Realtime
      </span>
    </div>

    <div class="flex-1 overflow-y-auto pr-1 space-y-3 z-10 custom-scrollbar">
      
      <div 
        v-for="(item, index) in items" 
        :key="item.id || index" 
        class="flex items-center justify-between p-3 bg-gray-50 rounded-xl hover:bg-green-50 transition-colors group cursor-default"
      >
        
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded-full bg-white border border-gray-100 flex items-center justify-center text-[#143d2e] shadow-sm group-hover:scale-110 transition-transform">
             <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5">
               <path fill-rule="evenodd" d="M12.97 3.97a.75.75 0 011.06 0l7.5 7.5a.75.75 0 010 1.06l-7.5 7.5a.75.75 0 11-1.06-1.06l6.22-6.22H3a.75.75 0 010-1.5h16.19l-6.22-6.22a.75.75 0 010-1.06z" clip-rule="evenodd" />
             </svg>
          </div>
          
          <div>
            <p class="font-bold text-gray-800 group-hover:text-[#143d2e] leading-tight">
              {{ item.plat_nomor || 'Unknown' }}
            </p>
            <p class="text-[11px] text-gray-400 capitalize mt-0.5">
              {{ formatTimeAgo(item.waktu_pencatatan || item.created_at) }}
            </p>
          </div>
        </div>

        <div class="text-right">
          <p class="font-black text-[#143d2e] text-sm">{{ item.liter }} L</p>
          <p class="text-[10px] text-gray-400 font-medium bg-gray-200 px-1.5 py-0.5 rounded text-center inline-block mt-1">
             {{ item.jenis_kendaraan || 'Umum' }}
          </p>
        </div>

      </div>

      <div v-if="items.length === 0" class="h-full flex flex-col items-center justify-center text-gray-400 text-sm opacity-60">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-8 h-8 mb-2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
        <p>Menunggu data masuk...</p>
      </div>

    </div>

    <div class="absolute top-0 right-0 w-24 h-24 bg-green-50 rounded-full blur-3xl -translate-y-5 translate-x-5 pointer-events-none"></div>
  </div>
</template>

<style scoped>
.custom-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;  
}

.custom-scrollbar::-webkit-scrollbar {
  display: none; 
}
</style>