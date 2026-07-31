<script setup>
defineProps({
  totalNetworkRevenue: {
    type: String,
    required: true
  },
  totalNetworkVolume: {
    type: String,
    required: true
  },
  activeSpbuCountText: {
    type: String,
    required: true
  },
  totalTransactionsCount: {
    type: String,
    required: true
  },
  periodLabel: {
    type: String,
    required: true
  },
  transactionCardTitle: {
    type: String,
    required: true
  },
  spbuCount: {
    type: Number,
    default: 0
  }
})
</script>

<template>
  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">

    <!-- Revenue Card -->
    <div class="relative overflow-hidden bg-gradient-to-br from-[#143d2e] to-[#258f62] rounded-[2rem] p-6 text-white shadow-xl shadow-green-900/10 hover:scale-[1.01] transition-transform">
      <div class="flex justify-between items-start mb-4">
        <p class="text-xs font-bold uppercase tracking-widest text-green-200">Total Revenue</p>
        <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center text-green-200">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" d="M2.25 18L9 11.25l4.306 4.307a11.95 11.95 0 005.814-5.519l2.74-1.22m0 0l-5.94-2.28m5.94 2.28l-2.28 5.941" /></svg>
        </div>
      </div>
      <h3 class="text-3xl lg:text-4xl font-black tracking-tight text-white mb-1">{{ totalNetworkRevenue }}</h3>
      <div class="absolute -right-6 -bottom-10 w-32 h-32 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
    </div>

    <!-- Volume Card -->
    <div class="relative overflow-hidden bg-gradient-to-br from-[#143d2e] to-[#1e6b4a] rounded-[2rem] p-6 text-white shadow-xl shadow-green-900/10 hover:scale-[1.01] transition-transform">
      <div class="flex justify-between items-start mb-4">
        <p class="text-xs font-bold uppercase tracking-widest text-green-200">Volume BBM</p>
        <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center text-green-200">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" d="M12 21a9 9 0 100-18 9 9 0 000 18z" /></svg>
        </div>
      </div>
      <h3 class="text-3xl lg:text-4xl font-black tracking-tight text-white mb-1">{{ totalNetworkVolume }}</h3>
      <div class="absolute -right-6 -bottom-10 w-32 h-32 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
    </div>

    <!-- Active SPBU Card -->
    <div class="relative overflow-hidden bg-gradient-to-br from-[#143d2e] to-[#2aa672] rounded-[2rem] p-6 text-white shadow-xl shadow-green-900/10 hover:scale-[1.01] transition-transform">
      <div class="flex justify-between items-start mb-4">
        <p class="text-xs font-bold uppercase tracking-widest text-green-200">Total SPBU</p>
        <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center text-green-200">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" /></svg>
        </div>
      </div>
      <h3 class="text-3xl lg:text-4xl font-black tracking-tight text-white mb-1">{{ activeSpbuCountText }}</h3>
      <div class="absolute -right-6 -bottom-10 w-32 h-32 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
    </div>

    <!-- Transactions Card -->
    <div class="relative overflow-hidden bg-gradient-to-br from-[#143d2e] to-[#208358] rounded-[2rem] p-6 text-white shadow-xl shadow-green-900/10 hover:scale-[1.01] transition-transform">
      <div class="flex justify-between items-start mb-4">
        <p class="text-xs font-bold uppercase tracking-widest text-green-200">{{ transactionCardTitle }}</p>
        <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center text-green-200">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
        </div>
      </div>
      <h3 class="text-3xl lg:text-4xl font-black tracking-tight text-white mb-1">{{ totalTransactionsCount }}</h3>
      <div class="absolute -right-6 -bottom-10 w-32 h-32 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
    </div>

  </div>
</template>
