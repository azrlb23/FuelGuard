import { ref, onUnmounted } from 'vue'
import { toast } from 'vue3-toastify'
import Tesseract from 'tesseract.js'

export function useCameraScanner() {
  const isScanning = ref(false)
  const isProcessing = ref(false)
  const stream = ref(null)

  const startCamera = async () => {
    isScanning.value = true
    
    if (stream.value) {
      stream.value.getTracks().forEach(t => t.stop())
    }

    try {
      try {
        stream.value = await navigator.mediaDevices.getUserMedia({ 
          audio: false, 
          video: { facingMode: { exact: "environment" } } 
        })
      } catch (err) {
        console.warn("Gagal akses kamera belakang, mencoba kamera standar...", err)
        stream.value = await navigator.mediaDevices.getUserMedia({ 
          audio: false, 
          video: true 
        })
      }

      return stream.value

    } catch (err) {
      console.error("Camera Fatal Error:", err)
      isScanning.value = false

      if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
        toast.error("Izin kamera ditolak browser!")
      } else if (err.name === 'NotFoundError') {
        toast.error("Perangkat kamera tidak ditemukan!")
      } else {
        toast.error("Gagal buka kamera: " + err.message)
      }
      return null
    }
  }

  const stopCamera = () => {
    if (stream.value) {
      stream.value.getTracks().forEach(track => track.stop())
      stream.value = null
    }
    isScanning.value = false
    isProcessing.value = false
  }

  const validateAndFormat = (rawText) => {
    const clean = rawText.replace(/[^A-Z0-9]/gi, '').toUpperCase()

    const platePattern = /^([A-Z]{1,2})(\d{1,4})([A-Z]{1,3})$/

    const match = clean.match(platePattern)

    if (match) {
      return `${match[1]} ${match[2]} ${match[3]}`
    }

    return null
  }

  const scanPlateNumber = async (videoElement) => {
    if (!videoElement) return null
    isProcessing.value = true
    
    const canvas = document.createElement('canvas')
    canvas.width = videoElement.videoWidth
    canvas.height = videoElement.videoHeight
    const ctx = canvas.getContext('2d')
    ctx.drawImage(videoElement, 0, 0)
    
    try {
      const { data: { text } } = await Tesseract.recognize(canvas, 'eng', { tessedit_char_whitelist: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789' })
      
      const cleanText = text.replace(/[^A-Z0-9]/gi, '').toUpperCase()
      
      isProcessing.value = false
      stopCamera()
      return cleanText
      
    } catch (err) {
      console.error(err)
      isProcessing.value = false
      toast.error("Gagal membaca teks")
      return null
    }
  }

  onUnmounted(() => {
    stopCamera()
  })

  return {
    isScanning,
    isProcessing,
    stream,
    startCamera,
    stopCamera,
    scanPlateNumber
  }
}