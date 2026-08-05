import { ref, watch, onMounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { useRoute } from 'vue-router'
import * as XLSX from 'xlsx'

export function useMasterHistory(itemsPerPage = 10) {
  const transactions = ref([])
  const loading = ref(false)
  const isExporting = ref(false)
  const currentPage = ref(1)
  const totalItems = ref(0)

  // Format tanggal lokal (YYYY-MM-DD) untuk 7 hari terakhir (termasuk hari ini)
  const getSevenDaysAgoStr = () => {
    const d = new Date()
    d.setDate(d.getDate() - 6)
    const year = d.getFullYear()
    const month = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  const getTodayStr = () => {
    const d = new Date()
    const year = d.getFullYear()
    const month = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  // Filter state (Default: 7 hari terakhir agar cepat & ringan)
  const searchQuery = ref('')
  const selectedSpbu = ref('')
  const dateFrom = ref(getSevenDaysAgoStr())
  const dateTo = ref(getTodayStr())
  const sortField = ref('waktu_pencatatan')
  const sortDir = ref('desc')
  const spbuList = ref([])

  const route = useRoute()

  // ─── Fetch SPBU Dropdown Options ───────────────────────────────────────────
  const fetchSpbuOptions = async () => {
    try {
      const { data } = await supabase.from('spbu').select('id, nama, alamat')
      if (data && data.length > 0) {
        spbuList.value = data.map(s => ({
          id: String(s.id),
          nama: s.nama || `SPBU #${s.id}`
        }))
      }
    } catch (err) {
      console.warn('[useMasterHistory] Failed to fetch SPBU options:', err)
    }
  }

  /**
   * Fetch riwayat transaksi terpaginasi via RPC get_master_history_paginated.
   * Search, filtering, sorting, dan pagination semuanya dieksekusi di PostgreSQL.
   */
  const fetchHistory = async () => {
    loading.value = true
    try {
      const isSearching = !!searchQuery.value.trim()
      const rpcPageSize = isSearching ? 500 : itemsPerPage
      const rpcPage = isSearching ? 1 : currentPage.value

      const { data, error } = await supabase.rpc('get_master_history_paginated', {
        p_search: '',
        p_spbu_id: selectedSpbu.value || '',
        p_date_from: dateFrom.value || '',
        p_date_to: dateTo.value || '',
        p_sort_field: sortField.value || 'waktu_pencatatan',
        p_sort_dir: sortDir.value || 'desc',
        p_page: rpcPage,
        p_page_size: rpcPageSize
      })

      if (error) throw error

      if (data) {
        let list = data.transactions || []
        if (isSearching) {
          const q = searchQuery.value.trim().toLowerCase()
          list = list.filter(trx => {
            const platMatch = trx.plat_nomor && trx.plat_nomor.toLowerCase().includes(q)
            const opMatch = (trx.operator_name && trx.operator_name.toLowerCase().includes(q)) || 
                            (trx.nama_operator && trx.nama_operator.toLowerCase().includes(q))
            const spbuMatch = (trx.spbu_name && trx.spbu_name.toLowerCase().includes(q)) ||
                              (trx.spbu_id && String(trx.spbu_id).toLowerCase().includes(q))
            let timeMatch = false
            if (trx.waktu_pencatatan) {
              const d = new Date(trx.waktu_pencatatan)
              const timeStr = d.toLocaleTimeString('id-ID', {
                hour: '2-digit',
                minute: '2-digit',
                hour12: false
              }).replace('.', ':')
              
              const dateStr = d.toLocaleDateString('id-ID', {
                day: '2-digit',
                month: 'short',
                year: 'numeric'
              }).toLowerCase()

              timeMatch = timeStr.includes(q) || 
                          timeStr.replace(':', '.').includes(q) || 
                          dateStr.includes(q)
            }
            return platMatch || opMatch || spbuMatch || timeMatch
          })
          totalItems.value = list.length
          const startIdx = (currentPage.value - 1) * itemsPerPage
          transactions.value = list.slice(startIdx, startIdx + itemsPerPage)
        } else {
          transactions.value = list
          totalItems.value = data.total_count || 0
        }
      } else {
        transactions.value = []
        totalItems.value = 0
      }
    } catch (err) {
      console.error('[useMasterHistory] Error:', err.message || err)
      transactions.value = []
      totalItems.value = 0
    } finally {
      loading.value = false
    }
  }

  /**
   * Export SELURUH data transaksi terfilter ke format spreadsheet Excel (.xlsx).
   * Menggunakan strategi Chunk-Fetching (5000 item/halaman) agar tidak terpotong oleh limit Supabase.
   */
  const exportToExcel = async () => {
    if (isExporting.value) return
    isExporting.value = true
    try {
      const CHUNK_SIZE = 5000
      let allTransactions = []
      let page = 1
      let totalCountToFetch = totalItems.value || 0

      // Ambil Chunk Pertama
      const { data, error } = await supabase.rpc('get_master_history_paginated', {
        p_search: searchQuery.value.trim(),
        p_spbu_id: selectedSpbu.value,
        p_date_from: dateFrom.value,
        p_date_to: dateTo.value,
        p_sort_field: sortField.value,
        p_sort_dir: sortDir.value,
        p_page: page,
        p_page_size: CHUNK_SIZE
      })

      if (error) throw error

      if (data && data.transactions) {
        allTransactions.push(...data.transactions)
        totalCountToFetch = data.total_count || totalCountToFetch
      }

      // Jika data terfilter melebihi 5000 (misal 10.000+ data), lakukan fetch chunk berikutnya
      const totalPagesToFetch = Math.ceil(totalCountToFetch / CHUNK_SIZE)
      while (page < totalPagesToFetch) {
        page++
        const { data: chunkData, error: chunkError } = await supabase.rpc('get_master_history_paginated', {
          p_search: searchQuery.value.trim(),
          p_spbu_id: selectedSpbu.value,
          p_date_from: dateFrom.value,
          p_date_to: dateTo.value,
          p_sort_field: sortField.value,
          p_sort_dir: sortDir.value,
          p_page: page,
          p_page_size: CHUNK_SIZE
        })

        if (chunkError) {
          console.warn('[useMasterHistory] Chunk export warning:', chunkError)
          break
        }

        if (chunkData && chunkData.transactions) {
          allTransactions.push(...chunkData.transactions)
        } else {
          break
        }
      }

      if (allTransactions.length === 0) return

      const excelData = allTransactions.map((trx, idx) => {
        const d = new Date(trx.waktu_pencatatan)
        const dateStr = isNaN(d.getTime()) ? trx.waktu_pencatatan : d.toLocaleDateString('id-ID', { day: '2-digit', month: '2-digit', year: 'numeric' })
        const timeStr = isNaN(d.getTime()) ? '' : d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' })

        return {
          'No': idx + 1,
          'Tanggal': dateStr,
          'Waktu': timeStr,
          'SPBU': trx.spbu_name || `SPBU #${trx.spbu_id}`,
          'Operator': trx.operator_name || '-',
          'Kategori': trx.is_ojol ? 'Ojol' : 'Umum',
          'Plat Nomor': trx.plat_nomor,
          'Liter (L)': trx.liter,
          'Harga (Rp)': trx.harga
        }
      })

      const worksheet = XLSX.utils.json_to_sheet(excelData)
      const workbook = XLSX.utils.book_new()
      XLSX.utils.book_append_sheet(workbook, worksheet, 'Riwayat Transaksi')

      let periodTag = ''
      if (dateFrom.value && dateTo.value) {
        periodTag = dateFrom.value === dateTo.value ? dateFrom.value : `${dateFrom.value}_sd_${dateTo.value}`
      } else if (dateFrom.value) {
        periodTag = `mulai_${dateFrom.value}`
      } else if (dateTo.value) {
        periodTag = `sampai_${dateTo.value}`
      } else {
        const dates = allTransactions.map(t => new Date(t.waktu_pencatatan).toISOString().slice(0, 10)).filter(Boolean).sort()
        if (dates.length > 0) {
          const minDate = dates[0]
          const maxDate = dates[dates.length - 1]
          periodTag = minDate === maxDate ? minDate : `${minDate}_sd_${maxDate}`
        } else {
          periodTag = new Date().toISOString().slice(0, 10)
        }
      }

      const fileName = `Riwayat_Transaksi_Periode_${periodTag}.xlsx`
      XLSX.writeFile(workbook, fileName)
    } catch (err) {
      console.error('[useMasterHistory] Export Excel Error:', err)
    } finally {
      isExporting.value = false
    }
  }

  // Auto-fetch saat filter selain searchQuery berubah secara instan
  watch([selectedSpbu, dateFrom, dateTo, sortField, sortDir], () => {
    currentPage.value = 1
    fetchHistory()
  })

  // Watch searchQuery dengan Debounce (500ms)
  let searchDebounceTimer = null
  watch(searchQuery, () => {
    clearTimeout(searchDebounceTimer)
    searchDebounceTimer = setTimeout(() => {
      currentPage.value = 1
      fetchHistory()
    }, 500)
  })

  // Re-fetch ketika halaman berubah
  watch(currentPage, () => {
    fetchHistory()
  })

  // Sync search dari URL query param jika ada
  watch(() => route.query.q, (newQuery) => {
    if (newQuery !== undefined) {
      searchQuery.value = newQuery
    }
  })

  const resetFilters = () => {
    searchQuery.value = ''
    selectedSpbu.value = ''
    dateFrom.value = ''
    dateTo.value = ''
    sortField.value = 'waktu_pencatatan'
    sortDir.value = 'desc'
    currentPage.value = 1
    fetchHistory()
  }

  onMounted(() => {
    if (route.query.q) {
      searchQuery.value = route.query.q
    }
    fetchSpbuOptions()
    fetchHistory()
  })

  return {
    transactions,
    loading,
    isExporting,
    totalItems,
    currentPage,
    searchQuery,
    selectedSpbu,
    spbuList,
    dateFrom,
    dateTo,
    sortField,
    sortDir,
    fetchHistory,
    exportToExcel,
    resetFilters
  }
}
