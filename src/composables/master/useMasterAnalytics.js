import { ref, watch, onMounted, computed } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import * as XLSX from 'xlsx'

const getDefaultDates = () => {
  const today = new Date()
  const sevenDaysAgo = new Date()
  sevenDaysAgo.setDate(today.getDate() - 6)

  const formatDateStr = (d) => {
    const year = d.getFullYear()
    const month = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  return {
    from: formatDateStr(sevenDaysAgo),
    to: formatDateStr(today)
  }
}

export function useMasterAnalytics() {
  const loading = ref(false)
  const dataSource = ref('RPC Database (Server-side)')

  // Filter state (Default: 7 Hari Terakhir / Mingguan)
  const defaultDates = getDefaultDates()
  const dateFrom = ref(defaultDates.from)
  const dateTo = ref(defaultDates.to)
  const selectedSpbuId = ref('')
  const spbuOptions = ref([])

  // Data state
  const kpi = ref({
    totalSales: 0,
    totalVolume: 0,
    totalTransactions: 0,
    avgTrxPerDay: 0
  })

  const trendData = ref([])
  const leaderboard = ref([])
  const spbuShares = ref([])

  // ─── Fetch SPBU Dropdown Options ───────────────────────────────────────────
  const fetchSpbuOptions = async () => {
    try {
      const { data } = await supabase.from('spbu').select('id, nama, alamat')
      if (data) {
        spbuOptions.value = data.map(s => ({
          id: String(s.id),
          name: s.nama || `SPBU #${s.id}`
        }))
      }
    } catch (err) {
      console.warn('[useMasterAnalytics] Failed to fetch SPBU options:', err)
    }
  }
  const selectedSpbuName = computed(() => {
    if (!selectedSpbuId.value) return 'Semua SPBU'
    const found = spbuOptions.value.find(s => String(s.id) === String(selectedSpbuId.value))
    return found ? found.name : `SPBU #${selectedSpbuId.value}`
  })
  const topPlates = ref([])
  const fetchTopPlates = async () => {
    if (!selectedSpbuId.value) {
      topPlates.value = []
      return
    }
    try {
      const { data, error } = await supabase.rpc('get_spbu_top_plates', {
        p_spbu_id: selectedSpbuId.value,
        p_date_from: dateFrom.value || '',
        p_date_to: dateTo.value || '',
        // p_limit: 10
      })

      if (error) {
        console.error('[useMasterAnalytics] fetchTopPlates RPC error:', error)
        return
      }

      if (data && data.success) {
        topPlates.value = data.top_plates || []
      } else {
        topPlates.value = []
      }
    } catch (err) {
      console.error('[useMasterAnalytics] fetchTopPlates error:', err)
      topPlates.value = []
    }
  }
  /**
   * Fetch analytics data via RPC get_master_analytics_summary.
   * KPI, trend harian, dan leaderboard SPBU dihitung di PostgreSQL.
   */
  const fetchAnalytics = async () => {
    loading.value = true
    const minLoadingPromise = new Promise(resolve => setTimeout(resolve, 350))

    try {
      fetchTopPlates()
      const { data, error } = await supabase.rpc('get_master_analytics_summary', {
        p_date_from: dateFrom.value,
        p_date_to: dateTo.value,
        p_spbu_id: selectedSpbuId.value
      })

      if (error) {
        console.error('[useMasterAnalytics] RPC error:', error)
        return
      }

      if (data) {
        kpi.value = data.kpis || kpi.value
        trendData.value = data.trend || []

        const rawLeaderboard = data.leaderboard || []
        const totalLeaderboardSales = rawLeaderboard.reduce((sum, item) => sum + (item.revenue || 0), 0)
        leaderboard.value = rawLeaderboard.map((item, index) => ({
          ...item,
          rank: index + 1,
          sharePct: totalLeaderboardSales > 0 ? ((item.revenue / totalLeaderboardSales) * 100).toFixed(1) : 0
        }))

        spbuShares.value = data.spbuShares || []
      }
      await minLoadingPromise
    } catch (err) {
      console.error('[useMasterAnalytics] Error:', err)
    } finally {
      loading.value = false
    }
  }

  // ─── Export Functions (Tetap di Frontend — presentation layer) ──────────────
  const exportToExcel = () => {
    if (!leaderboard.value || leaderboard.value.length === 0) return

    const excelData = leaderboard.value.map((row, index) => ({
      'Rank': `#${index + 1}`,
      'Nama SPBU': row.name,
      'Omzet (Rp)': row.revenue,
      'Volume (Liter)': row.volume,
      'Total Transaksi': row.trxCount,
      'Lokasi': row.location || '-'
    }))

    const worksheet = XLSX.utils.json_to_sheet(excelData)
    const workbook = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Laporan Analisis SPBU')

    const dNow = new Date()
    const year = dNow.getFullYear()
    const month = String(dNow.getMonth() + 1).padStart(2, '0')
    const day = String(dNow.getDate()).padStart(2, '0')
    const dateTag = `${year}-${month}-${day}`
    const fileName = `Laporan_Analisis_SPBU_${dateTag}.xlsx`

    XLSX.writeFile(workbook, fileName)
  }

  const exportToPDF = () => {
    const printWindow = window.open('', '_blank')
    if (!printWindow) return

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val || 0)
    const formatDateStr = (dateStr) => {
      if (!dateStr) return ''
      const d = new Date(dateStr)
      if (isNaN(d.getTime())) return dateStr
      return d.toLocaleDateString('id-ID', { day: '2-digit', month: 'long', year: 'numeric' })
    }

    let periodLabel = 'Semua Periode'
    if (dateFrom.value && dateTo.value) {
      if (dateFrom.value === dateTo.value) {
        periodLabel = formatDateStr(dateFrom.value)
      } else {
        periodLabel = `${formatDateStr(dateFrom.value)} - ${formatDateStr(dateTo.value)}`
      }
    } else if (dateFrom.value) {
      periodLabel = `Mulai ${formatDateStr(dateFrom.value)}`
    } else if (dateTo.value) {
      periodLabel = `Sampai ${formatDateStr(dateTo.value)}`
    }

    const printDate = new Date().toLocaleDateString('id-ID', { day: '2-digit', month: 'long', year: 'numeric' })

    const tableRowsHtml = leaderboard.value.map((row, index) => `
      <tr>
        <td style="padding:10px; border-bottom:1px solid #eee; text-align:center;"><b>#${index + 1}</b></td>
        <td style="padding:10px; border-bottom:1px solid #eee;"><b>${row.name}</b></td>
        <td style="padding:10px; border-bottom:1px solid #eee; text-align:right; font-weight:bold; color:#143d2e;">${formatCurrency(row.revenue)}</td>
        <td style="padding:10px; border-bottom:1px solid #eee; text-align:right;">${(row.volume || 0).toLocaleString('id-ID')} L</td>
        <td style="padding:10px; border-bottom:1px solid #eee; text-align:center;">${(row.trxCount || 0).toLocaleString('id-ID')}</td>
        <td style="padding:10px; border-bottom:1px solid #eee; text-align:right; font-weight:bold; color:#143d2e;">${row.sharePct || 0}%</td>
      </tr>
    `).join('')

    printWindow.document.write(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Laporan Analisis SPBU - FuelGuard</title>
          <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; padding: 40px; color: #1a1a1a; }
            .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 3px solid #143d2e; padding-bottom: 15px; margin-bottom: 30px; }
            .title { font-size: 24px; font-weight: 900; color: #143d2e; margin: 0; }
            .sub { font-size: 12px; color: #666; margin-top: 4px; }
            .kpi-grid { display: flex; gap: 15px; margin-bottom: 30px; }
            .kpi-card { flex: 1; background: #f8faf9; border-left: 4px solid #143d2e; padding: 12px 15px; border-radius: 8px; }
            .kpi-label { font-size: 10px; text-transform: uppercase; color: #555; font-weight: bold; tracking: 0.5px; }
            .kpi-val { font-size: 18px; font-weight: 900; color: #143d2e; margin-top: 6px; }
            table { width: 100%; border-collapse: collapse; margin-top: 20px; font-size: 13px; }
            th { background: #143d2e; color: white; padding: 12px; text-align: left; font-size: 11px; text-transform: uppercase; }
            .footer { margin-top: 50px; font-size: 11px; color: #888; text-align: right; border-top: 1px solid #eee; padding-top: 15px; }
          </style>
        </head>
        <body>
          <div class="header">
            <div>
              <h1 class="title">FUELGUARD</h1>
              <div class="sub">Laporan Analisis Penjualan BBM SPBU</div>
            </div>
            <div style="text-align:right;">
              <div style="font-size:12px; font-weight:bold; color:#143d2e;">Periode Laporan:</div>
              <div style="font-size:12px; color:#333; font-weight:600; margin-bottom:3px;">${periodLabel}</div>
              <div style="font-size:10px; color:#777;">Tanggal Cetak: ${printDate}</div>
            </div>
          </div>

          <div class="kpi-grid">
            <div class="kpi-card">
              <div class="kpi-label">TOTAL TRANSAKSI</div>
              <div class="kpi-val">${(kpi.value.totalTransactions || 0).toLocaleString('id-ID')}</div>
            </div>
            <div class="kpi-card">
              <div class="kpi-label">TOTAL VOLUME BBM</div>
              <div class="kpi-val">${(kpi.value.totalVolume || 0).toLocaleString('id-ID')} Liter</div>
            </div>
            <div class="kpi-card">
              <div class="kpi-label">TOTAL REVENUE</div>
              <div class="kpi-val">${formatCurrency(kpi.value.totalSales)}</div>
            </div>
            <div class="kpi-card">
              <div class="kpi-label">RATA - RATA TRANSAKSI / HARI</div>
              <div class="kpi-val">${kpi.value.avgTrxPerDay || 0}</div>
            </div>
          </div>

          <h3 style="color:#143d2e; margin-bottom:10px; font-weight:800;">Peringkat SPBU Berdasarkan Penjualan</h3>
          <table>
            <thead>
              <tr>
                <th style="text-align:center;">Rank</th>
                <th>Nama SPBU</th>
                <th style="text-align:right;">Revenue</th>
                <th style="text-align:right;">Volume</th>
                <th style="text-align:center;">Total Transaksi</th>
                <th style="text-align:right;">Kontribusi (%)</th>
              </tr>
            </thead>
            <tbody>
              ${tableRowsHtml}
            </tbody>
          </table>

          <div class="footer">
            Dokumen ini dihasilkan secara otomatis oleh Sistem Eksekutif FuelGuard. Confidential.
          </div>

          <script>
            window.onload = function() {
              window.print();
            };
          </script>
        </body>
      </html>
    `)
    printWindow.document.close()
  }

  // Watchers to trigger refetch
  watch([dateFrom, dateTo, selectedSpbuId], () => {
    fetchAnalytics()
  })

  onMounted(() => {
    fetchSpbuOptions()
    fetchAnalytics()
  })

  return {
    loading,
    dataSource,
    dateFrom,
    dateTo,
    selectedSpbuId,
    spbuOptions,
    kpi,
    trendData,
    leaderboard,
    spbuShares,
    topPlates,
    selectedSpbuName,
    fetchAnalytics,
    exportToExcel,
    exportToPDF
  }
}
