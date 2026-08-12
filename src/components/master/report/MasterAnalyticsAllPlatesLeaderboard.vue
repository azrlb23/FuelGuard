<script setup>
import { ref } from 'vue'

const props = defineProps({
  loading: {
    type: Boolean,
    default: false
  },
  topPlates: {
    type: Array,
    default: () => []
  },
  formatRupiah: {
    type: Function,
    required: true
  },
  formatVolume: {
    type: Function,
    required: true
  }
})

// Expanded state tracking (set of expanded plate numbers)
const expandedPlates = ref(new Set())

const toggleExpand = (platNomor) => {
  if (expandedPlates.value.has(platNomor)) {
    expandedPlates.value.delete(platNomor)
  } else {
    expandedPlates.value.add(platNomor)
  }
}

const isExpanded = (platNomor) => expandedPlates.value.has(platNomor)

// Formatters
const formatDateOnly = (dateStr) => {
  if (!dateStr) return '-'
  const d = new Date(dateStr)
  if (isNaN(d.getTime())) return dateStr
  return d.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
}

const formatTimeOnly = (dateStr) => {
  if (!dateStr) return '-'
  const d = new Date(dateStr)
  if (isNaN(d.getTime())) return dateStr
  return d.toLocaleTimeString('id-ID', {
    timeZone: 'Asia/Makassar',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  }).replace('.', ':') + ' WITA'
}
</script>

