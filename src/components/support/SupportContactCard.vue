<script setup>
import { useAuthStore } from '@/stores/auth'
import { computed } from 'vue'

const authStore = useAuthStore()
const userEmail = computed(() => authStore.user?.email || 'User')
</script>

<template>
  <div class="bg-gradient-to-br from-[#143d2e] to-[#1e5c45] rounded-[2rem] p-8 text-white shadow-xl shadow-green-900/20 relative overflow-hidden">
    <div class="absolute top-0 right-0 w-40 h-40 bg-white/10 rounded-full blur-3xl -translate-y-10 translate-x-10 pointer-events-none"></div>
    
    <h3 class="text-xl font-bold mb-4 flex items-center gap-2 relative z-10">
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
        <path stroke-linecap="round" stroke-linejoin="round" d="M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z" />
      </svg>
      Kontak Darurat
    </h3>
    
    <div class="space-y-6 text-green-50 text-sm leading-relaxed relative z-10">
      <p>
        Untuk kendala kritis yang menyebabkan operasional SPBU berhenti total, silakan hubungi langsung via WhatsApp.
      </p>
      
      <div class="bg-white/10 rounded-xl p-4 border border-white/10 backdrop-blur-sm transition-transform hover:scale-105 duration-300">
        <p class="text-[10px] font-bold uppercase tracking-widest text-green-300 mb-1">Developer</p>
        <p class="text-lg font-bold text-white">Azriel</p>
        <div class="flex items-center gap-2 mt-2 opacity-90">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-4 h-4 text-green-400">
            <path fill-rule="evenodd" d="M1.5 4.5a3 3 0 013-3h1.372c.86 0 1.61.586 1.819 1.42l1.105 4.423a1.875 1.875 0 01-.694 1.955l-1.293.97c-.135.101-.164.249-.126.352a11.285 11.285 0 006.697 6.697c.103.038.25.009.352-.126l.97-1.293a1.875 1.875 0 011.955-.694l4.423 1.105c.834.209 1.42.959 1.42 1.82V19.5a3 3 0 01-3 3h-2.25C8.552 22.5 1.5 15.448 1.5 5.25V4.5z" clip-rule="evenodd" />
          </svg>
          <span class="font-mono text-white">+62 898-1708-857</span>
        </div>
      </div>

      <div class="pt-4 border-t border-white/10">
        <p class="text-xs opacity-70 mb-2">Logged in as:</p>
        <div class="flex items-center gap-2">
          <p class="font-bold truncate text-white">{{ userEmail }}</p>
        </div>
      </div>
    </div>
  </div>
</template>