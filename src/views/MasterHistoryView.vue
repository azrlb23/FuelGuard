<script setup>
import { ref, computed } from 'vue'
import { useMasterHistory } from '@/composables/useMasterHistory'

// ─── Master History State via Composable ────────────────────────────────────
const itemsPerPage = 10

const {
  transactions,
  loading,
  totalItems,
  currentPage,
  searchQuery,
  selectedSpbu,
  spbuList,
  dateFrom,
  dateTo,
  sortField,
  sortDir,
  resetFilters
} = useMasterHistory(itemsPerPage)

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
  const found = SORT_OPTIONS.find(o => o.field === sortField.value && o.dir === sortDir.value)
  return found ? found.label : 'Terbaru'
})

const selectedSpbuLabel = computed(() => {
  if (!selectedSpbu.value) return 'Semua SPBU'
  const found = spbuList.value.find(s => String(s.id) === String(selectedSpbu.value))
  return found ? found.nama : `SPBU #${selectedSpbu.value}`
})

const activeFilters = computed(() => {
  const filters = []
  if (searchQuery.value) filters.push({ key: 'search', label: `Plat: ${searchQuery.value.toUpperCase()}` })
  if (selectedSpbu.value) filters.push({ key: 'spbu', label: `SPBU: ${selectedSpbuLabel.value}` })
  if (dateFrom.value) filters.push({ key: 'dateFrom', label: `Dari: ${dateFrom.value}` })
  if (dateTo.value) filters.push({ key: 'dateTo', label: `Sampai: ${dateTo.value}` })
  if (sortField.value !== 'waktu_pencatatan' || sortDir.value !== 'desc') {
    filters.push({ key: 'sort', label: `Urut: ${currentSortLabel.value}` })
  }
  return filters
})

// ─── Helpers ─────────────────────────────────────────────────────────────────
const formatRupiah = (num) => {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(num || 0)
}

