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
        Silakan pilih kategori kendaraan yang akan diisi BBM Pertalite
      </p>
    </div>

    <!-- TOMBOL IKON KENDARAAN (MOTOR BIASA & MOTOR OJOL) -->
    <div class="flex flex-col sm:flex-row gap-4 md:gap-6 w-full max-w-xl justify-center px-2 animate-enter">
      <!-- Motor Biasa (Kiri) -->
      <button
        @click="onSelectCategory(false)"
        title="Motor Biasa"
        aria-label="Motor Biasa"
        class="group relative flex-1 bg-white/10 hover:bg-white/20 border-2 border-white/30 hover:border-white rounded-2xl md:rounded-3xl p-6 md:p-8 transition-all duration-300 flex flex-col items-center justify-center gap-3 hover:scale-[1.03] active:scale-95 shadow-xl hover:shadow-emerald-500/20 backdrop-blur-sm"
      >
        <!-- Logo Motor Biasa (Sepeda Motor Sleek) -->
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none" class="w-16 h-16 md:w-20 md:h-20 text-white group-hover:scale-105 transition-transform" aria-hidden="true">
          <path d="M18 42 C18 42 22 28 30 26 C36 24 44 28 44 28 L48 38" stroke="currentColor" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
          <path d="M26 26 L34 26 L36 31 L24 31 Z" fill="currentColor" opacity="0.6"/>
          <path d="M44 36 L52 38 L52 40 L44 40" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" fill="none"/>
          <path d="M23 26 L18 23 M23 26 L21 21" stroke="currentColor" stroke-width="3" stroke-linecap="round"/>
          <path d="M27 24 L37 24 L39 22 L25 22 Z" fill="currentColor" opacity="0.85"/>
          <circle cx="16" cy="42" r="8" stroke="currentColor" stroke-width="3.5" fill="none"/>
          <circle cx="16" cy="42" r="3" fill="currentColor" opacity="0.6"/>
          <circle cx="48" cy="42" r="8" stroke="currentColor" stroke-width="3.5" fill="none"/>
          <circle cx="48" cy="42" r="3" fill="currentColor" opacity="0.6"/>
        </svg>
        <span class="text-xl md:text-2xl font-black text-white tracking-wider uppercase">Motor Biasa</span>
      </button>

      <!-- Motor OJOL (Kanan) -->
      <button
        @click="onSelectCategory(true)"
        title="Motor OJOL"
        aria-label="Motor OJOL"
        class="group relative flex-1 bg-emerald-500/20 hover:bg-emerald-500/30 border-2 border-emerald-400/60 hover:border-emerald-300 rounded-2xl md:rounded-3xl p-6 md:p-8 transition-all duration-300 flex flex-col items-center justify-center gap-3 hover:scale-[1.03] active:scale-95 shadow-xl shadow-emerald-950/40 backdrop-blur-sm"
      >
        <!-- Logo Motor OJOL (Motor + Helm Ojol & Tas Delivery) -->
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none" class="w-16 h-16 md:w-20 md:h-20 text-emerald-300 group-hover:text-emerald-200 group-hover:scale-105 transition-all" aria-hidden="true">
          <!-- Bodi Motor -->
          <path d="M18 42 C18 42 22 28 30 26 C36 24 44 28 44 28 L48 38" stroke="currentColor" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
          <path d="M26 26 L34 26 L36 31 L24 31 Z" fill="currentColor" opacity="0.6"/>
          <path d="M23 26 L18 23 M23 26 L21 21" stroke="currentColor" stroke-width="3" stroke-linecap="round"/>
          <circle cx="16" cy="42" r="8" stroke="currentColor" stroke-width="3.5" fill="none"/>
          <circle cx="48" cy="42" r="8" stroke="currentColor" stroke-width="3.5" fill="none"/>
          <!-- Tas Delivery Ojol / Thermal Box di Belakang -->
          <rect x="8" y="22" width="12" height="13" rx="2.5" fill="currentColor" opacity="0.95"/>
          <path d="M10 26 L18 26" stroke="#143d2e" stroke-width="2" stroke-linecap="round"/>
          <!-- Helm Ojol dengan Visor Khas -->
          <path d="M28 17 C28 11.5 32.5 7 38 7 C43.5 7 48 11.5 48 17 C48 18 47.5 19 46.5 19 L29.5 19 C28.5 19 28 18 28 17 Z" fill="currentColor"/>
          <!-- Visor Helm -->
          <path d="M40 12 L47 12 C47.5 12 48 13.5 47.5 15 L41.5 15 C40.5 15 40 14 40 12 Z" fill="#143d2e"/>
        </svg>
        <span class="text-xl md:text-2xl font-black text-emerald-200 tracking-wider uppercase">Motor OJOL</span>
      </button>
    </div>

  </div>
</template>

