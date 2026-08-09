import { ref, onMounted, onUnmounted } from 'vue'

const isOnline = ref(typeof navigator !== 'undefined' ? navigator.onLine : true)
const isSyncing = ref(false)
const pendingSyncCount = ref(0)

export function useNetworkStatus() {
  const updateOnlineStatus = () => {
    isOnline.value = navigator.onLine
  }

  let isInitialized = false

  const initListeners = () => {
    if (isInitialized || typeof window === 'undefined') return
    window.addEventListener('online', updateOnlineStatus)
    window.addEventListener('offline', updateOnlineStatus)
    isInitialized = true
  }

  onMounted(() => {
    initListeners()
  })

  return {
    isOnline,
    isSyncing,
    pendingSyncCount,
    updateOnlineStatus
  }
}
