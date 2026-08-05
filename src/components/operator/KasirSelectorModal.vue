<script setup>
import { ref, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { toast } from 'vue3-toastify'

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false
  },
  isIdle: {
    type: Boolean,
    default: false
  },
  canClose: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['select', 'close'])
const authStore = useAuthStore()

const searchQuery = ref('')

const activeKasirId = computed(() => authStore.activeKasirId)

const filteredKasirList = computed(() => {
  if (!searchQuery.value.trim()) return authStore.kasirList
  return authStore.kasirList.filter(k =>
    k.nama_operator.toLowerCase().includes(searchQuery.value.toLowerCase().trim())
  )
})

const activeKasir = computed(() => {
  return authStore.kasirList.find(k => k.id === authStore.activeKasirId)
})

const selectKasir = (kasir) => {
  authStore.setActiveKasir(kasir.id)
  toast.success(`Operator aktif: ${kasir.nama_operator}`)
  emit('select', kasir)
}
</script>

<template>
  <Teleport to="body">
    <div
      v-if="isOpen && authStore.user"
      class="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-black/60 backdrop-blur-md animate-fade-in"
    >
      <div
        class="bg-white rounded-3xl w-full max-w-md overflow-hidden shadow-2xl flex flex-col max-h-[85vh] animate-scale-up"
      >
        <!-- Signature Gradient & Glassmorphism Header -->
        <div class="p-6 bg-gradient-to-br from-[#143d2e] via-[#1b4d3a] to-[#256a50] text-white relative overflow-hidden">
          <!-- Glassmorphism Blur Circle -->
          <div class="absolute top-0 right-0 w-48 h-48 bg-white/10 rounded-full blur-3xl -translate-y-12 translate-x-12 pointer-events-none"></div>

          <div class="flex items-center justify-between relative z-10">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-2xl bg-white/15 backdrop-blur-md border border-white/20 flex items-center justify-center text-white shrink-0 shadow-inner">
                <svg v-if="isIdle" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
                </svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
                </svg>
              </div>
              <div>
                <h3 class="text-base font-black tracking-tight leading-tight">
                  {{ isIdle ? 'Aplikasi Terkunci' : 'Pilih Operator Bertugas' }}
                </h3>
                <p class="text-xs text-emerald-100/80 font-medium mt-0.5">
                  {{ isIdle ? 'Silakan konfirmasi operator' : 'Pilih identitas Anda' }}
                </p>
              </div>
            </div>

            <button
              v-if="canClose && !isIdle"
              @click="$emit('close')"
              class="text-white/80 hover:text-white bg-white/10 hover:bg-white/20 p-2 rounded-2xl transition-all cursor-pointer backdrop-blur-md border border-white/15 active:scale-95"
              title="Tutup"
            >
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>

        <!-- Body & Search -->
        <div class="p-5 flex-1 overflow-y-auto space-y-3.5">
          <!-- Glassmorphic Search Bar -->
          <div class="relative w-full">
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Cari operator..."
              class="w-full pl-10 pr-4 py-2.5 bg-gray-50/80 border border-gray-200/80 rounded-2xl text-xs font-bold text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] transition-all"
            />
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-gray-400 absolute left-3.5 top-3">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
            </svg>
          </div>

          <!-- Empty State -->
          <div v-if="filteredKasirList.length === 0" class="text-center py-6 text-gray-400">
            <p class="text-xs font-bold text-gray-500">Operator tidak ditemukan</p>
          </div>

          <!-- Minimalist List with Gradient Accent -->
          <div v-else class="space-y-2">
            <button
              v-for="kasir in filteredKasirList"
              :key="kasir.id"
              @click="selectKasir(kasir)"
              class="w-full flex items-center justify-between p-3 rounded-2xl border text-left transition-all active:scale-[0.99] cursor-pointer"
              :class="activeKasirId === kasir.id ? 'border-[#143d2e] bg-gradient-to-r from-emerald-50/90 to-green-50/50 shadow-xs' : 'border-gray-200/60 hover:border-emerald-300 bg-gray-50/40 hover:bg-white'"
            >
              <div class="flex items-center gap-3 min-w-0">
                <div
                  class="w-9 h-9 rounded-xl flex items-center justify-center text-xs font-black shrink-0 transition-all shadow-2xs"
                  :class="activeKasirId === kasir.id ? 'bg-gradient-to-br from-[#143d2e] to-[#1e5c45] text-white' : 'bg-gray-200 text-gray-700'"
                >
                  {{ kasir.nama_operator.charAt(0).toUpperCase() }}
                </div>
                <p class="text-xs font-bold text-gray-900 truncate uppercase tracking-tight">
                  {{ kasir.nama_operator }}
                </p>
              </div>

              <span
                v-if="activeKasirId === kasir.id"
                class="text-[10px] font-extrabold bg-[#143d2e] text-white px-2.5 py-1 rounded-lg uppercase tracking-wider shadow-2xs"
              >
                Aktif
              </span>
            </button>
          </div>
        </div>


      </div>
    </div>
  </Teleport>
</template>
