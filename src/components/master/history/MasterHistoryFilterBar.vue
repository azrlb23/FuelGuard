<script setup>
import { ref } from 'vue'

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
  activeFilters: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits([
  'update:selectedSpbu',
  'update:dateFrom',
  'update:dateTo',
  'sortChange',
  'resetFilters',
  'removeFilter'
])

const dateFromRef = ref(null)
const dateToRef = ref(null)

const triggerDateFrom = () => {
  if (dateFromRef.value) {
    if (typeof dateFromRef.value.showPicker === 'function') {
      dateFromRef.value.showPicker()
    } else {
      dateFromRef.value.focus()
      dateFromRef.value.click()
    }
  }
}

const triggerDateTo = () => {
  if (dateToRef.value) {
    if (typeof dateToRef.value.showPicker === 'function') {
      dateToRef.value.showPicker()
    } else {
      dateToRef.value.focus()
      dateToRef.value.click()
    }
  }
}

const onSortSelectChange = (e) => {
  emit('sortChange', e.target.value)
}
</script>

<template>
  <div class="space-y-3">
    <!-- Filter Controls Bar -->
    <div class="bg-white rounded-2xl p-3.5 sm:p-4 border border-gray-200/90 shadow-xs flex flex-col sm:flex-row sm:flex-wrap items-stretch sm:items-center gap-3">

      <!-- SPBU Filter Dropdown -->
      <div class="group relative flex items-center gap-2 bg-gray-50/90 hover:bg-gray-100/90 border border-gray-200/90 focus-within:border-[#143d2e] focus-within:ring-2 focus-within:ring-[#143d2e]/15 focus-within:bg-white rounded-full px-4 py-2 text-xs font-bold text-gray-700 flex-1 min-w-[180px] transition-all cursor-pointer select-none shadow-2xs">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-[#143d2e] group-hover:scale-110 transition-transform shrink-0">
          <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 21v-7.5a.75.75 0 0 1 .75-.75h3a.75.75 0 0 1 .75.75V21m-4.5 0H2.25a.75.75 0 0 1-.75-.75V4.5a.75.75 0 0 1 .75-.75h19.5a.75.75 0 0 1 .75.75v15.75a.75.75 0 0 1-.75.75H18m-4.5 0v-7.5" />
        </svg>
        <span class="text-[#143d2e]/60 uppercase text-[10px] tracking-wider font-extrabold shrink-0">SPBU</span>
        <span class="text-gray-800 font-bold max-w-[140px] truncate">{{ selectedSpbuLabel }}</span>
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5 text-gray-400 absolute right-4 pointer-events-none group-hover:text-[#143d2e] transition-colors">
          <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
        </svg>
        <select
          :value="selectedSpbu"
          @change="$emit('update:selectedSpbu', $event.target.value)"
          class="appearance-none bg-transparent outline-none text-gray-800 font-bold text-xs sm:text-sm cursor-pointer w-full pr-6 truncate z-10 opacity-0 absolute inset-0"
        >
          <option value="">Semua SPBU</option>
          <option v-for="spbu in spbuList" :key="spbu.id" :value="spbu.id">
            {{ spbu.nama }}
          </option>
        </select>
      </div>

      <!-- Date From -->
      <div
        @click="triggerDateFrom"
        class="group relative flex items-center gap-2.5 bg-gray-50/90 hover:bg-gray-100/90 border border-gray-200/90 focus-within:border-[#143d2e] focus-within:ring-2 focus-within:ring-[#143d2e]/15 focus-within:bg-white rounded-full px-4 py-2 text-xs font-bold text-gray-700 flex-1 min-w-[150px] transition-all cursor-pointer select-none shadow-2xs"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-[#143d2e] group-hover:scale-110 transition-transform shrink-0">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
        </svg>
        <span class="text-[#143d2e]/60 uppercase text-[10px] tracking-wider font-extrabold shrink-0">Dari</span>
        <input
          ref="dateFromRef"
          :value="dateFrom"
          @input="$emit('update:dateFrom', $event.target.value)"
          type="date"
          class="bg-transparent outline-none text-gray-800 font-bold text-xs sm:text-sm cursor-pointer w-full"
          @click.stop
        />
      </div>

      <!-- Date To -->
      <div
        @click="triggerDateTo"
        class="group relative flex items-center gap-2.5 bg-gray-50/90 hover:bg-gray-100/90 border border-gray-200/90 focus-within:border-[#143d2e] focus-within:ring-2 focus-within:ring-[#143d2e]/15 focus-within:bg-white rounded-full px-4 py-2 text-xs font-bold text-gray-700 flex-1 min-w-[150px] transition-all cursor-pointer select-none shadow-2xs"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-[#143d2e] group-hover:scale-110 transition-transform shrink-0">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
        </svg>
        <span class="text-[#143d2e]/60 uppercase text-[10px] tracking-wider font-extrabold shrink-0">Sampai</span>
        <input
          ref="dateToRef"
          :value="dateTo"
          @input="$emit('update:dateTo', $event.target.value)"
          type="date"
          class="bg-transparent outline-none text-gray-800 font-bold text-xs sm:text-sm cursor-pointer w-full"
          @click.stop
        />
      </div>

      <!-- Sort Dropdown -->
      <div class="group relative flex items-center gap-1.5 bg-gray-50/90 hover:bg-gray-100/90 border border-gray-200/90 focus-within:border-[#143d2e] focus-within:ring-2 focus-within:ring-[#143d2e]/15 focus-within:bg-white rounded-full px-4 py-2 text-xs font-bold text-gray-700 flex-1 min-w-[150px] transition-all cursor-pointer select-none shadow-2xs">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-[#143d2e] group-hover:scale-110 transition-transform shrink-0">
          <path stroke-linecap="round" stroke-linejoin="round" d="M3 7.5 7.5 3m0 0L12 7.5M7.5 3v13.5m13.5 0L16.5 21m0 0L12 16.5m4.5 4.5V7.5" />
        </svg>
        <span class="text-[#143d2e]/60 uppercase text-[10px] tracking-wider font-extrabold shrink-0">Urut:</span>
        <span class="text-gray-800 font-bold truncate">{{ currentSortLabel }}</span>
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5 text-gray-400 absolute right-4 pointer-events-none group-hover:text-[#143d2e] transition-colors">
          <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
        </svg>
        <select
          :value="`${sortField}:${sortDir}`"
          @change="onSortSelectChange"
          class="absolute inset-0 opacity-0 w-full h-full cursor-pointer z-10"
        >
          <option v-for="opt in SORT_OPTIONS" :key="opt.label" :value="`${opt.field}:${opt.dir}`">
            {{ opt.label }}
          </option>
        </select>
      </div>

      <!-- Reset Filter Button -->
      <button
        v-if="activeFilters.length > 0"
        @click="$emit('resetFilters')"
        class="sm:ml-auto flex items-center justify-center gap-1.5 bg-red-50 border border-red-200 rounded-full px-4 py-2 text-xs font-bold text-red-500 hover:bg-red-100 transition-all cursor-pointer shadow-2xs self-end sm:self-center"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
        </svg>
        Reset
      </button>

    </div>

    <!-- Active Filter Badges -->
    <div v-if="activeFilters.length > 0" class="flex flex-wrap gap-2">
      <span
        v-for="f in activeFilters"
        :key="f.key"
        class="inline-flex items-center gap-1.5 bg-[#143d2e]/10 text-[#143d2e] text-[11px] font-bold px-3 py-1 rounded-full border border-[#143d2e]/20"
      >
        {{ f.label }}
        <button @click="$emit('removeFilter', f.key)" class="hover:text-red-500 transition-colors cursor-pointer">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3 h-3">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
          </svg>
        </button>
      </span>
    </div>
  </div>
</template>
