import { ref, computed, watch, onMounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { useRoute } from 'vue-router'

export function useMasterHistory(itemsPerPage = 10) {
  const rawTransactions = ref([])
  const loading = ref(false)
  const currentPage = ref(1)

  // Filter state
  const searchQuery = ref('')
  const selectedSpbu = ref('')
  const dateFrom = ref('')
  const dateTo = ref('')
  const sortField = ref('waktu_pencatatan')
  const sortDir = ref('desc') // 'asc' | 'desc'
  const spbuList = ref([])

  const route = useRoute()

  // Helper function to match transaction to best SPBU item
  const matchSpbuForTransaction = (trx, spbuItems) => {
    if (!spbuItems || spbuItems.length === 0) return null

    // 1. Direct ID match
    if (trx.spbu_id) {
      const foundById = spbuItems.find(s => String(s.id) === String(trx.spbu_id))
      if (foundById) return foundById
    }

    // 2. Direct Name match
    if (trx.spbu_name) {
      const foundByName = spbuItems.find(s => s.nama.toLowerCase() === trx.spbu_name.toLowerCase())
      if (foundByName) return foundByName
    }

    // 3. Keyword / Token match (e.g. "MT Haryono" matching "SPBU 61.761.03 MT Haryono")
    if (trx.spbu_name) {
      const tNameLower = trx.spbu_name.toLowerCase()
      const tWords = tNameLower.replace(/spbu/g, '').trim().split(/\s+/).filter(w => w.length > 2)

      const foundByKeyword = spbuItems.find(s => {
        const sNameLower = s.nama.toLowerCase()
        return tWords.some(w => sNameLower.includes(w))
      })
      if (foundByKeyword) return foundByKeyword
    }

    // 4. Fallback to first SPBU
    return spbuItems[0]
  }

  // ─── Fetch All Data Once from Database ─────────────────────────────────────
  const fetchAllData = async () => {
    loading.value = true
    try {
      // 1. Fetch SPBU list from DB
      const { data: dbSpbus } = await supabase
        .from('spbu')
        .select('id, nama, alamat, manajer_id')

      // 2. Fetch all transactions from DB
      const { data: dbTransactions, error } = await supabase
        .from('transaksi_pertalite')
        .select('*')
        .order('waktu_pencatatan', { ascending: false })

      if (error) throw error

      const rawList = dbTransactions || []

      // Build SPBU options Map
      const spbuMap = new Map()

      if (dbSpbus && dbSpbus.length > 0) {
        dbSpbus.forEach(s => {
          const sId = String(s.id)
          const name = s.nama || `SPBU #${sId}`
          spbuMap.set(sId, { id: sId, nama: name })
        })
      }

      // Collect SPBUs from transactions as well to ensure 100% coverage
      rawList.forEach(trx => {
        const sId = trx.spbu_id ? String(trx.spbu_id) : (trx.spbu_name || '1')
        const sName = trx.spbu_name || (spbuMap.get(sId)?.nama) || (dbSpbus && dbSpbus[0]?.nama) || `SPBU #${sId}`
        if (!spbuMap.has(sId)) {
          spbuMap.set(sId, { id: sId, nama: sName })
        }
      })

      if (spbuMap.size === 0) {
        spbuMap.set('1', { id: '1', nama: 'SPBU Utama' })
      }

      const availableSpbus = Array.from(spbuMap.values())
      spbuList.value = availableSpbus

      // Enrich transactions with best matched SPBU info
      rawTransactions.value = rawList.map(trx => {
        const matched = matchSpbuForTransaction(trx, availableSpbus)
        return {
          ...trx,
          spbu_id: matched ? matched.id : String(trx.spbu_id || '1'),
          spbu_name: matched ? matched.nama : (trx.spbu_name || `SPBU #${trx.spbu_id || '1'}`)
        }
      })

    } catch (err) {
      console.error('[useMasterHistory] Error loading data:', err.message)
    } finally {
      loading.value = false
    }
  }

  // ─── In-Memory Filtered & Sorted Data ──────────────────────────────────────
  const filteredTransactions = computed(() => {
    let result = [...rawTransactions.value]

    // Search Plat Nomor
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.trim().toLowerCase()
      result = result.filter(t => t.plat_nomor && t.plat_nomor.toLowerCase().includes(q))
    }

    // Filter SPBU (Flexible matching by ID, Name, or Token Keywords)
    if (selectedSpbu.value) {
      const targetId = String(selectedSpbu.value).toLowerCase()
      const targetItem = spbuList.value.find(s => String(s.id).toLowerCase() === targetId)
      const targetName = targetItem ? targetItem.nama.toLowerCase() : targetId

      result = result.filter(t => {
        const tId = String(t.spbu_id || '').toLowerCase()
        const tName = String(t.spbu_name || '').toLowerCase()

        // Match by ID
        if (tId && tId === targetId) return true
        // Match by exact Name
        if (tName && tName === targetName) return true
        // Match by substring either way (e.g. "SPBU MT Haryono" vs "SPBU 61.761.03 MT Haryono")
        if (tName && targetName && (tName.includes(targetName) || targetName.includes(tName))) return true

        // Keyword token match (e.g., "haryono")
        const targetTokens = targetName.replace(/spbu/g, '').trim().split(/\s+/).filter(w => w.length > 2)
        if (targetTokens.length > 0 && targetTokens.some(w => tName.includes(w))) return true

        return false
      })
    }

    // Filter Date Range
    if (dateFrom.value) {
      const fromTime = new Date(`${dateFrom.value}T00:00:00`).getTime()
      result = result.filter(t => {
        if (!t.waktu_pencatatan) return true
        const tTime = new Date(t.waktu_pencatatan).getTime()
        return !isNaN(tTime) && tTime >= fromTime
      })
    }

    if (dateTo.value) {
      const toTime = new Date(`${dateTo.value}T23:59:59`).getTime()
      result = result.filter(t => {
        if (!t.waktu_pencatatan) return true
        const tTime = new Date(t.waktu_pencatatan).getTime()
        return !isNaN(tTime) && tTime <= toTime
      })
    }

    // Sorting
    result.sort((a, b) => {
      let valA = a[sortField.value]
      let valB = b[sortField.value]

      if (sortField.value === 'waktu_pencatatan') {
        valA = new Date(valA || 0).getTime()
        valB = new Date(valB || 0).getTime()
      } else {
        valA = Number(valA) || 0
        valB = Number(valB) || 0
      }

      if (sortDir.value === 'asc') {
        return valA > valB ? 1 : valA < valB ? -1 : 0
      } else {
        return valA < valB ? 1 : valA > valB ? -1 : 0
      }
    })

    return result
  })

  // Total item count after filtering
  const totalItems = computed(() => filteredTransactions.value.length)

  // Paginated subset
  const transactions = computed(() => {
    const from = (currentPage.value - 1) * itemsPerPage
    const to = from + itemsPerPage
    return filteredTransactions.value.slice(from, to)
  })

  // Watchers to reset page to 1 on filter change
  watch([searchQuery, selectedSpbu, dateFrom, dateTo, sortField, sortDir], () => {
    currentPage.value = 1
  })

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
  }

  onMounted(() => {
    if (route.query.q) {
      searchQuery.value = route.query.q
    }
    fetchAllData()
  })

  return {
    transactions,
    loading,
    totalItems,
    currentPage,
    searchQuery,
    selectedSpbu,
    spbuList,
    dateFrom,
    dateTo,
    sortField,
    sortDir,
    fetchHistory: fetchAllData,
    resetFilters
  }
}
