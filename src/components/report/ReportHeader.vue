<script setup>
defineProps({
  startDate: String,
  endDate: String,
  loading: Boolean,
  exportLoading: Boolean
})

const emit = defineEmits(['update:startDate', 'update:endDate', 'fetch', 'export'])
</script>

<template>
  <div class="flex flex-col lg:flex-row justify-between items-start lg:items-end mb-2 gap-6 animate-enter">
    
    <div>
      <h2 class="text-3xl md:text-4xl font-extrabold text-black tracking-tight mb-1">Laporan Operasional</h2>
      <p class="text-gray-500 font-bold text-sm">Analisis & Export Data Transaksi</p>
    </div>

    <div class="w-full lg:w-auto bg-[#143d2e] p-2 md:p-2.5 rounded-3xl md:rounded-full shadow-xl shadow-green-900/10 flex flex-col md:flex-row gap-2 md:gap-3 items-stretch md:items-center">
      
      <div class="flex flex-col md:flex-row gap-2 md:gap-0 items-center bg-white/10 rounded-2xl md:rounded-full px-4 py-2 border border-white/10 flex-1">
        
        <div class="flex flex-col w-full md:w-auto">
          <label class="text-[10px] text-green-200 uppercase font-bold tracking-wider mb-0.5 md:hidden">Dari</label>
          <input 
            :value="startDate"
            @input="emit('update:startDate', $event.target.value)"
            type="date" 
            class="bg-transparent outline-none text-sm font-bold text-white w-full md:w-32 cursor-pointer dark-date-icon" 
          />
        </div>

        <span class="hidden md:block text-white/30 mx-3">|</span>
        <div class="md:hidden w-full h-px bg-white/10 my-1"></div>

        <div class="flex flex-col w-full md:w-auto">
          <label class="text-[10px] text-green-200 uppercase font-bold tracking-wider mb-0.5 md:hidden">Sampai</label>
          <input 
            :value="endDate"
            @input="emit('update:endDate', $event.target.value)"
            type="date" 
            class="bg-transparent outline-none text-sm font-bold text-white w-full md:w-32 cursor-pointer dark-date-icon" 
          />
        </div>
      </div>

      <div class="flex gap-2">
        <button 
          @click="emit('fetch')"
          :disabled="loading"
          class="flex-1 md:flex-none bg-[#34d399] hover:bg-[#2eb886] text-[#064e3b] px-6 py-2.5 md:py-2 rounded-xl md:rounded-full font-bold text-sm transition-all shadow-sm active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 min-w-[100px]"
        >
          <span v-if="loading" class="loading loading-spinner loading-xs"></span>
          <span v-else class="flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
            </svg>
            Cari
          </span>
        </button>

        <button 
          @click="emit('export')"
          :disabled="exportLoading"
          class="flex-1 md:flex-none bg-white/10 hover:bg-white/20 text-white px-4 py-2.5 md:py-2 rounded-xl md:rounded-full transition-all active:scale-95 disabled:opacity-50 border border-white/10 flex items-center justify-center"
          title="Download Excel"
        >
          <span v-if="exportLoading" class="loading loading-spinner loading-xs"></span>
          <svg v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-5 h-5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3" />
          </svg>
        </button>
      </div>

    </div>
  </div>
</template>

<style scoped>
/* Magic CSS agar ikon kalender menjadi putih */
.dark-date-icon {
  color-scheme: dark;
}
</style>