<script setup>
import { ref, watch } from 'vue'
import HistoryHeader from '@/components/history/HistoryHeader.vue'
import HistoryTable from '@/components/history/HistoryTable.vue'
import { useTransactionHistory } from '@/composables/operator/useTransactionHistory'
import { useRepeatedLogs } from '@/composables/operator/useRepeatedLogs'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

// Tab Active State: 'history' | 'pengetap'
const activeTab = ref('history')

// Composable 1: Riwayat Transaksi Sukses Hari Ini
const { 
  transactions, 
  loading: loadingHistory, 
  searchQuery: searchHistory, 
  vehicleFilter,
  dateFrom,
  dateTo,
  sortField,
  sortDir,
  currentPage: pageHistory, 
  totalItems: totalHistory,
  resetFilters: resetHistory
} = useTransactionHistory(10, { dateFilter: true })

// Composable 2: Log Alert Pengetap (grouped accordion)
const itemsPerPagePengetap = 50
const {
  groupedLogs: pengetapGrouped,
  loading: loadingPengetap,
  totalCount: totalPengetap,
  currentPage: pagePengetap,
  searchQuery: searchPengetap,
  fetchOperatorLogs,
  resetFilters: resetPengetap
} = useRepeatedLogs(itemsPerPagePengetap)

// Track which plat rows are expanded (Set of plat_nomor strings)
const expandedPlates = ref(new Set())

const togglePlate = (platNomor) => {
  const s = new Set(expandedPlates.value)
  if (s.has(platNomor)) {
    s.delete(platNomor)
  } else {
    s.add(platNomor)
  }
  expandedPlates.value = s
}

watch(activeTab, (newTab) => {
  if (newTab === 'pengetap') {
    fetchOperatorLogs()
  }
})
  
const formatRupiah = (number) => {
  if (!number && number !== 0) return 'Rp 0'
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(number)
}

const formatWitaTime = (timeStr) => {
  return timeStr || '-'
}

const nextPagePengetap = () => {
  if ((pagePengetap.value * itemsPerPagePengetap) < totalPengetap.value) {
    pagePengetap.value++
  }
}

const prevPagePengetap = () => {
  if (pagePengetap.value > 1) {
    pagePengetap.value--
  }
}
</script>

