import { ref } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { toast } from 'vue3-toastify'
import * as XLSX from 'xlsx'

export function useExcelExport() {
  const exportLoading = ref(false)
  const progress = ref(0)

  const formatDate = (date) => new Date(date).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })

  const downloadExcel = async (startDate, endDate) => {
    if (!startDate || !endDate) {
      toast.warn("Pilih rentang tanggal terlebih dahulu.")
      return
    }
    
    exportLoading.value = true
    progress.value = 0
    
    try {
      let allData = []
      let page = 0
      let pageSize = 1000 
      let hasMore = true

      while (hasMore) {
        const from = page * pageSize
        const to = from + pageSize - 1
        
        const { data, error } = await supabase
          .from('transaksi_pertalite')
          .select('*')
          .gte('waktu_pencatatan', `${startDate}T00:00:00`)
          .lte('waktu_pencatatan', `${endDate}T23:59:59`)
          .order('waktu_pencatatan', { ascending: true })
          .range(from, to)

        if (error) throw error

        if (data.length > 0) {
          allData = [...allData, ...data]
          progress.value = allData.length
          page++
        }
        
        if (data.length < pageSize) hasMore = false
      }

      if (allData.length === 0) {
        toast.info("Tidak ada data untuk diexport.")
        return
      }

      const formattedData = allData.map(item => ({
        'ID': item.id,
        'Waktu': formatDate(item.waktu_pencatatan),
        'Jenis': item.jenis_kendaraan,
        'Plat Nomor': item.plat_nomor,
        'Volume (L)': item.liter,
        'Harga (Rp)': item.harga,
        'Operator': item.operator_id || '-'
      }))

      const worksheet = XLSX.utils.json_to_sheet(formattedData)
      const colWidths = [{wch:8}, {wch:22}, {wch:10}, {wch:15}, {wch:12}, {wch:15}, {wch:30}]
      worksheet['!cols'] = colWidths

      const workbook = XLSX.utils.book_new()
      XLSX.utils.book_append_sheet(workbook, worksheet, "Laporan Transaksi")

      XLSX.writeFile(workbook, `Laporan_${startDate}_${endDate}.xlsx`)
      toast.success(`Berhasil mengunduh ${allData.length} data!`)

    } catch (err) {
      console.error(err)
      toast.error("Gagal export: " + err.message)
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