<script setup>
import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const displayName = computed(() => {
  return authStore.user?.user_metadata?.full_name || authStore.user?.email?.split('@')[0] || 'Operator'
})
const email = computed(() => authStore.user?.email || '-')
const role = computed(() => authStore.role || 'Staff')
</script>

<template>
  <div class="bg-[#143d2e] rounded-2xl p-6 text-white shadow-lg relative overflow-hidden">
    <div class="absolute top-0 right-0 w-32 h-32 bg-white/5 rounded-full -translate-y-1/2 translate-x-1/2 blur-2xl"></div>

    <div class="flex items-center gap-5 relative z-10">
      <div class="w-16 h-16 rounded-full bg-white/20 border-2 border-white/30 flex items-center justify-center text-2xl font-bold backdrop-blur-sm">
        {{ displayName.charAt(0).toUpperCase() }}
      </div>
      
      <div>
        <h2 class="text-xl font-bold leading-tight">{{ displayName }}</h2>
        <p class="text-green-200/80 text-sm font-medium mb-2">{{ email }}</p>
        <span class="px-2.5 py-1 rounded-lg bg-black/20 text-xs font-bold uppercase tracking-wider border border-white/10">
          {{ role }}
        </span>
      </div>
    </div>
  </div>
</template>