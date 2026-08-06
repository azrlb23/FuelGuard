<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

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
  selectedSpbuId: String,
  activeTab: {
    type: String,
    default: 'operators'
  },
  resetAccountPassword: {
    type: Function,
    default: null
  }
})

const emit = defineEmits([
  'update:searchQuery',
  'update:selectedSpbuId',
  'createOperator',
  'updateOperator',
  'toggleStatus'
])

// Modal & Dropdown State
const isModalOpen = ref(false)
const isResetModalOpen = ref(false)
const modalMode = ref('create') // 'create' | 'edit'
const selectedAccount = ref(null)

const isFormSpbuDropdownOpen = ref(false)
const spbuModalDropdownRef = ref(null)

const formData = ref({
  id: null,
  nama_operator: '',
  spbu_id: '',
  is_active: true
})

const selectFormSpbu = (spbuId) => {
  formData.value.spbu_id = spbuId
  isFormSpbuDropdownOpen.value = false
}

const getSelectedSpbuName = () => {
  if (!formData.value || !formData.value.spbu_id) return 'Pilih Unit SPBU'
  if (!props.spbuList || !Array.isArray(props.spbuList) || props.spbuList.length === 0) {
    return `SPBU #${formData.value.spbu_id}`
  }
  const spbu = props.spbuList.find(s => s && String(s.id) === String(formData.value.spbu_id))
  return spbu ? spbu.name : `SPBU #${formData.value.spbu_id}`
}

// Filter Bar SPBU Custom Dropdown State
const isFilterSpbuDropdownOpen = ref(false)
const filterSpbuDropdownContainerRef = ref(null)

const selectFilterSpbuOption = (spbuId) => {
  emit('update:selectedSpbuId', spbuId)
  isFilterSpbuDropdownOpen.value = false
}

const selectedFilterSpbuLabel = computed(() => {
  if (!props.selectedSpbuId) return 'Semua Unit SPBU'
  const found = props.spbuList.find(s => String(s.id) === String(props.selectedSpbuId))
  return found ? found.name : `SPBU #${props.selectedSpbuId}`
})