const formatDate = (dateString) => {
  if (!dateString) return '-'
  const d = new Date(dateString)
  return d.toLocaleDateString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const getSpbuName = (trx) => {
  return trx.spbu_name || 'SPBU 64.7501'
}

const removeFilter = (key) => {
  if (key === 'search') searchQuery.value = ''
  if (key === 'spbu') selectedSpbu.value = ''
  if (key === 'dateFrom') dateFrom.value = ''
  if (key === 'dateTo') dateTo.value = ''
  if (key === 'sort') {
    sortField.value = 'waktu_pencatatan'
    sortDir.value = 'desc'
  }
}

const onSortSelectChange = (e) => {
  const [field, dir] = e.target.value.split(':')
  sortField.value = field
  sortDir.value = dir
}

const totalPages = computed(() => Math.ceil(totalItems.value / itemsPerPage) || 1)
</script>

<template>
  <div class="space-y-6 animate-enter">

    <!-- Header Section: Title & Search -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-end gap-4">
      <div>
        <h2 class="text-3xl md:text-4xl font-extrabold text-black tracking-tight mb-1">Transaction History</h2>
        <p class="text-gray-500 text-sm font-bold">Rekapitulasi seluruh transaksi operasional</p>
      </div>

      <!-- Search Input -->
      <div class="relative w-full md:w-72">
        <input 
          v-model="searchQuery"
          type="text" 
          placeholder="Cari Plat Nomor..." 
          class="w-full pl-10 pr-4 py-2.5 rounded-full bg-white border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#143d2e] focus:border-transparent shadow-sm text-xs md:text-sm font-medium transition-all"
        />
        <span class="absolute left-3.5 top-2.5 text-gray-400">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
            <path stroke-linecap="round" stroke-linejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" />
          </svg>
        </span>
      </div>
    </div>

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
          v-model="selectedSpbu"
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
          v-model="dateFrom"
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
          v-model="dateTo"
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
        @click="resetFilters"
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
        <button @click="removeFilter(f.key)" class="hover:text-red-500 transition-colors cursor-pointer">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3 h-3">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
          </svg>
        </button>
      </span>
    </div>

    <!-- Main History Table Container (Rich Dark Green Theme) -->
    <div class="bg-gradient-to-br from-[#143d2e] to-[#1e5c45] rounded-[2rem] p-6 md:p-8 shadow-xl shadow-green-900/10 text-white relative overflow-hidden">
      
      <div class="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full blur-3xl pointer-events-none"></div>

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
              <span class="text-xs text-green-200/70 font-medium">{{ formatDate(trx.waktu_pencatatan) }}</span>
              <span class="text-[10px] font-bold bg-emerald-500/20 text-emerald-300 px-2 py-0.5 rounded-full border border-emerald-500/20">Success</span>
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

      <!-- Desktop Table View (SPBU menggantikan Kendaraan) -->
      <div class="hidden md:block overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="text-green-200/70 text-xs font-bold uppercase tracking-wider border-b border-white/15 pb-4">
              <th class="pb-4 pl-3">WAKTU</th>
              <th class="pb-4">SPBU</th>
              <th class="pb-4">PLAT NOMOR</th>
              <th class="pb-4">VOLUME</th>
              <th class="pb-4">REVENUE</th>
              <th class="pb-4 pr-3 text-right">STATUS</th>
            </tr>
          </thead>
          <tbody class="text-sm">
            <template v-if="loading">
              <tr v-for="n in 5" :key="n" class="border-b border-white/5">
                <td class="py-4 pl-3"><div class="skeleton h-4 w-28 bg-white/10 rounded"></div></td>
                <td class="py-4"><div class="skeleton h-6 w-24 bg-white/10 rounded-full"></div></td>
                <td class="py-4"><div class="skeleton h-4 w-20 bg-white/10 rounded"></div></td>
                <td class="py-4"><div class="skeleton h-4 w-16 bg-white/10 rounded"></div></td>
                <td class="py-4"><div class="skeleton h-4 w-24 bg-white/10 rounded"></div></td>
                <td class="py-4 pr-3 flex justify-end"><div class="skeleton h-6 w-16 bg-white/10 rounded-md"></div></td>
              </tr>
            </template>

            <template v-else-if="transactions.length > 0">
              <tr 
                v-for="trx in transactions" 
                :key="trx.id" 
                class="hover:bg-white/5 transition-colors duration-150 border-b border-white/10 last:border-0"
              >
                <td class="py-4 pl-3 text-green-50 font-medium text-xs md:text-sm">{{ formatDate(trx.waktu_pencatatan) }}</td>
                <td class="py-4">
                  <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-white/15 text-green-100 border border-white/10">
                    {{ getSpbuName(trx) }}
                  </span>
                </td>
                <td class="py-4 font-mono font-bold text-white tracking-wider">{{ trx.plat_nomor }}</td>
                <td class="py-4 text-white/90 font-semibold">{{ trx.liter }} L</td>
                <td class="py-4 font-black text-emerald-300">{{ formatRupiah(trx.harga) }}</td>
                <td class="py-4 pr-3 text-right">
                  <span class="text-xs text-emerald-300 font-bold bg-emerald-500/20 px-3 py-1 rounded-full border border-emerald-500/30">Success</span>
                </td>
              </tr>
            </template>

            <tr v-else>
              <td colspan="6" class="py-16 text-center text-green-100/60">
                <span class="text-3xl block mb-2">🍃</span>
                <span class="text-sm font-medium">Tidak ada transaksi ditemukan.</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination Bar (Paging Per 10 Transaksi) -->
      <div class="flex flex-col md:flex-row items-center justify-between mt-6 pt-5 border-t border-white/15 gap-4">
        <span class="text-xs text-green-200/70 font-medium order-2 md:order-1">
          Menampilkan {{ transactions.length ? (currentPage - 1) * itemsPerPage + 1 : 0 }} - 
          {{ Math.min(currentPage * itemsPerPage, totalItems) }} dari {{ totalItems }} data
        </span>

        <div class="flex items-center gap-2 order-1 md:order-2">
          <!-- Previous Page Button -->
          <button 
            @click="currentPage--" 
            :disabled="currentPage <= 1 || loading"
            class="px-4 py-2 rounded-full bg-white/10 hover:bg-white/20 disabled:opacity-40 disabled:cursor-not-allowed text-xs font-bold transition-all cursor-pointer"
          >
            Kembali
          </button>

          <!-- Page Numbers -->
          <div class="flex items-center gap-1">
            <button
              v-for="p in totalPages"
              :key="p"
              @click="currentPage = p"
              :class="[
                'w-8 h-8 rounded-full text-xs font-black transition-all cursor-pointer flex items-center justify-center',
                currentPage === p
                  ? 'bg-white text-[#143d2e] shadow-md'
                  : 'text-white/80 hover:bg-white/15'
              ]"
            >
              {{ p }}
            </button>
          </div>

          <!-- Next Page Button -->
          <button 
            @click="currentPage++" 
            :disabled="(currentPage * itemsPerPage) >= totalItems || loading"
            class="px-4 py-2 rounded-full bg-white text-[#143d2e] hover:bg-emerald-50 disabled:opacity-40 disabled:cursor-not-allowed text-xs font-bold transition-all shadow-md cursor-pointer"
          >
            Lanjut
          </button>
        </div>
      </div>

    </div>

  </div>
</template>
