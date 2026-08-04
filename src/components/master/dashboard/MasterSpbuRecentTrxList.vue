<script setup>
defineProps({
  recentTransactions: {
    type: Array,
    default: () => []
  },
  periodLabel: {
    type: String,
    default: 'Hari Ini'
  }
})
</script>

<template>
  <div class="bg-white rounded-2xl p-4 border border-gray-100 shadow-sm">
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center gap-2">
        <h5 class="text-xs font-black text-[#143d2e] uppercase tracking-wider">10 Transaksi Terakhir ({{ periodLabel }})</h5>
      </div>
    </div>

    <div class="space-y-2 max-h-64 overflow-y-auto pr-1 hide-scrollbar">
      <div v-if="recentTransactions.length === 0" class="py-6 text-center text-gray-400 text-xs font-medium">
        Belum ada transaksi tercatat pada periode ({{ periodLabel }}) untuk SPBU ini.
      </div>
      <div
        v-for="tx in recentTransactions"
        :key="tx.id"
        class="flex items-center justify-between p-2.5 rounded-xl bg-gray-50 hover:bg-green-50/40 border border-gray-100 transition-colors gap-2"
      >
        <div class="flex items-center gap-2.5 sm:gap-3 min-w-0">
          <div class="px-2.5 py-1 bg-[#143d2e] text-white rounded-lg text-xs font-mono font-black tracking-wider shadow-xs shrink-0">
            {{ tx.plat }}
          </div>
          <div class="min-w-0">
            <div class="flex flex-col sm:flex-row sm:items-center sm:gap-1.5 leading-tight">
              <span class="text-xs font-bold text-gray-800 truncate">{{ tx.date }}</span>
              <span class="text-[10px] sm:text-xs font-semibold text-gray-400 sm:text-gray-500 flex items-center gap-1">
                <span class="hidden sm:inline text-gray-300">•</span>
                {{ tx.time }}
              </span>
            </div>
          </div>
        </div>

        <div class="text-right shrink-0">
          <p class="text-xs font-black text-[#143d2e]">{{ tx.liter }}</p>
          <p class="text-[10px] text-gray-500 font-semibold">{{ tx.amount }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
