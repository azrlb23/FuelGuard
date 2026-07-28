import { ref, watch, onMounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'

export function useMasterAnalytics() {
  const loading = ref(false)
  const dataSource = ref('Checking...')

  // Filter state
  const dateFrom = ref('')
  const dateTo = ref('')
  const selectedSpbuId = ref('') // '' = All SPBUs
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

  // ─── Direct Table Fallback Query ───────────────────────────────────────────
  const fetchDirectTableData = async () => {
    try {
      let query = supabase
        .from('transaksi_pertalite')
        .select('*')
        .order('waktu_pencatatan', { ascending: true })

      if (selectedSpbuId.value) {
        query = query.eq('spbu_id', selectedSpbuId.value)
      }
      if (dateFrom.value) {
        query = query.gte('waktu_pencatatan', `${dateFrom.value}T00:00:00`)
      }
      if (dateTo.value) {
        query = query.lte('waktu_pencatatan', `${dateTo.value}T23:59:59`)
      }

      const { data: allTrx } = await query
      const trxList = allTrx || []

      // 1. KPI
      const totalSales = trxList.reduce((s, i) => s + (Number(i.harga) || 0), 0)
      const totalVol = trxList.reduce((s, i) => s + (Number(i.liter) || 0), 0)
      const totalTrxCount = trxList.length

      let daysSpan = 30
      if (dateFrom.value && dateTo.value) {
        const d1 = new Date(dateFrom.value)
        const d2 = new Date(dateTo.value)
        const diff = Math.ceil((d2 - d1) / (1000 * 60 * 60 * 24)) + 1
        daysSpan = Math.max(diff, 1)
      }

      kpi.value = {
        total_sales: totalSales,
        total_volume: totalVol,
        total_trx: totalTrxCount,
        avg_trx_per_day: Number((totalTrxCount / daysSpan).toFixed(1))
      }

      // 2. Trend Group by Date
      const trendMap = {}
      trxList.forEach(t => {
        const d = new Date(t.waktu_pencatatan)
        if (isNaN(d.getTime())) return
        const dateKey = d.toLocaleDateString('id-ID', { day: '2-digit', month: 'short' })
        if (!trendMap[dateKey]) trendMap[dateKey] = { sales: 0, volume: 0 }
        trendMap[dateKey].sales += Number(t.harga) || 0
        trendMap[dateKey].volume += Number(t.liter) || 0
      })

      trendData.value = Object.keys(trendMap).map(k => ({
        date: k,
        sales: trendMap[k].sales,
        volume: trendMap[k].volume
      }))

      // 3. Leaderboard Group by SPBU
      const spbuMap = {}
      trxList.forEach(t => {
        const sId = t.spbu_id ? String(t.spbu_id) : '1'
        if (!spbuMap[sId]) spbuMap[sId] = { sales: 0, volume: 0, total_trx: 0 }
        spbuMap[sId].sales += Number(t.harga) || 0
        spbuMap[sId].volume += Number(t.liter) || 0
        spbuMap[sId].total_trx += 1
      })

      const rawLeaderboard = spbuOptions.value.map(s => {
        const stats = spbuMap[s.id] || { sales: 0, volume: 0, total_trx: 0 }
        const sharePct = totalSales > 0 ? Number(((stats.sales / totalSales) * 100).toFixed(1)) : 0
        return {
          spbu_id: s.id,
          spbu_name: s.name,
          sales: stats.sales,
          volume: stats.volume,
          total_trx: stats.total_trx,
          share_pct: sharePct
        }
      }).sort((a, b) => b.sales - a.sales)

      leaderboard.value = rawLeaderboard.map((item, idx) => ({
        ...item,
        rank: idx + 1,
        status: idx === 0 && item.sales > 0 ? 'Top Performer' : item.sales === 0 ? 'No Activity' : 'Normal'
      }))

    } catch (err) {
      console.error('[useMasterAnalytics Direct Query] Error:', err)
    }
  }

  // ─── Main Fetch (Prioritas RPC Database -> Fallback Direct Fetch) ─────────────
  const fetchAnalytics = async () => {
    loading.value = true
    let rpcSuccess = false

    try {
      const { data, error } = await supabase.rpc('get_master_analytics_summary', {
        p_date_from: dateFrom.value,
        p_date_to: dateTo.value,
        p_spbu_id: selectedSpbuId.value
      })

      if (!error && data) {
        kpi.value = data.kpi || kpi.value
        trendData.value = data.trend || []
        leaderboard.value = data.leaderboard || []
        rpcSuccess = true
        dataSource.value = 'RPC Database (Server-side)'
      }
    } catch (err) {
      // RPC not available yet
    }

    if (!rpcSuccess) {
      dataSource.value = 'Fallback Direct Query (Frontend)'
      await fetchDirectTableData()
    }

    loading.value = false
  }

  // ─── Export Functions ──────────────────────────────────────────────────────
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
            .footer { margin-top: 50px; font-size: 11px; color: #888; text-align: right; border-t: 1px solid #eee; padding-top: 15px; }
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
