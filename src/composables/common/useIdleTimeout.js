import { ref, onMounted, onUnmounted } from 'vue'

export function useIdleTimeout(timeoutMs = 3 * 60 * 1000, onIdleCallback = null) {
  const isIdle = ref(false)
  let timer = null

  const resetTimer = () => {
    if (timer) clearTimeout(timer)
    isIdle.value = false

    timer = setTimeout(() => {
      isIdle.value = true
      if (onIdleCallback && typeof onIdleCallback === 'function') {
        onIdleCallback()
      }
    }, timeoutMs)
  }

  const handleUserActivity = () => {
    // Hanya reset timer jika aplikasi TIDAK dalam keadaan locked/idle
    if (!isIdle.value) {
      resetTimer()
    }
  }

  const events = ['mousemove', 'mousedown', 'keydown', 'touchstart', 'scroll']

  const startIdleTimer = () => {
    events.forEach(evt => window.addEventListener(evt, handleUserActivity, { passive: true }))
    resetTimer()
  }

  const stopIdleTimer = () => {
    if (timer) clearTimeout(timer)
    events.forEach(evt => window.removeEventListener(evt, handleUserActivity))
  }

  onMounted(() => {
    startIdleTimer()
  })

  onUnmounted(() => {
    stopIdleTimer()
  })

  return {
    isIdle,
    resetTimer,
    startIdleTimer,
    stopIdleTimer
  }
}
