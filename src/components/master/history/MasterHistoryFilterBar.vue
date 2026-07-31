<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
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
const isSpbuOpen = ref(false)
const isSortOpen = ref(false)

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

const handleClickOutside = (e) => {
  if (filterBarRef.value && !filterBarRef.value.contains(e.target)) {
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
  <div ref="filterBarRef" class="space-y-3 mb-6">
    <!-- Filter Controls Bar -->
    <div class="flex flex-col sm:flex-row sm:flex-wrap items-stretch sm:items-center gap-3">

      <!-- Custom SPBU Filter Dropdown -->
      <div class="relative flex-1 min-w-[180px]">
        <button
          type="button"
          @click="toggleSpbuDropdown"
          class="w-full flex items-center justify-between gap-2 bg-white/10 hover:bg-white/20 border border-white/15 focus:border-white focus:ring-2 focus:ring-white/20 rounded-full px-4 py-2 text-xs font-bold text-white transition-all cursor-pointer select-none shadow-sm"
        >
          <div class="flex items-center gap-2 min-w-0">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-green-300 shrink-0">
              <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 21v-7.5a.75.75 0 0 1 .75-.75h3a.75.75 0 0 1 .75.75V21m-4.5 0H2.25a.75.75 0 0 1-.75-.75V4.5a.75.75 0 0 1 .75-.75h19.5a.75.75 0 0 1 .75.75v15.75a.75.75 0 0 1-.75.75H18m-4.5 0v-7.5" />
            </svg>
            <span class="text-green-200/80 uppercase text-[10px] tracking-wider font-extrabold shrink-0">SPBU</span>
            <span class="text-white font-bold truncate">{{ selectedSpbuLabel }}</span>
          </div>
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" :class="['w-3.5 h-3.5 text-green-200/70 transition-transform duration-200 shrink-0', isSpbuOpen ? 'rotate-180 text-white' : '']">
            <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
          </svg>
        </button>

        <!-- Dropdown Menu Card -->
        <div
          v-if="isSpbuOpen"
          class="absolute left-0 mt-2 w-full sm:w-64 bg-white rounded-2xl shadow-2xl border border-gray-100 p-1.5 z-50 animate-enter text-gray-800 text-xs font-bold space-y-0.5"
        >
          <button
            type="button"
            @click="selectSpbuOption('')"
            :class="[
              'w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl transition-all text-left cursor-pointer',
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
              'w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl transition-all text-left cursor-pointer',
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

      <!-- Date From -->
      <CustomDatePicker
        :modelValue="dateFrom"
        @update:modelValue="$emit('update:dateFrom', $event)"
        label="Dari"
        placeholder="Pilih Tanggal"
        variant="dark"
      />

      <!-- Date To -->
      <CustomDatePicker
        :modelValue="dateTo"
        @update:modelValue="$emit('update:dateTo', $event)"
        label="Sampai"
        placeholder="Pilih Tanggal"
        variant="dark"
      />

      <!-- Custom Sort Filter Dropdown -->
      <div class="relative flex-1 min-w-[150px]">
        <button
          type="button"
          @click="toggleSortDropdown"
          class="w-full flex items-center justify-between gap-2 bg-white/10 hover:bg-white/20 border border-white/15 focus:border-white focus:ring-2 focus:ring-white/20 rounded-full px-4 py-2 text-xs font-bold text-white transition-all cursor-pointer select-none shadow-sm"
        >
          <div class="flex items-center gap-1.5 min-w-0">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-green-300 shrink-0">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3 7.5 7.5 3m0 0L12 7.5M7.5 3v13.5m13.5 0L16.5 21m0 0L12 16.5m4.5 4.5V7.5" />
            </svg>
            <span class="text-green-200/80 uppercase text-[10px] tracking-wider font-extrabold shrink-0">Urut:</span>
            <span class="text-white font-bold truncate">{{ currentSortLabel }}</span>
          </div>
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" :class="['w-3.5 h-3.5 text-green-200/70 transition-transform duration-200 shrink-0', isSortOpen ? 'rotate-180 text-white' : '']">
            <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
          </svg>
        </button>

        <!-- Sort Menu Card -->
        <div
          v-if="isSortOpen"
          class="absolute right-0 mt-2 w-48 bg-white rounded-2xl shadow-2xl border border-gray-100 p-1.5 z-50 animate-enter text-gray-800 text-xs font-bold space-y-0.5"
        >
          <button
            v-for="opt in SORT_OPTIONS"
            :key="opt.label"
            type="button"
            @click="selectSortOption(opt)"
            :class="[
              'w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl transition-all text-left cursor-pointer',
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

      <!-- Search Input (Posisi Paling Kanan) -->
      <div class="relative flex-1 min-w-[200px]">
        <input 
          :value="searchQuery"
          @input="$emit('update:searchQuery', $event.target.value)"
          type="text" 
          placeholder="Cari Plat Nomor..." 
          class="w-full pl-9 pr-4 py-2 bg-white/10 hover:bg-white/20 border border-white/15 focus:border-white focus:ring-2 focus:ring-white/20 focus:outline-none rounded-full text-xs font-bold text-white placeholder-green-200/60 transition-all shadow-sm"
        />
        <span class="absolute left-3 top-2.5 text-green-300 pointer-events-none">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" />
          </svg>
        </span>
      </div>

    </div>

    <!-- Active Filter Badges & Reset Button Row -->
    <div v-if="activeFilters.length > 0" class="flex flex-wrap items-center gap-2 pt-1">
      <span
        v-for="f in activeFilters"
        :key="f.key"
        class="inline-flex items-center gap-1.5 bg-white/15 text-white text-[11px] font-bold px-3 py-1 rounded-full border border-white/20 shadow-xs"
      >
        {{ f.label }}
        <button @click="$emit('removeFilter', f.key)" class="hover:text-red-300 transition-colors cursor-pointer">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3 h-3">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
          </svg>
        </button>
      </span>

      <!-- Reset Filter Button (Placed next to active filter badges) -->
      <button
        @click="$emit('resetFilters')"
        class="inline-flex items-center gap-1.5 bg-red-500/20 border border-red-400/30 hover:bg-red-500/30 text-red-200 text-[11px] font-bold px-3 py-1 rounded-full transition-all cursor-pointer shadow-xs ml-auto sm:ml-1"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3 h-3">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
        </svg>
        Reset
      </button>
    </div>
  </div>
</template>
