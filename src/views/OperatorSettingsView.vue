<script setup>
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import ProfileCard from '@/components/settings/ProfileCard.vue'
import PreferenceForm from '@/components/settings/PreferenceForm.vue'

const router = useRouter()
const authStore = useAuthStore()

const goBack = () => {
  router.push('/operator') 
}
</script>

<template>
  <div class="flex flex-col gap-6 animate-enter pb-10">
    
    <!-- Top Back Button (Desktop Only) -->
    <div class="hidden sm:flex items-center gap-4 px-1">
      <button 
        @click="goBack" 
        aria-label="Kembali"
        class="w-11 h-11 flex items-center justify-center rounded-2xl bg-white hover:bg-gray-100 text-[#143d2e] transition-all border border-gray-200 shadow-xs cursor-pointer active:scale-95 shrink-0"
        title="Kembali ke Dashboard"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-5 h-5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
        </svg>
      </button>
    </div>

    <!-- Section 1: Profil Operator Header -->
    <div class="bg-gradient-to-br from-[#143d2e] to-[#1e5c45] rounded-3xl p-6 md:p-8 text-white shadow-xl shadow-green-900/10 relative overflow-hidden">
      <div class="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full blur-3xl -translate-y-20 translate-x-20 pointer-events-none"></div>
      <ProfileCard />
    </div>

    <!-- Section 2: Informasi SPBU & Tim Operator -->
    <div class="bg-white rounded-3xl border border-gray-100 shadow-xs p-6 md:p-8 space-y-6">
      <!-- Informasi SPBU & Sesi Bertugas -->
      <div>
        <h3 class="text-xs font-bold text-gray-400 uppercase tracking-widest mb-4">
          Informasi SPBU & Sesi Bertugas
        </h3>
        
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <!-- Lokasi SPBU -->
          <div class="p-4 bg-gray-50/70 rounded-2xl border border-gray-100 flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-gray-100 text-[#143d2e] flex items-center justify-center shrink-0">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
                </svg>
              </div>
              <div>
                <p class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Lokasi SPBU</p>
                <p class="text-sm font-bold text-gray-900">SPBU {{ authStore.spbuId }}</p>
              </div>
            </div>
            <span class="text-[10px] font-bold bg-gray-200/80 text-gray-700 px-2.5 py-1 rounded-md uppercase">Aktif</span>
          </div>

          <!-- Kasir Bertugas -->
          <div class="p-4 bg-gray-50/70 rounded-2xl border border-gray-100 flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-gray-100 text-[#143d2e] flex items-center justify-center shrink-0">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
                </svg>
              </div>
              <div>
                <p class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Kasir Bertugas</p>
                <p class="text-sm font-bold text-gray-900 uppercase">
                  {{ authStore.kasirList.find(k => k.id === authStore.activeKasirId)?.nama_operator || 'Belum Dipilih' }}
                </p>
              </div>
            </div>
            <span class="text-[10px] font-extrabold bg-gradient-to-r from-[#143d2e] to-[#1e5c45] text-white px-2.5 py-1 rounded-lg uppercase shadow-2xs">Bertugas</span>
          </div>
        </div>
      </div>

      <!-- Tim Operator Terdaftar (Clean Minimalist List - No Subtitle) -->
      <div class="border-t border-gray-100 pt-5">
        <div class="flex items-center justify-between mb-3">
          <h3 class="text-xs font-bold text-gray-400 uppercase tracking-widest">
            Tim Operator Terdaftar
          </h3>
          <span class="text-xs font-bold text-gray-600 bg-gray-100 px-2 py-0.5 rounded-md">
            {{ authStore.kasirList.length }} Orang
          </span>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-2.5">
          <div
            v-for="op in authStore.kasirList"
            :key="op.id"
            class="flex items-center gap-3 p-2.5 rounded-xl bg-gray-50/60 border border-gray-100"
          >
            <div class="w-8 h-8 rounded-lg bg-gray-200 text-gray-700 flex items-center justify-center font-bold text-xs shrink-0">
              {{ (op.nama_operator || 'O')[0].toUpperCase() }}
            </div>
            <div class="min-w-0">
              <p class="text-xs font-bold text-gray-800 truncate">{{ op.nama_operator }}</p>
              <p class="text-[10px] text-gray-400 font-medium">Operator SPBU</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Card 2: Pengaturan Notifikasi & Audio -->
    <div class="bg-white rounded-3xl border border-gray-100 shadow-xs p-6 md:p-8">
      <h3 class="text-xs font-bold text-gray-400 uppercase tracking-widest mb-6">
        Preferensi Notifikasi & Audio
      </h3>
      <PreferenceForm />
    </div>

  </div>
</template>