const handleFilterSpbuClickOutside = (e) => {
  if (filterSpbuDropdownContainerRef.value && !filterSpbuDropdownContainerRef.value.contains(e.target)) {
    isFilterSpbuDropdownOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleFilterSpbuClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleFilterSpbuClickOutside)
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

const isConfirmModalOpen = ref(false)

const handleSubmit = () => {
  if (!formData.value.nama_operator.trim()) return
  if (modalMode.value === 'create') {
    emit('createOperator', { ...formData.value })
    isModalOpen.value = false
  } else {
    isConfirmModalOpen.value = true
  }
}

const confirmUpdateOperator = () => {
  emit('updateOperator', formData.value.id, { ...formData.value })
  isConfirmModalOpen.value = false
  isModalOpen.value = false
}

const resetForm = ref({
  password: '',
  copied: false,
  success: false
})
const resetSubmitting = ref(false)
const isResetConfirmModalOpen = ref(false)
const showResetPassword = ref(false)

const openResetModal = (account) => {
  selectedAccount.value = account
  resetForm.value = {
    password: `Pertamina#${Math.floor(1000 + Math.random() * 9000)}`,
    copied: false,
    success: false
  }
  showResetPassword.value = false
  isResetModalOpen.value = true
}

const generateRandomPassword = () => {
  resetForm.value.password = `Pertamina#${Math.floor(1000 + Math.random() * 9000)}`
  resetForm.value.success = false
}

const openResetConfirmModal = () => {
  if (!selectedAccount.value || !selectedAccount.value.user_id) {
    alert("Akun SPBU ini belum memiliki User ID Auth (belum ditautkan di tabel user_roles).")
    return
  }
  if (!resetForm.value.password || resetForm.value.password.length < 6) {
    alert("Password minimal harus 6 karakter")
    return
  }
  isResetConfirmModalOpen.value = true
}

const confirmResetPassword = async () => {
  isResetConfirmModalOpen.value = false
  await handleExecuteResetPassword()
}

const handleExecuteResetPassword = async () => {
  if (!selectedAccount.value || !selectedAccount.value.user_id) {
    alert("Akun SPBU ini belum memiliki User ID Auth (belum ditautkan di tabel user_roles).")
    return
  }
  if (!resetForm.value.password || resetForm.value.password.length < 6) {
    alert("Password minimal harus 6 karakter")
    return
  }

  resetSubmitting.value = true
  try {
    let res = null
    if (typeof props.resetAccountPassword === 'function') {
      res = await props.resetAccountPassword(
        selectedAccount.value.user_id,
        resetForm.value.password
      )
    }

    if (res && res.success) {
      resetForm.value.success = true
    } else {
      alert(res?.message || 'Gagal mereset password. Pastikan RPC 08_master_reset_password_rpc.sql sudah dijalankan di Supabase.')
    }
  } catch (err) {
    console.error(err)
    alert(err.message || 'Terjadi kesalahan saat mereset password')
  } finally {
    resetSubmitting.value = false
  }
}

const copyTempPassword = () => {
  navigator.clipboard.writeText(resetForm.value.password)
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
  <div class="w-full">

    <!-- Single Unified Card: Tabs + Filters + Table (Signature Green Glassmorphism Gradient) -->
    <div class="bg-gradient-to-br from-[#143d2e] via-[#1b4d3a] to-[#256a50] rounded-3xl md:rounded-[2rem] p-5 md:p-8 border border-white/20 shadow-xl shadow-green-900/15 text-white relative overflow-hidden backdrop-blur-xl">
      <div class="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl -translate-y-20 translate-x-20 pointer-events-none"></div>

      <!-- Background Glow Effect -->
      <div class="absolute top-0 right-0 w-64 h-64 bg-emerald-500/5 rounded-full blur-3xl pointer-events-none"></div>

      <!-- Filters Bar -->
      <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 relative z-20 pb-4 border-b border-emerald-800/40">
        <!-- Search Input -->
        <div class="relative flex-1">
          <span class="absolute left-3 top-3 text-green-300 pointer-events-none">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
              <path stroke-linecap="round" stroke-linejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" />
            </svg>
          </span>
          <input
            :value="searchQuery"
            @input="$emit('update:searchQuery', $event.target.value)"
            type="text"
            :placeholder="activeTab === 'operators' ? 'Cari nama operator...' : 'Cari nama SPBU atau email...'"
            class="w-full pl-9 pr-4 py-2.5 bg-white/10 hover:bg-white/20 border border-white/15 focus:border-white focus:ring-2 focus:ring-white/20 focus:outline-none rounded-full text-xs font-bold text-white placeholder-green-200/60 transition-all shadow-sm"
          />
        </div>

        <!-- SPBU Filter Dropdown (Custom Premium Card) -->
        <div ref="filterSpbuDropdownContainerRef" class="relative w-full sm:w-56">
          <button
            type="button"
            @click="isFilterSpbuDropdownOpen = !isFilterSpbuDropdownOpen"
            class="w-full flex items-center justify-between gap-2 bg-white/10 hover:bg-white/20 border border-white/15 focus:border-white focus:ring-2 focus:ring-white/20 rounded-full px-4 py-2.5 text-xs font-bold text-white transition-all shadow-sm cursor-pointer select-none"
          >
            <span class="truncate">{{ selectedFilterSpbuLabel }}</span>
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" :class="['w-3.5 h-3.5 text-green-200/70 transition-transform duration-200 shrink-0', isFilterSpbuDropdownOpen ? 'rotate-180 text-white' : '']">
              <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
            </svg>
          </button>

          <!-- Floating SPBU Menu Card -->
          <div
            v-if="isFilterSpbuDropdownOpen"
            class="absolute left-0 mt-1.5 w-full bg-white rounded-2xl shadow-2xl border border-gray-100 p-1.5 z-[110] text-gray-800 text-xs font-bold space-y-0.5 max-h-56 overflow-y-auto animate-enter"
          >
            <button
              type="button"
              @click="selectFilterSpbuOption('')"
              :class="[
                'w-full flex items-center justify-between px-3.5 py-2 rounded-xl transition-all text-left cursor-pointer',
                !selectedSpbuId ? 'bg-[#143d2e]/10 text-[#143d2e] font-black' : 'hover:bg-gray-100 text-gray-700'
              ]"
            >
              <span>Semua Unit SPBU</span>
              <svg v-if="!selectedSpbuId" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="3" stroke="currentColor" class="w-4 h-4 text-[#143d2e] shrink-0">
                <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
              </svg>
            </button>

            <button
              v-for="spbu in spbuList"
              :key="spbu.id"
              type="button"
              @click="selectFilterSpbuOption(spbu.id)"
              :class="[
                'w-full flex items-center justify-between px-3.5 py-2 rounded-xl transition-all text-left cursor-pointer',
                String(selectedSpbuId) === String(spbu.id) ? 'bg-[#143d2e]/10 text-[#143d2e] font-black' : 'hover:bg-gray-100 text-gray-700'
              ]"
            >
              <span class="truncate">{{ spbu.name }}</span>
              <svg v-if="String(selectedSpbuId) === String(spbu.id)" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="3" stroke="currentColor" class="w-4 h-4 text-[#143d2e] shrink-0">
                <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
              </svg>
            </button>
          </div>
        </div>

        <!-- Action: Tambah Operator Button -->
        <button
          v-if="activeTab === 'operators'"
          @click="openCreateModal"
          class="inline-flex items-center justify-center gap-2 px-5 py-2.5 bg-emerald-500/20 border border-emerald-400/50 text-emerald-200 text-xs font-bold rounded-full shadow-sm hover:bg-emerald-500/30 active:scale-95 transition-all cursor-pointer shrink-0 w-full sm:w-auto"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
          <span>Tambah Profil Operator</span>
        </button>
      </div>

      <!-- Table/Cards Content (no gap, same card) -->

      <!-- TAB 1: PROFIL OPERATOR (SHIFT WORKERS) -->
      <div v-if="activeTab === 'operators'" class="pt-1">

        <!-- Mobile List View -->
        <div class="block md:hidden space-y-3">
          <!-- Skeleton Loading State -->
          <template v-if="loading">
            <div v-for="n in 3" :key="n" class="bg-black/20 rounded-2xl p-4 border border-white/10 animate-pulse space-y-3">
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-xl bg-white/20"></div>
                  <div class="space-y-1.5">
                    <div class="h-4 w-32 bg-white/25 rounded-md"></div>
                    <div class="h-3 w-20 bg-white/15 rounded-md"></div>
                  </div>
                </div>
                <div class="h-5 w-14 bg-white/20 rounded-full"></div>
              </div>
            </div>
          </template>

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
              <span
                class="px-2.5 py-0.5 rounded-full text-[10px] font-bold border"
                :class="member.is_active ? 'bg-emerald-500/20 text-emerald-300 border-emerald-500/30' : 'bg-red-500/20 text-red-300 border-red-500/30'"
              >
                {{ member.is_active ? 'Aktif' : 'Nonaktif' }}
              </span>
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
            <thead class="border-b border-white/15 text-emerald-200/90">
              <tr class="text-xs font-extrabold uppercase tracking-wider">
                <th class="py-3.5 pl-3">NAMA OPERATOR</th>
                <th class="py-3.5">SPBU</th>
                <th class="py-3.5">STATUS PETUGAS</th>
                <th class="py-3.5">TANGGAL DIBUAT</th>
                <th class="py-3.5 pr-3 text-right">AKSI</th>
              </tr>
            </thead>

            <tbody class="text-sm">
              <template v-if="loading">
                <tr v-for="n in 3" :key="n" class="border-b border-white/10 animate-pulse">
                  <td class="py-4 pl-3">
                    <div class="flex items-center gap-3">
                      <div class="w-10 h-10 rounded-xl bg-white/20"></div>
                      <div class="h-4 w-32 bg-white/25 rounded-md"></div>
                    </div>
                  </td>
                  <td class="py-4"><div class="h-4 w-36 bg-white/20 rounded-md"></div></td>
                  <td class="py-4"><div class="h-5 w-16 bg-white/20 rounded-full"></div></td>
                  <td class="py-4"><div class="h-4 w-28 bg-white/20 rounded-md"></div></td>
                  <td class="py-4 pr-3 text-right"><div class="h-8 w-20 bg-white/20 rounded-xl ml-auto"></div></td>
                </tr>
              </template>

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
                      <!-- <p class="text-[11px] text-green-200/60 font-semibold">SPBU</p> -->
                    </div>
                  </div>
                </td>

                <td class="py-4">
                  <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-white/15 text-green-100 border border-white/10">
                    {{ member.spbu_name }}
                  </span>
                </td>

                <td class="py-4">
                  <span
                    class="px-3 py-1 rounded-full text-xs font-bold border"
                    :class="member.is_active ? 'bg-emerald-500/20 text-emerald-300 border-emerald-500/30' : 'bg-red-500/20 text-red-300 border-red-500/30'"
                  >
                    {{ member.is_active ? '● Aktif' : '○ Nonaktif' }}
                  </span>
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
      <div v-else-if="activeTab === 'accounts'" class="pt-1">

        <!-- Mobile List View -->
        <div class="block md:hidden space-y-3">
          <template v-if="loading">
            <div v-for="n in 3" :key="n" class="bg-black/20 rounded-2xl p-4 border border-white/10 animate-pulse space-y-3">
              <div class="flex items-center justify-between">
                <div class="space-y-1.5">
                  <div class="h-4 w-32 bg-white/25 rounded-md"></div>
                  <div class="h-3 w-40 bg-white/15 rounded-md"></div>
                </div>
                <div class="h-5 w-16 bg-white/20 rounded-full"></div>
              </div>
            </div>
          </template>

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
                <p class="text-xs text-green-200/80 font-medium mt-0.5">{{ acc.email }}</p>
              </div>
              <span class="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 uppercase">
                {{ acc.role || 'Operator' }}
              </span>
            </div>

            <div class="h-px bg-white/10 w-full"></div>

            <div class="flex justify-end pt-0.5">
              <button
                @click="openResetModal(acc)"
                class="px-4 py-1.5 rounded-full bg-white/10 hover:bg-white/20 border border-white/15 text-white font-bold text-xs shadow-sm transition-all cursor-pointer active:scale-95"
              >
                Reset Password Akun
              </button>
            </div>
          </div>
        </div>

        <!-- Desktop Table View -->
        <div class="hidden md:block overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead class="border-b border-white/15 text-emerald-200/90">
              <tr class="text-xs font-extrabold uppercase tracking-wider">
                <th class="py-3.5 pl-3">SPBU</th>
                <th class="py-3.5">EMAIL AKUN</th>
                <th class="py-3.5">PERAN</th>
                <th class="py-3.5 pr-3 text-right">AKSI</th>
              </tr>
            </thead>

            <tbody class="text-sm">
              <template v-if="loading">
                <tr v-for="n in 3" :key="n" class="border-b border-white/10 animate-pulse">
                  <td class="py-4 pl-3"><div class="h-4 w-32 bg-white/20 rounded-md"></div></td>
                  <td class="py-4"><div class="h-4 w-48 bg-white/20 rounded-md"></div></td>
                  <td class="py-4"><div class="h-5 w-16 bg-white/20 rounded-full"></div></td>
                  <td class="py-4 pr-3 text-right"><div class="h-8 w-32 bg-white/20 rounded-xl ml-auto"></div></td>
                </tr>
              </template>

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
                      {{ acc.spbu_name?.charAt(0).toUpperCase() || 'S' }}
                    </div>
                    <div>
                      <p class="font-bold text-white text-sm leading-tight">{{ acc.spbu_name }}</p>
                      <!-- <p class="text-[11px] text-green-200/60 font-semibold  ">ID: {{ acc.spbu_id }}</p> -->
                    </div>
                  </div>
                </td>

                <td class="py-4 text-emerald-100 font-bold text-xs md:text-sm">
                  {{ acc.email }}
                </td>

                <td class="py-4">
                  <span class="px-3 py-1 rounded-full text-xs font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 uppercase tracking-wider">
                    {{ acc.role || 'Operator' }}
                  </span>
                </td>

                <td class="py-4 pr-3 text-right">
                  <button
                    @click="openResetModal(acc)"
                    class="px-4 py-1.5 rounded-full bg-white/10 hover:bg-white/20 border border-white/15 text-white font-bold text-xs shadow-sm transition-all cursor-pointer active:scale-95"
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
            <div ref="spbuModalDropdownRef" class="relative">
              <button
                type="button"
                @click.stop="isFormSpbuDropdownOpen = !isFormSpbuDropdownOpen"
                class="w-full flex items-center justify-between gap-2 bg-gray-50 hover:bg-gray-100/80 border border-gray-200 focus:ring-2 focus:ring-[#143d2e]/20 rounded-2xl px-4 py-2.5 text-sm font-semibold text-gray-800 transition-all cursor-pointer select-none"
              >
                <span class="truncate">{{ getSelectedSpbuName() }}</span>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" :class="['w-4 h-4 text-gray-500 transition-transform duration-200 shrink-0', isFormSpbuDropdownOpen ? 'rotate-180' : '']">
                  <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
                </svg>
              </button>

              <!-- Dropdown Menu Options -->
              <div
                v-if="isFormSpbuDropdownOpen"
                class="absolute left-0 mt-1.5 w-full bg-white rounded-2xl shadow-2xl border border-gray-100 p-1.5 z-[120] text-gray-700 text-sm font-semibold space-y-0.5 max-h-48 overflow-y-auto"
              >
                <button
                  v-for="spbu in spbuList"
                  :key="spbu.id"
                  type="button"
                  @click="selectFormSpbu(spbu.id)"
                  :class="[
                    'w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl transition-all text-left cursor-pointer',
                    String(formData.spbu_id) === String(spbu.id) ? 'bg-[#143d2e]/10 text-[#143d2e] font-bold' : 'hover:bg-gray-50 text-gray-600'
                  ]"
                >
                  <span class="truncate">{{ spbu.name }}</span>
                  <svg v-if="String(formData.spbu_id) === String(spbu.id)" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="3" stroke="currentColor" class="w-4 h-4 text-[#143d2e] shrink-0">
                    <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                  </svg>
                </button>
              </div>
            </div>
          </div>

          <div>
            <label class="block text-xs font-bold text-gray-700 uppercase mb-1.5">Status Petugas</label>
            <div class="bg-gray-50 p-1.5 rounded-2xl flex max-w-[280px] border border-gray-200">
              <button
                type="button"
                @click="formData.is_active = true"
                class="flex-1 py-2 px-4 rounded-xl text-xs font-bold transition-all duration-200 flex items-center justify-center gap-1.5 cursor-pointer"
                :class="formData.is_active ? 'bg-emerald-600 text-white shadow-sm font-extrabold' : 'text-gray-500 hover:text-gray-700'"
              >
                Aktif
              </button>
              <button
                type="button"
                @click="formData.is_active = false"
                class="flex-1 py-2 px-4 rounded-xl text-xs font-bold transition-all duration-200 flex items-center justify-center gap-1.5 cursor-pointer"
                :class="!formData.is_active ? 'bg-red-600 text-white shadow-sm font-extrabold' : 'text-gray-500 hover:text-gray-700'"
              >
                Nonaktif
              </button>
            </div>
          </div>

          <div class="flex justify-end gap-3 pt-4 border-t border-gray-100">
            <button
              type="button"
              @click="isModalOpen = false"
              class="px-5 py-2.5 rounded-full text-xs font-bold text-gray-600 bg-gray-200 hover:bg-gray-300 transition-colors"
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
      <div class="bg-white rounded-3xl p-6 md:p-8 max-w-md w-full shadow-2xl space-y-5 border border-gray-100 animate-enter">
        <div class="flex items-center justify-between border-b border-gray-100 pb-4">
          <div>
            <h3 class="text-lg font-black text-[#143d2e]">Reset Password Akun SPBU</h3>
            <p class="text-xs text-gray-500 font-medium">Akun: {{ selectedAccount?.spbu_name }} ({{ selectedAccount?.email }})</p>
          </div>
          <button @click="isResetModalOpen = false" class="p-1 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>

        <div v-if="resetForm.success" class="space-y-6 text-center py-4">
          <h4 class="text-base font-black text-[#143d2e]">Password Akun Berhasil Di-reset!</h4>
          <div class="flex justify-end pt-2">
            <button
              @click="isResetModalOpen = false"
              class="px-6 py-2.5 rounded-full text-xs font-bold bg-[#143d2e] text-white hover:bg-[#1a4a38] transition-colors shadow-md cursor-pointer"
            >
              Selesai
            </button>
          </div>
        </div>

        <form v-else @submit.prevent="openResetConfirmModal" class="space-y-4">
          <div>
            <label class="block text-xs font-bold text-gray-700 uppercase mb-1.5">Password Baru Akun SPBU</label>
            <div class="flex items-center gap-2">
              <div class="relative flex-1">
                <input
                  v-model="resetForm.password"
                  :type="showResetPassword ? 'text' : 'password'"
                  required
                  minlength="6"
                  placeholder="Masukkan password baru"
                  class="w-full pl-4 pr-10 py-2.5 rounded-2xl bg-gray-50 border border-gray-200 text-sm font-semibold text-gray-800 focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] transition-all"
                />
                <button
                  type="button"
                  @click="showResetPassword = !showResetPassword"
                  class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 p-1 rounded-lg transition-colors cursor-pointer select-none"
                  :title="showResetPassword ? 'Sembunyikan Password' : 'Tampilkan Password'"
                >
                  <svg v-if="showResetPassword" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M3.98 8.223A10.477 10.477 0 0 0 1.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.451 10.451 0 0 1 12 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 0 1-4.293 5.774M6.228 6.228 3 3m3.228 3.228 3.65 3.65m7.894 7.894L21 21m-3.228-3.228-3.65-3.65m0 0a3 3 0 1 0-4.243-4.243m4.242 4.242L9.88 9.88" />
                  </svg>
                  <svg v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12c1.274-4.057 5.065-7 9.542-7 4.477 0 8.268 2.943 9.542 7-1.274 4.057-5.065 7-9.542 7-4.477 0-8.268-2.943-9.542-7Z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
                  </svg>
                </button>
              </div>
              <button
                type="button"
                @click="generateRandomPassword"
                title="Generate Password Acak"
                class="px-4 py-2.5 bg-[#143d2e] hover:bg-[#1a4a38] border border-[#143d2e] text-white rounded-2xl text-xs font-bold transition-all cursor-pointer shrink-0 select-none flex items-center justify-center"
              >
                Acak
              </button>
            </div>
          </div>

          <div class="flex justify-end gap-3 pt-4 border-t border-gray-100">
            <button
              type="button"
              @click="isResetModalOpen = false"
              class="px-5 py-2.5 rounded-full text-xs font-bold text-gray-600 bg-gray-200 hover:bg-gray-300 transition-colors"
            >
              Batal
            </button>
            <button
              type="submit"
              :disabled="resetSubmitting"
              class="px-6 py-2.5 rounded-full text-xs font-bold bg-[#143d2e] text-white hover:bg-[#1a4a38] transition-colors shadow-md shadow-green-900/10 active:scale-95 disabled:opacity-50 cursor-pointer flex items-center gap-2"
            >
              <span v-if="resetSubmitting" class="loading loading-spinner loading-xs"></span>
              Reset Password Akun
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Custom Modern Confirmation Modal (Reset Password) -->
    <div v-if="isResetConfirmModalOpen" class="fixed inset-0 bg-black/60 backdrop-blur-sm z-[60] flex items-center justify-center p-4">
      <div class="bg-white rounded-3xl p-6 sm:p-7 max-w-sm w-full shadow-2xl border border-gray-100 space-y-5 animate-enter text-center">

        <div>
          <h3 class="text-base font-black text-[#143d2e]">Konfirmasi Reset Password</h3>
          <p class="text-xs text-gray-500 font-medium mt-1.5 leading-relaxed">
            Apakah Anda yakin ingin mengubah password ini ?
          </p>
        </div>

        <!-- Summary Preview Box -->
        <div class="bg-gray-50 rounded-2xl p-3.5 text-left space-y-2 text-xs font-semibold text-gray-700">
          <div class="flex justify-between items-center">
            <span class="text-gray-400 font-bold uppercase text-[10px]">Akun SPBU</span>
            <span class="font-bold text-gray-900 truncate max-w-[170px]">{{ selectedAccount?.spbu_name }}</span>
          </div>
          <div class="flex justify-between items-center">
            <span class="text-gray-400 font-bold uppercase text-[10px]">Email Akun</span>
            <span class="font-bold text-[#143d2e] truncate max-w-[170px]">{{ selectedAccount?.email }}</span>
          </div>
          <div class="flex justify-between items-center">
            <span class="text-gray-400 font-bold uppercase text-[10px]">Password Baru</span>
            <span class="font-mono font-bold text-emerald-700 py-0.5 rounded-lg">{{ resetForm.password }}</span>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="space-y-3 pt-1">
          <p class="text-[11px] font-bold text-red-500/90 text-center">
            Tindakan ini tidak dapat dibatalkan.
          </p>
          <div class="flex items-center gap-3">
            <button
              type="button"
              @click="isResetConfirmModalOpen = false"
              class="flex-1 py-2.5 px-4 rounded-xl border border-gray-200 text-gray-600 text-xs font-bold bg-gray-200 hover:bg-gray-300 active:scale-95 transition-all cursor-pointer select-none"
            >
              Batal
            </button>
            <button
              type="button"
              @click="confirmResetPassword"
              class="flex-1 py-2.5 px-4 rounded-xl bg-gradient-to-r from-[#143d2e] to-[#1a4a38] text-white text-xs font-bold shadow-md hover:brightness-110 active:scale-95 transition-all cursor-pointer select-none"
            >
              Ya, Reset
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Custom Modern Confirmation Modal (Edit Profil) -->
    <div v-if="isConfirmModalOpen" class="fixed inset-0 bg-black/60 backdrop-blur-sm z-[60] flex items-center justify-center p-4">
      <div class="bg-white rounded-3xl p-6 sm:p-7 max-w-sm w-full shadow-2xl border border-gray-100 space-y-5 animate-enter text-center">

        <div>
          <h3 class="text-base font-black text-[#143d2e]">Konfirmasi Pembaruan</h3>
          <p class="text-xs text-gray-500 font-medium mt-1.5 leading-relaxed">
            Apakah Anda yakin ?
          </p>
        </div>

        <!-- Summary Preview Box -->
        <div class="bg-gray-50 rounded-2xl p-3.5 text-left space-y-2 text-xs font-semibold text-gray-700">
          <div class="flex justify-between items-center">
            <span class="text-gray-400 font-bold uppercase text-[10px]">Nama Operator</span>
            <span class="font-bold text-gray-900 truncate max-w-[170px]">{{ formData.nama_operator }}</span>
          </div>
          <div class="flex justify-between items-center">
            <span class="text-gray-400 font-bold uppercase text-[10px]">Unit SPBU</span>
            <span class="font-bold text-[#143d2e] py-0.5 rounded-lg">{{ getSelectedSpbuName() }}</span>
          </div>
          <div class="flex justify-between items-center">
            <span class="text-gray-400 font-bold uppercase text-[10px]">Status</span>
            <span :class="formData.is_active ? 'text-emerald-700 font-extrabold' : 'text-red-600 font-extrabold'">
              {{ formData.is_active ? 'Aktif' : 'Nonaktif' }}
            </span>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="space-y-3 pt-1">
          <p class="text-[11px] font-bold text-red-500/90 text-center">
            Tindakan ini tidak dapat dibatalkan.
          </p>
          <div class="flex items-center gap-3">
            <button
              type="button"
              @click="isConfirmModalOpen = false"
              class="flex-1 py-2.5 px-4 rounded-xl border border-gray-200 text-gray-600 text-xs font-bold hover:bg-gray-100 active:scale-95 transition-all cursor-pointer select-none"
            >
              Batal
            </button>
            <button
              type="button"
              @click="confirmUpdateOperator"
              class="flex-1 py-2.5 px-4 rounded-xl bg-gradient-to-r from-[#143d2e] to-[#1a4a38] text-white text-xs font-bold shadow-md hover:brightness-110 active:scale-95 transition-all cursor-pointer select-none"
            >
              Ya, Perbarui
            </button>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>
