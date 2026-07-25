<script setup>
defineEmits(['reset'])
</script>

<template>
  <div class="flex flex-col items-center justify-center text-center animate-enter py-6 md:py-10">
    <div class="w-16 h-16 md:w-24 md:h-24 bg-green-500 rounded-full flex items-center justify-center shadow-lg mb-4 md:mb-6 animate-bounce">
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="3" stroke="currentColor" class="w-8 h-8 md:w-12 md:h-12 text-white">
        <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
      </svg>
    </div>
    
    <h3 class="text-2xl md:text-3xl font-bold text-white mb-2">Transaksi Berhasil!</h3>
    <p class="text-green-200 mb-6 md:mb-8 text-sm md:text-base">Data telah tersimpan ke sistem.</p>
    
    <button @click="$emit('reset')" class="px-6 py-2 md:px-8 md:py-3 bg-white/10 hover:bg-white/20 rounded-full font-bold text-white text-sm md:text-base transition-all">
      Input Transaksi Baru
    </button>
  </div>
</template>