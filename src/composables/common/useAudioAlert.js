import { ref } from 'vue'

const isAudioEnabled = ref(localStorage.getItem('fg_audio_enabled') !== 'false')
const isSuccessSoundEnabled = ref(localStorage.getItem('fg_audio_success') !== 'false')
const isWarningSoundEnabled = ref(localStorage.getItem('fg_audio_warning') !== 'false')

let audioCtx = null

const getAudioContext = () => {
  if (!audioCtx) {
    const AudioContextClass = window.AudioContext || window.webkitAudioContext
    if (AudioContextClass) {
      audioCtx = new AudioContextClass()
    }
  }
  if (audioCtx && audioCtx.state === 'suspended') {
    audioCtx.resume()
  }
  return audioCtx
}

export function useAudioAlert() {
  
  // Play Success Sound: High-pitched double chime (C5 -> E5)
  const playSuccessSound = () => {
    if (!isAudioEnabled.value || !isSuccessSoundEnabled.value) return
    try {
      const ctx = getAudioContext()
      if (!ctx) return

      const now = ctx.currentTime
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()

      osc.type = 'sine'
      osc.frequency.setValueAtTime(523.25, now) // C5
      osc.frequency.setValueAtTime(659.25, now + 0.08) // E5

      gain.gain.setValueAtTime(0.15, now)
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.25)

      osc.connect(gain)
      gain.connect(ctx.destination)

      osc.start(now)
      osc.stop(now + 0.25)
    } catch (e) {
      console.warn('[AudioAlert] Error playing success sound:', e)
    }
  }

  // Play Warning / Error Sound: Double low-frequency warning alert
  const playWarningSound = () => {
    if (!isAudioEnabled.value || !isWarningSoundEnabled.value) return
    try {
      const ctx = getAudioContext()
      if (!ctx) return

      const now = ctx.currentTime
      
      // Beep 1
      const osc1 = ctx.createOscillator()
      const gain1 = ctx.createGain()
      osc1.type = 'triangle'
      osc1.frequency.setValueAtTime(783.99, now) // G5
      gain1.gain.setValueAtTime(0.2, now)
      gain1.gain.exponentialRampToValueAtTime(0.01, now + 0.12)
      osc1.connect(gain1)
      gain1.connect(ctx.destination)
      osc1.start(now)
      osc1.stop(now + 0.12)

      // Beep 2
      const osc2 = ctx.createOscillator()
      const gain2 = ctx.createGain()
      osc2.type = 'triangle'
      osc2.frequency.setValueAtTime(523.25, now + 0.15) // C5
      gain2.gain.setValueAtTime(0.25, now + 0.15)
      gain2.gain.exponentialRampToValueAtTime(0.01, now + 0.35)
      osc2.connect(gain2)
      gain2.connect(ctx.destination)
      osc2.start(now + 0.15)
      osc2.stop(now + 0.35)
    } catch (e) {
      console.warn('[AudioAlert] Error playing warning sound:', e)
    }
  }

  const toggleMasterAudio = (val) => {
    isAudioEnabled.value = val
    localStorage.setItem('fg_audio_enabled', val)
  }

  const toggleSuccessSound = (val) => {
    isSuccessSoundEnabled.value = val
    localStorage.setItem('fg_audio_success', val)
  }

  const toggleWarningSound = (val) => {
    isWarningSoundEnabled.value = val
    localStorage.setItem('fg_audio_warning', val)
  }

  return {
    isAudioEnabled,
    isSuccessSoundEnabled,
    isWarningSoundEnabled,
    playSuccessSound,
    playWarningSound,
    toggleMasterAudio,
    toggleSuccessSound,
    toggleWarningSound
  }
}
