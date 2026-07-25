<script setup>
const props = defineProps({
  transactions: Array,
  loading: Boolean,
  currentPage: Number,
  totalItems: Number,
  itemsPerPage: Number
})

const emit = defineEmits(['changePage'])


const formatRupiah = (number) => {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(number)
}

const formatDate = (dateString) => {
  const options = { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }
  return new Date(dateString).toLocaleDateString('id-ID', options)
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
          class="bg-black/20 rounded-2xl p-4 border border-white/5 flex flex-col gap-3"
        >
          <div class="flex justify-between items-start">
            <span class="text-xs text-green-200/70 font-medium">{{ formatDate(trx.waktu_pencatatan) }}</span>
            <span class="text-[10px] font-bold bg-green-500/20 text-green-300 px-2 py-0.5 rounded-full border border-green-500/20">Success</span>
          </div>

          <div class="flex justify-between items-center">
            <h3 class="text-xl font-mono font-bold tracking-wider text-white">{{ trx.plat_nomor }}</h3>
             <span class="inline-flex items-center px-2 py-1 rounded-lg text-[10px] font-bold uppercase tracking-wide border border-white/10" 
                :class="trx.jenis_kendaraan === 'Mobil' ? 'bg-blue-500/20 text-blue-100' : 'bg-yellow-500/20 text-yellow-100'">
                {{ trx.jenis_kendaraan }}
              </span>
          </div>

          <div class="h-px w-full bg-white/10"></div>

          <div class="flex justify-between items-end">
            <div>
              <p class="text-[10px] text-green-100/50 uppercase tracking-widest mb-0.5">Volume</p>
              <p class="text-sm font-medium text-white/90">{{ trx.liter }} Liter</p>
            </div>
            <div class="text-right">
              <p class="text-[10px] text-green-100/50 uppercase tracking-widest mb-0.5">Total</p>
              <p class="text-lg font-bold text-green-300">{{ formatRupiah(trx.harga) }}</p>
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
        <thead>
          <tr class="text-green-100/70 text-xs uppercase tracking-wider border-b border-white/10">
            <th class="pb-4 pl-2 font-medium">Waktu</th>
            <th class="pb-4 font-medium">Kendaraan</th>
            <th class="pb-4 font-medium">Plat Nomor</th>
            <th class="pb-4 font-medium">Volume</th>
            <th class="pb-4 font-medium">Revenue</th>
            <th class="pb-4 pr-2 font-medium text-right">Status</th>
          </tr>
        </thead>
        <tbody class="text-sm">
          <template v-if="loading">
            <tr v-for="n in 5" :key="n" class="border-b border-white/5">
              <td class="py-4 pl-2"><div class="skeleton h-4 w-24 bg-white/10 rounded"></div></td>
              <td class="py-4"><div class="skeleton h-6 w-16 bg-white/10 rounded-full"></div></td>
              <td class="py-4"><div class="skeleton h-4 w-20 bg-white/10 rounded"></div></td>
              <td class="py-4"><div class="skeleton h-4 w-12 bg-white/10 rounded"></div></td>
              <td class="py-4"><div class="skeleton h-4 w-24 bg-white/10 rounded"></div></td>
              <td class="py-4 pr-2 flex justify-end"><div class="skeleton h-6 w-16 bg-white/10 rounded-md"></div></td>
            </tr>
          </template>

          <template v-else-if="transactions.length > 0">
            <tr 
              v-for="trx in transactions" 
              :key="trx.id" 
              class="group hover:bg-white/5 transition-colors duration-200 border-b border-white/5 last:border-0"
            >
              <td class="py-4 pl-2 text-green-50 font-medium">{{ formatDate(trx.waktu_pencatatan) }}</td>
              <td class="py-4">
                <span class="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-bold" 
                  :class="trx.jenis_kendaraan === 'Mobil' ? 'bg-blue-500/20 text-blue-100' : 'bg-yellow-500/20 text-yellow-100'">
                  {{ trx.jenis_kendaraan }}
                </span>
              </td>
              <td class="py-4 font-mono text-white/90">{{ trx.plat_nomor }}</td>
              <td class="py-4 text-white/80">{{ trx.liter }} L</td>
              <td class="py-4 font-bold text-white">{{ formatRupiah(trx.harga) }}</td>
              <td class="py-4 pr-2 text-right">
                <span class="text-xs text-green-300 font-bold bg-green-500/20 px-2 py-1 rounded-md">Success</span>
              </td>
            </tr>
          </template>

          <tr v-else>
            <td colspan="6" class="py-12 text-center flex flex-col items-center justify-center text-green-100/50">
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