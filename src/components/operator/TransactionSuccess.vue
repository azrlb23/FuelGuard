<script setup>
defineEmits(['reset'])
</script>

<template>
  <div class="flex flex-col items-center justify-center text-center animate-enter py-6 md:py-8 px-4 relative overflow-hidden">
    
    <!-- Background Glow Rings -->
    <div class="absolute w-40 h-40 bg-emerald-400/20 rounded-full blur-3xl -z-10 animate-pulse"></div>

    <!-- Animated Checkmark Container with Ripple Rings -->
    <div class="relative mb-6">
      <div class="absolute inset-0 rounded-full bg-emerald-400/30 animate-ping opacity-75"></div>
      <div class="w-20 h-20 md:w-24 md:h-24 bg-gradient-to-br from-emerald-400 to-emerald-600 rounded-full flex items-center justify-center shadow-xl shadow-emerald-900/40 relative z-10 animate-bounce-short">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="3" stroke="currentColor" class="w-10 h-10 md:w-12 md:h-12 text-[#143d2e]">
          <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
        </svg>
      </div>
    </div>
    
    <span class="text-xs font-black text-emerald-300 uppercase tracking-widest mb-1.5 animate-fade-in-up">
      Transaksi Berhasil
    </span>
    <h3 class="text-2xl md:text-3xl font-black text-white mb-2 tracking-tight animate-fade-in-up">
      DATA TERSSIMPAN
    </h3>
    <p class="text-emerald-100/70 mb-8 text-xs md:text-sm max-w-xs font-medium animate-fade-in-up">
      Pengisian BBM berhasil dicatat ke sistem FuelGuard.
    </p>
    
    <button 
      @click="$emit('reset')" 
      class="px-8 py-3.5 bg-white hover:bg-emerald-50 text-[#143d2e] rounded-2xl font-black text-sm md:text-base shadow-xl active:scale-95 transition-all cursor-pointer animate-fade-in-up"
    >
      INPUT TRANSAKSI BARU
    </button>

  </div>
</template>

<style scoped>
@keyframes bounceShort {
  0% { transform: scale(0.3); opacity: 0; }
  60% { transform: scale(1.15); opacity: 1; }
  80% { transform: scale(0.95); }
  100% { transform: scale(1); }
}
.animate-bounce-short {
  animation: bounceShort 0.6s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards;
}

@keyframes fadeInUp {
  from { opacity: 0; transform: translateY(12px); }
  to { opacity: 1; transform: translateY(0); }
}
.animate-fade-in-up {
  animation: fadeInUp 0.4s ease-out forwards;
}
</style>