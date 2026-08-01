<script setup>
import { ref, computed } from 'vue'

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

const onSortSelectChange = (e) => {
  const [field, dir] = e.target.value.split(':')
  emit('update:sortField', field)
  emit('update:sortDir', dir)
}
</script>

<template>
  <div class="flex flex-col sm:flex-row justify-between items-center gap-3">

    <!-- Search Input -->
    <div class="relative w-full sm:w-72">
      <input 
        :value="modelValue"
        @input="$emit('update:modelValue', $event.target.value)"
        type="text" 
        placeholder="Cari Plat, Operator, atau Jam (14:30)..." 
        class="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl text-xs font-bold focus:outline-none focus:ring-2 focus:ring-[#143d2e]/15 focus:border-[#143d2e] focus:bg-white transition-all shadow-2xs"
      />
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-gray-400 absolute left-3.5 top-2.5">
        <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
      </svg>
    </div>

    <!-- Vehicle Type Chips (Semua, Ojol, Biasa) -->
    <div class="flex items-center justify-center sm:justify-end gap-1 bg-gray-50 border border-gray-200 rounded-xl p-1 shadow-2xs w-full sm:w-auto">
      <button
        v-for="opt in [
          { val: '', label: 'Semua' },
          { val: 'ojol', label: 'Ojol' },
          { val: 'non_ojol', label: 'Biasa' }
        ]"
        :key="opt.val"
        @click="$emit('update:vehicleFilter', opt.val)"
        :class="[
          'px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer select-none flex-1 sm:flex-initial text-center',
          vehicleFilter === opt.val
            ? 'bg-[#143d2e] text-white shadow-xs'
            : 'text-gray-500 hover:text-gray-800 hover:bg-gray-200/60'
        ]"
      >
        {{ opt.label }}
      </button>
    </div>

  </div>
</template>