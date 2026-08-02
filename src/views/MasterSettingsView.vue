<script setup>
// import { useAuthStore } from '@/stores/auth'
import ProfileCard from '@/components/settings/ProfileCard.vue'
import SecurityForm from '@/components/settings/SecurityForm.vue'
import FuelPriceForm from '@/components/settings/FuelPriceForm.vue'

// const authStore = useAuthStore()
</script>

<template>
  <div class="space-y-6 animate-enter pb-8">

    <!-- Top Header -->
    <div class="px-1">
      <h2 class="text-3xl md:text-4xl font-extrabold text-black tracking-tight mb-1">Pengaturan</h2>
    </div>

    <!-- Profile Overview Card -->
    <ProfileCard />

    <!-- Master / Admin System Configuration Zone -->
    <div class="animate-enter" style="animation-delay: 100ms">
      <div class="px-1 mb-3 mt-8 flex items-center gap-2">
        <div class="w-2 h-2 rounded-full bg-[#34d399]"></div>
        <span class="text-xs font-extrabold text-[#143d2e] uppercase tracking-wider">
          Konfigurasi Jaringan SPBU
        </span>
      </div>
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <FuelPriceForm />
      </div>
    </div>

    <!-- Account Settings (Profile & Security) -->
    <div class="px-1 mb-2 mt-8 flex items-center gap-2">
      <div class="w-2 h-2 rounded-full bg-gray-400"></div>
      <span class="text-xs font-extrabold text-gray-500 uppercase tracking-wider">
        Pengaturan Akun & Keamanan
      </span>
    </div>
    <SecurityForm />

    <!-- Footer Note -->
    <p class="text-center text-xs text-gray-400 font-medium pt-8 pb-4">
      FuelGuard Master Console &copy; {{ new Date().getFullYear() }} Habi Jaya Group. All rights reserved.
    </p>

  </div>
</template>
