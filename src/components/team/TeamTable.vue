<script setup>
import { ref } from 'vue'

const props = defineProps({
  members: {
    type: Array,
    default: () => []
  },
  accounts: {
    type: Array,
    default: () => []
  },
  spbuList: {
    type: Array,
    default: () => []
  },
  loading: Boolean,
  isSubmitting: Boolean,
  searchQuery: String,
  selectedSpbuId: String
})

const emit = defineEmits([
  'update:searchQuery',
  'update:selectedSpbuId',
  'createOperator',
  'updateOperator',
  'toggleStatus'
])

// Tab State
const activeTab = ref('operators') // 'operators' | 'accounts'

// Modal State
const isModalOpen = ref(false)
const isResetModalOpen = ref(false)
const modalMode = ref('create') // 'create' | 'edit'
const selectedAccount = ref(null)

const formData = ref({
  id: null,
  nama_operator: '',
  spbu_id: '',
  is_active: true
})

// Reset Password State
const resetForm = ref({
  temporaryPassword: '',
  copied: false
})

const openCreateModal = () => {
  modalMode.value = 'create'
  formData.value = {
    id: null,
    nama_operator: '',
    spbu_id: props.spbuList.length > 0 ? props.spbuList[0].id : '',
    is_active: true
  }
  isModalOpen.value = true
}

const openEditModal = (member) => {
  modalMode.value = 'edit'
  formData.value = {
    id: member.id,
    nama_operator: member.nama_operator,
    spbu_id: member.spbu_id,
    is_active: member.is_active
  }
  isModalOpen.value = true
}

const openResetModal = (account) => {
  selectedAccount.value = account
  resetForm.value = {
    temporaryPassword: `Pertamina#${Math.floor(1000 + Math.random() * 9000)}`,
    copied: false
  }
  isResetModalOpen.value = true
}

const handleSubmit = () => {
  if (!formData.value.nama_operator.trim()) return
  if (modalMode.value === 'create') {
    emit('createOperator', { ...formData.value })
  } else {
    emit('updateOperator', formData.value.id, { ...formData.value })
  }
  isModalOpen.value = false
}

const copyTempPassword = () => {
  navigator.clipboard.writeText(resetForm.value.temporaryPassword)
  resetForm.value.copied = true
  setTimeout(() => {
    resetForm.value.copied = false
  }, 2000)
}

const formatDate = (dateString) => {
  if (!dateString) return '-'
  const d = new Date(dateString)
  if (isNaN(d.getTime())) return dateString
  return d.toLocaleDateString('id-ID', {
    day: '2-digit', month: 'short', year: 'numeric'
  })
}
</script>

