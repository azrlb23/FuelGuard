<script setup>
import { useRegisterSW } from 'virtual:pwa-register/vue'

const { offlineReady, needRefresh, updateServiceWorker } = useRegisterSW()

const close = () => {
  offlineReady.value = false
  needRefresh.value = false
}
</script>

<template>
  <div 
    v-if="offlineReady || needRefresh"
    class="fixed top-4 right-4 z-[9999] max-w-sm p-4 rounded-2xl bg-[#143d2e] text-white shadow-2xl shadow-green-900/40 border border-emerald-600/40 backdrop-blur-md animate-bounce-short"
  >
    <div class="flex items-start gap-3">
      <div class="p-2 rounded-xl bg-white/10 text-emerald-400">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
      </div>
      <div class="flex-1">
        <h4 class="font-bold text-sm text-white">
          {{ offlineReady ? 'Aplikasi Siap Offline' : 'Versi Baru Tersedia' }}
        </h4>
        <p class="text-xs text-gray-300 mt-1">
          {{ offlineReady ? 'FuelGuard sekarang dapat diakses tanpa koneksi internet.' : 'Pembaruan sistem terbaru siap dipasang.' }}
        </p>
        <div class="mt-3 flex items-center gap-2">
          <button
            v-if="needRefresh"
            @click="updateServiceWorker()"
            class="px-3 py-1.5 rounded-xl bg-emerald-500 hover:bg-emerald-600 text-white font-bold text-xs active:scale-95 transition-all shadow-md cursor-pointer"
          >
            Perbarui Sekarang
          </button>
          <button
            @click="close"
            class="px-3 py-1.5 rounded-xl bg-white/10 hover:bg-white/20 text-gray-300 font-medium text-xs active:scale-95 transition-all cursor-pointer"
          >
            Tutup
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
