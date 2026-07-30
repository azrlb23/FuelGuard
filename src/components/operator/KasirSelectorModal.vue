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
      v-if="isOpen"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-md animate-fade-in"
    >
      <div
        class="bg-white rounded-3xl w-full max-w-lg overflow-hidden shadow-2xl border border-gray-100 flex flex-col max-h-[90vh] animate-scale-up"
      >
        <!-- Modal Header -->
        <div class="p-6 bg-gradient-to-r from-[#143d2e] to-[#1e5c45] text-white relative">
          <!-- Close button if canClose is true -->
          <button
            v-if="canClose && !isIdle"
            @click="$emit('close')"
            class="absolute top-4 right-4 text-white/70 hover:text-white bg-white/10 hover:bg-white/20 p-2 rounded-full transition-all cursor-pointer"
            title="Tutup"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>

          <div class="flex items-center gap-3">
            <div class="w-12 h-12 rounded-2xl bg-white/10 flex items-center justify-center text-white border border-white/20">
              <!-- SVG Icon for Lock / User (No Emoji) -->
              <svg v-if="isIdle" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6">
                <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
              </svg>
              <svg v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
              </svg>
            </div>
            <div>
              <h3 class="text-xl font-bold tracking-tight">
                {{ isIdle ? 'Aplikasi Terkunci (Idle)' : 'Pilih Operator Bertugas' }}
              </h3>
              <p class="text-xs text-green-100/80 mt-0.5">
                {{ isIdle ? 'Perangkat lama tidak disentuh. Konfirmasi operator yang bertugas.' : 'Pilih nama Anda sebelum memulai transaksi' }}
              </p>
            </div>
          </div>
        </div>

        <!-- Modal Body -->
        <div class="p-6 flex-1 overflow-y-auto space-y-4">
          <!-- Search Bar -->
          <div class="relative w-full">
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Cari nama operator..."
              class="w-full pl-10 pr-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-sm font-medium focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e]"
            />
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-gray-400 absolute left-3.5 top-3">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
            </svg>
          </div>

          <!-- Empty State (No Emojis, No Add Option) -->
          <div v-if="filteredKasirList.length === 0" class="text-center py-10 text-gray-400 space-y-2">
            <div class="w-12 h-12 mx-auto rounded-full bg-gray-100 flex items-center justify-center text-gray-400">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
              </svg>
            </div>
            <p class="text-xs font-medium text-gray-500">Tidak ada operator terdaftar.</p>
            <p class="text-[11px] text-gray-400">Penambahan operator hanya dapat dilakukan oleh Master melalui akun manajemen.</p>
          </div>

          <!-- Operator List Cards (No Dots) -->
          <div v-else class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <button
              v-for="kasir in filteredKasirList"
              :key="kasir.id"
              @click="selectKasir(kasir)"
              class="flex items-center gap-3 p-3.5 rounded-2xl border-2 text-left transition-all duration-200 active:scale-95 group relative cursor-pointer"
              :class="activeKasirId === kasir.id ? 'border-[#143d2e] bg-green-50/70 shadow-sm' : 'border-gray-100 hover:border-green-200 bg-gray-50/50 hover:bg-white'"
            >
              <!-- Avatar Initial -->
              <div
                class="w-10 h-10 rounded-xl flex items-center justify-center text-sm font-bold shadow-xs transition-transform group-hover:scale-105"
                :class="activeKasirId === kasir.id ? 'bg-[#143d2e] text-white' : 'bg-gray-200 text-gray-700 group-hover:bg-green-100 group-hover:text-[#143d2e]'"
              >
                {{ kasir.nama_operator.charAt(0).toUpperCase() }}
              </div>

              <!-- Operator Info (No Dots) -->
              <div class="flex-1 min-w-0">
                <p class="text-xs font-bold text-gray-900 truncate uppercase tracking-tight">
                  {{ kasir.nama_operator }}
                </p>
                <p class="text-[10px] font-medium text-[#143d2e] uppercase tracking-wider mt-0.5">
                  Kasir Bertugas
                </p>
              </div>

              <!-- Checkmark Icon if Selected -->
              <div v-if="activeKasirId === kasir.id" class="text-[#143d2e]">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="3" stroke="currentColor" class="w-5 h-5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                </svg>
              </div>
            </button>
          </div>
        </div>

        <!-- Modal Footer -->
        <div class="p-4 bg-gray-50 border-t border-gray-100 text-center flex justify-between items-center">
          <span class="text-[11px] font-bold text-gray-800 uppercase">
            {{ activeKasir?.nama_operator || 'Belum dipilih' }}
          </span>
          <button
            v-if="canClose && activeKasirId && !isIdle"
            @click="$emit('close')"
            class="px-4 py-1.5 bg-[#143d2e] hover:bg-[#1e5c45] text-white font-bold text-xs rounded-xl transition-all cursor-pointer"
          >
            Lanjutkan
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>
