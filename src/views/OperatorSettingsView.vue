<script setup>
import { useRouter } from 'vue-router'
import ProfileCard from '@/components/settings/ProfileCard.vue'
import PreferenceForm from '@/components/settings/PreferenceForm.vue'

const router = useRouter()

const goBack = () => {
  router.push('/operator') 
}
</script>

<template>
  <div class="flex flex-col h-full bg-[#f5f5f5] p-6 overflow-y-auto">
    <!-- Single Unified Card (Termasuk Tombol Kembali) -->
    <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
      
      <!-- Profile Header Section & Back Button -->
      <div class="bg-[#143d2e] p-6 text-white relative overflow-hidden">
        <div class="absolute top-0 right-0 w-32 h-32 bg-white/5 rounded-full -translate-y-1/2 translate-x-1/2 blur-2xl"></div>

        <!-- Button Kembali (Icon Only) -->
        <button 
          @click="goBack" 
          aria-label="Kembali"
          class="w-9 h-9 flex items-center justify-center rounded-full bg-white/10 hover:bg-white/20 text-white transition-colors mb-5 backdrop-blur-sm border border-white/10 relative z-10"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-5 h-5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
          </svg>
        </button>

        <div class="flex items-center gap-4 relative z-10">
          <ProfileCard />
        </div>
      </div>

      <!-- Preferences / Settings Section inside the same Card -->
      <div class="p-6">
        <h4 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-4">Pengaturan Operasional</h4>
        <PreferenceForm />
      </div>

    </div>

    <div class="text-center pt-8 pb-4 opacity-50">
      <p class="text-[10px] uppercase font-bold text-gray-400">Habi Jaya System v2.5</p>
    </div>
  </div>
</template>