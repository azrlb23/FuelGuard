<script setup>
import { computed } from 'vue'
import MasterHistoryFilterBar from './MasterHistoryFilterBar.vue'

const props = defineProps({
  loading: {
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
  'update:selectedSpbu',
  'update:dateFrom',
  'update:dateTo',
  'sortChange',
  'resetFilters',
  'removeFilter'
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
  <div class="bg-gradient-to-br from-[#143d2e] to-[#1e5c45] rounded-[2rem] p-6 md:p-8 shadow-xl shadow-green-900/10 text-white relative overflow-hidden border border-green-800/40">
    
    <div class="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full blur-3xl pointer-events-none"></div>

    <!-- Integrated Filter Bar -->
    <MasterHistoryFilterBar
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
              <span class="text-white/40">•</span>
              <span class="font-mono text-green-300">{{ formatTimeOnly(trx.waktu_pencatatan) }}</span>
            </div>
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

    <!-- Desktop Table View -->
    <div class="hidden md:block overflow-x-auto">
      <table class="w-full text-left border-collapse">
        <thead>
          <tr class="text-green-200/70 text-xs font-bold uppercase tracking-wider border-b border-white/15 pb-4">
            <th class="pb-4 pl-3">TANGGAL</th>
            <th class="pb-4">WAKTU</th>
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
              <td class="py-4 pl-3"><div class="skeleton h-4 w-24 bg-white/10 rounded"></div></td>
              <td class="py-4"><div class="skeleton h-4 w-16 bg-white/10 rounded"></div></td>
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
              <td class="py-4 pl-3 text-green-50 font-medium text-xs md:text-sm">{{ formatDateOnly(trx.waktu_pencatatan) }}</td>
              <td class="py-4 text-green-200/90 font-mono text-xs md:text-sm">{{ formatTimeOnly(trx.waktu_pencatatan) }}</td>
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
            <td colspan="7" class="py-16 text-center text-green-100/60">
              <span class="text-3xl block mb-2">🍃</span>
              <span class="text-sm font-medium">Tidak ada transaksi ditemukan.</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Pagination Bar (Paging Per 10 Transaksi) -->
    <div class="flex flex-col sm:flex-row items-center justify-between mt-6 pt-5 border-t border-white/15 gap-4">
      <span class="text-xs text-green-200/70 font-medium order-2 sm:order-1 text-center sm:text-left">
        Menampilkan {{ transactions.length ? ((currentPage - 1) * itemsPerPage + 1).toLocaleString('id-ID') : 0 }} - 
        {{ Math.min(currentPage * itemsPerPage, totalItems).toLocaleString('id-ID') }} dari {{ totalItems.toLocaleString('id-ID') }} data
      </span>

      <div class="flex items-center gap-1.5 order-1 sm:order-2 flex-wrap justify-center">
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
