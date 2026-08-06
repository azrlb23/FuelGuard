<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import CustomDatePicker from '@/components/common/CustomDatePicker.vue'

const props = defineProps({
  dateFrom: {
    type: String,
    default: ''
  },
  dateTo: {
    type: String,
    default: ''
  },
  selectedSpbuId: {
    type: [String, Number],
    default: ''
  },
  spbuOptions: {
    type: Array,
    default: () => []
  },
  loading: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits([
  'update:dateFrom',
  'update:dateTo',
  'update:selectedSpbuId',
  'resetFilters'
])

const analyticsContainerRef = ref(null)
const spbuSelectContainerRef = ref(null)
const isSpbuDropdownOpen = ref(false)
const isSpbuSelectOpen = ref(false)

const toggleSpbuDropdown = () => {
  isSpbuDropdownOpen.value = !isSpbuDropdownOpen.value
}

const toggleSpbuSelect = () => {
  isSpbuSelectOpen.value = !isSpbuSelectOpen.value
}

const selectSpbu = (id) => {
  emit('update:selectedSpbuId', id)
  isSpbuSelectOpen.value = false
}

const handleClickOutside = (e) => {
  if (analyticsContainerRef.value && !analyticsContainerRef.value.contains(e.target)) {
    isSpbuDropdownOpen.value = false
    isSpbuSelectOpen.value = false
  } else if (spbuSelectContainerRef.value && !spbuSelectContainerRef.value.contains(e.target)) {
    isSpbuSelectOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})

const selectedSpbuName = computed(() => {
  if (!props.selectedSpbuId) return 'Semua SPBU'
  const found = props.spbuOptions.find(s => String(s.id) === String(props.selectedSpbuId))
  return found ? found.name : `SPBU #${props.selectedSpbuId}`
})

const activeFilterCount = computed(() => {
  return (props.dateFrom ? 1 : 0) + (props.dateTo ? 1 : 0) + (props.selectedSpbuId ? 1 : 0)
})

const resetFilters = () => {
  emit('update:dateFrom', '')
  emit('update:dateTo', '')
  emit('update:selectedSpbuId', '')
  emit('resetFilters')
}
</script>

<template>
  <div ref="analyticsContainerRef" class="relative z-40 w-full sm:w-auto">
    <button
      type="button"
      @click="toggleSpbuDropdown"
      :class="[
        'w-full sm:w-auto px-4 py-2.5 rounded-full text-xs font-extrabold transition-all cursor-pointer flex items-center justify-between sm:justify-start gap-2 border select-none shadow-sm',
        isSpbuDropdownOpen || dateFrom || dateTo || selectedSpbuId
          ? 'bg-[#143d2e] text-white border-[#143d2e]'
          : 'bg-white hover:bg-gray-50 border-gray-200 text-gray-700'
      ]"
    >
      <div class="flex items-center gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" :class="['w-4 h-4 shrink-0', isSpbuDropdownOpen || dateFrom || dateTo || selectedSpbuId ? 'text-emerald-800' : 'text-emerald-600']">
          <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 6h9.75M10.5 6a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0m-9.75 0h9.75" />
        </svg>
        <span>Filter</span>
      </div>

      <div class="flex items-center gap-2">
        <!-- Active Filter Badge Counter -->
        <span
          v-if="activeFilterCount > 0"
          class="w-5 h-5 rounded-full bg-emerald-500 text-white text-[10px] font-black flex items-center justify-center shrink-0 shadow-2xs"
        >
          {{ activeFilterCount }}
        </span>

        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" :class="['w-3.5 h-3.5 transition-transform duration-200 shrink-0', isSpbuDropdownOpen || dateFrom || dateTo || selectedSpbuId ? 'rotate-180 text-emerald-800' : 'text-gray-400']">
          <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
        </svg>
      </div>
    </button>

    <!-- Collapsible Floating Filter Panel Card -->
    <div
      v-if="isSpbuDropdownOpen"
      class="absolute left-0 right-0 sm:left-auto sm:right-0 mt-2 w-full sm:w-[380px] max-w-[calc(100vw-2rem)] bg-[#143d2e] border border-emerald-700/60 rounded-2xl p-4 sm:p-5 shadow-2xl z-[100] space-y-4 animate-enter text-white text-xs font-bold"
    >
      <!-- Panel Header -->
      <div class="flex items-center justify-between pb-3 border-b border-emerald-800/60">
        <div class="flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4 text-emerald-400 shrink-0">
            <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 6h9.75M10.5 6a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0m-9.75 0h9.75" />
          </svg>
          <span class="text-sm font-black text-white truncate">Filter Laporan</span>
        </div>

        <button
          type="button"
          @click="isSpbuDropdownOpen = false"
          class="w-7 h-7 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white/80 transition-colors shrink-0"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <!-- Filter Option 1: SPBU Selection (Custom Floating Card Dropdown) -->
      <div class="space-y-1.5">
        <label class="text-[10px] font-extrabold uppercase tracking-wider text-emerald-200/80">Lokasi SPBU</label>
        <div ref="spbuSelectContainerRef" class="relative">
          <button
            type="button"
            @click="toggleSpbuSelect"
            class="w-full flex items-center justify-between gap-2 bg-white/10 hover:bg-white/20 border border-white/15 focus:border-white focus:ring-2 focus:ring-white/20 rounded-xl px-3.5 py-2.5 text-xs font-bold text-white transition-all cursor-pointer select-none"
          >
            <span class="truncate">{{ selectedSpbuName }}</span>
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" :class="['w-3.5 h-3.5 text-green-200/70 transition-transform duration-200 shrink-0', isSpbuSelectOpen ? 'rotate-180 text-white' : '']">
              <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
            </svg>
          </button>

          <!-- SPBU Menu Card -->
          <div
            v-if="isSpbuSelectOpen"
            class="absolute left-0 mt-1 w-full bg-white rounded-xl shadow-2xl border border-gray-100 p-1 z-[110] text-gray-800 text-xs font-bold space-y-0.5 max-h-48 overflow-y-auto"
          >
            <button
              type="button"
              @click="selectSpbu('')"
              :class="[
                'w-full flex items-center justify-between px-3 py-2 rounded-lg transition-all text-left cursor-pointer',
                !selectedSpbuId ? 'bg-[#143d2e]/10 text-[#143d2e] font-black' : 'hover:bg-gray-100 text-gray-700'
              ]"
            >
              <span>Semua SPBU</span>
              <svg v-if="!selectedSpbuId" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="3" stroke="currentColor" class="w-3.5 h-3.5 text-[#143d2e] shrink-0">
                <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
              </svg>
            </button>

            <button
              v-for="s in spbuOptions"
              :key="s.id"
              type="button"
              @click="selectSpbu(s.id)"
              :class="[
                'w-full flex items-center justify-between px-3 py-2 rounded-lg transition-all text-left cursor-pointer',
                String(selectedSpbuId) === String(s.id) ? 'bg-[#143d2e]/10 text-[#143d2e] font-black' : 'hover:bg-gray-100 text-gray-700'
              ]"
            >
              <span class="truncate">{{ s.name }}</span>
              <svg v-if="String(selectedSpbuId) === String(s.id)" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="3" stroke="currentColor" class="w-3.5 h-3.5 text-[#143d2e] shrink-0">
                <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
              </svg>
            </button>
          </div>
        </div>
      </div>

      <!-- Filter Option 2: Date Range -->
      <div class="space-y-1.5">
        <label class="text-[10px] font-extrabold uppercase tracking-wider text-emerald-200/80">Rentang Tanggal</label>
        <div class="flex flex-col space-y-2">
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

      <!-- Panel Footer Actions -->
      <div class="flex items-center justify-between pt-3 border-t border-emerald-800/60">
        <span v-if="loading" class="animate-pulse text-emerald-300 text-xs font-bold">Memuat...</span>
        <span v-else class="text-emerald-200/70 text-[11px] font-bold"></span>

        <button
          type="button"
          @click="resetFilters"
          class="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-red-500/20 hover:bg-red-500/30 text-red-300 border border-red-400/30 text-xs font-bold transition-all cursor-pointer shadow-sm shrink-0"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5 text-red-400 shrink-0">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
          </svg>
          <span>Reset Filter</span>
        </button>
      </div>

    </div>
  </div>
</template>
