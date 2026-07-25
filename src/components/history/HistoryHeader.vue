<script setup>
import { computed } from 'vue'

const props = defineProps({
  modelValue: String,
  vehicleFilter: { type: String, default: '' },
  dateFrom: { type: String, default: '' },
  dateTo: { type: String, default: '' },
  sortField: { type: String, default: 'waktu_pencatatan' },
  sortDir: { type: String, default: 'desc' },
})

const emit = defineEmits([
  'update:modelValue',
  'update:vehicleFilter',
  'update:dateFrom',
  'update:dateTo',
  'update:sortField',
  'update:sortDir',
  'reset'
])

const SORT_OPTIONS = [
  { label: 'Terbaru', field: 'waktu_pencatatan', dir: 'desc' },
  { label: 'Terlama', field: 'waktu_pencatatan', dir: 'asc' },
  { label: 'Harga ↑', field: 'harga', dir: 'asc' },
  { label: 'Harga ↓', field: 'harga', dir: 'desc' },
  { label: 'Liter ↑', field: 'liter', dir: 'asc' },
  { label: 'Liter ↓', field: 'liter', dir: 'desc' },
]

const currentSortLabel = computed(() => {
  const found = SORT_OPTIONS.find(
    o => o.field === props.sortField && o.dir === props.sortDir
  )
  return found ? found.label : 'Terbaru'
})

const activeFilters = computed(() => {
  const filters = []
  if (props.modelValue) filters.push({ key: 'search', label: `Plat: ${props.modelValue.toUpperCase()}` })
  if (props.vehicleFilter) filters.push({ key: 'vehicle', label: props.vehicleFilter })
  if (props.dateFrom) filters.push({ key: 'dateFrom', label: `Dari: ${props.dateFrom}` })
  if (props.dateTo) filters.push({ key: 'dateTo', label: `Sampai: ${props.dateTo}` })
  if (props.sortField !== 'waktu_pencatatan' || props.sortDir !== 'desc')
    filters.push({ key: 'sort', label: `Urut: ${currentSortLabel.value}` })
  return filters
})

const removeFilter = (key) => {
  if (key === 'search') emit('update:modelValue', '')
  if (key === 'vehicle') emit('update:vehicleFilter', '')
  if (key === 'dateFrom') emit('update:dateFrom', '')
  if (key === 'dateTo') emit('update:dateTo', '')
  if (key === 'sort') {
    emit('update:sortField', 'waktu_pencatatan')
    emit('update:sortDir', 'desc')
  }
}

const setSort = (field, dir) => {
  emit('update:sortField', field)
  emit('update:sortDir', dir)
}
</script>

<template>
  <div class="flex flex-col gap-4">
    
    <!-- Header Title -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-end gap-4">
      <div>
        <h2 class="text-3xl md:text-4xl font-extrabold text-black tracking-tight mb-1">Transaction History</h2>
        <p class="text-gray-500 text-sm font-bold">Rekapitulasi seluruh transaksi operasional</p>
      </div>

      <!-- Search -->
      <div class="relative w-full md:w-64">
        <input 
          :value="modelValue"
          @input="$emit('update:modelValue', $event.target.value)"
          type="text" 
          placeholder="Cari Plat Nomor..." 
          class="w-full pl-10 pr-4 py-2.5 rounded-full bg-white border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#143d2e] focus:border-transparent shadow-sm text-sm transition-all"
        />
        <span class="absolute left-3.5 top-2.5 text-gray-400">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
            <path stroke-linecap="round" stroke-linejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" />
          </svg>
        </span>
      </div>
    </div>

    <!-- Filter Bar -->
    <div class="flex flex-wrap items-center gap-2 md:gap-3">

      <!-- Vehicle Type Chips -->
      <div class="flex items-center gap-1 bg-white border border-gray-200 rounded-full p-1 shadow-sm">
        <button
          v-for="v in ['', 'Motor', 'Mobil']"
          :key="v"
          @click="$emit('update:vehicleFilter', v)"
          :class="[
            'px-3.5 py-1 rounded-full text-xs font-bold transition-all',
            vehicleFilter === v
              ? 'bg-[#143d2e] text-white shadow'
              : 'text-gray-500 hover:text-gray-800 hover:bg-gray-100'
          ]"
        >
          {{ v || 'Semua' }}
        </button>
      </div>

      <!-- Date From -->
      <div class="flex items-center gap-1.5 bg-white border border-gray-200 rounded-full px-3.5 py-1.5 shadow-sm text-xs font-bold text-gray-600">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3.5 h-3.5 text-gray-400 shrink-0">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
        </svg>
        <span class="text-gray-400">Dari</span>
        <input
          :value="dateFrom"
          @input="$emit('update:dateFrom', $event.target.value)"
          type="date"
          class="bg-transparent outline-none text-gray-700 font-bold text-xs cursor-pointer w-28"
        />
      </div>

      <!-- Date To -->
      <div class="flex items-center gap-1.5 bg-white border border-gray-200 rounded-full px-3.5 py-1.5 shadow-sm text-xs font-bold text-gray-600">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3.5 h-3.5 text-gray-400 shrink-0">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
        </svg>
        <span class="text-gray-400">Sampai</span>
        <input
          :value="dateTo"
          @input="$emit('update:dateTo', $event.target.value)"
          type="date"
          class="bg-transparent outline-none text-gray-700 font-bold text-xs cursor-pointer w-28"
        />
      </div>

      <!-- Sort Dropdown -->
      <div class="relative group">
        <button class="flex items-center gap-1.5 bg-white border border-gray-200 rounded-full px-3.5 py-1.5 shadow-sm text-xs font-bold text-gray-600 hover:border-gray-300 transition-all cursor-pointer">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3.5 h-3.5 text-gray-400">
            <path stroke-linecap="round" stroke-linejoin="round" d="M3 7.5 7.5 3m0 0L12 7.5M7.5 3v13.5m13.5 0L16.5 21m0 0L12 16.5m4.5 4.5V7.5" />
          </svg>
          {{ currentSortLabel }}
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3 h-3 text-gray-400">
            <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
          </svg>
        </button>
        <div class="absolute left-0 top-full mt-1 bg-white border border-gray-200 rounded-2xl shadow-lg z-20 py-1.5 min-w-[130px] hidden group-hover:block">
          <button
            v-for="opt in SORT_OPTIONS"
            :key="opt.label"
            @click="setSort(opt.field, opt.dir)"
            :class="[
              'w-full px-4 py-2 text-xs font-bold text-left transition-colors cursor-pointer',
              sortField === opt.field && sortDir === opt.dir
                ? 'bg-[#143d2e]/10 text-[#143d2e]'
                : 'text-gray-600 hover:bg-gray-50'
            ]"
          >
            {{ opt.label }}
          </button>
        </div>
      </div>

      <!-- Reset Button — tampil hanya jika ada filter aktif -->
      <button
        v-if="activeFilters.length > 0"
        @click="$emit('reset')"
        class="flex items-center gap-1.5 bg-red-50 border border-red-200 rounded-full px-3.5 py-1.5 text-xs font-bold text-red-500 hover:bg-red-100 transition-all cursor-pointer"
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
        <button @click="removeFilter(f.key)" class="hover:text-red-500 transition-colors cursor-pointer leading-none">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3 h-3">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
          </svg>
        </button>
      </span>
    </div>

  </div>
</template>