<script setup>
import { useAuthStore } from '@/stores/auth'
import ProfileCard from '@/components/settings/ProfileCard.vue'
import SecurityForm from '@/components/settings/SecurityForm.vue'
import FuelPriceForm from '@/components/settings/FuelPriceForm.vue'
import ProfileForm from '@/components/settings/ProfileForm.vue'
import ShiftForm from '@/components/settings/ShiftForm.vue'

const authStore = useAuthStore()
const isManager = authStore.role === 'manajer'
</script>

<template>
  <div class="flex flex-col h-full gap-6 animate-enter overflow-hidden pb-4">
    
    <div class="flex-none px-1">
      <h2 class="text-3xl font-extrabold text-black tracking-tight mb-1">Settings</h2>
      <p class="text-gray-500 text-sm">Kelola preferensi akun, sistem, dan keamanan.</p>
    </div>

    <div class="flex-1 overflow-y-auto space-y-6">
      
      <ProfileCard />

      <div v-if="isManager" class="animate-enter" style="animation-delay: 100ms">
        <div class="px-1 mb-2 mt-8">
          <span class="text-xs font-bold text-[#143d2e] bg-green-100 px-2 py-1 rounded uppercase tracking-wider">
            Admin Zone
          </span>
        </div>
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <FuelPriceForm />
          <ShiftForm /> </div>
      </div>

      <div class="px-1 mb-2 mt-6">
        <span class="text-xs font-bold text-gray-400 uppercase tracking-wider">General</span>
      </div>
      
      <ProfileForm />
      <SecurityForm />

      <p class="text-center text-xs text-gray-300 pt-8 pb-4">
        Habi Jaya Management System v2.1 &copy; {{ new Date().getFullYear() }}
      </p>

    </div>
  </div>
</template>