<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const showModal = ref(false)
const isMigrating = ref(false)

const TARGET_DOMAIN = 'fuelguard.id'
const TARGET_URL = 'https://fuelguard.id/login'

onMounted(() => {
  if (typeof window === 'undefined') return

  const hostname = window.location.hostname.toLowerCase()

  if (hostname !== TARGET_DOMAIN && hostname !== `www.${TARGET_DOMAIN}`) {
    showModal.value = true
  }
})

const handleMigration = async () => {
  if (isMigrating.value) return
  isMigrating.value = true

  try {
    await authStore.logout()
  } catch (err) {
    console.warn('[DomainMigrationModal] Error resetting auth state:', err)
  } finally {
    try {
      localStorage.clear()
    } catch (e) {}

    try {
      sessionStorage.clear()
    } catch (e) {}

    try {
      if ('serviceWorker' in navigator) {
        const registrations = await navigator.serviceWorker.getRegistrations()
        for (const registration of registrations) {
          await registration.unregister()
        }
      }
      if ('caches' in window) {
        const cacheKeys = await caches.keys()
        await Promise.all(cacheKeys.map(key => caches.delete(key)))
      }
    } catch (e) {
      console.warn('[DomainMigrationModal] Error clearing SW caches:', e)
    }

    window.location.href = TARGET_URL
  }
}
</script>

<template>
  <Teleport to="body">
    <Transition name="modal-fade">
      <div
        v-if="showModal"
        class="fixed inset-0 z-[99999] bg-slate-900/60 backdrop-blur-md flex items-center justify-center p-4 sm:p-6"
        role="dialog"
        aria-modal="true"
        aria-labelledby="migration-modal-title"
      >
        <Transition name="modal-slide">
          <div
            v-if="showModal"
            class="bg-white rounded-3xl w-full max-w-md overflow-hidden shadow-2xl flex flex-col relative"
          >
            <!-- Header Ringkas Tanpa Border -->
            <div class="p-6 bg-gradient-to-br from-[#143d2e] via-[#1b4d3a] to-[#256a50] text-white relative overflow-hidden">
              <div class="absolute top-0 right-0 w-48 h-48 bg-white/10 rounded-full blur-3xl -translate-y-12 translate-x-12 pointer-events-none"></div>

              <div class="flex items-center gap-3.5 relative z-10">
                <div class="w-11 h-11 rounded-2xl bg-white/15 backdrop-blur-md flex items-center justify-center p-2.5 shrink-0 shadow-inner">
                  <img src="@/assets/fuelguard_logo.png" alt="FuelGuard Logo" class="w-full h-full object-contain brightness-0 invert" />
                </div>
                <h3 id="migration-modal-title" class="text-lg font-black tracking-tight leading-tight text-white">
                  Pemindahan Domain
                </h3>
              </div>
            </div>

            <!-- Body Ringkas & Minimalis -->
            <div class="p-6 space-y-4 text-left">
              <p class="text-sm text-gray-700 leading-relaxed font-semibold">
                FuelGuard telah berpindah ke domain <strong class="text-[#143d2e] font-extrabold underline underline-offset-4 decoration-emerald-500">fuelguard.id</strong>. Seluruh sesi lama Anda akan dibersihkan dan dialihkan ke halaman login baru.
              </p>

              <button
                @click="handleMigration"
                :disabled="isMigrating"
                class="w-full py-3.5 px-5 rounded-2xl bg-[#143d2e] hover:bg-[#1b4d3a] text-white font-extrabold text-sm shadow-lg shadow-emerald-950/20 transition-all duration-200 active:scale-95 flex items-center justify-center cursor-pointer disabled:opacity-60 disabled:cursor-not-allowed mt-2"
              >
                <template v-if="!isMigrating">
                  <span>Pindah</span>
                </template>
                <template v-else>
                  <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  <span>Mengarahkan...</span>
                </template>
              </button>
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.2s ease;
}
.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

.modal-slide-enter-active {
  transition: opacity 0.25s ease, transform 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}
.modal-slide-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}
.modal-slide-enter-from {
  opacity: 0;
  transform: scale(0.96) translateY(10px);
}
.modal-slide-leave-to {
  opacity: 0;
  transform: scale(0.98) translateY(6px);
}
</style>
