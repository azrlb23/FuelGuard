import { ref } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { toast } from 'vue3-toastify'
import { useAuthStore } from '@/stores/auth'
import * as XLSX from 'xlsx'

export function useExcelExport() {
  const exportLoading = ref(false)
  const progress = ref(0)
  const authStore = useAuthStore()

  const formatDateOnly = (date) => new Date(date).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
  const formatTimeOnly = (date) => new Date(date).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }).replace('.', ':')

  /**
   * Download data transaksi dan generate file Excel.
   * Menggunakan RPC get_export_transactions untuk mengambil semua data
   * dalam 1 kali request (menggantikan looping pagination sebelumnya).
   */
  const downloadExcel = async (startDate, endDate) => {
    if (!startDate || !endDate) {
      toast.warn("Pilih rentang tanggal terlebih dahulu.")
      return
    }

    if (!authStore.spbuId) {
      toast.error("Data SPBU belum tersedia. Silakan login ulang.")
      return
    }

    exportLoading.value = true
    progress.value = 0

    try {
      const { data: allData, error } = await supabase.rpc('get_export_transactions', {
        p_start_date: startDate,
        p_end_date: endDate,
        p_spbu_id: authStore.spbuId
      })

      if (error) throw error

      const dataList = allData || []
      progress.value = dataList.length

      if (dataList.length === 0) {
        toast.info("Tidak ada data untuk diexport.")
        return
      }

      const formattedData = dataList.map(item => ({
        'ID': item.id,
        'Tanggal': formatDateOnly(item.waktu_pencatatan),
        'Waktu': formatTimeOnly(item.waktu_pencatatan),
        'Jenis': item.is_ojol ? 'Ojol' : 'Non-Ojol',
        'Plat Nomor': item.plat_nomor,
        'Volume (L)': item.liter,
        'Harga (Rp)': item.harga,
        'SPBU': item.spbu_nama || '-'
      }))

      const worksheet = XLSX.utils.json_to_sheet(formattedData)
      const colWidths = [{wch:8}, {wch:15}, {wch:10}, {wch:10}, {wch:15}, {wch:12}, {wch:15}, {wch:30}]
      worksheet['!cols'] = colWidths

      const workbook = XLSX.utils.book_new()
      XLSX.utils.book_append_sheet(workbook, worksheet, "Laporan Transaksi")

      XLSX.writeFile(workbook, `Riwayat_Transaksi_${startDate}_sd_${endDate}.xlsx`)

    } catch (err) {
      console.error(err)
      toast.error("Gagal export.")
    } finally {
      exportLoading.value = false
      progress.value = 0
    }
  }

  return {
    exportLoading,
    progress,
    downloadExcel
  }
}
