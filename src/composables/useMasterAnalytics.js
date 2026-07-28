import { ref, watch, onMounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'

export function useMasterAnalytics() {
  const loading = ref(false)
  const dataSource = ref('RPC Database (Server-side)')

  // Filter state
  const dateFrom = ref('')
  const dateTo = ref('')
  const selectedSpbuId = ref('')
  const spbuOptions = ref([])

  // Data state
  const kpi = ref({
    total_sales: 0,
    total_volume: 0,
    total_trx: 0,
    avg_trx_per_day: 0
  })

  const trendData = ref([])
  const leaderboard = ref([])

  // ─── Fetch SPBU Dropdown Options ───────────────────────────────────────────
  const fetchSpbuOptions = async () => {
    try {
      const { data } = await supabase.from('spbu').select('id, nama, alamat, manajer_id')
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

  /**
   * Fetch analytics data via RPC get_master_analytics_summary.
   * KPI, trend harian, dan leaderboard SPBU dihitung di PostgreSQL.
   */
  const fetchAnalytics = async () => {
    loading.value = true

    try {
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
        kpi.value = data.kpi || kpi.value
        trendData.value = data.trend || []
        leaderboard.value = data.leaderboard || []
      }
    } catch (err) {
      console.error('[useMasterAnalytics] Error:', err)
    } finally {
      loading.value = false
    }
  }

  // ─── Export Functions (Tetap di Frontend — presentation layer) ──────────────
  const exportToExcel = () => {
    const headers = ['Rank,SPBU Name,Revenue (IDR),Volume (Liter),Total Transactions,Share (%)\n']
    const rows = leaderboard.value.map(row => 
      `"${row.rank}","${row.spbu_name}","${row.sales}","${row.volume}","${row.total_trx}","${row.share_pct}%"`
    ).join('\n')

    const blob = new Blob([headers + rows], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    const url = URL.createObjectURL(blob)
    link.setAttribute('href', url)
    link.setAttribute('download', `Laporan_Analisis_SPBU_${new Date().toISOString().slice(0, 10)}.csv`)
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }

  const exportToPDF = () => {
    const printWindow = window.open('', '_blank')
    if (!printWindow) return

    const formatCurrency = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val || 0)

    const tableRowsHtml = leaderboard.value.map(row => `
      <tr>
        <td style="padding:10px; border-bottom:1px solid #eee; text-align:center;"><b>#${row.rank}</b></td>
        <td style="padding:10px; border-bottom:1px solid #eee;"><b>${row.spbu_name}</b></td>
        <td style="padding:10px; border-bottom:1px solid #eee; text-align:right; font-weight:bold; color:#143d2e;">${formatCurrency(row.sales)}</td>
        <td style="padding:10px; border-bottom:1px solid #eee; text-align:right;">${row.volume} L</td>
        <td style="padding:10px; border-bottom:1px solid #eee; text-align:center;">${row.total_trx}</td>
        <td style="padding:10px; border-bottom:1px solid #eee; text-align:right; font-weight:bold;">${row.share_pct}%</td>
      </tr>
    `).join('')

    printWindow.document.write(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Laporan Analisis Eksekutif SPBU - Habi Jaya FuelGuard</title>
          <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; padding: 40px; color: #1a1a1a; }
            .header { display: flex; justify-content: space-between; align-items: center; border-b: 3px solid #143d2e; padding-bottom: 15px; margin-bottom: 30px; }
            .title { font-size: 24px; font-weight: 900; color: #143d2e; margin: 0; }
            .sub { font-size: 12px; color: #666; margin-top: 4px; }
            .kpi-grid { display: flex; gap: 20px; margin-bottom: 30px; }
            .kpi-card { flex: 1; background: #f8faf9; border-left: 4px solid #143d2e; padding: 15px; border-radius: 8px; }
            .kpi-label { font-size: 11px; text-transform: uppercase; color: #666; font-weight: bold; }
            .kpi-val { font-size: 20px; font-weight: 900; color: #143d2e; margin-top: 5px; }
            table { width: 100%; border-collapse: collapse; margin-top: 20px; font-size: 13px; }
            th { background: #143d2e; color: white; padding: 12px; text-align: left; font-size: 11px; text-transform: uppercase; }
            .footer { margin-top: 50px; font-size: 11px; color: #888; text-align: right; border-top: 1px solid #eee; padding-top: 15px; }
          </style>
        </head>
        <body>
          <div class="header">
            <div>
              <h1 class="title">HABI JAYA FUELGUARD</h1>
              <div class="sub">Laporan Analisis Eksekutif Penjualan BBM Jaringan SPBU</div>
            </div>
            <div style="text-align:right;">
              <div style="font-size:12px; font-weight:bold;">Tanggal Cetak:</div>
              <div style="font-size:12px; color:#555;">${new Date().toLocaleDateString('id-ID', { day: '2-digit', month: 'long', year: 'numeric' })}</div>
            </div>
          </div>

          <div class="kpi-grid">
            <div class="kpi-card">
              <div class="kpi-label">Total Gross Sales</div>
              <div class="kpi-val">${formatCurrency(kpi.value.total_sales)}</div>
            </div>
            <div class="kpi-card">
              <div class="kpi-label">Total Volume BBM</div>
              <div class="kpi-val">${(kpi.value.total_volume || 0).toLocaleString('id-ID')} Liter</div>
            </div>
            <div class="kpi-card">
              <div class="kpi-label">Total Transaksi</div>
              <div class="kpi-val">${kpi.value.total_trx}</div>
            </div>
            <div class="kpi-card">
              <div class="kpi-label">Rerata Trx / Hari</div>
              <div class="kpi-val">${kpi.value.avg_trx_per_day}</div>
            </div>
          </div>

          <h3 style="color:#143d2e; margin-bottom:10px;">Leaderboard & Benchmarking Performa SPBU</h3>
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
            Dokumen ini dihasilkan secara otomatis oleh Sistem Eksekutif Habi Jaya FuelGuard. Confidential.
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
    fetchAnalytics,
    exportToExcel,
    exportToPDF
  }
}
