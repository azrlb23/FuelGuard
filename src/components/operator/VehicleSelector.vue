<script setup>
import { ref } from 'vue'

const emit = defineEmits(['select'])
const isSelecting = ref(false)
const selectedType = ref('')

const handleSelect = (payload) => {
  if (isSelecting.value) return
  isSelecting.value = true
  selectedType.value = payload.type
  emit('select', payload)
  setTimeout(() => {
    isSelecting.value = false
    selectedType.value = ''
  }, 400)
}
</script>

<template>
  <div class="flex flex-col items-center animate-enter w-full py-2 md:py-4">

    <!-- HEADER TEKS: Diberikan margin bawah (mb-8) agar tidak terlalu dekat dengan tombol -->
    <div class="text-center space-y-2 mb-6 md:mb-10">
      <h3 class="text-2xl md:text-3xl font-extrabold text-white tracking-tight drop-shadow-sm">
        Pilih Jenis Kendaraan
      </h3>
      <p class="text-xs md:text-sm text-green-100/80 font-medium max-w-md mx-auto leading-relaxed">
        Silakan pilih kategori motor yang akan diisi BBM Pertalite
      </p>
    </div>

    <div class="flex flex-col sm:flex-row gap-4 md:gap-6 w-full max-w-2xl md:max-w-3xl justify-center px-2">
      <!-- Button Ojol -->
      <button
        @click="handleSelect({ type: 'Ojol', isOjol: true })"
        :disabled="isSelecting"
        class="group relative flex-1 bg-white/10 hover:bg-white/20 border-2 border-white/30 hover:border-white rounded-2xl md:rounded-3xl p-6 md:p-10 transition-all duration-300 flex flex-col items-center justify-center gap-3 hover:scale-[1.03] active:scale-95 shadow-xl hover:shadow-emerald-500/20 backdrop-blur-sm cursor-pointer min-h-[110px] md:min-h-[140px] disabled:opacity-60 disabled:cursor-not-allowed"
      >
        <span v-if="isSelecting && selectedType === 'Ojol'" class="loading loading-spinner loading-lg text-white"></span>
        <span v-else class="text-xl md:text-3xl font-black text-white tracking-wider uppercase text-center leading-tight">Ojol</span>
      </button>

      <!-- Button Umum -->
      <button
        @click="handleSelect({ type: 'Non-Ojol', isOjol: false })"
        :disabled="isSelecting"
        class="group relative flex-1 bg-white/10 hover:bg-white/20 border-2 border-white/30 hover:border-white rounded-2xl md:rounded-3xl p-6 md:p-10 transition-all duration-300 flex flex-col items-center justify-center gap-3 hover:scale-[1.03] active:scale-95 shadow-xl hover:shadow-emerald-500/20 backdrop-blur-sm cursor-pointer min-h-[110px] md:min-h-[140px] disabled:opacity-60 disabled:cursor-not-allowed"
      >
        <span v-if="isSelecting && selectedType === 'Non-Ojol'" class="loading loading-spinner loading-lg text-white"></span>
        <span v-else class="text-xl md:text-3xl font-black text-white tracking-wider uppercase text-center leading-tight">Umum</span>
      </button>

    </div>
  </div>
</template>
