<script setup>
import { ref } from 'vue'

defineProps({
  startDate: String,
  endDate: String,
  loading: Boolean,
  exportLoading: Boolean
})

const emit = defineEmits(['update:startDate', 'update:endDate', 'fetch', 'export'])

const startDateRef = ref(null)
const endDateRef = ref(null)

const triggerStartDate = () => {
  if (startDateRef.value) {
    if (typeof startDateRef.value.showPicker === 'function') startDateRef.value.showPicker()
    else startDateRef.value.focus()
  }
}

const triggerEndDate = () => {
  if (endDateRef.value) {
    if (typeof endDateRef.value.showPicker === 'function') endDateRef.value.showPicker()
    else endDateRef.value.focus()
  }
}
</script>

<template>
  <div class="flex flex-col lg:flex-row justify-between items-start lg:items-center mb-2 gap-4 animate-enter">
    
    <div>
      <h2 class="text-2xl sm:text-3xl md:text-4xl font-extrabold text-black tracking-tight mb-1">Laporan Operasional</h2>
      <p class="text-gray-500 font-bold text-xs sm:text-sm">Analisis & Export Data Transaksi</p>
    </div>

    <div class="w-full lg:w-auto bg-[#143d2e] p-2.5 rounded-3xl md:rounded-full shadow-xl shadow-green-900/10 flex flex-col md:flex-row gap-2.5 items-stretch md:items-center border border-green-800/40">
      
      <div class="flex flex-col sm:flex-row gap-2.5 md:gap-0 items-stretch sm:items-center bg-white/10 backdrop-blur-md rounded-2xl md:rounded-full px-4 py-2 border border-white/15 flex-1">
        
        <!-- Date From -->
        <div @click="triggerStartDate" class="group flex items-center gap-2.5 w-full sm:w-auto cursor-pointer select-none">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-green-300 group-hover:scale-110 transition-transform shrink-0">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
          </svg>
          <span class="text-[10px] text-green-200/80 uppercase font-extrabold tracking-wider shrink-0">Dari</span>
          <input 
            ref="startDateRef"
            :value="startDate"
            @input="emit('update:startDate', $event.target.value)"
            type="date" 
            class="bg-transparent outline-none text-xs sm:text-sm font-bold text-white w-full sm:w-32 cursor-pointer dark-date-icon" 
            @click.stop
          />
        </div>

        <span class="hidden sm:block text-white/30 mx-3">|</span>
        <div class="sm:hidden w-full h-px bg-white/10 my-1"></div>

        <!-- Date To -->
        <div @click="triggerEndDate" class="group flex items-center gap-2.5 w-full sm:w-auto cursor-pointer select-none">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-green-300 group-hover:scale-110 transition-transform shrink-0">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
          </svg>
          <span class="text-[10px] text-green-200/80 uppercase font-extrabold tracking-wider shrink-0">Sampai</span>
          <input 
            ref="endDateRef"
            :value="endDate"
            @input="emit('update:endDate', $event.target.value)"
            type="date" 
            class="bg-transparent outline-none text-xs sm:text-sm font-bold text-white w-full sm:w-32 cursor-pointer dark-date-icon" 
            @click.stop
          />
        </div>
      </div>

      <div class="flex gap-2">
        <button 
          @click="emit('fetch')"
          :disabled="loading"
          class="flex-1 md:flex-none bg-[#34d399] hover:bg-[#2eb886] text-[#064e3b] px-6 py-2.5 md:py-2 rounded-xl md:rounded-full font-extrabold text-xs sm:text-sm transition-all shadow-md active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 min-w-[100px] cursor-pointer"
        >
          <span v-if="loading" class="loading loading-spinner loading-xs"></span>
          <span v-else class="flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
            </svg>
            Terapkan
          </span>
        </button>

        <button 
          @click="emit('export')"
          :disabled="exportLoading"
          class="flex-1 md:flex-none bg-white/10 hover:bg-white/20 text-white px-4 py-2.5 md:py-2 rounded-xl md:rounded-full transition-all active:scale-95 disabled:opacity-50 border border-white/15 flex items-center justify-center cursor-pointer shadow-sm"
          title="Download Excel"
        >
          <span v-if="exportLoading" class="loading loading-spinner loading-xs"></span>
          <svg v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-5 h-5 text-green-200">
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
.dark-date-icon::-webkit-calendar-picker-indicator {
  cursor: pointer;
  filter: invert(1) brightness(1.5);
  opacity: 0.8;
  transition: transform 0.2s ease;
}
.dark-date-icon:hover::-webkit-calendar-picker-indicator {
  opacity: 1;
  transform: scale(1.1);
}
</style>