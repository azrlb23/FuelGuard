<script setup>
import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

const displayName = computed(() => {
  return authStore.user?.user_metadata?.full_name || authStore.user?.email?.split('@')[0] || 'Operator'
})

const email = computed(() => authStore.user?.email || '-')
const role = computed(() => authStore.role || 'operator')

const activeKasir = computed(() => {
  return authStore.kasirList.find(k => k.id === authStore.activeKasirId)
})

const spbuId = computed(() => authStore.spbuId || '-')
</script>

<template>
  <div class="flex items-center gap-3.5 w-full">
    <!-- User Info & Avatar -->
    <div class="w-12 h-12 rounded-full bg-white/20 border border-white/30 flex items-center justify-center text-xl font-black text-white shrink-0 shadow-inner">
      {{ displayName.charAt(0).toUpperCase() }}
    </div>
    
    <div>
      <div class="flex items-center gap-2">
        <h2 class="text-base md:text-lg font-bold text-white leading-tight tracking-tight">{{ displayName }}</h2>
        <span class="px-2 py-0.5 rounded text-[9px] font-bold bg-white/15 text-white uppercase border border-white/10">
          {{ role }}
        </span>
      </div>
      <p class="text-green-100/70 text-xs font-medium mt-0.5">{{ email }}</p>
    </div>
  </div>
</template>