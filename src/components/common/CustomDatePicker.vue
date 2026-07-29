<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  modelValue: {
    type: String,
    default: ''
  },
  label: {
    type: String,
    default: ''
  },
  placeholder: {
    type: String,
    default: 'Pilih Tanggal'
  },
  variant: {
    type: String,
    default: 'dark' // 'dark' (for green card) or 'light' (for white card)
  }
})

const emit = defineEmits(['update:modelValue'])

const isOpen = ref(false)
const containerRef = ref(null)

const viewDate = ref(new Date())

watch(() => props.modelValue, (newVal) => {
  if (newVal) {
    const d = new Date(newVal)
    if (!isNaN(d.getTime())) {
      viewDate.value = new Date(d.getFullYear(), d.getMonth(), 1)
    }
  }
}, { immediate: true })

const currentYear = computed(() => viewDate.value.getFullYear())
const currentMonth = computed(() => viewDate.value.getMonth())

const monthNames = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
]

const monthLabel = computed(() => `${monthNames[currentMonth.value]} ${currentYear.value}`)

const formattedDisplayDate = computed(() => {
  if (!props.modelValue) return props.placeholder || 'mm/dd/yyyy'
  const d = new Date(props.modelValue)
  if (isNaN(d.getTime())) return props.modelValue
  return d.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
})

const prevMonth = () => {
  viewDate.value = new Date(currentYear.value, currentMonth.value - 1, 1)
}

const nextMonth = () => {
  viewDate.value = new Date(currentYear.value, currentMonth.value + 1, 1)
}

const calendarDays = computed(() => {
  const year = currentYear.value
  const month = currentMonth.value

  const firstDayIndex = new Date(year, month, 1).getDay()
  const daysInMonth = new Date(year, month + 1, 0).getDate()
  const prevDaysInMonth = new Date(year, month, 0).getDate()

  const days = []

  for (let i = firstDayIndex - 1; i >= 0; i--) {
    days.push({
      day: prevDaysInMonth - i,
      isCurrentMonth: false,
      dateStr: ''
    })
  }

  for (let d = 1; d <= daysInMonth; d++) {
    const monthStr = String(month + 1).padStart(2, '0')
    const dayStr = String(d).padStart(2, '0')
    const dateStr = `${year}-${monthStr}-${dayStr}`
    days.push({
      day: d,
      isCurrentMonth: true,
      dateStr
    })
  }

  const remaining = (7 - (days.length % 7)) % 7
  for (let i = 1; i <= remaining; i++) {
    days.push({
      day: i,
      isCurrentMonth: false,
      dateStr: ''
    })
  }

  return days
})

const selectDate = (dayObj) => {
  if (!dayObj.isCurrentMonth || !dayObj.dateStr) return
  emit('update:modelValue', dayObj.dateStr)
  isOpen.value = false
}

const selectToday = () => {
  const today = new Date()
  const year = today.getFullYear()
  const monthStr = String(today.getMonth() + 1).padStart(2, '0')
  const dayStr = String(today.getDate()).padStart(2, '0')
  const dateStr = `${year}-${monthStr}-${dayStr}`
  emit('update:modelValue', dateStr)
  viewDate.value = new Date(year, today.getMonth(), 1)
  isOpen.value = false
}

const clearDate = () => {
  emit('update:modelValue', '')
  isOpen.value = false
}

const toggleOpen = () => {
  isOpen.value = !isOpen.value
}

