<script setup>
import { ref, onMounted, watch } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { toast } from 'vue3-toastify'
import { useExcelExport } from '@/composables/useExcelExport'
import { useAuthStore } from '@/stores/auth'
import ReportHeader from '@/components/report/ReportHeader.vue'
import ReportStats from '@/components/report/ReportStats.vue'
import HistoryTable from '@/components/history/HistoryTable.vue'

const authStore = useAuthStore()

const startDate = ref('')
const endDate = ref('')
const loading = ref(false)
const stats = ref({ volume: 0, revenue: 0, vehicle: 0 })
const transactions = ref([])

const currentPage = ref(1)
const itemsPerPage = 10
const totalItems = ref(0)

const { exportLoading, progress, downloadExcel } = useExcelExport()

const setDefaultDates = () => {
  const date = new Date()
  const firstDay = new Date(date.getFullYear(), date.getMonth(), 1)
  const today = new Date() 
  startDate.value = firstDay.toISOString().split('T')[0]
  endDate.value = today.toISOString().split('T')[0]
}

const handleFetch = () => { currentPage.value = 1; fetchReport(); }
const handleExport = () => { downloadExcel(startDate.value, endDate.value); }

const fetchReport = async () => {
  if (!startDate.value || !endDate.value) {
    toast.warn("Pilih tanggal.")
    return
  }
  if (!authStore.spbuId) {
    toast.error("Data SPBU belum tersedia. Silakan login ulang.")
    return
  }
  loading.value = true
  try {
    // Aggregasi langsung dari transaksi_pertalite (menggantikan RPC get_report_summary yang belum ada)
    const { data: summaryData, error: summaryError } = await supabase
      .from('transaksi_pertalite')
      .select('liter, harga')
      .eq('spbu_id', authStore.spbuId)
      .gte('waktu_pencatatan', `${startDate.value}T00:00:00`)
      .lte('waktu_pencatatan', `${endDate.value}T23:59:59`)

    if (summaryError) throw summaryError

    const rows = summaryData || []
    stats.value = {
      volume: rows.reduce((sum, r) => sum + (Number(r.liter) || 0), 0),
      revenue: rows.reduce((sum, r) => sum + (Number(r.harga) || 0), 0),
      vehicle: rows.length
    }

    await fetchTableData()
  } catch (err) {
    console.error(err)
    toast.error(err.message)
  } finally {
    loading.value = false
  }
}

const fetchTableData = async () => {
  const from = (currentPage.value - 1) * itemsPerPage
  const to = from + itemsPerPage - 1
  const { data, count, error } = await supabase.from('transaksi_pertalite')
    .select('*', { count: 'exact' })
    .eq('spbu_id', authStore.spbuId)
    .gte('waktu_pencatatan', `${startDate.value}T00:00:00`)
    .lte('waktu_pencatatan', `${endDate.value}T23:59:59`)
    .order('waktu_pencatatan', { ascending: false })
    .range(from, to)
  
  if (error) throw error
  transactions.value = data
  totalItems.value = count
}

watch(currentPage, () => { if (startDate.value) fetchTableData() })
onMounted(() => { setDefaultDates(); fetchReport(); })
</script>

<template>
  <div class="flex flex-col gap-4 animate-enter pb-24">
    
    <div class="flex-none flex flex-col gap-4">
      
      <ReportHeader 
        v-model:startDate="startDate"
        v-model:endDate="endDate"
        :loading="loading"
        :exportLoading="exportLoading"
        @fetch="handleFetch"
        @export="handleExport"
      />

      <div v-if="exportLoading" class="w-full bg-gray-200 rounded-full h-2.5 overflow-hidden">
        <div 
          class="bg-green-600 h-2.5 rounded-full transition-all duration-300 animate-pulse" 
          :style="{ width: '100%' }"
        ></div>
        <p class="text-xs text-center mt-1 text-gray-500">Sedang mengambil {{ progress }} data...</p>
      </div>

      <ReportStats 
        :stats="stats" 
        filter="custom" 
        :loading="loading" 
      />
    </div>

    <div class="rounded-4xl relative">
      <HistoryTable 
        :transactions="transactions"
        :loading="loading"
        :current-page="currentPage"
        :total-items="totalItems"
        :items-per-page="itemsPerPage"
        @change-page="(newPage) => currentPage = newPage"
      />
    </div>

  </div>
</template>