import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { useAuthStore } from '@/stores/auth'
import { secureSetItem, secureGetItem, secureRemoveItem } from '@/utils/cryptoStorage'

const STORAGE_KEY_PENGETAP = 'hj_cache_pengetap_v1'

const getTodayStr = () => {
  try {
    const formatter = new Intl.DateTimeFormat('sv-SE', { timeZone: 'Asia/Makassar' })
    return formatter.format(new Date())
  } catch (e) {
    const now = new Date()
    const y = now.getFullYear()
    const m = String(now.getMonth() + 1).padStart(2, '0')
    const d = String(now.getDate()).padStart(2, '0')
    return `${y}-${m}-${d}`
  }
}

const getCachedPengetapLogs = (spbuId) => {
  try {
    const parsed = secureGetItem(STORAGE_KEY_PENGETAP)
    if (!parsed) return []
    if (parsed.cacheDate !== getTodayStr() || (spbuId && parsed.spbuId !== spbuId)) {
      secureRemoveItem(STORAGE_KEY_PENGETAP)
      return []
    }
    return Array.isArray(parsed.logs) ? parsed.logs : []
  } catch (e) {
    return []
  }
}

const savePengetapCache = (logsList, spbuId) => {
  try {
    if (Array.isArray(logsList)) {
      secureSetItem(STORAGE_KEY_PENGETAP, {
        cacheDate: getTodayStr(),
        spbuId: spbuId,
        logs: logsList
      })
    }
  } catch (e) {}
}

export function useRepeatedLogs(itemsPerPage = 50) {
  const logs = ref([])
  const loading = ref(false)
  const totalCount = ref(0)
  const currentPage = ref(1)
  const searchQuery = ref('')

  const authStore = useAuthStore()

  const fetchOperatorLogs = async () => {
    if (!authStore.isInitialized) {
      await authStore.initialize()
    }

    loading.value = true

    // Offline Fallback: Gunakan cache lokal & jalankan client-side search jika offline
    if (typeof navigator !== 'undefined' && !navigator.onLine) {
      let cachedList = getCachedPengetapLogs()
      if (searchQuery.value.trim()) {
        const q = searchQuery.value.trim().toLowerCase()
        cachedList = cachedList.filter(l => l.plat_nomor && l.plat_nomor.toLowerCase().includes(q))
      }
      logs.value = cachedList
      totalCount.value = cachedList.length
      loading.value = false
      return
    }

    try {
      // Panggil RPC dengan p_spbu_id: null agar Cross-SPBU seluruh log hari ini
      const { data, error } = await supabase.rpc('get_operator_repeated_logs', {
        p_spbu_id: null,
        p_page: currentPage.value,
        p_page_size: itemsPerPage,
        p_search: searchQuery.value.trim()
      })

      if (error) {
        console.warn('[useRepeatedLogs] RPC Error during fetch:', error.message)
        throw error
      }

      if (data) {
        const fetchedLogs = data.logs || []
        logs.value = fetchedLogs
        totalCount.value = data.total_count || 0
        if (!searchQuery.value.trim()) {
          savePengetapCache(fetchedLogs)
        }
      }
    } catch (err) {
      console.warn('[useRepeatedLogs] Network fetch failed, reading cached logs:', err.message)
      let cachedList = getCachedPengetapLogs()
      if (searchQuery.value.trim()) {
        const q = searchQuery.value.trim().toLowerCase()
        cachedList = cachedList.filter(l => l.plat_nomor && l.plat_nomor.toLowerCase().includes(q))
      }
      logs.value = cachedList
      totalCount.value = cachedList.length
    } finally {
      loading.value = false
    }
  }

  // Grouped logs: group flat log entries by plat_nomor for accordion UI
  const groupedLogs = computed(() => {
    const map = new Map()

    for (const item of logs.value) {
      if (!map.has(item.plat_nomor)) {
        map.set(item.plat_nomor, {
          plat_nomor: item.plat_nomor,
          is_ojol: item.is_ojol,
          attempt_count: 0,
          latest_waktu: item.waktu,
          latest_tanggal: item.tanggal,
          spbu_ids: new Set(),
          entries: []
        })
      }
      const group = map.get(item.plat_nomor)
      group.attempt_count++
      group.spbu_ids.add(item.attempt_spbu_id)
      // First item in sorted desc order = latest
      if (group.entries.length === 0) {
        group.latest_waktu = item.waktu
        group.latest_tanggal = item.tanggal
      }
      group.entries.push(item)
    }

    return Array.from(map.values()).map(g => ({
      ...g,
      spbu_ids: Array.from(g.spbu_ids)
    }))
  })

  // Debounce search (300ms) to avoid flooding RPC on every keystroke
  let searchDebounceTimer = null
  watch(searchQuery, () => {
    clearTimeout(searchDebounceTimer)
    searchDebounceTimer = setTimeout(() => {
      currentPage.value = 1
      fetchOperatorLogs()
    }, 300)
  })

  const handleOnlineReconnect = () => {
    fetchOperatorLogs()
  }

  const resetFilters = () => {
    searchQuery.value = ''
    currentPage.value = 1
    fetchOperatorLogs()
  }

  onMounted(() => {
    if (typeof window !== 'undefined') {
      window.addEventListener('online', handleOnlineReconnect)
    }
    fetchOperatorLogs()
  })

  onUnmounted(() => {
    clearTimeout(searchDebounceTimer)
    if (typeof window !== 'undefined') {
      window.removeEventListener('online', handleOnlineReconnect)
    }
  })

  return {
    logs,
    groupedLogs,
    loading,
    totalCount,
    currentPage,
    searchQuery,
    fetchOperatorLogs,
    resetFilters
  }
}
