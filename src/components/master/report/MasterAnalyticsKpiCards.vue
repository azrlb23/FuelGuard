<script setup>
defineProps({
  loading: {
    type: Boolean,
    default: false
  },
  kpi: {
    type: Object,
    default: () => ({
      totalSales: 0,
      totalVolume: 0,
      totalTransactions: 0,
      avgTrxPerDay: 0
    })
  },
  formatRupiah: {
    type: Function,
    required: true
  },
  formatVolume: {
    type: Function,
    required: true
  }
})
</script>

<template>
  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">

    <!-- Loading Skeleton Cards -->
    <template v-if="loading">
      <div v-for="n in 4" :key="n" class="relative overflow-hidden bg-gradient-to-br from-[#143d2e] to-[#258f62] rounded-[2rem] p-6 text-white shadow-xl shadow-green-900/10 animate-pulse space-y-4">
        <div class="flex justify-between items-start">
          <div class="h-3 w-24 bg-white/25 rounded-full"></div>
          <div class="w-10 h-10 rounded-2xl bg-white/20"></div>
        </div>
        <div class="h-8 w-36 bg-white/30 rounded-xl"></div>
        <div class="absolute -right-6 -bottom-10 w-32 h-32 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
      </div>
    </template>

    <template v-else>
      <!-- Card 1: Total Transaksi -->
      <div class="relative overflow-hidden bg-gradient-to-br from-[#143d2e] to-[#2aa672] rounded-[2rem] p-6 text-white shadow-xl shadow-green-900/10 hover:scale-[1.01] transition-transform">
        <div class="flex justify-between items-start mb-4">
          <p class="text-xs font-bold uppercase tracking-widest text-green-200">Total Transaksi</p>
          <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center text-green-200">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5.586a1 1 0 0 1 .707.293l5.414 5.414a1 1 0 0 1 .293.707V19a2 2 0 0 1-2 2Z" />
            </svg>
          </div>
        </div>
        <h3 class="text-3xl lg:text-4xl font-black tracking-tight text-white mb-1">{{ kpi.totalTransactions?.toLocaleString('id-ID') || 0 }}</h3>
        <div class="absolute -right-6 -bottom-10 w-32 h-32 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
      </div>

      <!-- Card 2: Total Volume BBM -->
      <div class="relative overflow-hidden bg-gradient-to-br from-[#143d2e] to-[#1e6b4a] rounded-[2rem] p-6 text-white shadow-xl shadow-green-900/10 hover:scale-[1.01] transition-transform">
        <div class="flex justify-between items-start mb-4">
          <p class="text-xs font-bold uppercase tracking-widest text-green-200">Total Volume BBM</p>
          <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center text-green-200">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15.362 5.214A8.252 8.252 0 0 1 12 21 8.25 8.25 0 0 1 6.038 7.047 8.287 8.287 0 0 1 9 3.603e-7a8.287 8.287 0 0 1 6.362 5.214Z" />
            </svg>
          </div>
        </div>
        <h3 class="text-3xl lg:text-4xl font-black tracking-tight text-white mb-1">{{ formatVolume(kpi.totalVolume) }}</h3>
        <div class="absolute -right-6 -bottom-10 w-32 h-32 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
      </div>

      <!-- Card 3: Total Revenue -->
      <div class="relative overflow-hidden bg-gradient-to-br from-[#143d2e] to-[#258f62] rounded-[2rem] p-6 text-white shadow-xl shadow-green-900/10 hover:scale-[1.01] transition-transform">
        <div class="flex justify-between items-start mb-4">
          <p class="text-xs font-bold uppercase tracking-widest text-green-200">Total Revenue</p>
          <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center text-green-200">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v12m-3-2.818l.879.659c1.171.879 3.07.879 4.242 0 1.172-.879 1.172-2.303 0-3.182C13.536 12.219 12.768 12 12 12c-.725 0-1.45-.22-2.003-.659-1.106-.879-1.106-2.303 0-3.182s2.9-.879 4.006 0l.415.33M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
            </svg>
          </div>
        </div>
        <h3 class="text-3xl lg:text-4xl font-black tracking-tight text-white mb-1">{{ formatRupiah(kpi.totalSales) }}</h3>
        <div class="absolute -right-6 -bottom-10 w-32 h-32 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
      </div>

      <!-- Card 4: Avg Trx / Hari -->
      <div class="relative overflow-hidden bg-gradient-to-br from-[#143d2e] to-[#208358] rounded-[2rem] p-6 text-white shadow-xl shadow-green-900/10 hover:scale-[1.01] transition-transform">
        <div class="flex justify-between items-start mb-4">
          <p class="text-xs font-bold uppercase tracking-widest text-green-200">Rata - Rata Transaksi / Hari</p>
          <div class="w-10 h-10 rounded-2xl bg-white/15 flex items-center justify-center text-green-200">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 18 9 11.25l4.306 4.307a11.95 11.95 0 0 0 5.814-5.519l2.74-1.22m0 0-5.94-2.28m5.94 2.28-2.28 5.941" />
            </svg>
          </div>
        </div>
        <h3 class="text-3xl lg:text-4xl font-black tracking-tight text-white mb-1">{{ kpi.avgTrxPerDay }}</h3>
        <div class="absolute -right-6 -bottom-10 w-32 h-32 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>
      </div>

    </template>
  </div>
</template>
