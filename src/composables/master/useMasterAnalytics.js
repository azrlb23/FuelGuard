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
      await fetchTopPlates()
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
    const isSingleSpbu = !!selectedSpbuId.value
    const spbuLabel = isSingleSpbu ? selectedSpbuName.value : 'Semua'

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

    // Header Metadata & KPI Rows
    const sheetRows = [
      ['FUELGUARD - LAPORAN ANALISIS PENJUALAN BBM SPBU'],
      [`SPBU: ${spbuLabel}`],
      [`Periode Laporan: ${periodLabel}`],
      [`Tanggal Cetak: ${printDate}`],
      [],
      ['RINGKASAN KPI'],
      ['Total Transaksi', 'Total Volume (Liter)', 'Total Revenue (Rp)', 'Rata-Rata Transaksi / Hari'],
      [
        kpi.value.totalTransactions || 0,
        kpi.value.totalVolume || 0,
        kpi.value.totalSales || 0,
        kpi.value.avgTrxPerDay || 0
      ],
      []
    ]

    let sheetName = 'Laporan Analisis SPBU'

    if (isSingleSpbu) {
      sheetRows.push(['PERINGKAT PLAT NOMOR PENGISI TERBANYAK'])
      sheetRows.push(['Rank', 'Nomor Plat', 'Kategori', 'Jumlah Transaksi', 'Total Volume (Liter)', 'Total Pembelian (Rp)'])

      if (topPlates.value && topPlates.value.length > 0) {
        topPlates.value.forEach((row, index) => {
          sheetRows.push([
            `#${index + 1}`,
            row.plat_nomor,
            row.is_ojol ? 'Ojol' : 'Umum',
            row.trx_count || 0,
            row.total_liter || 0,
            row.total_harga || 0
          ])
        })
      } else {
        sheetRows.push(['- Tidak ada data transaksi plat untuk SPBU ini pada periode yang dipilih.'])
      }
      sheetName = 'Ranking Plat'
    } else {
      sheetRows.push(['PERINGKAT SPBU BERDASARKAN PENJUALAN'])
      sheetRows.push(['Rank', 'Nama SPBU', 'Revenue (Rp)', 'Volume (Liter)', 'Total Transaksi', 'Kontribusi (%)'])

      if (leaderboard.value && leaderboard.value.length > 0) {
        leaderboard.value.forEach((row, index) => {
          sheetRows.push([
            `#${index + 1}`,
            row.name,
            row.revenue || 0,
            row.volume || 0,
            row.trxCount || 0,
            Number(row.sharePct || 0)
          ])
        })
      }
    }

    const worksheet = XLSX.utils.aoa_to_sheet(sheetRows)
    const workbook = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(workbook, worksheet, sheetName)

    const cleanPeriodStr = periodLabel.replace(/\s+/g, '_')
    const spbuTag = isSingleSpbu ? `_${selectedSpbuName.value.replace(/[^a-zA-Z0-9]/g, '_')}` : ''
    const fileName = `Laporan_Analisis_SPBU${spbuTag}_(${cleanPeriodStr}).xlsx`

    XLSX.writeFile(workbook, fileName)
  }

  const exportToPDF = () => {
    let iframe = document.getElementById('pdf-print-iframe')
    if (!iframe) {
      iframe = document.createElement('iframe')
      iframe.id = 'pdf-print-iframe'
      iframe.style.position = 'fixed'
      iframe.style.right = '0'
      iframe.style.bottom = '0'
      iframe.style.width = '0'
      iframe.style.height = '0'
      iframe.style.border = '0'
      iframe.style.visibility = 'hidden'
      document.body.appendChild(iframe)
    }

    const isSingleSpbu = !!selectedSpbuId.value
    const spbuLabel = isSingleSpbu ? selectedSpbuName.value : 'Semua'

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

    // Build Table Header & Rows conditionally based on Single SPBU vs All SPBUs
    let tableSectionTitle = 'Peringkat SPBU Berdasarkan Penjualan'
    let tableHeaderHtml = `
      <tr>
        <th style="text-align:center;">Rank</th>
        <th>Nama SPBU</th>
        <th style="text-align:right;">Revenue</th>
        <th style="text-align:right;">Volume</th>
        <th style="text-align:center;">Total Transaksi</th>
        <th style="text-align:right;">Kontribusi (%)</th>
      </tr>
    `
    let tableRowsHtml = ''

    if (isSingleSpbu) {
      tableSectionTitle = `Peringkat Plat Nomor Pengisi Terbanyak`
      tableHeaderHtml = `
        <tr>
          <th style="text-align:center; width:60px;">Rank</th>
          <th>Nomor Plat</th>
          <th style="text-align:center;">Kategori</th>
          <th style="text-align:center;">Jumlah Transaksi</th>
          <th style="text-align:right;">Total Volume</th>
          <th style="text-align:right;">Total Pembelian</th>
        </tr>
      `
      if (topPlates.value && topPlates.value.length > 0) {
        tableRowsHtml = topPlates.value.map((item, index) => `
          <tr>
            <td style="padding:10px; border-bottom:1px solid #eee; text-align:center;"><b>#${index + 1}</b></td>
            <td style="padding:10px; border-bottom:1px solid #eee; font-family:monospace; font-weight:bold; font-size:14px; color:#111;">${item.plat_nomor}</td>
            <td style="padding:10px; border-bottom:1px solid #eee; text-align:center;">
              <span style="padding:3px 8px; border-radius:4px; font-size:10px; font-weight:bold; ${item.is_ojol ? 'background:#dcfce7; color:#166534;' : 'background:#f3f4f6; color:#374151;'}">
                ${item.is_ojol ? 'OJOL' : 'UMUM'}
              </span>
            </td>
            <td style="padding:10px; border-bottom:1px solid #eee; text-align:center; font-weight:bold;">${(item.trx_count || 0).toLocaleString('id-ID')}x</td>
            <td style="padding:10px; border-bottom:1px solid #eee; text-align:right; font-weight:bold; color:#143d2e;">${(item.total_liter || 0).toLocaleString('id-ID')} L</td>
            <td style="padding:10px; border-bottom:1px solid #eee; text-align:right; font-weight:bold; color:#143d2e;">${formatCurrency(item.total_harga)}</td>
          </tr>
        `).join('')
      } else {
        tableRowsHtml = `
          <tr>
            <td colspan="6" style="padding:20px; text-align:center; color:#888;">Tidak ada data transaksi plat untuk SPBU ini pada periode yang dipilih.</td>
          </tr>
        `
      }
    } else {
      tableRowsHtml = leaderboard.value.map((row, index) => `
        <tr>
          <td style="padding:10px; border-bottom:1px solid #eee; text-align:center;"><b>#${index + 1}</b></td>
          <td style="padding:10px; border-bottom:1px solid #eee;"><b>${row.name}</b></td>
          <td style="padding:10px; border-bottom:1px solid #eee; text-align:right; font-weight:bold; color:#143d2e;">${formatCurrency(row.revenue)}</td>
          <td style="padding:10px; border-bottom:1px solid #eee; text-align:right;">${(row.volume || 0).toLocaleString('id-ID')} L</td>
          <td style="padding:10px; border-bottom:1px solid #eee; text-align:center;">${(row.trxCount || 0).toLocaleString('id-ID')}</td>
          <td style="padding:10px; border-bottom:1px solid #eee; text-align:right; font-weight:bold; color:#143d2e;">${row.sharePct || 0}%</td>
        </tr>
      `).join('')
    }

    const doc = iframe.contentWindow.document
    doc.open()
    doc.write(`
      <!DOCTYPE html>
      <html>
        <head>
          <title></title>
          <style>
            @page {
              size: portrait;
              margin: 0;
            }
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 15mm; color: #1a1a1a; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
            .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 3px solid #143d2e; padding-bottom: 15px; margin-bottom: 25px; }
            .title { font-size: 24px; font-weight: 900; color: #143d2e; margin: 0; }
            .sub { font-size: 12px; color: #666; margin-top: 4px; }
            .kpi-grid { display: flex; gap: 15px; margin-bottom: 25px; }
            .kpi-card { flex: 1; background: #f8faf9; border-left: 4px solid #143d2e; padding: 12px 15px; border-radius: 8px; }
            .kpi-label { font-size: 10px; text-transform: uppercase; color: #555; font-weight: bold; tracking: 0.5px; }
            .kpi-val { font-size: 18px; font-weight: 900; color: #143d2e; margin-top: 6px; }
            table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 13px; }
            th { background: #143d2e; color: white; padding: 12px; text-align: left; font-size: 11px; text-transform: uppercase; }
            .footer { margin-top: 40px; font-size: 11px; color: #888; text-align: right; border-top: 1px solid #eee; padding-top: 15px; }
          </style>
        </head>
        <body>
          <div class="header">
            <div style="display:flex; align-items:center; gap:12px;">
              <div style="width:42px; height:42px; display:flex; align-items:center; justify-content:center; shrink:0;">
                <img src="${window.location.origin}/fuelguard_logo.png" alt="FuelGuard Logo" style="width:100%; height:100%; object-fit:contain;" />
              </div>
              <div>
                <h1 class="title">FUELGUARD</h1>
                <div class="sub">Laporan Analisis Penjualan BBM SPBU</div>
              </div>
            </div>
            <div style="text-align:right;">
              <div style="font-size:12px; font-weight:bold; color:#143d2e; margin-bottom:3px;">
                SPBU: <span style="font-weight:600; color:#333;">${spbuLabel}</span>
              </div>
              <div style="font-size:12px; font-weight:bold; color:#143d2e; margin-bottom:3px;">
                Periode Laporan: <span style="font-weight:600; color:#333;">${periodLabel}</span>
              </div>
              <div style="font-size:10px; color:#777; margin-top:2px;">Tanggal Cetak: ${printDate}</div>
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

          <h3 style="color:#143d2e; margin-bottom:10px; font-weight:800;">${tableSectionTitle}</h3>
          <table>
            <thead>
              ${tableHeaderHtml}
            </thead>
            <tbody>
              ${tableRowsHtml}
            </tbody>
          </table>

          <div class="footer">
            Dokumen ini dihasilkan secara otomatis oleh Sistem Eksekutif FuelGuard. Confidential.
          </div>
        </body>
      </html>
    `)
    doc.close()

    setTimeout(() => {
      iframe.contentWindow.focus()
      iframe.contentWindow.print()
    }, 250)
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
