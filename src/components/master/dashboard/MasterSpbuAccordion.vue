<script setup>
import { ref, computed } from 'vue'
import MasterSpbuRecentTrxList from './MasterSpbuRecentTrxList.vue'

const props = defineProps({
  spbuList: {
    type: Array,
    default: () => []
  },
  searchQuery: {
    type: String,
    default: ''
  },
  periodLabel: {
    type: String,
    default: 'Hari Ini'
  }
})

defineEmits(['update:searchQuery'])

const activeSpbuId = ref(null)

const filteredSpbuList = computed(() => {
  if (!props.searchQuery || !props.searchQuery.trim()) return props.spbuList
  const q = props.searchQuery.toLowerCase()
  return props.spbuList.filter(s =>
    (s.name && s.name.toLowerCase().includes(q)) ||
    (s.location && s.location.toLowerCase().includes(q)) ||
    (s.manager && s.manager.toLowerCase().includes(q))
  )
})

const toggleSpbuAccordion = (id) => {
  activeSpbuId.value = activeSpbuId.value === id ? null : id
}

const getRecentTransactions = (spbuId) => {
  const spbu = props.spbuList.find(s => String(s.id) === String(spbuId))
  const txs = spbu ? (spbu.recentTransactions || spbu.transactions) : []
  if (txs && txs.length > 0) {
    return txs.slice(0, 10).map((tx, idx) => {
      const date = new Date(tx.waktu_pencatatan)
      const isValid = !isNaN(date.getTime())
      const dateFormatted = isValid
        ? date.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })
        : '-'
      const timeFormatted = isValid
        ? date.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
        : '-'

      return {
        id: idx + 1,
        plat: tx.plat_nomor || '-',
        fuel: 'Pertalite',
        liter: `${(Number(tx.liter) || 0).toFixed(1)} L`,
        amount: new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(tx.harga || 0),
        date: dateFormatted,
        time: timeFormatted
      }
    })
  }
  return []
}

const formatRupiah = (val) => {
  const num = Number(val) || 0
  if (num === 0) return 'Rp 0'
  if (num >= 1000000000) return `Rp ${(num / 1000000000).toFixed(2)} M`
  if (num >= 1000000) return `Rp ${(num / 1000000).toFixed(1)} Jt`
  if (num >= 1000) return `Rp ${Math.round(num / 1000)} Rb`
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(num)
}

const formatVolume = (val) => {
  if (!val || val === 0) return '0 Liter'
  return val >= 1000 ? `${(val / 1000).toFixed(1)}K Liter` : `${val} Liter`
}
</script>

<template>
  <div class="bg-white rounded-[2rem] p-6 shadow-xl shadow-green-900/5 border border-gray-100">

    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-5">
      <div>
        <h4 class="text-[#143d2e] font-black text-lg">Performa SPBU</h4>
      </div>

      <!-- Search Bar SPBU -->
      <div class="relative w-full sm:w-64">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
        </svg>
        <input
          :value="searchQuery"
          @input="$emit('update:searchQuery', $event.target.value)"
          type="text"
          placeholder="Cari SPBU..."
          class="w-full pl-9 pr-4 py-2 rounded-full bg-gray-50 border border-gray-200 text-xs text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-transparent transition-all shadow-xs"
        />
      </div>
    </div>

    <div class="space-y-3">
      <!-- Empty State Filter -->
      <div v-if="filteredSpbuList.length === 0" class="py-12 text-center text-gray-400 text-xs font-medium border border-dashed border-gray-200 rounded-2xl">
        <p class="text-gray-500 font-bold text-sm mb-1">Belum ada data SPBU di database</p>
      </div>

      <div
        v-for="(spbu, index) in filteredSpbuList"
        :key="spbu.id"
        class="rounded-2xl transition-all duration-300 overflow-hidden border"
        :class="[
          activeSpbuId === spbu.id
            ? 'bg-gradient-to-b from-green-50/50 to-white border-[#143d2e]/20 shadow-md ring-1 ring-[#143d2e]/10'
            : 'bg-white hover:bg-gray-50/80 border-gray-100'
        ]"
      >
        <!-- Accordion Header Bar -->
        <button
          @click="toggleSpbuAccordion(spbu.id)"
          class="w-full p-3.5 text-left transition-colors cursor-pointer select-none space-y-2.5 sm:space-y-0 sm:flex sm:items-center sm:gap-3"
        >
          <!-- Top section (Mobile full width / Desktop flex left) -->
          <div class="flex items-center gap-3 flex-1 min-w-0">
            <!-- Sequential Index Badge (1, 2, 3...) -->
            <div
              class="w-8 h-8 rounded-xl flex-shrink-0 flex items-center justify-center text-xs font-black text-white shadow-sm"
              style="background: linear-gradient(135deg, #143d2e, #258f62)"
            >
              {{ index + 1 }}
            </div>

            <div class="flex-1 min-w-0">
              <p class="text-gray-900 font-bold text-sm leading-tight break-words sm:truncate">{{ spbu.name }}</p>
            </div>

            <!-- Chevron Toggle Button (Mobile Top-Right) -->
            <div
              class="w-7 h-7 rounded-full flex-shrink-0 flex sm:hidden items-center justify-center transition-transform duration-200"
              :class="[
                activeSpbuId === spbu.id ? 'bg-[#143d2e] text-white rotate-180' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
              ]"
            >
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5"><path stroke-linecap="round" stroke-linejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" /></svg>
            </div>
          </div>

          <!-- Bottom section (Mobile stacked metrics bar / Desktop right side) -->
          <div class="flex items-center justify-between sm:justify-end gap-3 pt-2 sm:pt-0 border-t border-gray-100 sm:border-t-0 pl-11 sm:pl-0 pr-0 sm:pr-2">
            <div class="flex items-center gap-4 sm:gap-3 w-full sm:w-auto justify-between sm:justify-start">
              <div>
                <p class="text-[10px] text-gray-400 uppercase font-bold tracking-wider">Revenue</p>
                <p class="text-[#143d2e] font-black text-sm leading-tight">{{ formatRupiah(spbu.revenue) }}</p>
              </div>
              <div class="h-6 w-px bg-gray-200"></div>
              <div>
                <p class="text-[10px] text-gray-400 uppercase font-bold tracking-wider">Volume</p>
                <p class="text-gray-800 font-bold text-sm leading-tight">{{ formatVolume(spbu.volume) }}</p>
              </div>
            </div>

            <!-- Chevron Toggle Button (Desktop Right) -->
            <div
              class="w-7 h-7 rounded-full flex-shrink-0 hidden sm:flex items-center justify-center transition-transform duration-200"
              :class="[
                activeSpbuId === spbu.id ? 'bg-[#143d2e] text-white rotate-180' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
              ]"
            >
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5"><path stroke-linecap="round" stroke-linejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" /></svg>
            </div>
          </div>
        </button>

        <!-- Accordion Expanded Content -->
        <div
          v-if="activeSpbuId === spbu.id"
          class="px-4 pb-5 pt-3 border-t border-gray-100/80 space-y-4 animate-enter"
        >
          <!-- 10 Transaksi Terakhir SPBU Ini -->
          <MasterSpbuRecentTrxList
            :recentTransactions="getRecentTransactions(spbu.id)"
            :periodLabel="periodLabel"
          />
        </div>

      </div>
    </div>

  </div>
</template>
