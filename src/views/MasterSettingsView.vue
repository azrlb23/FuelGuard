<script setup>
import ProfileCard from '@/components/settings/ProfileCard.vue'
import SecurityForm from '@/components/settings/SecurityForm.vue'
import FuelPriceForm from '@/components/settings/FuelPriceForm.vue'
</script>

<template>
  <div class="flex flex-col gap-6 animate-enter pb-10">

    <!-- Top Header -->
    <div class="px-1">
      <h2 class="text-3xl md:text-4xl font-extrabold text-[#143d2e] tracking-tight">Pengaturan</h2>
    </div>

    <!-- Section 1: Profil Master Header Banner (Signature Green Glassmorphism Gradient) -->
    <div class="bg-gradient-to-br from-[#143d2e] via-[#1b4d3a] to-[#256a50] rounded-3xl p-6 md:p-8 text-white shadow-xl shadow-green-900/15 relative overflow-hidden border border-white/20 backdrop-blur-xl">
      <div class="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl -translate-y-20 translate-x-20 pointer-events-none"></div>
      <ProfileCard />
    </div>

    <!-- Section 2: Konfigurasi Harga BBM Pertalite -->
    <div class="bg-white rounded-3xl border border-gray-100 shadow-xs p-6 md:p-8">
      <h3 class="text-xs font-bold text-gray-400 uppercase tracking-widest mb-6">
        Pengaturan Harga Pertalite
      </h3>
      <FuelPriceForm />
    </div>

    <!-- Section 3: Keamanan Akun Superadmin -->
    <div class="bg-white rounded-3xl border border-gray-100 shadow-xs p-6 md:p-8">
      <h3 class="text-xs font-bold text-gray-400 uppercase tracking-widest mb-6">
        Pengaturan Keamanan Akun
      </h3>
      <SecurityForm />
    </div>

  </div>
</template>
