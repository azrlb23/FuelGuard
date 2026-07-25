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
  <div class="flex flex-col h-full bg-[#f5f5f5]">
    
    <div class="flex-none px-6 py-5 bg-white border-b border-gray-100 flex items-center gap-4 sticky top-0 z-10">
      <button 
        @click="goBack" 
        class="p-2 -ml-2 rounded-full hover:bg-gray-100 text-gray-600 transition-colors"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-6 h-6">
          <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
        </svg>
      </button>
      <div>
        <h1 class="text-xl font-bold text-gray-900 leading-none">Pengaturan</h1>
        <p class="text-xs text-gray-400 mt-1">Konfigurasi akun & alat kerja</p>
      </div>
    </div>

    <div class="flex-1 overflow-y-auto p-6 space-y-6">
      
      <section>
        <ProfileCard />
      </section>

      <section>
        <div class="mb-3 px-1">
          <h4 class="text-xs font-bold text-gray-400 uppercase tracking-widest">Metode Input</h4>
        </div>
        <PreferenceForm />
      </section>

      <div class="text-center pt-8 pb-4 opacity-50">
        <p class="text-[10px] uppercase font-bold text-gray-400">Habi Jaya System v2.5</p>
      </div>

    </div>
  </div>
</template>