<script setup>
import { ref } from 'vue'

const props = defineProps({
  transactions: Array,
  loading: Boolean,
  currentPage: Number,
  totalItems: Number,
  itemsPerPage: Number
})

const emit = defineEmits(['changePage'])

// Track expanded card IDs on mobile view
const expandedTrx = ref(new Set())

const toggleTrx = (id) => {
  const s = new Set(expandedTrx.value)
  if (s.has(id)) {
    s.delete(id)
  } else {
    s.add(id)
  }
  expandedTrx.value = s
}

const formatRupiah = (number) => {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(number)
}

const formatDateOnly = (dateString) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
}

const formatTimeOnly = (dateString) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', hour12: false }).replace('.', ':')
}

const nextPage = () => {
  if ((props.currentPage * props.itemsPerPage) < props.totalItems) {
    emit('changePage', props.currentPage + 1)
  }
}

const prevPage = () => {
  if (props.currentPage > 1) {
    emit('changePage', props.currentPage - 1)
  }
}
</script>

<template>
  <div class="bg-gradient-to-br from-[#143d2e] to-[#1e5c45] rounded-[1.5rem] md:rounded-[2rem] p-5 md:p-8 shadow-xl shadow-green-900/10 text-white relative overflow-hidden">
    
    <div class="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full blur-3xl -translate-y-20 translate-x-20 pointer-events-none"></div>

    <!-- 📱 MOBILE VIEW: COLLAPSIBLE ACCORDION CARDS 📱 -->
    <div class="block md:hidden space-y-2.5">
      
      <template v-if="loading">
        <div v-for="n in 3" :key="n" class="bg-white/10 rounded-2xl p-3 animate-pulse flex items-center justify-between">
          <div class="h-5 w-28 bg-white/10 rounded"></div>
          <div class="h-5 w-20 bg-white/10 rounded"></div>
        </div>
      </template>

      <template v-else-if="transactions.length > 0">
        <div 
          v-for="trx in transactions" 
          :key="trx.id" 
          class="rounded-2xl border border-white/10 overflow-hidden transition-all duration-200"
          :class="expandedTrx.has(trx.id) ? 'bg-white/10' : 'bg-black/20 hover:bg-black/30'"
        >
          <!-- Collapsed Header Row (Clickable) -->
          <button
            type="button"
            @click="toggleTrx(trx.id)"
            class="w-full flex items-center justify-between px-3.5 py-3 text-left cursor-pointer transition-colors gap-2"
          >
            <!-- Kiri: Plat Nomor -->
            <span class="text-base font-mono font-black tracking-wider text-white whitespace-nowrap">
              {{ trx.plat_nomor }}
            </span>

            <!-- Kanan: Waktu WITA & Chevron Indicator -->
            <div class="flex items-center gap-2 shrink-0">
              <span class="inline-flex items-center px-2 py-0.5 rounded bg-white/10 text-white font-mono text-[11px] font-bold border border-white/10">
                {{ formatTimeOnly(trx.waktu_pencatatan) }} WITA
              </span>

              <div 
                class="shrink-0 w-6 h-6 rounded-full bg-white/10 flex items-center justify-center transition-transform duration-300"
                :class="expandedTrx.has(trx.id) ? 'rotate-180' : ''"
              >
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5 text-white/80">
                  <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
                </svg>
              </div>
            </div>
          </button>

          <!-- Expanded Details Section -->
          <div v-if="expandedTrx.has(trx.id)" class="border-t border-white/10 px-3.5 py-3 space-y-2 bg-black/20 text-xs">
            <div class="flex justify-between items-center">
              <span class="text-green-100/60 font-medium">Kategori Kendaraan</span>
              <span 
                class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wide border border-white/15"
                :class="trx.is_ojol ? 'bg-green-500/20 text-green-200' : 'bg-white/10 text-white/90'"
              >
                {{ trx.is_ojol ? 'Ojol' : 'Umum' }}
              </span>
            </div>

            <div class="flex justify-between items-center">
              <span class="text-green-100/60 font-medium">Volume Pengisian</span>
              <span class="font-bold text-white">{{ trx.liter }} Liter</span>
            </div>

            <div class="flex justify-between items-center">
              <span class="text-green-100/60 font-medium">Total Transaksi</span>
              <span class="font-black text-green-300 text-sm">{{ formatRupiah(trx.harga) }}</span>
            </div>

            <div v-if="trx.spbu_nama || trx.spbu_id" class="flex justify-between items-center">
              <span class="text-green-100/60 font-medium">SPBU / Lokasi</span>
              <span class="font-bold text-green-200">{{ trx.spbu_nama || ('SPBU ' + trx.spbu_id) }}</span>
            </div>

            <div v-if="trx.nama_operator" class="flex justify-between items-center">
              <span class="text-green-100/60 font-medium">Operator Bertugas</span>
              <span class="font-bold text-white uppercase">{{ trx.nama_operator }}</span>
            </div>

            <div class="flex justify-between items-center pt-1 border-t border-white/5 text-[10px] text-green-100/40">
              <span>Tanggal</span>
              <span>{{ formatDateOnly(trx.waktu_pencatatan) }}</span>
            </div>
          </div>
        </div>
      </template>

      <div v-else class="py-10 text-center text-green-100/50">
        <span class="text-4xl mb-2 block">🍃</span>
        <span class="italic text-sm">Tidak ada riwayat transaksi.</span>
      </div>
    </div>

    <div class="hidden md:block overflow-x-auto">
      <table class="w-full text-left border-collapse">
        <thead class="border-b border-white/15 text-emerald-200/90">
          <tr class="text-xs font-extrabold uppercase tracking-wider">
            <th class="py-3.5 pl-3">Tanggal</th>
            <th class="py-3.5">Waktu</th>
            <th class="py-3.5">Operator</th>
            <th class="py-3.5">Kendaraan</th>
            <th class="py-3.5">Plat Nomor</th>
            <th class="py-3.5">Volume</th>
            <th class="py-3.5 pr-3">Revenue</th>
          </tr>
        </thead>
        <tbody class="text-sm">
          <template v-if="loading">
            <tr v-for="n in 5" :key="n" class="border-b border-white/5">
              <td class="py-4 pl-2"><div class="skeleton h-4 w-24 bg-white/10 rounded"></div></td>
              <td class="py-4"><div class="skeleton h-4 w-16 bg-white/10 rounded"></div></td>
              <td class="py-4"><div class="skeleton h-4 w-20 bg-white/10 rounded"></div></td>
              <td class="py-4"><div class="skeleton h-6 w-16 bg-white/10 rounded-full"></div></td>
              <td class="py-4"><div class="skeleton h-4 w-20 bg-white/10 rounded"></div></td>
              <td class="py-4"><div class="skeleton h-4 w-12 bg-white/10 rounded"></div></td>
              <td class="py-4 pr-2"><div class="skeleton h-4 w-24 bg-white/10 rounded"></div></td>
            </tr>
          </template>

          <template v-else-if="transactions.length > 0">
            <tr 
              v-for="trx in transactions" 
              :key="trx.id" 
              class="group hover:bg-white/5 transition-colors duration-200 border-b border-white/5 last:border-0"
            >
              <td class="py-4 pl-2 text-white/90 font-medium">{{ formatDateOnly(trx.waktu_pencatatan) }}</td>
              <td class="py-4">
                <span class="inline-flex items-center px-2 py-0.5 rounded-md bg-white/10 text-white font-mono text-xs font-bold border border-white/10">
                  {{ formatTimeOnly(trx.waktu_pencatatan) }} WITA
                </span>
              </td>
              <td class="py-4 text-emerald-200 font-bold uppercase text-xs">
                {{ trx.nama_operator || trx.operator_name || '-' }}
              </td>
              <td class="py-4">
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-white/10 text-white/90 border border-white/15">
                  {{ trx.is_ojol ? 'Ojol' : 'Umum' }}
                </span>
              </td>
              <td class="py-4 font-mono font-bold text-white tracking-wider">{{ trx.plat_nomor }}</td>
              <td class="py-4 text-white/80 font-medium">{{ trx.liter }} L</td>
              <td class="py-4 pr-2 font-bold text-white">{{ formatRupiah(trx.harga) }}</td>
            </tr>
          </template>

          <tr v-else>
            <td colspan="7" class="py-12 text-center flex flex-col items-center justify-center text-green-100/50">
              <span class="text-4xl mb-2">🍃</span>
              <span class="italic">Tidak ada riwayat transaksi ditemukan.</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="flex flex-col md:flex-row items-center justify-between mt-6 pt-4 border-t border-white/10 gap-4">
      <span class="text-xs text-green-100/60 order-2 md:order-1">
        Menampilkan {{ transactions.length ? (currentPage - 1) * itemsPerPage + 1 : 0 }} - 
        {{ Math.min(currentPage * itemsPerPage, totalItems) }} dari {{ totalItems }} data
      </span>
      <div class="flex gap-2 order-1 md:order-2 w-full md:w-auto justify-center">
        <button 
          @click="prevPage" 
          :disabled="currentPage === 1"
          class="px-6 py-2 rounded-full bg-white/10 hover:bg-white/20 disabled:opacity-50 disabled:cursor-not-allowed text-xs font-bold transition-all flex-1 md:flex-none"
        >
          Prev
        </button>
        <button 
          @click="nextPage" 
          :disabled="(currentPage * itemsPerPage) >= totalItems"
          class="px-6 py-2 rounded-full bg-white text-[#143d2e] hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed text-xs font-bold transition-all shadow-lg flex-1 md:flex-none"
        >
          Next
        </button>
      </div>
    </div>

  </div>
</template>