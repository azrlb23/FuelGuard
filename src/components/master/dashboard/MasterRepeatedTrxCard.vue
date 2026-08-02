<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import CustomDatePicker from '@/components/common/CustomDatePicker.vue'

const props = defineProps({
  repeatedLogs: {
    type: Array,
    default: () => []
  },
  loading: {
    type: Boolean,
    default: false
  },
  totalCount: {
    type: Number,
    default: 0
  },
  totalPlates: {
    type: Number,
    default: 0
  },
  searchQuery: {
    type: String,
    default: ''
  },
  selectedSpbu: {
    type: [String, Number],
    default: ''
  },
  dateFrom: {
    type: String,
    default: ''
  },
  dateTo: {
    type: String,
    default: ''
  },
  spbuList: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits([
  'update:searchQuery',
  'update:selectedSpbu',
  'update:dateFrom',
  'update:dateTo',
  'resetFilters'
])

const filterPanelRef = ref(null)
const isFilterPanelOpen = ref(false)
const isSpbuOpen = ref(false)
const spbuDropdownContainerRef = ref(null)

const toggleFilterPanel = () => {
  isFilterPanelOpen.value = !isFilterPanelOpen.value
}

const toggleSpbuDropdown = () => {
  isSpbuOpen.value = !isSpbuOpen.value
}

const selectSpbuOption = (id) => {
  emit('update:selectedSpbu', id)
  isSpbuOpen.value = false
}

const activeFilterCount = computed(() => {
  let count = 0
  if (props.selectedSpbu) count++
  if (props.dateFrom) count++
  if (props.dateTo) count++
  return count
})

const selectedSpbuName = computed(() => {
  if (!props.selectedSpbu) return 'Semua SPBU'
  const spbu = props.spbuList.find(s => String(s.id) === String(props.selectedSpbu))
  return spbu ? `${spbu.nama} (${spbu.id})` : 'Semua SPBU'
})

const normalizePlate = (plat) => {
  if (!plat) return ''
  return plat.trim().toUpperCase().replace(/\s+/g, ' ')
}

// Expanded state for accordion rows (plat_nomor key map)
const expandedPlates = ref({})

// Toggle accordion row for a plate
const togglePlate = (plat) => {
  expandedPlates.value[plat] = !expandedPlates.value[plat]
}

// Check if a plate is expanded (default: false / collapsed by default)
const isExpanded = (plat) => {
  return !!expandedPlates.value[plat]
}

const formatTimeOnly = (dateString) => {
  if (!dateString) return '-'
  const d = new Date(dateString)
  return d.toLocaleTimeString('id-ID', {
    timeZone: 'Asia/Makassar',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  }).replace('.', ':') + ' WITA'
}

const formatDateOnly = (dateString) => {
  if (!dateString) return '-'
  const d = new Date(dateString)
  return d.toLocaleDateString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  })
}

const getInitials = (name) => {
  if (!name) return 'A'
  return name.charAt(0).toUpperCase()
}