<template>
  <div class="flex flex-col gap-4 animate-enter pb-6">
    
    <!-- Header Navigation & Tab Switcher Bar -->
    <div class="flex-none flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 px-1">
      
      <!-- Back Button (Desktop Only) -->
      <div class="hidden sm:flex items-center gap-3">
        <router-link 
          to="/operator" 
          class="w-11 h-11 rounded-2xl bg-white hover:bg-gray-100 border border-gray-200 flex items-center justify-center text-[#143d2e] shadow-xs hover:shadow-md active:scale-95 transition-all cursor-pointer shrink-0"
          title="Kembali ke Dashboard"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-5 h-5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
          </svg>
        </router-link>
      </div>

      <!-- Segmented Tab Switcher (Riwayat vs Alert Pengetap) -->
      <div class="flex items-center bg-gray-200/70 p-1 rounded-2xl border border-gray-200 shadow-inner w-full sm:w-auto shrink-0">
        <!-- Tab 1: Riwayat Transaksi -->
        <button
          @click="activeTab = 'history'"
          class="flex-1 sm:flex-none px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center justify-center gap-2 select-none"
          :class="activeTab === 'history' ? 'bg-[#143d2e] text-white shadow-md' : 'text-gray-600 hover:text-gray-900 hover:bg-white/50'"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="w-4 h-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 6.75h12M8.25 12h12m-12 5.25h12M3.75 6.75h.008v.008H3.75V6.75Zm0 5.25h.008v.008H3.75V12Zm0 5.25h.008v.008H3.75v-.008Z" />
          </svg>
          Riwayat Transaksi
        </button>

        <!-- Tab 2: Alert Pengetap -->
        <button
          @click="activeTab = 'pengetap'"
          class="flex-1 sm:flex-none px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center justify-center gap-2 select-none relative"
          :class="activeTab === 'pengetap' ? 'bg-[#143d2e] text-white shadow-md' : 'text-gray-600 hover:text-gray-900 hover:bg-white/50'"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
          </svg>
          Alert Pengetap
        </button>
      </div>

    </div>

    <!-- TAB 1 CONTENT: Riwayat Transaksi Hari Ini -->
    <div 
      v-if="activeTab === 'history'"
      class="flex flex-col gap-4 animate-fade-in"
    >
      <!-- Top Section: Filter Bar -->
      <HistoryHeader 
        v-model="searchHistory" 
        v-model:vehicle-filter="vehicleFilter"
        v-model:date-from="dateFrom"
        v-model:date-to="dateTo"
        v-model:sort-field="sortField"
        v-model:sort-dir="sortDir"
        @reset="resetHistory"
      />

      <!-- Bottom Section: History Table (Deep Green Card) -->
      <HistoryTable 
        :transactions="transactions"
        :loading="loadingHistory"
        :current-page="pageHistory"
        :total-items="totalHistory"
        :items-per-page="10"
        @change-page="(newPage) => pageHistory = newPage"
      />
    </div>

    <!-- TAB 2 CONTENT: Alert Pengetap Terdeteksi Hari Ini -->
    <div 
      v-else-if="activeTab === 'pengetap'"
      class="flex flex-col gap-4 animate-fade-in"
    >
      <!-- Filter Bar -->
      <div class="flex flex-col sm:flex-row justify-between items-center gap-3">
        <!-- Search Input -->
        <div class="relative w-full sm:w-72">
          <input
            v-model="searchPengetap"
            type="text"
            placeholder="Cari Plat, Operator, Jam (21:00), atau Alasan..."
            class="w-full pl-10 pr-4 py-2 bg-white border border-gray-200 rounded-xl text-xs font-bold focus:outline-none focus:ring-2 focus:ring-[#143d2e]/15 focus:border-[#143d2e] transition-all shadow-xs"
          />
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-gray-400 absolute left-3.5 top-2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
        </div>

        <div v-if="searchPengetap" class="flex items-center gap-3 w-full sm:w-auto justify-end">
          <button
            @click="resetPengetap"
            class="text-xs font-bold text-gray-400 hover:text-red-600 transition-colors cursor-pointer"
          >
            Reset Pencarian
          </button>
        </div>
      </div>

      <!-- Accordion Pengetap Section (Deep Green Card) -->
      <div class="bg-gradient-to-br from-[#143d2e] to-[#1e5c45] rounded-[1.5rem] md:rounded-[2rem] p-5 md:p-8 shadow-xl shadow-green-900/10 text-white relative overflow-hidden">
        
        <!-- Glow decoration -->
        <div class="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full blur-3xl -translate-y-20 translate-x-20 pointer-events-none"></div>

        <!-- ── SKELETON ── -->
        <template v-if="loadingPengetap">
          <div class="space-y-3">
            <div v-for="n in 4" :key="n" class="bg-white/10 rounded-2xl p-4 animate-pulse flex items-center gap-4">
              <div class="w-8 h-8 rounded-full bg-white/10 shrink-0"></div>
              <div class="flex-1 space-y-2">
                <div class="h-5 w-32 bg-white/10 rounded"></div>
                <div class="h-3 w-48 bg-white/10 rounded"></div>
              </div>
              <div class="h-6 w-20 bg-white/10 rounded-full"></div>
            </div>
          </div>
        </template>

        <!-- ── EMPTY STATE ── -->
        <div v-else-if="pengetapGrouped.length === 0" class="py-16 text-center text-green-100/50">
          <span class="text-5xl mb-3 block">🍃</span>
          <span class="italic text-sm">Tidak ada percobaan pengetap terdeteksi hari ini.</span>
        </div>

        <!-- ── ACCORDION LIST ── -->
        <div v-else class="space-y-3">
          <div
            v-for="group in pengetapGrouped"
            :key="group.plat_nomor"
            class="rounded-2xl border border-white/10 overflow-hidden transition-all duration-200"
            :class="expandedPlates.has(group.plat_nomor) ? 'bg-white/10' : 'bg-black/20 hover:bg-black/30'"
          >
            <!-- ── HEADER ROW (clickable) ── -->
            <button
              type="button"
              @click="togglePlate(group.plat_nomor)"
              class="w-full flex items-center justify-between px-3 md:px-5 py-3 md:py-4 text-left cursor-pointer transition-colors gap-2"
            >
              <!-- Kiri: Plat Nomor & Kategori Badge -->
              <div class="flex items-center gap-2 min-w-0">
                <span class="text-base md:text-xl font-mono font-black text-white tracking-wider whitespace-nowrap">
                  {{ group.plat_nomor }}
                </span>
                <span
                  class="inline-flex items-center px-2 py-0.5 rounded-full text-[9px] md:text-[10px] font-bold bg-white/10 text-white/90 border border-white/15 shrink-0"
                >
                  {{ group.is_ojol ? 'Ojol' : 'Biasa' }}
                </span>
              </div>

              <!-- Kanan: Ikon Alert + Jumlah Percobaan + Chevron -->
              <div class="flex items-center gap-2 shrink-0">
                <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-red-500/20 border border-red-500/30 text-red-200 text-[10px] md:text-xs font-bold shadow-xs">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3.5 h-3.5 text-red-300">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
                  </svg>
                  {{ group.attempt_count }}x <span class="hidden sm:inline">Percobaan</span>
                </span>

                <!-- Chevron indicator -->
                <div class="shrink-0 w-6 h-6 md:w-7 md:h-7 rounded-full bg-white/10 flex items-center justify-center transition-transform duration-300"
                  :class="expandedPlates.has(group.plat_nomor) ? 'rotate-180' : ''">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3 h-3 md:w-3.5 md:h-3.5 text-white/80">
                    <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
                  </svg>
                </div>
              </div>
            </button>

            <!-- ── EXPANDED DETAIL ROWS ── -->
            <div v-if="expandedPlates.has(group.plat_nomor)" class="border-t border-white/10">
              <!-- Sub-header (3 Columns - Desktop) -->
              <div class="hidden md:grid grid-cols-3 gap-4 px-5 py-2.5 bg-black/20 text-[10px] uppercase tracking-widest text-green-100/50 font-semibold">
                <span>Jam (WITA)</span>
                <span>Lokasi SPBU</span>
                <span class="text-right">Status</span>
              </div>

              <!-- Individual log entries -->
              <div
                v-for="(entry, idx) in group.entries"
                :key="entry.id"
                class="px-3 md:px-5 py-2.5 md:py-3 flex flex-col md:grid md:grid-cols-3 gap-1.5 md:gap-4 items-start md:items-center transition-colors hover:bg-white/5"
                :class="idx < group.entries.length - 1 ? 'border-b border-white/5' : ''"
              >
                <!-- Line 1 Mobile (Waktu + SPBU In-Line) -->
                <div class="flex items-center justify-between w-full md:w-auto">
                  <span class="inline-flex items-center px-2 py-0.5 rounded bg-white/10 text-white font-mono text-[11px] font-bold border border-white/10">
                    {{ formatWitaTime(entry.waktu) }} WITA
                  </span>

                  <div class="flex items-center gap-1 md:hidden">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3 h-3 text-green-300 shrink-0">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
                    </svg>
                    <span class="text-[11px] text-green-100 font-bold">SPBU {{ entry.attempt_spbu_id }}</span>
                  </div>
                </div>

                <!-- 2. SPBU (Desktop Only) -->
                <div class="hidden md:flex items-center gap-1.5">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3.5 h-3.5 text-green-300 shrink-0">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
                  </svg>
                  <span class="text-xs text-green-100/90 font-bold">SPBU {{ entry.attempt_spbu_id }}</span>
                </div>

                <!-- 3. Status -->
                <div class="w-full md:w-auto md:text-right">
                  <span class="text-[10px] md:text-xs text-red-300 font-bold bg-red-500/15 px-2 py-0.5 rounded border border-red-500/20 whitespace-nowrap inline-block">
                    {{ entry.reason === 'category_mismatch' ? 'Ditolak (Beda Kategori)' : 'Ditolak (Kuota Habis)' }}
                  </span>
                </div>
              </div>
            </div>

          </div>
        </div>

        <!-- ── PAGINATION ── -->
        <div class="flex flex-col md:flex-row items-center justify-between mt-6 pt-4 border-t border-white/10 gap-4">
          <span class="text-xs text-green-100/60 order-2 md:order-1">
            Menampilkan {{ pengetapGrouped.length }} plat unik dari {{ totalPengetap }} total percobaan
          </span>
          <div class="flex gap-2 order-1 md:order-2 w-full md:w-auto justify-center">
            <button
              @click="prevPagePengetap"
              :disabled="pagePengetap === 1"
              class="px-6 py-2 rounded-full bg-white/10 hover:bg-white/20 disabled:opacity-50 disabled:cursor-not-allowed text-xs font-bold transition-all flex-1 md:flex-none"
            >
              Prev
            </button>
            <button
              @click="nextPagePengetap"
              :disabled="(pagePengetap * itemsPerPagePengetap) >= totalPengetap"
              class="px-6 py-2 rounded-full bg-white text-[#143d2e] hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed text-xs font-bold transition-all shadow-lg flex-1 md:flex-none"
            >
              Next
            </button>
          </div>
        </div>

      </div>
    </div>

  </div>
</template>