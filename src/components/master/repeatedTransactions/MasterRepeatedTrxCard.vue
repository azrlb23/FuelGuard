<script setup>
import { ref } from 'vue'
import * as XLSX from 'xlsx'
import { toast } from 'vue3-toastify'
import MasterRepeatedFilterBar from './MasterRepeatedFilterBar.vue'
import MasterRepeatedAccordionItem from './MasterRepeatedAccordionItem.vue'

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
  currentPage: {
    type: Number,
    default: 1
  },
  itemsPerPage: {
    type: Number,
    default: 10
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
  'update:currentPage',
  'resetFilters'
])

// Expanded state for accordion rows (plat_nomor key map)
const expandedPlates = ref({})

const togglePlate = (plat) => {
  expandedPlates.value[plat] = !expandedPlates.value[plat]
}

const isExpanded = (plat) => {
  return !!expandedPlates.value[plat]
}

const normalizePlate = (plat) => {
  if (!plat) return ''
  return plat.trim().toUpperCase().replace(/\s+/g, ' ')
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

const exportToExcel = () => {
  if (!props.repeatedLogs || props.repeatedLogs.length === 0) {
    toast.warn('Tidak ada data transaksi ditolak untuk diekspor.')
    return
  }
  const rows = []
  props.repeatedLogs.forEach((item) => {
    const attempts = item.attempts && item.attempts.length > 0 ? item.attempts : [item]
    attempts.forEach((attempt, index) => {
      const attemptNum = attempt.attempt_number || index + 1
      const totalNum = item.total_attempts || attempts.length
      rows.push({
        'Tanggal': formatDateOnly(attempt.created_at),
        'Waktu': formatTimeOnly(attempt.created_at),
        'Nomor Plat': normalizePlate(item.plat_nomor || attempt.plat_nomor),
        'Lokasi SPBU': attempt.spbu_nama || 'N/A',
        'Nama Operator': (attempt.operator_nama || 'N/A').toUpperCase(),
        'Kategori': attempt.is_ojol ? 'Ojol' : 'Non Ojol',
        'Alasan Ditolak': attempt.reason || attempt.deskripsi || attempt.catatan || `Percobaan ke-${attemptNum} (${totalNum}x Transaksi)`
      })
    })
  })
  if (rows.length === 0) {
    toast.warn('Tidak ada baris data transaksi ditolak untuk diekspor.')
    return
  }
  const worksheet = XLSX.utils.json_to_sheet(rows)
  worksheet['!cols'] = [
    { wch: 15 }, // Tanggal
    { wch: 15 }, // Waktu
    { wch: 16 }, // Nomor Plat
    { wch: 22 }, // Lokasi SPBU
    { wch: 20 }, // Nama Operator
    { wch: 14 }, // Kategori
    { wch: 38 }  // Alasan Ditolak
  ]
  const workbook = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Transaksi Ditolak')
  const dateRangeStr = props.dateFrom ? `${props.dateFrom}_sd_${props.dateTo || props.dateFrom}` : new Date().toISOString().slice(0, 10)
  XLSX.writeFile(workbook, `Ekspor_Transaksi_Ditolak_${dateRangeStr}.xlsx`)
  toast.success(`Berhasil mengunduh ${rows.length} data transaksi ditolak!`)
}
</script>

<template>
  <div class="bg-gradient-to-br from-[#103427] via-[#143d2e] to-[#0d2b20] rounded-[2rem] p-5 md:p-6 text-white shadow-xl shadow-green-900/10 border border-emerald-800/40 relative flex flex-col space-y-4">

    <!-- Background Glow Effect -->
    <div class="absolute top-0 right-0 w-64 h-64 bg-emerald-500/5 rounded-full blur-3xl pointer-events-none"></div>

    <!-- Filter Bar Header -->
    <MasterRepeatedFilterBar
      :searchQuery="searchQuery"
      @update:searchQuery="$emit('update:searchQuery', $event)"
      :selectedSpbu="selectedSpbu"
      @update:selectedSpbu="$emit('update:selectedSpbu', $event)"
      :dateFrom="dateFrom"
      @update:dateFrom="$emit('update:dateFrom', $event)"
      :dateTo="dateTo"
      @update:dateTo="$emit('update:dateTo', $event)"
      :spbuList="spbuList"
      @resetFilters="$emit('resetFilters')"
    />

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
            <p class="text-base font-extrabold text-white">Tidak Ada Transaksi Ditolak</p>
            <p class="text-xs font-semibold text-emerald-200/70 mt-1">Tidak ada percobaan transaksi ditolak yang terdeteksi saat ini.</p>
          </div>
        </div>
      </template>

      <!-- Plate Accordion Cards -->
      <template v-else>
        <MasterRepeatedAccordionItem
          v-for="(item, index) in repeatedLogs"
          :key="item.plat_nomor"
          :item="item"
          :index="index"
          :isExpanded="isExpanded(item.plat_nomor)"
          @toggle="togglePlate(item.plat_nomor)"
        />
      </template>

    </div>

    <!-- Card Footer -->
    <div class="flex flex-col sm:flex-row items-center justify-between gap-3 pt-3 border-t border-emerald-800/40 text-xs font-semibold text-emerald-200/70 relative z-10">
      <p>
        Menampilkan {{ repeatedLogs.length ? ((currentPage - 1) * itemsPerPage + 1) : 0 }} - {{ Math.min(currentPage * itemsPerPage, totalPlates) }} dari {{ totalPlates }} plat ({{ totalCount }} total percobaan)
      </p>

      <div class="flex items-center gap-2">
        <button
          type="button"
          @click="$emit('update:currentPage', currentPage - 1)"
          :disabled="currentPage <= 1 || loading"
          class="px-4 py-1.5 rounded-full bg-white/10 hover:bg-white/20 disabled:opacity-40 disabled:cursor-not-allowed text-xs font-bold transition-all cursor-pointer select-none text-white"
        >
          Prev
        </button>
        <button
          type="button"
          @click="$emit('update:currentPage', currentPage + 1)"
          :disabled="(currentPage * itemsPerPage) >= totalPlates || loading"
          class="px-4 py-1.5 rounded-full bg-emerald-500/20 hover:bg-emerald-500/30 text-emerald-200 border border-emerald-400/40 disabled:opacity-40 disabled:cursor-not-allowed text-xs font-bold transition-all cursor-pointer select-none"
        >
          Next
        </button>
      </div>

      <!-- Downloadable Ekspor XLSX Button -->
      <button
        type="button"
        @click="exportToExcel"
        :disabled="repeatedLogs.length === 0"
        title="Ekspor Data Transaksi Berulang ke File Excel (.xlsx)"
        class="w-full sm:w-auto px-4 py-2.5 rounded-full text-xs font-extrabold transition-all cursor-pointer flex items-center justify-center gap-2 border select-none shadow-sm bg-emerald-500/20 hover:bg-emerald-500/30 text-emerald-200 border-emerald-400/40 disabled:opacity-40 disabled:cursor-not-allowed active:scale-95 shrink-0"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4 text-emerald-300 shrink-0">
          <path stroke-linecap="round" stroke-linejoin="round" d="M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5M16.5 12 12 16.5m0 0L7.5 12m4.5 4.5V3" />
        </svg>
        <span>Ekspor (.xlsx)</span>
      </button>
    </div>
  </div>
</template>