<template>
  <div class="bg-white rounded-3xl p-6 border border-gray-100 shadow-sm hover:shadow-md transition-all duration-300">
    <!-- Header Title -->
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 mb-4 pb-3 border-b border-gray-100">
      <div>
        <h3 class="text-lg md:text-xl font-extrabold text-[#143d2e] tracking-tight">
          Peringkat Plat Bedasarkan Pembelian
        </h3>
        <!-- <p class="text-xs text-gray-500 font-medium mt-0.5">
          Top 10 kendaraan pengisi BBM Pertalite dengan volume tertinggi di seluruh SPBU. Klik baris untuk melihat riwayat pengisian.
        </p> -->
      </div>

      <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-black bg-emerald-50 text-emerald-800 border border-emerald-200/60 shrink-0">
        {{ topPlates.length }} Plat Teratas
      </span>
    </div>

    <!-- Loading Skeleton -->
    <div v-if="loading" class="space-y-3 py-2">
      <div v-for="i in 3" :key="i" class="h-14 bg-gray-100 animate-pulse rounded-2xl"></div>
    </div>

    <!-- Plates List Accordion -->
    <div v-else-if="topPlates && topPlates.length > 0" class="space-y-2.5">
      <div
        v-for="(item, idx) in topPlates"
        :key="item.plat_nomor"
        class="border border-gray-200/80 hover:border-emerald-500/40 rounded-2xl overflow-hidden transition-all duration-200 shadow-2xs"
      >
        <!-- Item Header Bar (Clickable) -->
        <div
          @click="toggleExpand(item.plat_nomor)"
          class="p-3.5 sm:p-4 bg-gray-50/60 hover:bg-gray-100/70 flex items-center justify-between gap-3 cursor-pointer select-none transition-colors"
        >
          <!-- Left: Circular Rank Badge & Plat Info -->
          <div class="flex items-center gap-3 min-w-0">
            <!-- Rank Badge (Circular, matching SPBU leaderboard style) -->
            <span
              class="w-7 h-7 sm:w-8 sm:h-8 rounded-full text-xs font-black inline-flex items-center justify-center shrink-0 bg-gray-100 text-gray-600 shadow-2xs"
            >
              #{{ idx + 1 }}
            </span>

            <!-- Plat Nomor & Clean Subtitle (No symbols, no pills, no summary Ojol badge) -->
            <div class="min-w-0 flex-1">
              <div class="font-mono font-black text-sm sm:text-base text-gray-900 tracking-wider">
                {{ item.plat_nomor }}
              </div>

              <!-- Clean Text Subtitle in Dark Green (Slightly larger font size) -->
              <div class="text-xs text-[#143d2e] font-bold mt-0.5 truncate">
                {{ item.trx_count }}x Transaksi
                <span class="mx-1 opacity-60">•</span>
                <span v-if="item.unique_spbu_count > 1">{{ item.unique_spbu_count }} SPBU</span>
                <span v-else>1 SPBU</span>
              </div>
            </div>
          </div>

          <!-- Right: Volume & Rp + Chevron -->
          <div class="flex items-center gap-3 shrink-0">
            <div class="text-right">
              <div class="text-sm font-black text-[#143d2e]">
                {{ formatVolume(item.total_liter) }}
              </div>
              <div class="text-xs font-bold text-gray-500">
                {{ formatRupiah(item.total_harga) }}
              </div>
            </div>

            <!-- Toggle Chevron Button -->
            <button
              type="button"
              class="w-7 h-7 rounded-full bg-gray-200/60 flex items-center justify-center text-gray-600 transition-all duration-200 shrink-0"
              :class="isExpanded(item.plat_nomor) ? 'rotate-180 bg-[#143d2e] text-white' : ''"
              aria-label="Toggle rincian transaksi"
            >
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
                <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
              </svg>
            </button>
          </div>
        </div>

        <!-- Expanded Dropdown Section: Sub-Transactions List -->
        <div
          v-if="isExpanded(item.plat_nomor)"
          class="p-4 bg-gray-50 border-t border-gray-200/80 animate-enter"
        >
          <div class="flex items-center justify-between mb-2 pb-2 border-b border-gray-200/60">
            <h4 class="text-xs font-extrabold text-[#143d2e] uppercase tracking-wider">
              Rincian Pengisian ({{ item.transactions ? item.transactions.length : 0 }} Transaksi)
            </h4>
          </div>

          <!-- If sub-transactions exist -->
          <div v-if="item.transactions && item.transactions.length > 0">
            <!-- Desktop View: Clean Table -->
            <div class="hidden sm:block overflow-x-auto">
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="text-xs font-extrabold text-gray-500 uppercase tracking-wider border-b border-gray-200">
                    <th class="py-2.5 px-3">TANGGAL</th>
                    <th class="py-2.5 px-3">WAKTU</th>
                    <th class="py-2.5 px-3">LOKASI SPBU</th>
                    <th class="py-2.5 px-3">KATEGORI</th>
                    <th class="py-2.5 px-3 text-right">VOLUME</th>
                    <th class="py-2.5 px-3 text-right">NOMINAL</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200/60 text-sm">
                  <tr
                    v-for="trx in item.transactions"
                    :key="trx.id"
                    class="hover:bg-white transition-colors"
                  >
                    <!-- Tanggal -->
                    <td class="py-3 px-3 font-semibold text-gray-800">
                      {{ formatDateOnly(trx.waktu_pencatatan) }}
                    </td>

                    <!-- Jam / Waktu -->
                    <td class="py-3 px-3 font-mono font-bold text-gray-700">
                      {{ formatTimeOnly(trx.waktu_pencatatan) }}
                    </td>

                    <!-- Lokasi SPBU -->
                    <td class="py-3 px-3 font-bold text-gray-900">
                      {{ trx.spbu_nama }}
                    </td>

                    <!-- Kategori (Ojol matches PDF export button dark green) -->
                    <td class="py-3 px-3">
                      <span
                        :class="[
                          'px-2.5 py-0.5 text-[10px] font-extrabold rounded-md uppercase border',
                          trx.is_ojol
                            ? 'bg-[#143d2e] text-white border-[#143d2e]'
                            : 'bg-gray-100 text-gray-700 border-gray-200'
                        ]"
                      >
                        {{ trx.is_ojol ? 'Ojol' : 'Umum' }}
                      </span>
                    </td>

                    <!-- Volume -->
                    <td class="py-2.5 px-3 text-right font-black text-[#143d2e]">
                      {{ formatVolume(trx.liter) }}
                    </td>

                    <!-- Nominal -->
                    <td class="py-2.5 px-3 text-right font-bold text-gray-800">
                      {{ formatRupiah(trx.harga) }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Mobile View: Compact Cards -->
            <div class="block sm:hidden space-y-2">
              <div
                v-for="trx in item.transactions"
                :key="trx.id"
                class="bg-white p-3 rounded-xl border border-gray-200/70 space-y-1.5 text-xs shadow-2xs"
              >
                <!-- Top Row: Date & Time -->
                <div class="flex items-center justify-between border-b border-gray-100 pb-1.5">
                  <span class="font-bold text-gray-800">
                    {{ formatDateOnly(trx.waktu_pencatatan) }}
                  </span>
                  <span class="font-mono font-bold text-[#143d2e] text-[11px]">
                    {{ formatTimeOnly(trx.waktu_pencatatan) }}
                  </span>
                </div>

                <!-- Middle Row: SPBU & Kategori -->
                <div class="flex items-center justify-between gap-2 pt-0.5">
                  <div class="font-bold text-gray-900 truncate">
                    {{ trx.spbu_nama }}
                  </div>

                  <span
                    :class="[
                      'px-2 py-0.5 text-[9px] font-extrabold rounded-md uppercase shrink-0 border',
                      trx.is_ojol
                        ? 'bg-[#143d2e] text-white border-[#143d2e]'
                        : 'bg-gray-100 text-gray-700 border-gray-200'
                    ]"
                  >
                    {{ trx.is_ojol ? 'Ojol' : 'Umum' }}
                  </span>
                </div>

                <!-- Bottom Row: Volume & Nominal -->
                <div class="flex items-center justify-between text-[11px] pt-1 text-gray-600 font-semibold border-t border-gray-100">
                  <span>Volume: <strong class="text-[#143d2e] font-black">{{ formatVolume(trx.liter) }}</strong></span>
                  <span>Total: <strong class="text-gray-900 font-bold">{{ formatRupiah(trx.harga) }}</strong></span>
                </div>
              </div>
            </div>
          </div>

          <div v-else class="text-xs text-gray-400 py-3 text-center">
            Tidak ada riwayat rincian pengisian.
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else class="py-10 text-center text-gray-400">
      <span class="text-3xl mb-2 block">🍃</span>
      <p class="text-xs font-semibold">Tidak ada transaksi ditemukan pada periode filter ini.</p>
    </div>
  </div>
</template>
