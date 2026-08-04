<script setup>
import { useRepeatedLogs } from '@/composables/operator/useRepeatedLogs'

const itemsPerPage = 10
const {
  logs,
  loading,
  totalCount,
  currentPage,
  searchQuery,
  resetFilters
} = useRepeatedLogs(itemsPerPage)

const formatRupiah = (number) => {
  if (!number && number !== 0) return 'Rp 0'
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(number)
}

const nextPage = () => {
  if ((currentPage.value * itemsPerPage) < totalCount.value) {
    currentPage.value++
  }
}

const prevPage = () => {
  if (currentPage.value > 1) {
    currentPage.value--
  }
}
</script>

<template>
  <div class="flex flex-col h-full gap-4 animate-enter overflow-hidden pb-2">
    
    <!-- Top Action Bar -->
    <div class="flex-none flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 px-1">
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
            Audit Pengetap Terdeteksi
          </h2>
          <p class="text-xs text-gray-500 font-medium mt-1">
            Daftar kendaraan yang terdeteksi mencoba pengisian berulang melebihi kuota hari ini
          </p>
        </div>
      </div>

      <!-- Counter Badge -->
      <div class="flex items-center gap-2 bg-amber-50 border border-amber-200/80 px-4 py-2 rounded-2xl shadow-2xs shrink-0">
        <span class="text-xs font-bold text-amber-900 uppercase tracking-wider">Terdeteksi Hari Ini:</span>
        <span class="text-sm font-black text-amber-700 bg-amber-200/60 px-2.5 py-0.5 rounded-lg">
          {{ totalCount }}
        </span>
      </div>
    </div>

    <!-- Main Content Card -->
    <div class="flex-1 min-h-0 bg-white rounded-3xl border border-gray-100 shadow-xs flex flex-col overflow-hidden">
      
      <!-- Filter Bar -->
      <div class="p-4 border-b border-gray-100 bg-white flex flex-col sm:flex-row justify-between items-center gap-3">
        <!-- Search Input -->
        <div class="relative w-full sm:w-72">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Cari Plat Nomor..."
            class="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl text-xs font-bold focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] focus:bg-white transition-all"
          />
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-gray-400 absolute left-3.5 top-2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
        </div>

        <button
          v-if="searchQuery"
          @click="resetFilters"
          class="text-xs font-bold text-gray-400 hover:text-red-600 transition-colors cursor-pointer"
        >
          Reset Pencarian
        </button>
      </div>

      <!-- Table Section -->
      <div class="flex-1 overflow-y-auto p-4 bg-gray-50/40">
        <div class="bg-gradient-to-br from-[#143d2e] to-[#1e5c45] rounded-2xl p-4 md:p-6 shadow-xl text-white relative overflow-hidden">
          
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-green-100/70 text-xs uppercase tracking-wider border-b border-white/10">
                  <th class="pb-3 pl-2 font-medium">Jam</th>
                  <th class="pb-3 font-medium">Plat Nomor</th>
                  <th class="pb-3 font-medium">Kategori</th>
                  <th class="pb-3 font-medium text-right">Percobaan Liter</th>
                  <th class="pb-3 font-medium text-right">Akumulasi Hari Ini</th>
                  <th class="pb-3 font-medium">Operator Bertugas</th>
                  <th class="pb-3 pr-2 font-medium text-right">Status</th>
                </tr>
              </thead>
              <tbody class="text-sm">
                <!-- Skeleton Loader -->
                <template v-if="loading">
                  <tr v-for="n in 4" :key="n" class="border-b border-white/5">
                    <td class="py-3.5 pl-2"><div class="skeleton h-4 w-12 bg-white/10 rounded"></div></td>
                    <td class="py-3.5"><div class="skeleton h-4 w-24 bg-white/10 rounded"></div></td>
                    <td class="py-3.5"><div class="skeleton h-6 w-20 bg-white/10 rounded-full"></div></td>
                    <td class="py-3.5 text-right"><div class="skeleton h-4 w-12 bg-white/10 rounded ml-auto"></div></td>
                    <td class="py-3.5 text-right"><div class="skeleton h-4 w-20 bg-white/10 rounded ml-auto"></div></td>
                    <td class="py-3.5"><div class="skeleton h-4 w-24 bg-white/10 rounded"></div></td>
                    <td class="py-3.5 pr-2 text-right"><div class="skeleton h-6 w-20 bg-white/10 rounded ml-auto"></div></td>
                  </tr>
                </template>

                <!-- Data Rows -->
                <template v-else-if="logs.length > 0">
                  <tr
                    v-for="item in logs"
                    :key="item.id"
                    class="group hover:bg-white/5 transition-colors duration-200 border-b border-white/5 last:border-0"
                  >
                    <td class="py-3.5 pl-2 text-green-300 font-mono text-xs md:text-sm font-bold">
                      {{ item.waktu }}
                    </td>
                    <td class="py-3.5 font-mono font-bold text-white tracking-wider">
                      {{ item.plat_nomor }}
                    </td>
                    <td class="py-3.5">
                      <span 
                        class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold"
                        :class="item.is_ojol ? 'bg-emerald-500/20 text-emerald-200 border border-emerald-500/30' : 'bg-white/10 text-white/80 border border-white/10'"
                      >
                        {{ item.is_ojol ? 'Ojol' : 'Umum' }}
                      </span>
                    </td>
                    <td class="py-3.5 text-right text-white/90 font-medium">
                      {{ item.attempted_liter }} L
                    </td>
                    <td class="py-3.5 text-right font-bold text-amber-300">
                      {{ formatRupiah(item.total_harga_today) }}
                    </td>
                    <td class="py-3.5 text-green-100/90 text-xs font-medium uppercase">
                      {{ item.nama_operator || '-' }}
                    </td>
                    <td class="py-3.5 pr-2 text-right">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-md text-[10px] font-bold uppercase tracking-wider bg-red-500/25 text-red-200 border border-red-500/30">
                        Ditolak (Kuota Habis)
                      </span>
                    </td>
                  </tr>
                </template>

                <!-- Empty State -->
                <tr v-else>
                  <td colspan="7" class="py-12 text-center text-green-100/50">
                    <div class="flex flex-col items-center justify-center space-y-2">
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-10 h-10 opacity-40">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                      <span class="italic text-sm">Tidak ada percobaaan pengetap terdeteksi hari ini.</span>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Pagination Footer -->
          <div class="flex flex-col sm:flex-row items-center justify-between mt-6 pt-4 border-t border-white/10 gap-3">
            <span class="text-xs text-green-100/60 order-2 sm:order-1">
              Menampilkan {{ logs.length ? (currentPage - 1) * itemsPerPage + 1 : 0 }} - 
              {{ Math.min(currentPage * itemsPerPage, totalCount) }} dari {{ totalCount }} data
            </span>

            <div class="flex gap-2 order-1 sm:order-2 w-full sm:w-auto justify-center">
              <button 
                @click="prevPage" 
                :disabled="currentPage === 1"
                class="px-5 py-1.5 rounded-full bg-white/10 hover:bg-white/20 disabled:opacity-40 disabled:cursor-not-allowed text-xs font-bold transition-all cursor-pointer flex-1 sm:flex-none"
              >
                Prev
              </button>
              <button 
                @click="nextPage" 
                :disabled="(currentPage * itemsPerPage) >= totalCount"
                class="px-5 py-1.5 rounded-full bg-white text-[#143d2e] hover:bg-gray-100 disabled:opacity-40 disabled:cursor-not-allowed text-xs font-bold transition-all shadow-md cursor-pointer flex-1 sm:flex-none"
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
