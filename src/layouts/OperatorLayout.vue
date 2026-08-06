<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useRouter, useRoute } from 'vue-router'
import KasirSelectorModal from '@/components/operator/KasirSelectorModal.vue'
import { useIdleTimeout } from '@/composables/common/useIdleTimeout'

const authStore = useAuthStore()
const router = useRouter()
const route = useRoute()

const isLoggingOut = ref(false)
const showKasirModal = ref(false)

// Idle Timeout: 3 Menit (180.000 ms)
const { isIdle, resetTimer } = useIdleTimeout(3 * 60 * 1000, () => {
  if (authStore.user && !isLoggingOut.value) {
    showKasirModal.value = true
  }
})

const activeKasir = computed(() => {
  return authStore.kasirList.find(k => k.id === authStore.activeKasirId)
})

const activeKasirName = computed(() => {
  return activeKasir.value?.nama_operator || 'Pilih Kasir'
})

const handleSelectKasir = (kasir) => {
  showKasirModal.value = false
  resetTimer()
}

const handleLogout = async () => {
  isLoggingOut.value = true
  showKasirModal.value = false
  await authStore.logout()
}

onMounted(async () => {
  if (!authStore.isInitialized) {
    await authStore.initialize()
  }
  if (authStore.user && !authStore.activeKasirId && !isLoggingOut.value) {
    showKasirModal.value = true
  }
})

watch(() => authStore.activeKasirId, (newVal) => {
  if (!newVal && authStore.user && !isLoggingOut.value) {
    showKasirModal.value = true
  }
})
</script>