const handleClickOutside = (e) => {
  if (containerRef.value && !containerRef.value.contains(e.target)) {
    isOpen.value = false
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
  <div ref="containerRef" class="relative flex-1 min-w-[150px]">
    <!-- Trigger Pill -->
    <button
      type="button"
      @click="toggleOpen"
      :class="[
        'w-full flex items-center justify-between gap-2.5 rounded-full px-4 py-2 text-xs font-bold transition-all cursor-pointer select-none shadow-sm',
        variant === 'dark'
          ? 'bg-white/10 hover:bg-white/20 border border-white/15 text-white focus:border-white focus:ring-2 focus:ring-white/20'
          : 'bg-gray-50/90 hover:bg-gray-100/90 border border-gray-200/90 text-gray-700 focus-within:border-[#143d2e] focus-within:ring-2 focus-within:ring-[#143d2e]/15'
      ]"
    >
      <div class="flex items-center gap-2 min-w-0">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" :class="['w-4 h-4 shrink-0', variant === 'dark' ? 'text-green-300' : 'text-[#143d2e]']">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
        </svg>
        <span v-if="label" :class="['uppercase text-[10px] tracking-wider font-extrabold shrink-0', variant === 'dark' ? 'text-green-200/80' : 'text-[#143d2e]/60']">{{ label }}</span>
        <span :class="['truncate font-bold text-xs sm:text-sm', variant === 'dark' ? (modelValue ? 'text-white' : 'text-white/60') : (modelValue ? 'text-gray-800' : 'text-gray-400')]">
          {{ formattedDisplayDate }}
        </span>
      </div>
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" :class="['w-3.5 h-3.5 transition-transform duration-200 shrink-0', variant === 'dark' ? 'text-green-200/70' : 'text-gray-400', isOpen ? 'rotate-180' : '']">
        <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
      </svg>
    </button>

    <!-- Custom Floating Popover Calendar Card -->
    <div
      v-if="isOpen"
      class="absolute left-0 mt-2 w-72 bg-white rounded-2xl shadow-2xl border border-gray-100 p-4 z-50 animate-enter text-gray-800 text-xs font-bold"
    >
      <!-- Calendar Header: Month Navigation -->
      <div class="flex items-center justify-between mb-3 pb-2 border-b border-gray-100">
        <button
          type="button"
          @click="prevMonth"
          class="w-7 h-7 rounded-full hover:bg-gray-100 flex items-center justify-center text-gray-600 transition-colors cursor-pointer"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" />
          </svg>
        </button>

        <span class="text-sm font-extrabold text-[#143d2e]">{{ monthLabel }}</span>

        <button
          type="button"
          @click="nextMonth"
          class="w-7 h-7 rounded-full hover:bg-gray-100 flex items-center justify-center text-gray-600 transition-colors cursor-pointer"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" />
          </svg>
        </button>
      </div>

      <!-- Day Names Bar -->
      <div class="grid grid-cols-7 gap-1 text-center mb-2 text-[10px] text-gray-400 font-extrabold uppercase">
        <span>Min</span>
        <span>Sen</span>
        <span>Sel</span>
        <span>Rab</span>
        <span>Kam</span>
        <span>Jum</span>
        <span>Sab</span>
      </div>

      <!-- Days Grid -->
      <div class="grid grid-cols-7 gap-1 text-center">
        <button
          v-for="(d, idx) in calendarDays"
          :key="idx"
          type="button"
          :disabled="!d.isCurrentMonth"
          @click="selectDate(d)"
          :class="[
            'h-8 rounded-xl flex items-center justify-center text-xs font-bold transition-all',
            !d.isCurrentMonth ? 'text-gray-300 cursor-default' : 'cursor-pointer',
            d.isCurrentMonth && modelValue === d.dateStr
              ? 'bg-[#143d2e] text-white font-black shadow-md scale-105'
              : d.isCurrentMonth ? 'hover:bg-green-50 hover:text-[#143d2e] text-gray-700' : ''
          ]"
        >
          {{ d.day }}
        </button>
      </div>

      <!-- Footer Buttons -->
      <div class="flex items-center justify-between mt-3 pt-2 border-t border-gray-100">
        <button
          type="button"
          @click="clearDate"
          class="text-[11px] text-gray-400 hover:text-red-500 font-semibold cursor-pointer"
        >
          Hapus
        </button>
        <button
          type="button"
          @click="selectToday"
          class="text-[11px] text-[#143d2e] hover:underline font-bold cursor-pointer"
        >
          Hari Ini
        </button>
      </div>
    </div>
  </div>
</template>
