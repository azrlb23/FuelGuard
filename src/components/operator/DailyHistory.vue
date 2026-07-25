<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'

const transactions = ref([])
const loading = ref(false)
const searchQuery = ref('')

const formatRupiah = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val)

const fetchTodayHistory = async () => {
  loading.value = true
  try {
    const now = new Date()
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 6, 0, 0, 0).toISOString()
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999).toISOString()

    let query = supabase
      .from('transaksi_pertalite')
      .select('*')
      .gte('waktu_pencatatan', startOfDay)
      .lte('waktu_pencatatan', endOfDay)
      .order('waktu_pencatatan', { ascending: false })

    if (searchQuery.value) {
      query = query.ilike('plat_nomor', `%${searchQuery.value}%`)
    }

    const { data, error } = await query
    if (error) throw error
    transactions.value = data
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchTodayHistory()
})


defineExpose({ fetchTodayHistory })
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex justify-between items-center">
      <h3 class="text-xl font-bold text-gray-800">Riwayat Transaksi Hari Ini</h3>
      
      <div class="relative w-64">
        <input 
          v-model="searchQuery" 
          @input="fetchTodayHistory"
          type="text" 
          placeholder="Cari plat nomor..." 
          class="w-full pl-10 pr-4 py-2 rounded-full bg-white border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-[#143d2e]"
        />
        <span class="absolute left-3 top-2.5 text-gray-400 text-xs">🔍</span>
      </div>
    </div>

    <div class="bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-left">
          <thead class="bg-gray-50 border-b border-gray-100">
            <tr>
              <th class="px-6 py-4 text-xs font-bold text-gray-500 uppercase">Waktu</th>
              <th class="px-6 py-4 text-xs font-bold text-gray-500 uppercase">Plat Nomor</th>
              <th class="px-6 py-4 text-xs font-bold text-gray-500 uppercase">Jenis</th>
              <th class="px-6 py-4 text-xs font-bold text-gray-500 uppercase text-right">Liter</th>
              <th class="px-6 py-4 text-xs font-bold text-gray-500 uppercase text-right">Total</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-if="loading">
              <td colspan="5" class="px-6 py-8 text-center text-gray-400">Memuat data...</td>
            </tr>
            <tr v-else-if="transactions.length === 0">
              <td colspan="5" class="px-6 py-8 text-center text-gray-400 italic">Belum ada transaksi hari ini.</td>
            </tr>
            <tr v-for="trx in transactions" :key="trx.id" class="hover:bg-gray-50 transition-colors">
              <td class="px-6 py-4 text-sm font-medium text-gray-900">
                {{ new Date(trx.waktu_pencatatan).toLocaleTimeString('id-ID', {hour: '2-digit', minute:'2-digit'}) }}
              </td>
              <td class="px-6 py-4 text-sm font-mono font-bold text-gray-800">{{ trx.plat_nomor }}</td>
              <td class="px-6 py-4 text-sm">
                <span class="px-2 py-1 rounded-md text-xs font-bold"
                  :class="trx.jenis_kendaraan === 'Mobil' ? 'bg-blue-100 text-blue-700' : 'bg-yellow-100 text-yellow-700'">
                  {{ trx.jenis_kendaraan }}
                </span>
              </td>
              <td class="px-6 py-4 text-sm text-right font-medium">{{ trx.liter }} L</td>
              <td class="px-6 py-4 text-sm text-right font-bold text-[#143d2e]">{{ formatRupiah(trx.harga) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>