const handleClickOutside = (e) => {
  if (filterPanelRef.value && !filterPanelRef.value.contains(e.target)) {
    isFilterPanelOpen.value = false
  }
  if (spbuDropdownContainerRef.value && !spbuDropdownContainerRef.value.contains(e.target)) {
    isSpbuOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

<template>
  <div class="bg-gradient-to-br from-[#103427] via-[#143d2e] to-[#0d2b20] rounded-[2rem] p-5 md:p-6 text-white shadow-xl shadow-green-900/10 border border-emerald-800/40 relative flex flex-col space-y-4">

    <!-- Background Glow Effect -->
    <div class="absolute top-0 right-0 w-64 h-64 bg-emerald-500/5 rounded-full blur-3xl pointer-events-none"></div>

    <!-- Filter Bar Header (Search + Popover Filter Button) -->
    <div class="space-y-3 relative z-40 border-b border-emerald-800/40 pb-4">
      <div class="flex flex-col sm:flex-row items-center gap-2.5">

        <!-- 1. Search Input (Plat Nomor) -->
        <div class="relative w-full sm:flex-1">
          <input
            :value="searchQuery"
            @input="$emit('update:searchQuery', $event.target.value)"
            type="text"
            placeholder="Cari Plat Nomor..."
            class="w-full pl-9 pr-4 py-2.5 bg-white/10 hover:bg-white/20 border border-white/15 focus:border-white focus:ring-2 focus:ring-white/20 focus:outline-none rounded-full text-xs font-bold text-white placeholder-green-200/60 transition-all shadow-sm"
          />
          <span class="absolute left-3 top-3 text-green-300 pointer-events-none">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
              <path stroke-linecap="round" stroke-linejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" />
            </svg>
          </span>
        </div>

        <!-- 2. "Filter" Dropdown Toggle Button + Floating Popover -->
        <div ref="filterPanelRef" class="relative w-full sm:w-auto shrink-0">
          <button
            type="button"
            @click="toggleFilterPanel"
            :class="[
              'w-full sm:w-auto px-4 py-2.5 rounded-full text-xs font-extrabold transition-all cursor-pointer flex items-center justify-between sm:justify-start gap-2.5 border select-none shadow-sm',
              isFilterPanelOpen || activeFilterCount > 0
                ? 'bg-emerald-500/20 border-emerald-400/50 text-emerald-200'
                : 'bg-white/10 hover:bg-white/20 border-white/15 text-white'
            ]"
          >
            <div class="flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4 text-green-300 shrink-0">
                <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 6h9.75M10.5 6a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0m-9.75 0h9.75" />
              </svg>
              <span>Filter</span>
            </div>

            <div class="flex items-center gap-2">
              <span
                v-if="activeFilterCount > 0"
                class="w-5 h-5 rounded-full bg-emerald-400 text-emerald-950 text-[10px] font-black flex items-center justify-center shrink-0 shadow-2xs"
              >
                {{ activeFilterCount }}
              </span>

              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" :class="['w-3.5 h-3.5 text-green-200/70 transition-transform duration-200 shrink-0', isFilterPanelOpen ? 'rotate-180 text-white' : '']">
                <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
              </svg>
            </div>
          </button>

          <!-- Collapsible Floating Filter Panel Card -->
          <div
            v-if="isFilterPanelOpen"
            class="absolute top-full right-0 mt-2 w-full sm:w-[380px] max-w-[calc(100vw-2.5rem)] bg-[#143d2e] border border-emerald-700/60 rounded-2xl p-4 sm:p-5 shadow-2xl z-[100] space-y-5 animate-enter text-white text-xs font-bold"
          >
            <!-- Panel Header -->
            <div class="flex items-center justify-between pb-3 border-b border-emerald-800/60">
              <div class="flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4 text-emerald-400">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 6h9.75M10.5 6a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0m-9.75 0h9.75" />
                </svg>
                <span class="text-sm font-black text-white">Filter Transaksi Berulang</span>
              </div>

              <button
                type="button"
                @click="isFilterPanelOpen = false"
                class="w-7 h-7 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white/80 transition-colors"
              >
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <!-- Filter Option 1: SPBU Selection -->
            <div class="space-y-2.5">
              <label class="text-[10px] font-extrabold uppercase tracking-wider text-emerald-200/80 block">Lokasi SPBU</label>
              <div ref="spbuDropdownContainerRef" class="relative">
                <button
                  type="button"
                  @click="toggleSpbuDropdown"
                  class="w-full flex items-center justify-between gap-2 bg-white/10 hover:bg-white/20 border border-white/15 focus:border-white focus:ring-2 focus:ring-white/20 rounded-xl px-3.5 py-2.5 text-xs font-bold text-white transition-all cursor-pointer select-none"
                >
                  <span class="truncate">{{ selectedSpbuName }}</span>
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" :class="['w-3.5 h-3.5 text-green-200/70 transition-transform duration-200 shrink-0', isSpbuOpen ? 'rotate-180 text-white' : '']">
                    <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
                  </svg>
                </button>

                <!-- SPBU Menu Card -->
                <div
                  v-if="isSpbuOpen"
                  class="absolute left-0 mt-1 w-full bg-white rounded-xl shadow-2xl border border-gray-100 p-1 z-[110] text-gray-800 text-xs font-bold space-y-0.5 max-h-48 overflow-y-auto"
                >
                  <button
                    type="button"
                    @click="selectSpbuOption('')"
                    :class="[
                      'w-full flex items-center justify-between px-3 py-2 rounded-lg transition-all text-left cursor-pointer',
                      selectedSpbu === '' ? 'bg-[#143d2e]/10 text-[#143d2e] font-black' : 'hover:bg-gray-100 text-gray-700'
                    ]"
                  >
                    <span>Semua SPBU</span>
                    <svg v-if="selectedSpbu === ''" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="3" stroke="currentColor" class="w-3.5 h-3.5 text-[#143d2e]">
                      <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                    </svg>
                  </button>

                  <button
                    v-for="spbu in spbuList"
                    :key="spbu.id"
                    type="button"
                    @click="selectSpbuOption(spbu.id)"
                    :class="[
                      'w-full flex items-center justify-between px-3 py-2 rounded-lg transition-all text-left cursor-pointer',
                      String(selectedSpbu) === String(spbu.id) ? 'bg-[#143d2e]/10 text-[#143d2e] font-black' : 'hover:bg-gray-100 text-gray-700'
                    ]"
                  >
                    <span class="truncate">{{ spbu.nama }} ({{ spbu.id }})</span>
                    <svg v-if="String(selectedSpbu) === String(spbu.id)" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="3" stroke="currentColor" class="w-3.5 h-3.5 text-[#143d2e] shrink-0">
                      <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>

            <!-- Filter Option 2: Date Range (Baris Masing-Masing) -->
            <div class="space-y-2.5">
              <label class="text-[10px] font-extrabold uppercase tracking-wider text-emerald-200/80 block">Rentang Tanggal</label>
              <div class="flex flex-col space-y-2.5">
                <CustomDatePicker
                  :modelValue="dateFrom"
                  @update:modelValue="$emit('update:dateFrom', $event)"
                  label="Dari"
                  placeholder="Pilih Tanggal"
                  variant="dark"
                />
                <CustomDatePicker
                  :modelValue="dateTo"
                  @update:modelValue="$emit('update:dateTo', $event)"
                  label="Sampai"
                  placeholder="Pilih Tanggal"
                  variant="dark"
                />
              </div>
            </div>

            <!-- Panel Footer Actions (Reset Filter on the right side) -->
            <div class="flex items-center justify-end pt-3 border-t border-emerald-800/60">
              <button
                @click="$emit('resetFilters')"
                class="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-red-500/20 hover:bg-red-500/30 text-red-300 border border-red-400/30 text-xs font-bold transition-all cursor-pointer shadow-sm"
              >
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5 text-red-400">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
                </svg>
                <span>Reset Filter</span>
              </button>
            </div>

          </div>
        </div>

      </div>
    </div>

    <!-- Accordion List Container -->
    <div class="space-y-3 relative z-0">

      <!-- Loading Skeleton -->
      <template v-if="loading && repeatedLogs.length === 0">
        <div v-for="n in 2" :key="n" class="h-20 bg-white/10 rounded-2xl animate-pulse"></div>
      </template>

      <!-- Empty State -->
      <template v-else-if="repeatedLogs.length === 0">
        <div class="flex flex-col items-center justify-center py-12 text-center space-y-3">
          <div class="w-14 h-14 rounded-2xl bg-emerald-900/60 border border-emerald-700/50 text-emerald-300 flex items-center justify-center shadow-lg">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-7 h-7">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751A11.959 11.959 0 0 1 12 2.714Z" />
            </svg>
          </div>
          <div>
            <p class="text-base font-extrabold text-white">Sistem Aman & Terkendali</p>
            <p class="text-xs font-semibold text-emerald-200/70 mt-1">Tidak ada percobaan transaksi berulang / over-quota yang terdeteksi saat ini.</p>
          </div>
        </div>
      </template>

      <!-- Plate Accordion Cards -->
      <template v-else>
        <div
          v-for="(item, index) in repeatedLogs"
          :key="item.plat_nomor"
          class="bg-[#184635]/90 border border-emerald-800/60 rounded-2xl overflow-hidden shadow-md transition-all duration-200"
        >
          <!-- Accordion Header Bar -->
          <div
            @click="togglePlate(item.plat_nomor)"
            class="p-4 flex items-center justify-between gap-4 cursor-pointer hover:bg-white/5 transition-colors select-none"
          >
            <!-- Left: License Plate -->
            <div class="flex items-center gap-3">
              <h3 class="text-lg md:text-xl font-black font-mono tracking-wider text-white">
                {{ normalizePlate(item.plat_nomor) }}
              </h3>
            </div>

            <!-- Right: Warning Pill + Chevron Toggle -->
            <div class="flex items-center gap-3">
              <div class="px-3 py-1 rounded-full bg-red-950/70 border border-red-700/60 text-red-300 text-xs font-extrabold flex items-center gap-1.5 shadow-2xs">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5 text-red-400">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
                </svg>
                <span>{{ item.attempt_count }}x</span>
              </div>

              <button
                type="button"
                class="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white/80 transition-transform duration-200"
                :class="isExpanded(item.plat_nomor, index) ? 'rotate-180 bg-white/20' : ''"
              >
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="3" stroke="currentColor" class="w-4 h-4">
                  <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
                </svg>
              </button>
            </div>
          </div>

          <!-- Expanded Accordion Content -->
          <div
            v-if="isExpanded(item.plat_nomor, index)"
            class="px-4 pb-4 pt-1 border-t border-emerald-800/40 bg-[#0e2e23]/90"
          >
            <!-- Mobile View: Compact Responsive Cards -->
            <div class="block md:hidden space-y-2.5 pt-2">
              <div
                v-for="attempt in item.attempts"
                :key="attempt.id"
                class="bg-emerald-950/70 border border-emerald-800/40 rounded-xl p-3 space-y-2.5 text-xs"
              >
                <!-- Top Row: Jam, Badge Tipe Transaksi & Tanggal -->
                <div class="flex items-center justify-between gap-2 border-b border-emerald-900/50 pb-2">
                  <div class="flex items-center gap-2">
                    <span class="text-emerald-200/90 text-[11px] font-bold font-mono">
                      {{ formatTimeOnly(attempt.created_at) }}
                    </span>
                    <span
                      :class="[
                        'text-[10px] font-extrabold px-2 py-0.5 rounded-full border transition-all',
                        attempt.is_ojol
                          ? 'bg-emerald-900/70 text-emerald-300 border-emerald-600/40'
                          : 'bg-white/10 text-gray-200 border-white/15'
                      ]"
                    >
                      {{ attempt.is_ojol ? 'Ojol' : 'Biasa' }}
                    </span>
                  </div>
                  <span class="text-emerald-200/80 text-[11px] font-bold">
                    {{ formatDateOnly(attempt.created_at) }}
                  </span>
                </div>

                <!-- Bottom Row: SPBU & Operator -->
                <div class="grid grid-cols-2 gap-2 text-emerald-100 font-semibold text-[11px] pt-1">
                  <div class="flex items-center gap-1.5 truncate">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3.5 h-3.5 text-emerald-400 shrink-0">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
                      <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1 1 15 0Z" />
                    </svg>
                    <span class="truncate">{{ attempt.spbu_nama }}</span>
                  </div>

                  <div class="flex items-center gap-1.5 truncate">
                    <div class="w-4 h-4 rounded-full bg-emerald-800 text-emerald-200 flex items-center justify-center text-[9px] font-black shrink-0">
                      {{ getInitials(attempt.operator_nama) }}
                    </div>
                    <span class="uppercase truncate">{{ attempt.operator_nama }}</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Desktop View: Clean Table -->
            <div class="hidden md:block overflow-x-auto">
              <table class="w-full text-left border-collapse min-w-[600px]">
                <thead>
                  <tr class="text-[10px] font-black uppercase tracking-wider text-emerald-300/60 border-b border-emerald-800/30">
                    <th class="py-2.5 px-3">JAM (WITA)</th>
                    <th class="py-2.5 px-3">KATEGORI</th>
                    <th class="py-2.5 px-3">LOKASI SPBU</th>
                    <th class="py-2.5 px-3">OPERATOR BERTUGAS</th>
                    <th class="py-2.5 px-3 text-right">TANGGAL</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-emerald-800/20 text-xs font-semibold">
                  <tr
                    v-for="attempt in item.attempts"
                    :key="attempt.id"
                    class="hover:bg-white/5 transition-colors"
                  >
                    <!-- JAM (WITA) -->
                    <td class="py-3 px-3 whitespace-nowrap text-emerald-200/90 font-bold text-xs font-mono">
                      {{ formatTimeOnly(attempt.created_at) }}
                    </td>

                    <!-- KATEGORI -->
                    <td class="py-3 px-3 whitespace-nowrap">
                      <span
                        :class="[
                          'text-[10px] font-extrabold px-2.5 py-0.5 rounded-full border transition-all',
                          attempt.is_ojol
                            ? 'bg-emerald-900/70 text-emerald-300 border-emerald-600/40'
                            : 'bg-white/10 text-gray-200 border-white/15'
                        ]"
                      >
                        {{ attempt.is_ojol ? 'Ojol' : 'Biasa' }}
                      </span>
                    </td>

                    <!-- LOKASI SPBU -->
                    <td class="py-3 px-3 whitespace-nowrap">
                      <div class="flex items-center gap-1.5 text-emerald-100 font-bold">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-emerald-400 shrink-0">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
                          <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1 1 15 0Z" />
                        </svg>
                        <span>{{ attempt.spbu_nama }}</span>
                      </div>
                    </td>

                    <!-- OPERATOR BERTUGAS -->
                    <td class="py-3 px-3 whitespace-nowrap">
                      <div class="flex items-center gap-2 text-emerald-100 font-bold">
                        <div class="w-5 h-5 rounded-full bg-emerald-800 text-emerald-200 flex items-center justify-center text-[10px] font-black shrink-0">
                          {{ getInitials(attempt.operator_nama) }}
                        </div>
                        <span class="uppercase">{{ attempt.operator_nama }}</span>
                      </div>
                    </td>

                    <!-- TANGGAL -->
                    <td class="py-3 px-3 text-right whitespace-nowrap text-emerald-200/90 font-bold">
                      {{ formatDateOnly(attempt.created_at) }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

        </div>
      </template>

    </div>

    <!-- Card Footer -->
    <div class="flex flex-col sm:flex-row items-center justify-between gap-3 pt-3 border-t border-emerald-800/40 text-xs font-semibold text-emerald-200/70 relative z-10">
      <p>
        Menampilkan {{ repeatedLogs.length }} plat unik dari {{ totalCount }} total percobaan
      </p>

      <div class="flex items-center gap-2">
        <button
          type="button"
          disabled
          class="px-4 py-1.5 rounded-full bg-white/10 text-white/50 text-xs font-bold cursor-not-allowed select-none"
        >
          Prev
        </button>
        <button
          type="button"
          disabled
          class="px-4 py-1.5 rounded-full bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 text-xs font-bold cursor-not-allowed select-none"
        >
          Next
        </button>
      </div>
    </div>
  </div>
</template>
