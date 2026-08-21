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

  // Muncul jika diakses dari domain selain fuelguard.id atau www.fuelguard.id
  if (hostname !== TARGET_DOMAIN && hostname !== `www.${TARGET_DOMAIN}`) {
    showModal.value = true
  }
})

const handleMigration = async () => {
  if (isMigrating.value) return
  isMigrating.value = true

  try {
    // 1. Sign out dari Supabase & Reset state store Pinia
    await authStore.logout()
  } catch (err) {
    console.warn('[DomainMigrationModal] Error resetting auth state:', err)
  } finally {
    // 2. Membersihkan Storage Lokal
    try {
      localStorage.clear()
    } catch (e) {}

    try {
      sessionStorage.clear()
    } catch (e) {}

    // 3. Membersihkan PWA Service Workers & Cache Storage jika ada
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

    // 4. Redirect ke Halaman Login Domain Baru
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
            class="bg-white rounded-3xl w-full max-w-md overflow-hidden shadow-2xl flex flex-col relative border border-gray-100"
          >
            <!-- Signature FuelGuard Emerald Header -->
            <div class="p-6 bg-gradient-to-br from-[#143d2e] via-[#1b4d3a] to-[#256a50] text-white relative overflow-hidden">
              <div class="absolute top-0 right-0 w-48 h-48 bg-white/10 rounded-full blur-3xl -translate-y-12 translate-x-12 pointer-events-none"></div>

              <div class="flex items-center gap-3.5 relative z-10">
                <div class="w-12 h-12 rounded-2xl bg-white/15 backdrop-blur-md border border-white/20 flex items-center justify-center p-2.5 shrink-0 shadow-inner">
                  <img src="@/assets/fuelguard_logo.png" alt="FuelGuard Logo" class="w-full h-full object-contain brightness-0 invert" />
                </div>
                <div>
                  <span class="text-[10px] font-bold text-green-300 uppercase tracking-widest block">Pengumuman Resmi</span>
                  <h3 id="migration-modal-title" class="text-lg font-black tracking-tight leading-tight text-white">
                    Pemindahan Domain
                  </h3>
                </div>
              </div>
            </div>

            <!-- Body Content -->
            <div class="p-6 space-y-4 text-left">
              <div>
                <p class="text-sm font-semibold text-gray-800 leading-relaxed">
                  FuelGuard kini secara resmi telah berpindah alamat domain ke:
                </p>
                <div class="mt-2.5 p-3.5 rounded-2xl bg-emerald-50/80 border border-emerald-200/80 flex items-center justify-between">
                  <span class="text-xs font-bold uppercase tracking-wider text-emerald-800">Domain Baru:</span>
                  <span class="font-extrabold text-base text-[#143d2e] tracking-tight">fuelguard.id</span>
                </div>
              </div>

              <div class="p-4 rounded-2xl bg-gray-50 border border-gray-100 space-y-1.5">
                <div class="flex items-center gap-2 text-xs font-bold text-gray-900">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-amber-500 shrink-0">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
                  </svg>
                  <span>Informasi Pembersihan Sesi</span>
                </div>
                <p class="text-xs text-gray-600 leading-relaxed">
                  Demi keamanan data, seluruh sesi lokal pada domain lama akan dibersihkan. Anda akan diarahkan ke halaman login domain baru.
                </p>
              </div>

              <button
                @click="handleMigration"
                :disabled="isMigrating"
                class="w-full py-4 px-5 rounded-2xl bg-[#143d2e] hover:bg-[#1b4d3a] text-white font-extrabold text-sm shadow-lg shadow-emerald-950/20 transition-all duration-200 active:scale-95 flex items-center justify-center gap-2 cursor-pointer disabled:opacity-60 disabled:cursor-not-allowed mt-2"
              >
                <template v-if="!isMigrating">
                  <span>Pindah ke fuelguard.id Sekarang</span>
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                  </svg>
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