<template>
  <div class="h-screen h-[100dvh] w-full bg-[#f5f5f5] font-sans text-gray-800 flex flex-col overflow-hidden relative">

    <!-- Header (Navbar Top Solid Rectangular) -->
    <header class="w-full bg-white border-b border-gray-200 px-4 sm:px-6 h-16 flex items-center justify-between shadow-xs z-40 flex-none">
      <!-- Brand Logo & Title -->
      <div class="flex items-center gap-3 select-none">
        <div class="w-10 h-10 rounded-2xl bg-gradient-to-br from-[#143d2e] via-[#1b4d3a] to-[#256a50] flex items-center justify-center p-2 shadow-md shadow-emerald-950/20 border border-white/10">
          <img src="@/assets/fuelguard_logo.png" alt="FuelGuard Logo" class="w-full h-full object-contain brightness-0 invert" />
        </div>
        <div>
          <h1 class="font-black text-lg tracking-tight text-[#143d2e] leading-none">FuelGuard</h1>
          <p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mt-0.5">Operator Console</p>
        </div>
      </div>

      <!-- Action Controls -->
      <div class="flex items-center gap-2 sm:gap-3">

        <!-- Kasir Display Pill (Ultra-Minimalist Glass) -->
        <button @click="showKasirModal = true" class="flex items-center gap-2 px-2 sm:px-3 py-1.5 rounded-full bg-gray-100/80 hover:bg-gray-200/80 border border-gray-200/60 text-gray-800 text-xs cursor-pointer active:scale-95 transition-all" title="Ganti Operator (Switch User)">
          <div class="w-6 h-6 rounded-full bg-gradient-to-br from-[#143d2e] to-[#1e5c45] text-white flex items-center justify-center font-bold text-[10px] shadow-2xs">
            {{ activeKasirName.charAt(0).toUpperCase() }}
          </div>
          <span class="font-bold text-gray-800 uppercase tracking-tight text-[10px] sm:text-xs truncate max-w-[80px] sm:max-w-[150px]">
            {{ activeKasirName }}
          </span>
        </button>

        <!-- Desktop Only Buttons -->
        <div class="hidden md:flex items-center gap-3">
          <div class="h-6 w-px bg-gray-200/80 mx-0.5"></div>

          <!-- Aktivitas & Audit Button -->
          <router-link
            to="/operator/history"
            class="w-9 h-9 flex items-center justify-center text-gray-600 hover:text-[#143d2e] hover:bg-gray-100/80 rounded-full transition-all active:scale-95 border border-transparent hover:border-gray-200"
            title="Riwayat & Audit Pengetap Hari Ini"
            active-class="bg-[#143d2e]/10 text-[#143d2e] border-gray-200 shadow-2xs"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 6.75h12M8.25 12h12m-12 5.25h12M3.75 6.75h.008v.008H3.75V6.75Zm0 5.25h.008v.008H3.75V12Zm0 5.25h.008v.008H3.75v-.008Z" />
            </svg>
          </router-link>

          <!-- Settings Button -->
          <router-link
            to="/operator/settings"
            class="w-9 h-9 flex items-center justify-center text-gray-500 hover:text-[#143d2e] hover:bg-gray-100/80 rounded-full transition-all active:scale-95 border border-transparent hover:border-gray-200"
            title="Pengaturan"
            active-class="bg-[#143d2e]/10 text-[#143d2e] border-green-200"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z" />
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          </router-link>

          <!-- Logout Button -->
          <button
            @click="handleLogout"
            class="w-9 h-9 flex items-center justify-center text-red-500 hover:bg-red-50 rounded-full transition-all active:scale-95 cursor-pointer border border-transparent hover:border-red-100"
            title="Keluar Sesi"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9" />
            </svg>
          </button>
        </div>
      </div>
    </header>

    <!-- Main View Content Area -->
    <main class="flex-1 w-full max-w-7xl mx-auto p-4 md:p-8 flex flex-col overflow-y-auto relative hide-scrollbar pb-24 md:pb-8">
      <slot></slot>
    </main>

    <!-- Bottom Navigation Bar (Fixed on Mobile) -->
    <nav class="md:hidden fixed bottom-0 left-0 right-0 w-full bg-white border-t border-gray-200 flex justify-around items-center shadow-[0_-4px_10px_rgba(0,0,0,0.08)] z-50" style="padding-bottom: max(0.5rem, env(safe-area-inset-bottom, 0px));">

      <!-- Input Transaksi -->
      <router-link
        to="/operator"
        class="flex-1 flex flex-col items-center justify-center py-2.5 text-gray-500 active:bg-gray-50 transition-colors"
        active-class="text-[#143d2e]"
        exact
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6 mb-1 transition-transform" :class="{'scale-110': $route.path === '/operator'}">
          <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6A2.25 2.25 0 016 3.75h2.25A2.25 2.25 0 0110.5 6v2.25a2.25 2.25 0 01-2.25 2.25H6a2.25 2.25 0 01-2.25-2.25V6zM3.75 15.75A2.25 2.25 0 016 13.5h2.25a2.25 2.25 0 012.25 2.25V18a2.25 2.25 0 01-2.25 2.25H6A2.25 2.25 0 013.75 18v-2.25zM13.5 6a2.25 2.25 0 012.25-2.25H18A2.25 2.25 0 0120.25 6v2.25A2.25 2.25 0 0118 10.5h-2.25a2.25 2.25 0 01-2.25-2.25V6zM13.5 15.75a2.25 2.25 0 012.25-2.25H18a2.25 2.25 0 012.25 2.25V18A2.25 2.25 0 0118 20.25h-2.25A2.25 2.25 0 0113.5 18v-2.25z" />
        </svg>
        <span class="text-[10px] font-bold">Input</span>
      </router-link>

      <!-- Riwayat -->
      <router-link
        to="/operator/history"
        class="flex-1 flex flex-col items-center justify-center py-2.5 text-gray-500 active:bg-gray-50 transition-colors"
        active-class="text-[#143d2e]"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6 mb-1 transition-transform" :class="{'scale-110': $route.path === '/operator/history'}">
          <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 6.75h12M8.25 12h12m-12 5.25h12M3.75 6.75h.008v.008H3.75V6.75Zm0 5.25h.008v.008H3.75V12Zm0 5.25h.008v.008H3.75v-.008Z" />
        </svg>
        <span class="text-[10px] font-bold">Riwayat</span>
      </router-link>

      <!-- Pengaturan -->
      <router-link
        to="/operator/settings"
        class="flex-1 flex flex-col items-center justify-center py-2.5 text-gray-500 active:bg-gray-50 transition-colors"
        active-class="text-[#143d2e]"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6 mb-1 transition-transform" :class="{'scale-110': $route.path === '/operator/settings'}">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z" />
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
        <span class="text-[10px] font-bold">Pengaturan</span>
      </router-link>

      <!-- Logout -->
      <button
        @click="handleLogout"
        class="flex-1 flex flex-col items-center justify-center py-2.5 text-red-400 active:bg-red-50 transition-colors"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6 mb-1">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9" />
        </svg>
        <span class="text-[10px] font-bold">Keluar</span>
      </button>

    </nav>

    <!-- Footer -->
    <footer class="flex-none text-center py-4 text-xs text-gray-400 bg-[#f5f5f5] hidden md:block">
      &copy; 2026 FuelGuard
    </footer>

    <!-- Modal Popup Pemilihan Operator & Lockscreen Idle -->
    <KasirSelectorModal
      :is-open="showKasirModal"
      :is-idle="isIdle"
      :can-close="!!authStore.activeKasirId"
      @select="handleSelectKasir"
      @close="showKasirModal = false"
    />
  </div>
</template>
