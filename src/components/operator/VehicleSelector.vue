<script setup>
const emit = defineEmits(['select'])

const onSelectCategory = (isOjol) => {
  emit('select', { type: 'Motor', isOjol })
}
</script>

<template>
  <div class="flex flex-col items-center animate-enter w-full py-2 md:py-4">

    <!-- HEADER TEKS -->
    <div class="text-center space-y-2 mb-6 md:mb-10 animate-enter">
      <h3 class="text-2xl md:text-3xl font-extrabold text-white tracking-tight drop-shadow-sm">
        Pilih Kategori Pengisian
      </h3>
      <p class="text-xs md:text-sm text-green-100/80 font-medium max-w-md mx-auto leading-relaxed">
        Silakan pilih kategori motor yang akan diisi BBM Pertalite
      </p>
    </div>

    <div class="flex flex-col sm:flex-row gap-4 md:gap-6 w-full max-w-xl justify-center px-2">
      <!-- Button Motor Ojol -->
      <button
        @click="$emit('select', 'Ojol')"
        class="group relative flex-1 bg-white/10 hover:bg-white/20 border-2 border-white/30 hover:border-white rounded-2xl md:rounded-3xl p-6 md:p-8 transition-all duration-300 flex flex-col items-center justify-center gap-3 hover:scale-[1.03] active:scale-95 shadow-xl hover:shadow-emerald-500/20 backdrop-blur-sm"
      >
        <span class="text-xl md:text-2xl font-black text-white tracking-wider uppercase text-center leading-tight">Motor<br>Ojol</span>
      </button>

      <!-- Button Motor Umum -->
      <button
        @click="$emit('select', 'Non-Ojol')"
        class="group relative flex-1 bg-white/10 hover:bg-white/20 border-2 border-white/30 hover:border-white rounded-2xl md:rounded-3xl p-6 md:p-8 transition-all duration-300 flex flex-col items-center justify-center gap-3 hover:scale-[1.03] active:scale-95 shadow-xl hover:shadow-emerald-500/20 backdrop-blur-sm"
      >
        <span class="text-xl md:text-2xl font-black text-white tracking-wider uppercase text-center leading-tight">Motor<br>Umum</span>
      </button>
    </div>

  </div>
</template>

