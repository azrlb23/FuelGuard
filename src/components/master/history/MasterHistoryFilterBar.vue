<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import CustomDatePicker from '@/components/common/CustomDatePicker.vue'

const props = defineProps({
  spbuList: {
    type: Array,
    default: () => []
  },
  selectedSpbu: {
    type: [String, Number],
    default: ''
  },
  selectedSpbuLabel: {
    type: String,
    default: 'Semua SPBU'
  },
  dateFrom: {
    type: String,
    default: ''
  },
  dateTo: {
    type: String,
    default: ''
  },
  sortField: {
    type: String,
    default: 'waktu_pencatatan'
  },
  sortDir: {
    type: String,
    default: 'desc'
  },
  currentSortLabel: {
    type: String,
    default: 'Terbaru'
  },
  SORT_OPTIONS: {
    type: Array,
    required: true
  },
  searchQuery: {
    type: String,
    default: ''
  },
  activeFilters: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits([
  'update:searchQuery',
  'update:selectedSpbu',
  'update:dateFrom',
  'update:dateTo',
  'sortChange',
  'resetFilters',
  'removeFilter'
])

const filterBarRef = ref(null)
const isFilterPanelOpen = ref(false)
const isSpbuOpen = ref(false)
const isSortOpen = ref(false)

const toggleFilterPanel = () => {
  isFilterPanelOpen.value = !isFilterPanelOpen.value
}

const toggleSpbuDropdown = () => {
  isSpbuOpen.value = !isSpbuOpen.value
  isSortOpen.value = false
}

const toggleSortDropdown = () => {
  isSortOpen.value = !isSortOpen.value
  isSpbuOpen.value = false
}

const selectSpbuOption = (id) => {
  emit('update:selectedSpbu', id)
  isSpbuOpen.value = false
}

const selectSortOption = (opt) => {
  emit('sortChange', `${opt.field}:${opt.dir}`)
  isSortOpen.value = false
}

const activeFilterCount = computed(() => {
  let count = 0
  if (props.selectedSpbu) count++
  if (props.dateFrom) count++
  if (props.dateTo) count++
  if (props.sortField !== 'waktu_pencatatan' || props.sortDir !== 'desc') count++
  return count
})

const handleClickOutside = (e) => {
  if (filterBarRef.value && !filterBarRef.value.contains(e.target)) {
    isFilterPanelOpen.value = false
    isSpbuOpen.value = false
    isSortOpen.value = false
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
  <div ref="filterBarRef" class="relative z-40 mb-6 space-y-2">
    <!-- Always Visible Header Bar (Mobile: 2 Baris, Desktop: 1 Baris) -->
    <div class="flex flex-col sm:flex-row items-center gap-2.5">

      <!-- 1. Search Input (Plat Nomor) -->
      <div class="relative w-full sm:flex-1">
        <input
          :value="searchQuery"
          @input="$emit('update:searchQuery', $event.target.value)"
          type="text"
          placeholder="Cari Plat Nomor..."
          class="w-full pl-9 pr-9 py-2.5 bg-white/10 hover:bg-white/20 border border-white/15 focus:border-white focus:ring-2 focus:ring-white/20 focus:outline-none rounded-full text-xs font-bold text-white placeholder-green-200/60 transition-all shadow-sm"
        />
        <span class="absolute left-3 top-3 text-green-300 pointer-events-none">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" />
          </svg>
        </span>
        <button
          v-if="searchQuery"
          type="button"
          @click="$emit('update:searchQuery', '')"
          class="absolute right-3 top-2.5 text-green-200/70 hover:text-white transition-colors cursor-pointer"
          title="Hapus pencarian"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <!-- 2. "Filter & Urutkan" Dropdown Button + Floating Popover -->
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
            <!-- Active Filter Badge Counter -->
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

        <!-- Collapsible Floating Filter Panel Card (Anchored to button) -->
        <div
          v-if="isFilterPanelOpen"
          class="absolute top-full left-0 right-0 sm:left-auto sm:right-0 mt-2 w-full sm:w-[380px] max-w-[calc(100vw-2.5rem)] bg-[#143d2e] border border-emerald-700/60 rounded-2xl p-4 sm:p-5 shadow-2xl z-[100] space-y-5 animate-enter text-white text-xs font-bold"
        >
          <!-- Panel Header -->
          <div class="flex items-center justify-between pb-3 border-b border-emerald-800/60">
            <div class="flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4 text-emerald-400">
                <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 6h9.75M10.5 6a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0m-9.75 0h9.75" />
              </svg>
              <span class="text-sm font-black text-white">Filter & Pengurutan</span>
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
            <div class="relative">
              <button
                type="button"
                @click="toggleSpbuDropdown"
                class="w-full flex items-center justify-between gap-2 bg-white/10 hover:bg-white/20 border border-white/15 focus:border-white focus:ring-2 focus:ring-white/20 rounded-xl px-3.5 py-2.5 text-xs font-bold text-white transition-all cursor-pointer select-none"
              >
                <span class="truncate">{{ selectedSpbuLabel }}</span>
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
                  <span class="truncate">{{ spbu.nama }}</span>
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

          <!-- Filter Option 3: Sorting Options -->
          <div class="space-y-2.5">
            <label class="text-[10px] font-extrabold uppercase tracking-wider text-emerald-200/80 block">Urutkan Berdasarkan</label>
            <div class="relative">
              <button
                type="button"
                @click="toggleSortDropdown"
                class="w-full flex items-center justify-between gap-2 bg-white/10 hover:bg-white/20 border border-white/15 focus:border-white focus:ring-2 focus:ring-white/20 rounded-xl px-3.5 py-2.5 text-xs font-bold text-white transition-all cursor-pointer select-none"
              >
                <span>{{ currentSortLabel }}</span>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" :class="['w-3.5 h-3.5 text-green-200/70 transition-transform duration-200 shrink-0', isSortOpen ? 'rotate-180 text-white' : '']">
                  <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
                </svg>
              </button>

              <!-- Sort Options Card -->
              <div
                v-if="isSortOpen"
                class="absolute left-0 mt-1 w-full bg-white rounded-xl shadow-2xl border border-gray-100 p-1 z-[110] text-gray-800 text-xs font-bold space-y-0.5"
              >
                <button
                  v-for="opt in SORT_OPTIONS"
                  :key="opt.label"
                  type="button"
                  @click="selectSortOption(opt)"
                  :class="[
                    'w-full flex items-center justify-between px-3 py-2 rounded-lg transition-all text-left cursor-pointer',
                    sortField === opt.field && sortDir === opt.dir ? 'bg-[#143d2e]/10 text-[#143d2e] font-black' : 'hover:bg-gray-100 text-gray-700'
                  ]"
                >
                  <span>{{ opt.label }}</span>
                  <svg v-if="sortField === opt.field && sortDir === opt.dir" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="3" stroke="currentColor" class="w-3.5 h-3.5 text-[#143d2e] shrink-0">
                    <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                  </svg>
                </button>
              </div>
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
</template>
