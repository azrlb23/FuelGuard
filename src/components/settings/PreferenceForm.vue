<script setup>
import { useAudioAlert } from '@/composables/useAudioAlert'
import { toast } from 'vue3-toastify'

const {
  isAudioEnabled,
  isSuccessSoundEnabled,
  isWarningSoundEnabled,
  playSuccessSound,
  playWarningSound,
  toggleMasterAudio,
  toggleSuccessSound,
  toggleWarningSound
} = useAudioAlert()

const handleMasterToggle = () => {
  toggleMasterAudio(isAudioEnabled.value)
  if (isAudioEnabled.value) {
    toast.success("Suara Notifikasi: AKTIF")
    playSuccessSound()
  } else {
    toast.info("Suara Notifikasi: DILAPISKAN (MUTE)")
  }
}

const handleSuccessToggle = () => {
  toggleSuccessSound(isSuccessSoundEnabled.value)
  if (isSuccessSoundEnabled.value) playSuccessSound()
}

const handleWarningToggle = () => {
  toggleWarningSound(isWarningSoundEnabled.value)
  if (isWarningSoundEnabled.value) playWarningSound()
}
</script>

<template>
  <div class="space-y-3 md:space-y-4">
    
    <!-- 1. Master Audio Switch -->
    <div class="flex items-center justify-between p-3 md:p-4 bg-gray-50/80 rounded-2xl border border-gray-100 gap-3">
      <div class="flex items-center gap-3 min-w-0">
        <div class="w-9 h-9 md:w-10 md:h-10 rounded-xl bg-[#143d2e]/10 text-[#143d2e] flex items-center justify-center shrink-0">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M19.114 5.636a9 9 0 010 12.728M16.463 8.287a6 6 0 010 7.427M12 6.75l-4.5 3.375H3v3.75h4.5L12 17.25V6.75z" />
          </svg>
        </div>
        <div class="min-w-0">
          <h3 class="font-bold text-gray-900 text-xs md:text-sm truncate">Efek Suara Notifikasi System</h3>
          <p class="text-[11px] md:text-xs text-gray-500 line-clamp-1">Aktifkan umpan balik suara saat transaksi diproses.</p>
        </div>
      </div>

      <input 
        type="checkbox" 
        v-model="isAudioEnabled" 
        class="toggle toggle-success shrink-0 cursor-pointer" 
        @change="handleMasterToggle"
      />
    </div>

    <!-- Sub-options Audio (Hanya tampil jika Master Audio Aktif) -->
    <div v-if="isAudioEnabled" class="space-y-3 animate-fade-in pl-1 sm:pl-3 border-l-2 border-[#143d2e]/20 ml-2 sm:ml-4">
      
      <!-- Suara Peringatan Pengetap / Kuota Habis -->
      <div class="flex items-center justify-between p-3 bg-white rounded-xl border border-gray-100 shadow-2xs gap-2">
        <div class="flex items-center gap-2.5 min-w-0">
          <div class="w-8 h-8 rounded-lg bg-emerald-50 text-[#143d2e] flex items-center justify-center shrink-0">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
            </svg>
          </div>
          <div class="min-w-0">
            <h4 class="font-bold text-xs text-gray-800 truncate">Suara Alert Pengetap & Kuota Habis</h4>
            <p class="text-[10px] md:text-[11px] text-gray-400 line-clamp-1">Bunyi nada peringatan saat transaksi ditolak.</p>
          </div>
        </div>

        <div class="flex items-center gap-2 shrink-0">
          <button 
            @click="playWarningSound" 
            class="px-2 py-1 rounded-md bg-gray-100 hover:bg-gray-200 text-gray-700 text-[10px] font-bold transition-colors cursor-pointer whitespace-nowrap"
            title="Tes Suara Warning"
          >
            Tes
          </button>
          <input 
            type="checkbox" 
            v-model="isWarningSoundEnabled" 
            class="toggle toggle-sm toggle-success cursor-pointer" 
            @change="handleWarningToggle"
          />
        </div>
      </div>

      <!-- Suara Konfirmasi Sukses -->
      <div class="flex items-center justify-between p-3 bg-white rounded-xl border border-gray-100 shadow-2xs gap-2">
        <div class="flex items-center gap-2.5 min-w-0">
          <div class="w-8 h-8 rounded-lg bg-emerald-50 text-[#143d2e] flex items-center justify-center shrink-0">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div class="min-w-0">
            <h4 class="font-bold text-xs text-gray-800 truncate">Suara Transaksi Berhasil</h4>
            <p class="text-[10px] md:text-[11px] text-gray-400 line-clamp-1">Bunyi nada konfirmasi saat transaksi sukses dicatat.</p>
          </div>
        </div>

        <div class="flex items-center gap-2 shrink-0">
          <button 
            @click="playSuccessSound" 
            class="px-2 py-1 rounded-md bg-gray-100 hover:bg-gray-200 text-gray-700 text-[10px] font-bold transition-colors cursor-pointer whitespace-nowrap"
            title="Tes Suara Sukses"
          >
            Tes
          </button>
          <input 
            type="checkbox" 
            v-model="isSuccessSoundEnabled" 
            class="toggle toggle-sm toggle-success cursor-pointer" 
            @change="handleSuccessToggle"
          />
        </div>
      </div>

    </div>

  </div>
</template>