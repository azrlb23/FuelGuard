<script setup>
import { computed } from 'vue'
import MasterHistoryFilterBar from './MasterHistoryFilterBar.vue'

const props = defineProps({
  loading: {
    type: Boolean,
    default: false
  },
  isExporting: {
    type: Boolean,
    default: false
  },
  transactions: {
    type: Array,
    default: () => []
  },
  currentPage: {
    type: Number,
    required: true
  },
  itemsPerPage: {
    type: Number,
    default: 10
  },
  totalItems: {
    type: Number,
    default: 0
  },
  totalPages: {
    type: Number,
    default: 1
  },
  spbuList: {
    type: Array,
    default: () => []
  },
  searchQuery: {
    type: String,
    default: ''
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
    default: () => []
  },
  activeFilters: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits([
  'update:currentPage',
  'update:searchQuery',
  'update:selectedSpbu',
  'update:dateFrom',
  'update:dateTo',
  'sortChange',
  'resetFilters',
  'removeFilter',
  'exportExcel'
])

const visiblePages = computed(() => {
  const total = props.totalPages
  const current = props.currentPage
  if (total <= 5) {
    return Array.from({ length: total }, (_, i) => i + 1)
  }

  const pages = []
  if (current <= 3) {
    pages.push(1, 2, 3, '...', total)
  } else if (current >= total - 2) {
    pages.push(1, '...', total - 2, total - 1, total)
  } else {
    pages.push(1, '...', current, '...', total)
  }
  return pages
})

const formatRupiah = (num) => {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(num || 0)
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

const formatTimeOnly = (dateString) => {
  if (!dateString) return '-'
  const d = new Date(dateString)
  return d.toLocaleTimeString('id-ID', {
    hour: '2-digit',
    minute: '2-digit'
  }).replace('.', ':')
}

const getSpbuName = (trx) => {
  return trx.spbu_name || 'SPBU 64.7501'
}

const setPage = (p) => {
  emit('update:currentPage', p)
}
</script>

<template>
  <div class="bg-gradient-to-br from-[#143d2e] to-[#1e5c45] rounded-[2rem] p-6 md:p-8 shadow-xl shadow-green-900/10 text-white relative border border-green-800/40">

    <!-- Background Glow Effect (Clipped to Card Corners) -->
    <div class="absolute inset-0 rounded-[2rem] overflow-hidden pointer-events-none">
      <div class="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full blur-3xl"></div>
    </div>

    <!-- Integrated Filter Bar -->
    <MasterHistoryFilterBar
      :searchQuery="searchQuery"
      @update:searchQuery="$emit('update:searchQuery', $event)"
      :spbuList="spbuList"
      :selectedSpbu="selectedSpbu"
      @update:selectedSpbu="$emit('update:selectedSpbu', $event)"
      :selectedSpbuLabel="selectedSpbuLabel"
      :dateFrom="dateFrom"
      @update:dateFrom="$emit('update:dateFrom', $event)"
      :dateTo="dateTo"
      @update:dateTo="$emit('update:dateTo', $event)"
      :sortField="sortField"
      :sortDir="sortDir"
      :currentSortLabel="currentSortLabel"
      :SORT_OPTIONS="SORT_OPTIONS"
      :activeFilters="activeFilters"
      @sortChange="$emit('sortChange', $event)"
      @resetFilters="$emit('resetFilters')"
      @removeFilter="$emit('removeFilter', $event)"
    />

    <!-- Mobile List View -->
    <div class="block md:hidden space-y-4">
      <template v-if="loading">
        <div v-for="n in 3" :key="n" class="bg-white/10 rounded-2xl p-4 animate-pulse space-y-3">
          <div class="flex justify-between">
            <div class="h-4 w-24 bg-white/10 rounded"></div>
            <div class="h-4 w-16 bg-white/10 rounded"></div>
          </div>
          <div class="h-6 w-32 bg-white/10 rounded"></div>
          <div class="h-4 w-full bg-white/10 rounded"></div>
        </div>
      </template>

      <template v-else-if="transactions.length > 0">
        <div
          v-for="trx in transactions"
          :key="trx.id"
          class="bg-black/20 rounded-2xl p-4 border border-white/10 flex flex-col gap-3"
        >
          <div class="flex justify-between items-start">
            <div class="flex items-center gap-2 text-xs text-green-200/70 font-medium">
              <span>{{ formatDateOnly(trx.waktu_pencatatan) }}</span>
              <span class="font-mono text-green-300">{{ formatTimeOnly(trx.waktu_pencatatan) }}</span>
            </div>
            <span v-if="trx.operator_name || trx.nama_operator" class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-emerald-900/60 text-emerald-200 border border-emerald-700/50 uppercase">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3 h-3 text-emerald-400">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z" />
              </svg>
              <span>{{ trx.operator_name || trx.nama_operator }}</span>
            </span>
          </div>

          <div class="flex justify-between items-center">
            <h3 class="text-xl font-mono font-bold tracking-wider text-white">{{ trx.plat_nomor }}</h3>
            <span class="inline-flex items-center px-2.5 py-1 rounded-xl text-[10px] font-bold bg-white/15 text-green-100 border border-white/10">
              {{ getSpbuName(trx) }}
            </span>
          </div>

          <div class="h-px w-full bg-white/10"></div>

          <div class="flex justify-between items-end">
            <div>
              <p class="text-[10px] text-green-100/50 uppercase tracking-widest mb-0.5">Volume</p>
              <p class="text-sm font-bold text-white">{{ trx.liter }} L</p>
            </div>
            <div class="text-right">
              <p class="text-[10px] text-green-100/50 uppercase tracking-widest mb-0.5">Revenue</p>
              <p class="text-lg font-black text-emerald-300">{{ formatRupiah(trx.harga) }}</p>
            </div>
          </div>
        </div>
      </template>

      <div v-else class="py-12 text-center text-green-100/60">
        <span class="text-3xl block mb-2">🍃</span>
        <span class="text-sm font-medium">Tidak ada transaksi ditemukan.</span>
      </div>
    </div>

    <!-- Desktop Table View -->
    <div class="hidden md:block overflow-x-auto">
      <table class="w-full text-left border-collapse">
        <thead class="border-b border-white/15 text-emerald-200/90">
          <tr class="text-xs font-extrabold uppercase tracking-wider">
            <th class="py-3.5 pl-3">TANGGAL</th>
            <th class="py-3.5">WAKTU</th>
            <th class="py-3.5">SPBU</th>
            <th class="py-3.5">OPERATOR</th>
            <th class="py-3.5">PLAT NOMOR</th>
            <th class="py-3.5">VOLUME</th>
            <th class="py-3.5 pr-3">REVENUE</th>
          </tr>
        </thead>
        <tbody class="text-sm">
          <template v-if="loading">
            <tr v-for="n in 5" :key="n" class="border-b border-white/5">
              <td class="py-4 pl-3"><div class="skeleton h-4 w-24 bg-white/10 rounded"></div></td>
              <td class="py-4"><div class="skeleton h-4 w-16 bg-white/10 rounded"></div></td>
              <td class="py-4"><div class="skeleton h-6 w-24 bg-white/10 rounded-full"></div></td>
              <td class="py-4"><div class="skeleton h-4 w-24 bg-white/10 rounded"></div></td>
              <td class="py-4"><div class="skeleton h-4 w-20 bg-white/10 rounded"></div></td>
              <td class="py-4"><div class="skeleton h-4 w-16 bg-white/10 rounded"></div></td>
              <td class="py-4 pr-3"><div class="skeleton h-4 w-24 bg-white/10 rounded"></div></td>
            </tr>
          </template>

          <template v-else-if="transactions.length > 0">
            <tr
              v-for="trx in transactions"
              :key="trx.id"
              class="hover:bg-white/5 transition-colors duration-150 border-b border-white/10 last:border-0"
            >
              <td class="py-4 pl-3 text-green-50 font-medium text-xs md:text-sm">{{ formatDateOnly(trx.waktu_pencatatan) }}</td>
              <td class="py-4 text-green-200/90 font-mono text-xs md:text-sm">{{ formatTimeOnly(trx.waktu_pencatatan) }}</td>
              <td class="py-4">
                <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-white/15 text-green-100 border border-white/10">
                  {{ getSpbuName(trx) }}
                </span>
              </td>
              <td class="py-4 text-emerald-200 font-bold text-xs md:text-sm uppercase">
                {{ trx.operator_name || trx.nama_operator || '-' }}
              </td>
              <td class="py-4 font-mono font-bold text-white tracking-wider">{{ trx.plat_nomor }}</td>
              <td class="py-4 text-white/90 font-semibold">{{ trx.liter }} L</td>
              <td class="py-4 pr-3 font-black text-emerald-300">{{ formatRupiah(trx.harga) }}</td>
            </tr>
          </template>

          <tr v-else>
            <td colspan="7" class="py-16 text-center text-green-100/60">
              <span class="text-3xl block mb-2">🍃</span>
              <span class="text-sm font-medium">Tidak ada transaksi ditemukan.</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Pagination Bar & Export Excel Button -->
    <div class="flex flex-col md:flex-row items-center justify-between mt-6 pt-5 border-t border-white/15 gap-4">

      <!-- Total Items & Download XLSX Button -->
      <div class="flex flex-wrap items-center gap-3 order-2 md:order-1 text-center md:text-left justify-center md:justify-start">
        <span class="text-xs text-green-200/70 font-medium">
          Menampilkan {{ transactions.length ? ((currentPage - 1) * itemsPerPage + 1).toLocaleString('id-ID') : 0 }} -
          {{ Math.min(currentPage * itemsPerPage, totalItems).toLocaleString('id-ID') }} dari {{ totalItems.toLocaleString('id-ID') }} data
        </span>

        <!-- Download XLSX Button -->
        <button
          @click="$emit('exportExcel')"
          :disabled="isExporting || totalItems === 0"
          class="inline-flex items-center gap-1.5 bg-emerald-500/20 hover:bg-emerald-500/30 border border-emerald-400/30 text-emerald-200 hover:text-white px-3.5 py-1.5 rounded-full text-xs font-bold transition-all cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed shadow-xs"
          title="Unduh laporan transaksi dalam format Excel (.xlsx)"
        >
          <svg v-if="!isExporting" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-emerald-300 shrink-0">
            <path stroke-linecap="round" stroke-linejoin="round" d="M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5M16.5 12 12 16.5m0 0L7.5 12m4.5 4.5V3" />
          </svg>
          <span v-else class="loading loading-spinner loading-xs text-emerald-300"></span>
          <span>{{ isExporting ? 'Mengeksport...' : 'Ekspor (.xlsx)' }}</span>
        </button>
      </div>

      <!-- Page Buttons -->
      <div class="flex items-center gap-1.5 order-1 md:order-2 flex-wrap justify-center">
        <!-- Previous Page Button -->
        <button
          @click="setPage(currentPage - 1)"
          :disabled="currentPage <= 1 || loading"
          class="px-3.5 py-1.5 rounded-full bg-white/10 hover:bg-white/20 disabled:opacity-40 disabled:cursor-not-allowed text-xs font-bold transition-all cursor-pointer mr-1"
        >
          Kembali
        </button>

        <!-- Page Numbers -->
        <template v-for="(p, index) in visiblePages" :key="index">
          <span v-if="p === '...'" class="px-1 text-white/50 text-xs font-bold select-none">...</span>
          <button
            v-else
            @click="setPage(p)"
            :class="[
              'min-w-8 h-8 px-2 rounded-full text-xs font-black transition-all cursor-pointer flex items-center justify-center shrink-0',
              currentPage === p
                ? 'bg-white text-[#143d2e] shadow-md scale-105'
                : 'text-white/80 hover:bg-white/15'
            ]"
          >
            {{ p }}
          </button>
        </template>

        <!-- Next Page Button -->
        <button
          @click="setPage(currentPage + 1)"
          :disabled="currentPage >= totalPages || loading"
          class="px-3.5 py-1.5 rounded-full bg-white/10 hover:bg-white/20 disabled:opacity-40 disabled:cursor-not-allowed text-xs font-bold transition-all cursor-pointer ml-1"
        >
          Lanjut
        </button>
      </div>
    </div>

  </div>
</template>
