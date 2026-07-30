<script setup>
import { ref, watch } from 'vue'
import HistoryHeader from '@/components/history/HistoryHeader.vue'
import HistoryTable from '@/components/history/HistoryTable.vue'
import { useTransactionHistory } from '@/composables/useTransactionHistory'
import { useRepeatedLogs } from '@/composables/useRepeatedLogs'
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
const itemsPerPagePengetap = 10
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
  if (!timeStr || typeof timeStr !== 'string' || !timeStr.includes(':')) return timeStr || '-'
  const parts = timeStr.split(':')
  const h = parseInt(parts[0], 10)
  const m = parts[1]
  if (!isNaN(h)) {
    const witaHour = (h + 8) % 24
    return `${String(witaHour).padStart(2, '0')}:${m}`
  }
  return timeStr
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
  <div class="flex flex-col h-full gap-4 animate-enter overflow-hidden pb-2">
    
    <!-- Header Navigation & Tab Switcher Bar -->
    <div class="flex-none flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 px-1">
      
      <!-- Back Button & Page Title -->
      <div class="flex items-center gap-3">
        <router-link 
          to="/operator" 
          class="w-11 h-11 rounded-2xl bg-white hover:bg-green-50 border border-green-200 flex items-center justify-center text-[#143d2e] shadow-xs hover:shadow-md active:scale-95 transition-all cursor-pointer shrink-0"
          title="Kembali ke Dashboard"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-5 h-5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
          </svg>
        </router-link>

        <div>
          <h2 class="text-xl md:text-2xl font-black text-[#143d2e] tracking-tight leading-none">
            Aktivitas Operasional
          </h2>
          <p class="text-xs text-gray-500 font-medium mt-1">
            Pantau riwayat pengisian sukses & audit alert pengetap hari ini
          </p>
        </div>
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
          :class="activeTab === 'pengetap' ? 'bg-amber-600 text-white shadow-md' : 'text-gray-600 hover:text-gray-900 hover:bg-white/50'"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
          </svg>
          Alert Pengetap
          <span 
            v-if="totalPengetap > 0"
            class="px-1.5 py-0.5 rounded-full text-[10px] font-black"
            :class="activeTab === 'pengetap' ? 'bg-white text-amber-700' : 'bg-amber-500 text-white'"
          >
            {{ totalPengetap }}
          </span>
        </button>
      </div>

    </div>

    <!-- TAB 1 CONTENT: Riwayat Transaksi Hari Ini -->
    <div 
      v-if="activeTab === 'history'"
      class="flex-1 min-h-0 bg-white rounded-3xl border border-gray-100 shadow-xs flex flex-col overflow-hidden animate-fade-in"
    >
      <!-- Top Section: Filter Bar -->
      <div class="p-4 border-b border-gray-100 bg-white">
        <HistoryHeader 
          v-model="searchHistory" 
          v-model:vehicle-filter="vehicleFilter"
          v-model:date-from="dateFrom"
          v-model:date-to="dateTo"
          v-model:sort-field="sortField"
          v-model:sort-dir="sortDir"
          @reset="resetHistory"
        />
      </div>

      <!-- Bottom Section: History Table -->
      <div class="flex-1 overflow-y-auto p-4 bg-gray-50/50">
        <HistoryTable 
          :transactions="transactions"
          :loading="loadingHistory"
          :current-page="pageHistory"
          :total-items="totalHistory"
          :items-per-page="10"
          @change-page="(newPage) => pageHistory = newPage"
        />
      </div>
    </div>

    <!-- TAB 2 CONTENT: Alert Pengetap Terdeteksi Hari Ini -->
    <div 
      v-else-if="activeTab === 'pengetap'"
      class="flex-1 min-h-0 bg-white rounded-3xl border border-gray-100 shadow-xs flex flex-col overflow-hidden animate-fade-in"
    >
      <!-- Filter Bar -->
      <div class="p-4 border-b border-gray-100 bg-white flex flex-col sm:flex-row justify-between items-center gap-3">
        <!-- Search Input -->
        <div class="relative w-full sm:w-72">
          <input
            v-model="searchPengetap"
            type="text"
            placeholder="Cari Plat Terduga..."
            class="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl text-xs font-bold focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-500 focus:bg-white transition-all"
          />
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-gray-400 absolute left-3.5 top-2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
        </div>

        <div class="flex items-center gap-3 w-full sm:w-auto justify-end">
          <button
            v-if="searchPengetap"
            @click="resetPengetap"
            class="text-xs font-bold text-gray-400 hover:text-red-600 transition-colors cursor-pointer"
          >
            Reset Pencarian
          </button>

          <button
            @click="fetchOperatorLogs"
            :disabled="loadingPengetap"
            class="px-3 py-1.5 bg-amber-50 hover:bg-amber-100 border border-amber-200 text-amber-900 rounded-xl text-xs font-bold transition-all active:scale-95 flex items-center gap-1.5 cursor-pointer disabled:opacity-50"
            title="Segarkan Data Log"
          >
            <svg 
              xmlns="http://www.w3.org/2000/svg" 
              fill="none" 
              viewBox="0 0 24 24" 
              stroke-width="2" 
              stroke="currentColor" 
              class="w-3.5 h-3.5"
              :class="{ 'animate-spin': loadingPengetap }"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182m0-4.991v4.99" />
            </svg>
            Segarkan Log
          </button>
        </div>
      </div>

      <!-- Accordion Pengetap Section -->
      <div class="flex-1 overflow-y-auto p-4 bg-gray-50/40">
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
                class="w-full flex items-center gap-3 px-4 py-3.5 text-left cursor-pointer transition-colors"
              >
                <!-- Chevron -->
                <div class="shrink-0 w-7 h-7 rounded-full bg-white/10 flex items-center justify-center transition-transform duration-300"
                  :class="expandedPlates.has(group.plat_nomor) ? 'rotate-180' : ''">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5 text-white/80">
                    <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
                  </svg>
                </div>

                <!-- Plat Nomor -->
                <span class="text-lg font-mono font-black text-white tracking-widest flex-shrink-0">
                  {{ group.plat_nomor }}
                </span>

                <!-- Kategori badge -->
                <span
                  class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold shrink-0"
                  :class="group.is_ojol ? 'bg-green-500/20 text-green-200 border border-green-500/30' : 'bg-blue-500/20 text-blue-200 border border-blue-500/30'"
                >
                  {{ group.is_ojol ? 'Motor OJOL' : 'Motor Biasa' }}
                </span>

                <!-- Spacer -->
                <div class="flex-1"></div>

                <!-- Attempt count badge -->
                <div class="flex items-center gap-1.5 shrink-0">
                  <span class="inline-flex items-center gap-1 px-3 py-1 rounded-full bg-red-500/20 border border-red-500/30 text-red-200 text-xs font-bold">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3 h-3">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
                    </svg>
                    {{ group.attempt_count }}x Percobaan
                  </span>

                  <!-- Latest time badge -->
                  <span class="hidden sm:inline-flex items-center px-2 py-1 rounded-lg bg-amber-400/20 border border-amber-400/30 text-amber-300 font-mono text-xs font-bold">
                    {{ formatWitaTime(group.latest_waktu) }} WITA
                  </span>

                  <!-- SPBU list pill -->
                  <span class="hidden md:inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-white/10 border border-white/10 text-green-100 text-xs font-bold">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3 h-3 text-green-300">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
                    </svg>
                    {{ group.spbu_ids.join(', ') }}
                  </span>
                </div>
              </button>

              <!-- ── EXPANDED DETAIL ROWS ── -->
              <div v-if="expandedPlates.has(group.plat_nomor)" class="border-t border-white/10">
                <!-- Sub-header -->
                <div class="hidden md:grid grid-cols-5 gap-4 px-4 py-2 bg-black/20 text-[10px] uppercase tracking-widest text-green-100/50 font-semibold">
                  <span>Jam (WITA)</span>
                  <span>Lokasi SPBU</span>
                  <span>Operator Bertugas</span>
                  <span class="text-right">Akumulasi Terisi</span>
                  <span class="text-right">Status</span>
                </div>

                <!-- Individual log entries -->
                <div
                  v-for="(entry, idx) in group.entries"
                  :key="entry.id"
                  class="px-4 py-3 flex flex-col md:grid md:grid-cols-5 gap-2 md:gap-4 items-start md:items-center transition-colors hover:bg-white/5"
                  :class="idx < group.entries.length - 1 ? 'border-b border-white/5' : ''"
                >
                  <!-- Jam -->
                  <div>
                    <span class="inline-flex items-center px-2 py-0.5 rounded-md bg-amber-400/15 text-amber-300 font-mono text-xs font-bold border border-amber-400/20">
                      {{ formatWitaTime(entry.waktu) }} WITA
                    </span>
                    <span class="md:hidden text-[10px] text-green-100/40 ml-2">{{ entry.tanggal }}</span>
                  </div>

                  <!-- SPBU -->
                  <div class="flex items-center gap-1.5">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3 h-3 text-green-300 shrink-0">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
                    </svg>
                    <span class="text-xs text-green-100/80 font-medium">SPBU {{ entry.attempt_spbu_id }}</span>
                  </div>

                  <!-- Operator -->
                  <div class="flex items-center gap-2">
                    <div class="w-5 h-5 rounded-full bg-white/15 flex items-center justify-center text-[9px] text-green-200 border border-white/20 font-bold shrink-0">
                      {{ (entry.nama_operator || 'O')[0] }}
                    </div>
                    <span class="text-xs text-white/80 font-medium uppercase">{{ entry.nama_operator || 'Operator' }}</span>
                  </div>

                  <!-- Akumulasi -->
                  <div class="text-right">
                    <span class="text-sm font-black text-amber-300">{{ formatRupiah(entry.total_harga_today) }}</span>
                    <p class="md:hidden text-[10px] text-amber-200/50">Akumulasi Terisi</p>
                  </div>

                  <!-- Status -->
                  <div class="text-right">
                    <span class="text-xs text-red-300 font-bold bg-red-500/15 px-2 py-0.5 rounded-md border border-red-500/20 whitespace-nowrap">
                      Ditolak
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

  </div>
</template>