<template>
  <div class="w-full space-y-4">
    
    <!-- Top Bar: Navigation Tabs & Search/Filters -->
    <div class="bg-white rounded-3xl p-4 md:p-6 border border-gray-200 shadow-sm flex flex-col gap-4">
      
      <!-- Section Tabs -->
      <div class="flex items-center justify-between border-b border-gray-100 pb-3 gap-2 overflow-x-auto">
        <div class="flex items-center gap-2">
          <button
            @click="activeTab = 'operators'"
            class="px-5 py-2.5 rounded-2xl text-xs font-black transition-all cursor-pointer flex items-center gap-2 shrink-0"
            :class="activeTab === 'operators' ? 'bg-[#143d2e] text-white shadow-md shadow-green-900/10' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z" />
            </svg>
            <span>Profil Operator Shift ({{ members.length }})</span>
          </button>

          <button
            @click="activeTab = 'accounts'"
            class="px-5 py-2.5 rounded-2xl text-xs font-black transition-all cursor-pointer flex items-center gap-2 shrink-0"
            :class="activeTab === 'accounts' ? 'bg-[#143d2e] text-white shadow-md shadow-green-900/10' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z" />
            </svg>
            <span>Akun Login SPBU ({{ accounts.length }})</span>
          </button>
        </div>

        <!-- Action: Tambah Operator Button (Only for Operator Profiles tab) -->
        <button
          v-if="activeTab === 'operators'"
          @click="openCreateModal"
          class="inline-flex items-center justify-center gap-2 px-5 py-2.5 bg-gradient-to-r from-[#143d2e] to-[#258f62] text-white text-xs font-bold rounded-full shadow-md shadow-green-900/10 hover:brightness-110 active:scale-95 transition-all cursor-pointer shrink-0"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
          <span>Tambah Profil Operator</span>
        </button>
      </div>

      <!-- Filters Bar -->
      <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
        <!-- Search Input -->
        <div class="relative flex-1">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
          <input 
            :value="searchQuery"
            @input="$emit('update:searchQuery', $event.target.value)"
            type="text"
            :placeholder="activeTab === 'operators' ? 'Cari nama operator...' : 'Cari nama SPBU atau email...'"
            class="w-full pl-9 pr-4 py-2.5 rounded-full bg-gray-50 border border-gray-200 text-xs text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] transition-all shadow-xs"
          />
        </div>

        <!-- SPBU Filter Dropdown -->
        <div class="w-full sm:w-56">
          <select
            :value="selectedSpbuId"
            @change="$emit('update:selectedSpbuId', $event.target.value)"
            class="w-full px-4 py-2.5 rounded-full bg-gray-50 border border-gray-200 text-xs font-bold text-gray-700 focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] transition-all shadow-xs cursor-pointer"
          >
            <option value="">Semua Unit SPBU</option>
            <option v-for="spbu in spbuList" :key="spbu.id" :value="spbu.id">
              {{ spbu.name }}
            </option>
          </select>
        </div>
      </div>

    </div>

    <!-- Container Table & Mobile Cards -->
    <div class="bg-[#143d2e] rounded-3xl p-5 md:p-6 text-white shadow-xl shadow-green-900/10 overflow-hidden border border-emerald-800/30">
      
      <!-- TAB 1: PROFIL OPERATOR (SHIFT WORKERS) -->
      <div v-if="activeTab === 'operators'">
        
        <!-- Mobile List View -->
        <div class="block md:hidden space-y-3">
          <div v-if="loading" class="py-12 text-center text-green-200/60 animate-pulse">
            Memuat profil operator...
          </div>

          <div v-else-if="members.length === 0" class="py-12 text-center text-green-200/60 text-xs font-medium border border-dashed border-white/10 rounded-2xl">
            Belum ada profil operator ditemukan.
          </div>

          <div 
            v-else
            v-for="member in members" 
            :key="member.id" 
            class="bg-black/20 rounded-2xl p-4 border border-white/10 flex flex-col gap-3"
          >
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-white/15 flex items-center justify-center font-black text-white text-sm shadow-xs border border-white/10">
                  {{ member.nama_operator?.charAt(0).toUpperCase() || 'O' }}
                </div>
                <div>
                  <h4 class="font-bold text-white text-sm leading-tight">{{ member.nama_operator }}</h4>
                  <p class="text-[11px] text-green-200/70 font-semibold">{{ member.spbu_name }}</p>
                </div>
              </div>
              <button 
                @click="$emit('toggleStatus', member.id)"
                class="px-2.5 py-0.5 rounded-full text-[10px] font-bold border transition-colors cursor-pointer"
                :class="member.is_active ? 'bg-emerald-500/20 text-emerald-300 border-emerald-500/30' : 'bg-red-500/20 text-red-300 border-red-500/30'"
              >
                {{ member.is_active ? 'Aktif' : 'Nonaktif' }}
              </button>
            </div>

            <div class="h-px bg-white/10 w-full"></div>

            <div class="flex items-center justify-between text-xs pt-0.5">
              <span class="text-green-200/60 font-medium">Dibuat: {{ formatDate(member.created_at) }}</span>
              <button 
                @click="openEditModal(member)"
                class="px-3 py-1 bg-white/10 text-white hover:bg-white/20 rounded-lg text-xs font-bold border border-white/15 transition-colors cursor-pointer"
              >
                Edit Profil
              </button>
            </div>
          </div>
        </div>

        <!-- Desktop Table View -->
        <div class="hidden md:block overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="text-green-200/70 text-xs font-bold uppercase tracking-wider border-b border-white/15 pb-4">
                <th class="pb-4 pl-3">NAMA OPERATOR</th>
                <th class="pb-4">UNIT SPBU PENUGASAN</th>
                <th class="pb-4">STATUS PETUGAS</th>
                <th class="pb-4">TANGGAL DIBUAT</th>
                <th class="pb-4 pr-3 text-right">AKSI</th>
              </tr>
            </thead>
            
            <tbody class="text-sm">
              <tr v-if="loading">
                <td colspan="5" class="py-12 text-center text-green-200/60 animate-pulse">
                  Memuat data operator...
                </td>
              </tr>

              <tr v-else-if="members.length === 0">
                <td colspan="5" class="py-12 text-center text-green-200/60 text-xs font-medium">
                  Tidak ada data operator ditemukan.
                </td>
              </tr>

              <tr 
                v-else
                v-for="member in members" 
                :key="member.id" 
                class="hover:bg-white/5 transition-colors duration-150 border-b border-white/10 last:border-0"
              >
                <td class="py-4 pl-3">
                  <div class="flex items-center gap-3">
                    <div class="w-10 h-10 rounded-xl bg-white/15 flex items-center justify-center font-black text-white text-sm shadow-xs border border-white/10">
                      {{ member.nama_operator?.charAt(0).toUpperCase() || 'O' }}
                    </div>
                    <div>
                      <p class="font-bold text-white text-sm leading-tight">{{ member.nama_operator }}</p>
                      <p class="text-[11px] text-green-200/60 font-semibold">Petugas Shift SPBU</p>
                    </div>
                  </div>
                </td>

                <td class="py-4">
                  <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-white/15 text-green-100 border border-white/10">
                    {{ member.spbu_name }}
                  </span>
                </td>

                <td class="py-4">
                  <button 
                    @click="$emit('toggleStatus', member.id)"
                    class="px-3 py-1 rounded-full text-xs font-bold border transition-all cursor-pointer active:scale-95"
                    :class="member.is_active ? 'bg-emerald-500/20 text-emerald-300 border-emerald-500/30 hover:bg-emerald-500/30' : 'bg-red-500/20 text-red-300 border-red-500/30 hover:bg-red-500/30'"
                    title="Klik untuk mengubah status"
                  >
                    {{ member.is_active ? '● Aktif' : '○ Nonaktif' }}
                  </button>
                </td>

                <td class="py-4 text-green-100 font-medium text-xs">
                  {{ formatDate(member.created_at) }}
                </td>

                <td class="py-4 pr-3 text-right">
                  <button 
                    @click="openEditModal(member)"
                    class="px-3 py-1.5 bg-white/15 text-white hover:bg-white/25 rounded-xl text-xs font-bold border border-white/15 transition-all cursor-pointer active:scale-95"
                  >
                    Edit Profil
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

      </div>

      <!-- TAB 2: AKUN SPBU (LOGIN & AUTHENTICATION CREDENTIALS) -->
      <div v-else-if="activeTab === 'accounts'">
        
        <!-- Mobile List View -->
        <div class="block md:hidden space-y-3">
          <div v-if="loading" class="py-12 text-center text-green-200/60 animate-pulse">
            Memuat akun SPBU...
          </div>

          <div v-else-if="accounts.length === 0" class="py-12 text-center text-green-200/60 text-xs font-medium border border-dashed border-white/10 rounded-2xl">
            Belum ada akun SPBU ditemukan.
          </div>

          <div 
            v-else
            v-for="acc in accounts" 
            :key="acc.user_id || acc.spbu_id" 
            class="bg-black/20 rounded-2xl p-4 border border-white/10 flex flex-col gap-3"
          >
            <div class="flex items-center justify-between">
              <div>
                <h4 class="font-bold text-white text-sm leading-tight">{{ acc.spbu_name }}</h4>
                <p class="text-xs text-amber-300 font-mono mt-0.5">{{ acc.email }}</p>
              </div>
              <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-purple-500/20 text-purple-200 border border-purple-500/30 uppercase">
                {{ acc.role || 'Operator' }}
              </span>
            </div>

            <div class="h-px bg-white/10 w-full"></div>

            <div class="flex justify-end pt-0.5">
              <button 
                @click="openResetModal(acc)"
                class="px-3 py-1.5 bg-amber-500/20 text-amber-300 hover:bg-amber-500/30 rounded-xl text-xs font-bold border border-amber-500/30 transition-colors cursor-pointer"
              >
                Reset Password Akun
              </button>
            </div>
          </div>
        </div>

        <!-- Desktop Table View -->
        <div class="hidden md:block overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="text-green-200/70 text-xs font-bold uppercase tracking-wider border-b border-white/15 pb-4">
                <th class="pb-4 pl-3">UNIT SPBU</th>
                <th class="pb-4">EMAIL AKUN LOGIN</th>
                <th class="pb-4">HAK AKSES (ROLE)</th>
                <th class="pb-4 pr-3 text-right">AKSI AUTHENTICATION</th>
              </tr>
            </thead>
            
            <tbody class="text-sm">
              <tr v-if="loading">
                <td colspan="4" class="py-12 text-center text-green-200/60 animate-pulse">
                  Memuat akun SPBU...
                </td>
              </tr>

              <tr v-else-if="accounts.length === 0">
                <td colspan="4" class="py-12 text-center text-green-200/60 text-xs font-medium">
                  Tidak ada data akun SPBU ditemukan.
                </td>
              </tr>

              <tr 
                v-else
                v-for="acc in accounts" 
                :key="acc.user_id || acc.spbu_id" 
                class="hover:bg-white/5 transition-colors duration-150 border-b border-white/10 last:border-0"
              >
                <td class="py-4 pl-3">
                  <div class="flex items-center gap-3">
                    <div class="w-10 h-10 rounded-xl bg-white/15 flex items-center justify-center font-black text-white text-sm shadow-xs border border-white/10">
                      ⛽
                    </div>
                    <div>
                      <p class="font-bold text-white text-sm leading-tight">{{ acc.spbu_name }}</p>
                      <p class="text-[11px] text-green-200/60 font-semibold">ID: {{ acc.spbu_id }}</p>
                    </div>
                  </div>
                </td>

                <td class="py-4 font-mono text-xs font-bold text-amber-200">
                  {{ acc.email }}
                </td>

                <td class="py-4">
                  <span class="px-3 py-1 rounded-full text-xs font-bold bg-purple-500/20 text-purple-200 border border-purple-500/30 uppercase tracking-wider">
                    {{ acc.role || 'Operator' }}
                  </span>
                </td>

                <td class="py-4 pr-3 text-right">
                  <button 
                    @click="openResetModal(acc)"
                    class="px-3 py-1.5 bg-amber-500/20 text-amber-300 hover:bg-amber-500/30 rounded-xl text-xs font-bold border border-amber-500/30 transition-all cursor-pointer active:scale-95"
                  >
                    Reset Password Akun
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

      </div>

    </div>

    <!-- Modal Form (Tambah / Edit Profil Operator) -->
    <div v-if="isModalOpen" class="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-3xl p-6 md:p-8 max-w-md w-full shadow-2xl space-y-6 border border-gray-100 animate-enter">
        <div class="flex items-center justify-between border-b border-gray-100 pb-4">
          <h3 class="text-lg font-black text-[#143d2e]">
            {{ modalMode === 'create' ? 'Tambah Profil Operator Baru' : 'Edit Profil Operator' }}
          </h3>
          <button @click="isModalOpen = false" class="p-1 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>

        <form @submit.prevent="handleSubmit" class="space-y-4">
          <div>
            <label class="block text-xs font-bold text-gray-700 uppercase mb-1.5">Nama Operator</label>
            <input 
              v-model="formData.nama_operator"
              type="text"
              required
              placeholder="Contoh: Agus Setiawan"
              class="w-full px-4 py-2.5 rounded-2xl bg-gray-50 border border-gray-200 text-sm font-semibold text-gray-800 focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] transition-all"
            />
          </div>

          <div>
            <label class="block text-xs font-bold text-gray-700 uppercase mb-1.5">Unit SPBU Penugasan</label>
            <select
              v-model="formData.spbu_id"
              required
              class="w-full px-4 py-2.5 rounded-2xl bg-gray-50 border border-gray-200 text-sm font-semibold text-gray-800 focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] transition-all cursor-pointer"
            >
              <option value="" disabled>Pilih Unit SPBU</option>
              <option v-for="spbu in spbuList" :key="spbu.id" :value="spbu.id">
                {{ spbu.name }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-xs font-bold text-gray-700 uppercase mb-1.5">Status Petugas</label>
            <div class="flex items-center gap-4 pt-1">
              <label class="inline-flex items-center gap-2 cursor-pointer">
                <input type="radio" v-model="formData.is_active" :value="true" class="radio radio-success radio-sm" />
                <span class="text-sm font-bold text-emerald-700">Aktif</span>
              </label>
              <label class="inline-flex items-center gap-2 cursor-pointer">
                <input type="radio" v-model="formData.is_active" :value="false" class="radio radio-error radio-sm" />
                <span class="text-sm font-bold text-red-600">Nonaktif</span>
              </label>
            </div>
          </div>

          <div class="flex justify-end gap-3 pt-4 border-t border-gray-100">
            <button 
              type="button" 
              @click="isModalOpen = false" 
              class="px-5 py-2.5 rounded-full text-xs font-bold text-gray-600 hover:bg-gray-100 transition-colors"
            >
              Batal
            </button>
            <button 
              type="submit" 
              :disabled="isSubmitting"
              class="px-6 py-2.5 rounded-full text-xs font-bold bg-[#143d2e] text-white hover:bg-[#1a4a38] transition-colors shadow-md shadow-green-900/10 cursor-pointer"
            >
              {{ isSubmitting ? 'Menyimpan...' : (modalMode === 'create' ? 'Simpan Profil' : 'Perbarui Profil') }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Modal Reset Password Akun SPBU -->
    <div v-if="isResetModalOpen" class="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-3xl p-6 md:p-8 max-w-md w-full shadow-2xl space-y-6 border border-gray-100 animate-enter">
        <div class="flex items-center justify-between border-b border-gray-100 pb-4">
          <div>
            <h3 class="text-lg font-black text-[#143d2e]">Reset Password Akun SPBU</h3>
            <p class="text-xs text-gray-500 font-medium">Unit: {{ selectedAccount?.spbu_name }} ({{ selectedAccount?.email }})</p>
          </div>
          <button @click="isResetModalOpen = false" class="p-1 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>

        <div class="space-y-4">
          <!-- Temporary Password Generator -->
          <div class="bg-amber-50 rounded-2xl p-4 border border-amber-200/70 space-y-2">
            <div class="flex items-center gap-2">
              <span class="text-amber-700 font-bold text-xs">⚡ Password Sementara Login Akun SPBU</span>
            </div>
            <p class="text-[11px] text-amber-900/80 leading-relaxed font-medium">
              Gunakan password sementara ini untuk login ke akun autentikasi unit {{ selectedAccount?.spbu_name }}:
            </p>
            <div class="flex items-center gap-2 pt-1">
              <input 
                readonly 
                :value="resetForm.temporaryPassword" 
                class="flex-1 bg-white font-mono font-bold text-sm px-3 py-2 rounded-xl border border-amber-300 text-gray-800 focus:outline-none"
              />
              <button 
                @click="copyTempPassword"
                class="px-3 py-2 bg-amber-600 hover:bg-amber-700 text-white rounded-xl text-xs font-bold transition-colors cursor-pointer"
              >
                {{ resetForm.copied ? 'Tercopy!' : 'Copy' }}
              </button>
            </div>
          </div>
        </div>

        <div class="flex justify-end pt-2">
          <button 
            @click="isResetModalOpen = false" 
            class="px-6 py-2.5 rounded-full text-xs font-bold bg-gray-800 text-white hover:bg-gray-900 transition-colors shadow-md cursor-pointer"
          >
            Selesai
          </button>
        </div>
      </div>
    </div>

  </div>
</template>