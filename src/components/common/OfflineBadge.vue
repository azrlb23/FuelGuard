<script setup>
import { useNetworkStatus } from '@/composables/common/useNetworkStatus'
import { useOfflineQueue } from '@/composables/common/useOfflineQueue'

const { isOnline } = useNetworkStatus()
const { pendingCount, isSyncing, syncPendingTransactions } = useOfflineQueue()
</script>

<template>
  <div class="fixed bottom-4 right-4 z-50 flex items-center gap-2 text-xs font-semibold">
    <!-- Offline Alert Pill -->
    <div 
      v-if="!isOnline" 
      class="flex items-center gap-2 px-4 py-2.5 rounded-full bg-amber-500 text-white shadow-lg shadow-amber-500/20 backdrop-blur-md animate-pulse border border-amber-400/40"
    >
      <span class="w-2.5 h-2.5 rounded-full bg-white animate-ping"></span>
      <span>Mode Offline</span>
      <span v-if="pendingCount > 0" class="ml-1 px-2 py-0.5 rounded-full bg-amber-700 text-white font-extrabold text-[10px]">
        {{ pendingCount }} Tersimpan
      </span>
    </div>

    <!-- Syncing Indicator -->
    <div 
      v-else-if="isSyncing"
      class="flex items-center gap-2 px-4 py-2.5 rounded-full bg-emerald-800 text-white shadow-lg shadow-emerald-900/30 backdrop-blur-md border border-emerald-600/40"
    >
      <svg class="animate-spin h-3.5 w-3.5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      <span>Menyinkronkan Data...</span>
    </div>

    <!-- Online with Unsynced Items -->
    <button 
      v-else-if="isOnline && pendingCount > 0"
      @click="syncPendingTransactions"
      class="flex items-center gap-2 px-4 py-2.5 rounded-full bg-[#143d2e] text-white shadow-lg shadow-emerald-900/30 hover:bg-[#1e5c45] active:scale-95 transition-all duration-200 border border-emerald-500/30 cursor-pointer"
    >
      <span class="w-2 h-2 rounded-full bg-emerald-400"></span>
      <span>{{ pendingCount }} Transaksi Belum Terkirim</span>
      <span class="underline font-bold text-emerald-200 ml-1">Kirim Sekarang</span>
    </button>
  </div>
</template>
