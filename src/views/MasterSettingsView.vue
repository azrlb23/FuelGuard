<script setup>
import { useAuthStore } from '@/stores/auth'
import ProfileCard from '@/components/settings/ProfileCard.vue'
import SecurityForm from '@/components/settings/SecurityForm.vue'
import FuelPriceForm from '@/components/settings/FuelPriceForm.vue'
import ProfileForm from '@/components/settings/ProfileForm.vue'
import ShiftForm from '@/components/settings/ShiftForm.vue'

const authStore = useAuthStore()
</script>

<template>
  <div class="flex flex-col h-full gap-6 animate-enter overflow-hidden pb-4">
    
    <!-- Top Header -->
    <div class="flex-none px-1">
      <div class="flex items-center gap-2 mb-1">
        <span class="px-2.5 py-0.5 rounded-full text-xs font-extrabold uppercase tracking-wider bg-[#143d2e] text-[#34d399]">
          Master Control
        </span>
      </div>
      <h2 class="text-3xl md:text-4xl font-extrabold text-black tracking-tight mb-1">Pengaturan Master</h2>
      <p class="text-gray-500 font-bold text-sm">Kelola profil Super Admin, keamanan akun, dan konfigurasi sistem jaringan SPBU.</p>
    </div>

    <!-- Main Content Area -->
    <div class="flex-1 overflow-y-auto space-y-6 pr-1">
      
      <!-- Profile Overview Card -->
      <ProfileCard />

      <!-- Master / Admin System Configuration Zone -->
      <div class="animate-enter" style="animation-delay: 100ms">
        <div class="px-1 mb-3 mt-8 flex items-center gap-2">
          <div class="w-2 h-2 rounded-full bg-[#34d399]"></div>
          <span class="text-xs font-extrabold text-[#143d2e] uppercase tracking-wider">
            Konfigurasi Jaringan SPBU (Global System Zone)
          </span>
        </div>
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <FuelPriceForm />
          <ShiftForm />
        </div>
      </div>

      <!-- Account Settings (Profile & Security) -->
      <div class="px-1 mb-2 mt-8 flex items-center gap-2">
        <div class="w-2 h-2 rounded-full bg-gray-400"></div>
        <span class="text-xs font-extrabold text-gray-500 uppercase tracking-wider">
          Pengaturan Akun & Keamanan
        </span>
      </div>
      
      <ProfileForm />
      <SecurityForm />

      <!-- Footer Note -->
      <p class="text-center text-xs text-gray-400 font-medium pt-8 pb-4">
        FuelGuard Master Console &copy; {{ new Date().getFullYear() }} Habi Jaya Group. All rights reserved.
      </p>

    </div>
  </div>
</template>
