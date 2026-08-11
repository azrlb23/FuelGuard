<script setup>
import { ref, computed, watch, onMounted, nextTick } from 'vue'
import { toast } from 'vue3-toastify'
import { supabase } from '@/lib/supabaseClient'
import { useAuthStore } from '@/stores/auth'
import { useCameraScanner } from '@/composables/operator/useCameraScanner'
import { useTransactionAction } from '@/composables/operator/useTransactionAction'
import { useAudioAlert } from '@/composables/common/useAudioAlert'
import { validatePlateFormat } from '@/utils/plateValidation'

const props = defineProps({
  vehicleType: { type: String, required: true },
  isOjol: { type: Boolean, default: false },
  loading: Boolean
})

const emit = defineEmits(['submit', 'back'])

const { playSuccessSound, playWarningSound } = useAudioAlert()
const { isScanning, isProcessing, startCamera, stopCamera, scanPlateNumber } = useCameraScanner()
const { checkPlateStatus, recordRepeatedLog, checkingPlate, submitTransaction } = useTransactionAction()
const authStore = useAuthStore()

const videoRef = ref(null)
const platInputRef = ref(null)
const literInputRef = ref(null)
const hargaInputRef = ref(null)
const submitBtnRef = ref(null)

const isCameraFeatureEnabled = ref(false)

const subStep = ref('check_plate') // 'check_plate' | 'input_liter'
const showRefueledModal = ref(false)
const refueledInfo = ref(null)

const scrollToBottomInput = () => {
  nextTick(() => {
    setTimeout(() => {
      if (literInputRef.value) {
        try {
          literInputRef.value.focus({ preventScroll: true })
        } catch (e) {
          literInputRef.value.focus()
        }
      }
      if (submitBtnRef.value) {
        submitBtnRef.value.scrollIntoView({ behavior: 'smooth', block: 'end' })
      } else {
        window.scrollTo({ top: document.body.scrollHeight || 99999, behavior: 'smooth' })
      }
    }, 60)
  })
}

watch(subStep, (newStep) => {
  if (newStep === 'input_liter') {
    scrollToBottomInput()
  }
})

const form = ref({
  plat_nomor: '',
  liter: '',
  totalHarga: ''
})

// Menentukan kolom mana yang terakhir diedit agar tidak terjadi loop
const lastEdited = ref('liter') // 'liter' | 'harga'

// ─── Validasi & Auto-Format Plat Nomor Indonesia ─────────────────────────────
// Format: [1-2 huruf kode wilayah] [1-4 angka] [1-3 huruf akhir]
// Contoh valid: KT 1234 AB, B 1234 CD, DK 123 A, KT 1234
const PLAT_REGEX = /^[A-Z]{1,2}\s\d{1,4}(\s[A-Z]{1,3})?$/

const platMessage = ref('')
const platStatus = ref('idle') // 'idle' | 'invalid' | 'validating' | 'valid'
const platTouched = ref(false)
let debounceTimeout = null

const formatAngka = (val) => {
  if (!val && val !== 0) return '0'
  return new Intl.NumberFormat('id-ID').format(val)
}

// Auto-format plat nomor sekuensial:
// Bagian 1: WAJIB 1-2 Huruf Kode Wilayah di awal (angka di awal ditolak)
// Bagian 2: HANYA 1-4 Angka Nomor Polisi
// Bagian 3: 1-3 Huruf Seri/Akhiran Wilayah
const formatPlatNomor = (val) => {
  if (!val) return ''
  const raw = val.toUpperCase().replace(/[^A-Z0-9]/g, '')

  let region = ''
  let number = ''
  let suffix = ''

  let i = 0

  // 1. Kode Wilayah: Wajib 1-2 Huruf di awal.
  // Abaikan/lewati jika user mencoba memasukkan angka sebelum ada huruf kode wilayah
  while (i < raw.length && !/[A-Z]/.test(raw[i])) {
    i++
  }

  // Ambil 1-2 huruf kode wilayah
  while (i < raw.length && /[A-Z]/.test(raw[i]) && region.length < 2) {
    region += raw[i]
    i++
  }

  // Jika tidak ada huruf kode wilayah sama sekali, tolak seluruh input (kembalikan kosong)
  if (!region) return ''

  // Jika ada huruf ke-3 sebelum angka, lewati huruf ekstra tersebut hingga menemukan angka
  while (i < raw.length && !/\d/.test(raw[i])) {
    i++
  }

  // 2. Nomor Polisi: HANYA 1-4 Angka (angka pertama TIDAK BOLEH 0)
  while (i < raw.length && /\d/.test(raw[i]) && number.length < 4) {
    // Angka pertama nomor polisi tidak boleh 0
    if (number.length === 0 && raw[i] === '0') {
      i++
      continue
    }
    number += raw[i]
    i++
  }

  // 3. Huruf Akhir / Seri Wilayah: 1-3 Huruf (hanya diisi jika nomor polisi sudah ada)
  if (number) {
    while (i < raw.length && suffix.length < 3) {
      if (/[A-Z]/.test(raw[i])) {
        suffix += raw[i]
      }
      i++
    }
  }

  let result = region
  if (number) result += ' ' + number
  if (suffix) result += ' ' + suffix

  return result
}

// Auto-check live ke database (HANYA UPDATE VISUAL TEKS INDIKATOR — TANPA BISA INSERT LOG)
const checkPlateLive = async (cleaned) => {
  const res = await checkPlateStatus(cleaned, props.vehicleType === 'Ojol')

  // Pastikan user tidak mengetik hal lain selagi menunggu
  if (form.value.plat_nomor.trim() !== cleaned) return

  if (res && res.success) {
    if (res.hasRefueledToday || res.remainingQuota <= 0) {
      platStatus.value = 'invalid'
      platMessage.value = 'Kendaraan ini sudah mencapai limit harian!'
    } else {
      platStatus.value = 'valid'
      platMessage.value = `Sisa Kuota: Rp ${formatAngka(res.remainingQuota)} (Tekan Enter)`
    }
  } else if (res && !res.success) {
    platStatus.value = 'invalid'
    platMessage.value = (res.message || 'Plat ditolak sistem.')
  }
}

// Sanitasi & auto-format input plat saat mengetik
const onPlatInput = (e) => {
  platTouched.value = true
  const formatted = formatPlatNomor(e.target.value)
  form.value.plat_nomor = formatted
  e.target.value = formatted

  const cleaned = formatted.trim()
  if (debounceTimeout) clearTimeout(debounceTimeout)

  if (!cleaned) {
    platStatus.value = 'idle'
    platMessage.value = ''
  } else {
    const valRes = validatePlateFormat(cleaned)
    if (!valRes.isValid) {
      platStatus.value = 'invalid'
      platMessage.value = valRes.message
    } else {
      platStatus.value = 'validating'
      platMessage.value = 'Sedang mengecek ke database...'

      debounceTimeout = setTimeout(() => {
        if (subStep.value === 'check_plate' && form.value.plat_nomor.trim() === cleaned) {
          checkPlateLive(cleaned)
        }
      }, 500)
    }
  }
}

// Blokir karakter terlarang di level keydown — sebelum sempat masuk DOM
const ALLOWED_KEYS = new Set([
  'Backspace', 'Delete', 'Tab', 'ArrowLeft', 'ArrowRight',
  'ArrowUp', 'ArrowDown', 'Home', 'End', ' ', 'Enter',
])

const onPlatKeydown = (e) => {
  if (e.ctrlKey || e.metaKey) return
  if (ALLOWED_KEYS.has(e.key)) return
  if (/^[a-zA-Z]$/.test(e.key)) return
  if (/^[0-9]$/.test(e.key)) return

  // Blokir semua karakter lainnya (simbol: = - _ ! @ # $ % dll)
  e.preventDefault()
}

onMounted(() => {
  isCameraFeatureEnabled.value = localStorage.getItem('hj_pref_camera') === 'true'
  nextTick(() => {
    if (platInputRef.value) {
      platInputRef.value.focus()
    }
  })
})

/**
 * HANDLER UTAMA SAAT OPERATOR MENEKAN TOMBOL "CEK PLAT" ATAU ENTER
 * (Di sini data alert HANYA TERCATAT 1x ke database jika terdeteksi limit/mismatch)
 */
const handleCheckPlate = async () => {
  if (checkingPlate.value) return
  if (debounceTimeout) clearTimeout(debounceTimeout)

  platTouched.value = true
  const cleaned = form.value.plat_nomor.trim()

  if (!cleaned) {
    platStatus.value = 'invalid'
    platMessage.value = 'Mohon masukkan nomor plat kendaraan'
    return
  }

  const valRes = validatePlateFormat(cleaned)
  if (!valRes.isValid) {
    platStatus.value = 'invalid'
    platMessage.value = valRes.message
    return
  }

  form.value.plat_nomor = valRes.platClean
  platMessage.value = 'Memproses...'

  const res = await checkPlateStatus(valRes.platClean, props.isOjol)

  if (res && res.success) {
    form.value.plat_nomor = res.plat || valRes.platClean
    refueledInfo.value = res

    if (res.hasRefueledToday || res.remainingQuota <= 0) {
      // 🚨 PENCATATAN EKSPLISIT: Catat log perulangan HANYA saat tombol Enter/Cek Plat ditekan!
      await recordRepeatedLog(valRes.platClean, props.isOjol, 'quota_exceeded', res.totalHargaToday)

      const history = res.history_today ? [...res.history_today] : []
      const nowWita = new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', hour12: false }).replace('.', ':') + ' WITA'
      history.unshift({
        waktu: nowWita,
        spbu_id: authStore.spbuId || 'SPBU ini',
        spbu_nama: 'SPBU ini',
        status: 'ditolak',
        liter: 0,
        reason: 'Kuota Habis'
      })

      refueledInfo.value = {
        ...res,
        history_today: history,
        isQuotaExceededTransaction: res.remainingQuota <= 0 || res.hasRefueledToday
      }
      showRefueledModal.value = true
      playWarningSound()
    } else {
      subStep.value = 'input_liter'
      form.value.liter = ''
      form.value.totalHarga = ''
      lastEdited.value = 'liter'
      scrollToBottomInput()
    }
  } else if (res && !res.success) {
    if (res.reason === 'category_mismatch') {
      // 🚨 PENCATATAN EKSPLISIT: Catat log mismatch HANYA saat tombol Enter/Cek Plat ditekan!
      await recordRepeatedLog(valRes.platClean, props.isOjol, 'category_mismatch', 0)

      const history = res.history_today ? [...res.history_today] : []
      const nowWita = new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', hour12: false }).replace('.', ':') + ' WITA'
      history.unshift({
        waktu: nowWita,
        spbu_id: authStore.spbuId || 'SPBU ini',
        spbu_nama: 'SPBU ini',
        status: 'ditolak',
        liter: 0,
        reason: 'Kategori Tidak Sesuai'
      })

      refueledInfo.value = {
        plat: cleaned,
        history_today: history,
        isCategoryMismatch: true,
        message: res.message || 'Kendaraan ini sudah terdaftar di kategori lain hari ini!'
      }
      showRefueledModal.value = true
    } else {
      platStatus.value = 'invalid'
      platMessage.value = res.message || 'Plat nomor ditolak oleh sistem.'
    }
  }
}

const handleEditPlateNumber = () => {
  showRefueledModal.value = false
  subStep.value = 'check_plate'
  platStatus.value = 'idle'
  nextTick(() => {
    if (platInputRef.value) {
      platInputRef.value.focus()
      platInputRef.value.select()
    }
  })
}

const handleResetVehicleSelection = () => {
  showRefueledModal.value = false
  refueledInfo.value = null
  form.value.plat_nomor = ''
  platStatus.value = 'idle'
  subStep.value = 'check_plate'
  emit('back')
}

const handleBackToPlateCheck = () => {
  subStep.value = 'check_plate'
  nextTick(() => {
    if (platInputRef.value) {
      platInputRef.value.focus()
    }
  })
}

const handleStartCamera = async () => {
  const mediaStream = await startCamera()

  if (mediaStream) {
    await nextTick()

    if (videoRef.value) {
      videoRef.value.srcObject = mediaStream
      try {
        await videoRef.value.play()
      } catch (e) {
        console.error("Gagal auto-play video:", e)
      }
    } else {
      toast.error("Error: Element video tidak ditemukan")
    }
  }
}

const handleScan = async () => {
  const result = await scanPlateNumber(videoRef.value)
  if (result) {
    const formatted = formatPlatNomor(result)
    form.value.plat_nomor = formatted
    toast.success("Plat Terdeteksi: " + formatted)
    await handleCheckPlate()
  } else {
    toast.warn("Coba lagi, pastikan gambar jelas.")
  }
}

// Harga per liter digunakan untuk kalkulasi tampilan UI 2 arah (liter <-> harga).
const hargaPerLiter = ref(10000)

const fetchFuelPrice = async () => {
  try {
    // Ambil harga Pertalite resmi regional
    const { data } = await supabase
      .from('fuel_prices')
      .select('price_per_liter')
      .ilike('fuel_type', '%pertalite%')
      .order('updated_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (data && data.price_per_liter) {
      hargaPerLiter.value = Number(data.price_per_liter)
    }
  } catch (err) {
    console.error('Error fetching Pertalite price for operator:', err)
  }
}

onMounted(() => {
  fetchFuelPrice()
})

const formatRupiah = (val) => {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val)
}

const formatWitaTime = (timeStr, fullDateStr) => {
  if (fullDateStr) {
    const d = new Date(fullDateStr)
    if (!isNaN(d.getTime())) {
      return d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', hour12: false }).replace('.', ':')
    }
  }
  if (timeStr && typeof timeStr === 'string' && timeStr.includes(':')) {
    const parts = timeStr.split(':')
    const h = parseInt(parts[0], 10)
    const m = parts[1]
    if (!isNaN(h)) {
      const witaHour = (h + 8) % 24
      return `${String(witaHour).padStart(2, '0')}:${m}`
    }
  }
  return timeStr || ''
}

const parseRupiah = (str) => {
  return parseFloat(String(str).replace(/[^\d]/g, '')) || 0
}

watch(() => form.value.liter, (val) => {
  if (lastEdited.value !== 'liter') return
  const liter = parseFloat(val) || 0
  form.value.totalHarga = liter > 0 ? formatAngka(liter * hargaPerLiter.value) : ''
})

watch(() => form.value.totalHarga, (val) => {
  if (lastEdited.value !== 'harga') return
  const harga = parseRupiah(val)
  form.value.liter = harga > 0 ? String(parseFloat((harga / hargaPerLiter.value).toFixed(3))) : ''
})

const ALLOWED_NUMERIC_KEYS = new Set([
  'Backspace', 'Delete', 'Tab', 'ArrowLeft', 'ArrowRight',
  'Home', 'End', 'Enter'
])

const onHargaKeydown = (e) => {
  if (e.ctrlKey || e.metaKey) return
  if (ALLOWED_NUMERIC_KEYS.has(e.key)) return
  if (/^[0-9]$/.test(e.key)) return

  // Blokir huruf, simbol, dan spasi
  e.preventDefault()
}

const onLiterKeydown = (e) => {
  if (e.ctrlKey || e.metaKey) return
  if (ALLOWED_NUMERIC_KEYS.has(e.key)) return
  if (/^[0-9.]$/.test(e.key)) return

  // Blokir huruf dan simbol selain angka dan titik desimal
  e.preventDefault()
}

const onHargaInput = (e) => {
  lastEdited.value = 'harga'
  const raw = parseRupiah(e.target.value)
  const formatted = raw > 0 ? formatAngka(raw) : ''
  form.value.totalHarga = formatted
  e.target.value = formatted
}

const onLiterInput = () => {
  lastEdited.value = 'liter'
}

const selectPresetLiter = (literValue) => {
  lastEdited.value = 'liter'
  form.value.liter = String(literValue)
  form.value.totalHarga = formatAngka(literValue * hargaPerLiter.value)
}

const selectPresetRupiah = (hargaNominal) => {
  lastEdited.value = 'harga'
  form.value.totalHarga = formatAngka(hargaNominal)
  const liter = (hargaNominal / hargaPerLiter.value).toFixed(2)
  form.value.liter = String(liter)
}

const selectPresetFullQuota = () => {
  let maxLiter = props.isOjol ? 10 : 5

  if (refueledInfo.value && refueledInfo.value.remainingQuota !== undefined) {
    const rem = refueledInfo.value.remainingQuota
    if (typeof rem === 'number' && rem > 0) {
      if (rem <= 100) {
        maxLiter = Math.min(maxLiter, rem)
      } else {
        const remLiter = rem / hargaPerLiter.value
        maxLiter = Math.min(maxLiter, remLiter)
      }
    }
  }

  selectPresetLiter(maxLiter)
}

const isSubmittingLock = ref(false)

const handleSubmit = async () => {
  if (isSubmittingLock.value) return
  isSubmittingLock.value = true
  setTimeout(() => { isSubmittingLock.value = false }, 300)

  const liter = parseFloat(form.value.liter)
  if (!liter || liter <= 0) {
    platStatus.value = 'invalid'
    platMessage.value = 'Mohon masukkan jumlah liter atau total harga'
    return
  }

  // Batas Maksimal Pengisian sesuai Aturan Database: Umum max 5 Liter (Rp 50k), Ojol max 10 Liter (Rp 100k)
  const maxLiterLimit = props.isOjol ? 10 : 5
  if (liter > maxLiterLimit) {
    playWarningSound()
    refueledInfo.value = {
      plat: form.value.plat_nomor,
      isQuotaExceededTransaction: true,
      attemptedLiter: liter,
      attemptedHarga: parseRupiah(form.value.totalHarga),
      message: `Jumlah pengisian (${liter} Liter) melebihi batas maksimal kategori ${props.isOjol ? 'Motor Ojol' : 'Motor Umum'} (${maxLiterLimit} Liter / Rp ${formatAngka(maxLiterLimit * hargaPerLiter.value)})!`
    }
    showRefueledModal.value = true
    return
  }

  // Pre-check status plat & sisa kuota sebelum kirim transaksi
  const statusRes = await checkPlateStatus(form.value.plat_nomor, props.isOjol)
  if (statusRes && statusRes.success) {
    const remaining = statusRes.remainingQuota ?? 999
    // Cek batas kuota (baik dalam liter atau Rupiah)
    if (remaining > 0 && remaining < 100 && liter > remaining) {
      playWarningSound()
      refueledInfo.value = {
        ...statusRes,
        isQuotaExceededTransaction: true,
        attemptedLiter: liter,
        attemptedHarga: parseRupiah(form.value.totalHarga),
        message: `Jumlah transaksi (${liter} Liter) melebihi sisa kuota hari ini (${remaining} Liter)!`
      }
      showRefueledModal.value = true
      return
    }
  }

  const res = await submitTransaction({
    platNomor: form.value.plat_nomor,
    liter: liter,
    isOjol: props.isOjol
  })

  if (res && res.success) {
    playSuccessSound()
    emit('submit', { success: true })
  } else if (res && !res.success) {
    playWarningSound()
    refueledInfo.value = {
      plat: form.value.plat_nomor,
      isCategoryMismatch: res.reason === 'category_mismatch',
      isQuotaExceededTransaction: res.reason === 'quota_exceeded' || res.reason === 'already_refueled',
      countToday: 1,
      message: res.message || 'Transaksi ditolak oleh sistem!'
    }
    showRefueledModal.value = true
  }
}
</script>

<template>
  <div class="w-full max-w-xl md:max-w-2xl lg:max-w-3xl mx-auto animate-enter relative">

    <!-- HEADER BAR -->
    <div class="flex items-center justify-between mb-3 md:mb-5">
      <button
        @click="$emit('back')"
        class="w-9 h-9 sm:w-10 sm:h-10 rounded-xl bg-white/10 hover:bg-white/20 border border-white/20 flex items-center justify-center text-white active:scale-95 transition-all shadow-sm"
        title="Kembali ke Pilih Kendaraan"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4 sm:w-5 sm:h-5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
        </svg>
      </button>
      <span class="px-4 py-1.5 rounded-full text-xs md:text-sm font-bold bg-white/10 border border-white/20 text-white tracking-wide shadow-sm">
        {{ vehicleType === 'Ojol' ? 'OJOL' : 'UMUM' }}
      </span>
    </div>

    <!-- TAHAP 1: INPUT & CEK PLAT NOMOR -->
    <div v-if="subStep === 'check_plate'" class="space-y-6 animate-enter">
      <div class="text-center space-y-1">
        <h3 class="text-xl md:text-2xl font-bold text-white">Masukkan Nomor Polisi</h3>
        <p class="text-xs md:text-sm text-green-100/80">Sistem akan mengecek riwayat pengisian di database terlebih dahulu</p>
      </div>

      <div class="space-y-4">
        <div class="flex flex-col gap-2">
          <div class="flex gap-2 items-stretch">
            <input
              ref="platInputRef"
              :value="form.plat_nomor"
              @input="onPlatInput"
              @keydown="onPlatKeydown"
              @keydown.enter.prevent="handleCheckPlate"
              type="text"
              maxlength="12"
              placeholder="KT 1234 ABC"
              autocomplete="off"
              spellcheck="false"
              class="flex-1 w-full h-16 bg-white/10 border-2 rounded-2xl px-4 py-3 text-2xl font-black uppercase tracking-wider text-white text-center placeholder-white/30 focus:outline-none focus:bg-white/20 transition-all shadow-inner"
              :class="{
                'border-white/30 focus:border-white': platStatus === 'idle',
                'border-emerald-400 focus:border-emerald-300': platStatus === 'valid',
                'border-red-400 focus:border-red-300': platStatus === 'invalid'
              }"
            />
          </div>

          <!-- Feedback validasi -->
          <Transition name="plat-err">
            <div v-if="platStatus === 'invalid'" class="flex items-center gap-2 px-1">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4 text-red-400 shrink-0">
                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-8-5a.75.75 0 01.75.75v4.5a.75.75 0 01-1.5 0v-4.5A.75.75 0 0110 5zm0 10a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd" />
              </svg>
              <span class="text-red-300 text-xs font-semibold">{{ platMessage }}</span>
            </div>
            <div v-else-if="platStatus === 'validating'" class="flex items-center gap-2 px-1">
              <span class="loading loading-spinner loading-xs text-blue-300 shrink-0"></span>
              <span class="text-blue-300 text-xs font-semibold">{{ platMessage }}</span>
            </div>
            <div v-else-if="platStatus === 'valid'" class="flex items-center gap-2 px-1">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4 text-emerald-400 shrink-0">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clip-rule="evenodd" />
              </svg>
              <span class="text-emerald-300 text-xs font-semibold">{{ platMessage }}</span>
            </div>
          </Transition>

          <!-- Format hint -->
          <p class="text-white/35 text-[10px] text-center tracking-wide">
            Contoh: <span class="font-bold text-white/50">KT1234ABC</span> &nbsp;·&nbsp; Spasi akan terisi otomatis secara rapi
          </p>
        </div>

        <div class="flex gap-3">
          <button
            type="button"
            @click.prevent="handleCheckPlate"
            :disabled="checkingPlate"
            class="flex-1 h-14 bg-white hover:bg-emerald-50 text-[#143d2e] font-black text-base md:text-lg rounded-2xl flex items-center justify-center gap-2 shadow-lg active:scale-95 transition-all disabled:opacity-50"
          >
            <span v-if="checkingPlate" class="loading loading-spinner loading-md"></span>
            <template v-else>
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-6 h-6 text-[#143d2e]">
                <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
              </svg>
              <span>CEK PLAT</span>
            </template>
          </button>

          <button
            v-if="isCameraFeatureEnabled"
            @click.prevent="handleStartCamera"
            type="button"
            class="w-14 h-14 shrink-0 bg-white/10 hover:bg-white/20 border border-white/20 rounded-2xl flex items-center justify-center text-white shadow-lg active:scale-95 transition-all"
            title="Scan Plat"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-7 h-7">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6.827 6.175A2.31 2.31 0 015.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574V18a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 00-1.134-.175 2.31 2.31 0 01-1.64-1.055l-.822-1.316a2.192 2.192 0 00-1.736-1.039 48.774 48.774 0 00-5.232 0 2.192 2.192 0 00-1.736 1.039l-.821 1.316z" />
              <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 12.75a4.5 4.5 0 11-9 0 4.5 4.5 0 019 0zM18.75 10.5h.008v.008h-.008V10.5z" />
            </svg>
          </button>
        </div>
      </div>
    </div>

    <!-- TAHAP 2: INPUT LITER & TRANSAKSI -->
    <form v-else-if="subStep === 'input_liter'" @submit.prevent="handleSubmit" class="space-y-2.5 sm:space-y-4 animate-enter">

      <!-- Info Plat Nomor -->
      <div class="bg-white/10 border border-white/20 rounded-2xl p-3 sm:p-4 flex items-center justify-between shadow-lg">
        <div class="text-xl sm:text-2xl font-black text-white tracking-wider font-mono">{{ form.plat_nomor }}</div>

        <button
          type="button"
          @click="handleBackToPlateCheck"
          class="w-9 h-9 sm:w-10 sm:h-10 rounded-xl bg-white/10 hover:bg-white/20 text-white border border-white/20 flex items-center justify-center transition-all active:scale-95 shadow-sm"
          title="Ganti Plat Nomor"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 sm:w-5 sm:h-5">
            <path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0 1 15.75 21H5.25A2.25 2.25 0 0 1 3 18.75V8.25A2.25 2.25 0 0 1 5.25 6H10" />
          </svg>
        </button>
      </div>

      <!-- Input Liter & Total Harga (2 Kolom Berdampingan di Semua Ukuran Layar) -->
      <div class="grid grid-cols-2 gap-2 sm:gap-4">
        <!-- Kolom Liter -->
        <div class="space-y-1">
          <label class="text-green-100 text-[11px] sm:text-xs md:text-sm font-bold ml-0.5 uppercase flex items-center gap-1">
            Jumlah Liter
            <span class="text-white/40 font-normal normal-case text-[9px] sm:text-[10px]">(L)</span>
          </label>
          <input
            ref="literInputRef"
            v-model="form.liter"
            @input="onLiterInput"
            @keydown="onLiterKeydown"
            type="number"
            step="0.001"
            min="0"
            placeholder="0.000"
            class="w-full bg-white/10 border-2 border-white/30 rounded-2xl px-2.5 sm:px-4 py-2.5 sm:py-3 md:py-4 text-base sm:text-xl md:text-2xl font-black text-white placeholder-white/30 focus:outline-none focus:bg-white/20 focus:border-white text-center transition-all no-spinner"
          />
        </div>

        <!-- Kolom Total Harga -->
        <div class="space-y-1">
          <label class="text-green-100 text-[11px] sm:text-xs md:text-sm font-bold ml-0.5 uppercase flex items-center gap-1">
            Total (Rp)
            <span class="text-white/40 font-normal normal-case text-[9px] sm:text-[10px]">(opsional)</span>
          </label>
          <input
            ref="hargaInputRef"
            :value="form.totalHarga"
            @input="onHargaInput"
            @keydown="onHargaKeydown"
            type="text"
            inputmode="numeric"
            placeholder="0"
            class="w-full bg-white/10 border-2 border-white/30 rounded-2xl px-2.5 sm:px-4 py-2.5 sm:py-3 md:py-4 text-base sm:text-xl md:text-2xl font-black text-white placeholder-white/30 focus:outline-none focus:bg-white/20 focus:border-white text-center transition-all"
          />
        </div>
      </div>

      <!-- Quick Preset Button (FULL) -->
      <div>
        <button
          type="button"
          @click="selectPresetFullQuota"
          class="w-full py-2.5 sm:py-3 px-4 rounded-2xl bg-emerald-400/20 hover:bg-emerald-400/30 active:bg-emerald-400/40 border border-emerald-400/40 text-emerald-200 font-black text-sm sm:text-base md:text-lg transition-all active:scale-95 flex items-center justify-center shadow-sm"
          :class="{ '!bg-emerald-400 !text-[#143d2e] !border-emerald-300 shadow-md': parseFloat(form.liter) === (props.isOjol ? 10 : 5) }"
        >
          FULL
        </button>
      </div>

      <!-- Submit Button -->
      <button
        ref="submitBtnRef"
        type="submit"
        :disabled="loading || !form.liter"
        class="w-full bg-white hover:bg-emerald-50 text-[#143d2e] font-black text-base sm:text-lg md:text-xl py-3 sm:py-4 rounded-2xl shadow-xl transform active:scale-95 transition-all mt-1 sm:mt-2 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <span v-if="loading" class="loading loading-spinner loading-md"></span>
        <span v-else>PROSES TRANSAKSI</span>
      </button>
    </form>

    <!-- MODAL POPUP KENDARAAN SUDAH MENGISI (STRICT GREEN & WHITE UI) -->
    <Teleport to="body">
      <div v-if="showRefueledModal" class="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm animate-enter">
        <div class="bg-white rounded-3xl max-w-sm md:max-w-md w-full text-slate-800 shadow-xl border border-gray-100 flex flex-col relative overflow-hidden max-h-[88dvh] mx-auto">

          <!-- Scrollable content area -->
          <div class="flex-1 overflow-y-auto overscroll-contain p-4 sm:p-6">

            <!-- Header Section -->
            <div class="flex items-center gap-3.5 mb-4">
              <div class="w-10 h-10 rounded-xl bg-red-50 border border-red-100 flex items-center justify-center text-red-600 shrink-0">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
                </svg>
              </div>
              <div class="flex items-center">
                <h3 class="text-base md:text-lg font-extrabold text-[#143d2e] tracking-tight leading-tight">
                  {{ refueledInfo?.isQuotaExceededTransaction ? 'Melebihi Kuota Subsidi' : (refueledInfo?.isCategoryMismatch ? 'Kategori Tidak Sesuai' : 'Melebihi Batas Pengisian') }}
                </h3>
              </div>
            </div>

            <!-- Details Card (Clean Minimalist List) -->
            <div class="bg-gray-50/70 rounded-2xl p-4 text-xs space-y-2.5 border border-gray-100">
              <!-- Plat -->
              <div class="flex justify-between items-center pb-2 border-b border-gray-200/50">
                <span class="text-gray-900 font-semibold uppercase text-[10px] tracking-wider">NOMOR POLISI</span>
                <span class="font-mono font-black text-gray-900 text-sm tracking-wider">
                  {{ refueledInfo?.plat }}
                </span>
              </div>

              <!-- Detail Pelanggaran Kategori (Sangat Minimalis & Elegan) -->
              <template v-if="refueledInfo?.isCategoryMismatch">
                <div class="flex justify-between items-center py-1">
                  <span class="text-gray-900 font-semibold">Kategori Sesi Ini</span>
                  <span class="font-semibold text-gray-900 uppercase">
                    {{ isOjol ? 'Ojek Online (Ojol)' : 'Umum' }}
                  </span>
                </div>

                <div class="flex justify-between items-center py-1 border-t border-gray-200/40">
                  <span class="text-gray-900 font-semibold">Kategori Terdaftar Hari Ini</span>
                  <span class="font-bold text-red-600 uppercase">
                    {{ isOjol ? 'Umum' : 'Ojol' }}
                  </span>
                </div>
              </template>

              <!-- Percobaan Pengisian (Jika Melebihi Kuota) -->
              <template v-else-if="refueledInfo?.attemptedLiter">
                <div class="flex justify-between items-center py-1 border-b border-gray-200/50">
                  <span class="text-gray-900 font-semibold">Input Transaksi</span>
                  <span class="font-bold text-red-600">
                    {{ refueledInfo.attemptedLiter }} Liter ({{ formatRupiah(refueledInfo.attemptedHarga) }})
                  </span>
                </div>
              </template>

              <template v-if="!refueledInfo?.isCategoryMismatch">
                <!-- Total Terisi -->
                <div v-if="refueledInfo?.totalHargaToday !== undefined || refueledInfo?.totalLiterToday !== undefined" class="flex justify-between items-center pb-2 border-b border-gray-200/50">
                  <span class="text-gray-900 font-semibold">Total Terisi Hari Ini</span>
                  <span class="font-semibold text-gray-900">
                    <template v-if="refueledInfo?.totalHargaToday !== undefined">
                      {{ formatRupiah(refueledInfo.totalHargaToday) }}
                    </template>
                    <template v-else-if="refueledInfo?.totalLiterToday !== undefined">
                      {{ refueledInfo.totalLiterToday }} Liter
                    </template>
                  </span>
                </div>

                <!-- Sisa Kuota -->
                <div v-if="refueledInfo?.remainingQuota !== undefined" class="flex justify-between items-center pb-2 border-b border-gray-200/50">
                  <span class="text-gray-900 font-semibold">
                    {{ refueledInfo?.hasRefueledToday ? 'Sisa Kuota Hari Ini' : 'Kuota Hari Ini' }}
                  </span>
                  <span class="font-black text-red-600">
                    <template v-if="typeof refueledInfo?.remainingQuota === 'number'">
                      <template v-if="refueledInfo.remainingQuota > 100">
                        {{ formatRupiah(refueledInfo.remainingQuota) }}
                      </template>
                      <template v-else-if="refueledInfo.remainingQuota === 0">
                        Rp 0 (Habis)
                      </template>
                      <template v-else>
                        {{ refueledInfo.remainingQuota }} Liter
                      </template>
                    </template>
                    <template v-else>
                      {{ refueledInfo.remainingQuota }}
                    </template>
                  </span>
                </div>

                <!-- Pengisian Terakhir -->
                <div v-if="refueledInfo?.lastTransaction" class="flex justify-between items-center pb-2 border-b border-gray-200/50">
                  <span class="text-gray-900 font-semibold">Pengisian Terakhir</span>
                  <span class="font-semibold text-gray-900">{{ refueledInfo?.lastTransaction?.liter }} Liter ({{ formatRupiah(refueledInfo?.lastTransaction?.harga) }})</span>
                </div>

                <!-- Waktu Terakhir -->
                <div v-if="refueledInfo?.lastTransaction?.waktu_pencatatan || refueledInfo?.timeFormatted" class="flex justify-between items-center pb-2 border-b border-gray-200/50">
                  <span class="text-gray-900 font-semibold">Waktu Terakhir</span>
                  <span class="font-semibold text-gray-900">
                    {{ formatWitaTime(refueledInfo?.timeFormatted, refueledInfo?.lastTransaction?.waktu_pencatatan) }} WITA
                  </span>
                </div>

                <!-- SPBU Pengisian -->
                <div v-if="refueledInfo?.lastTransaction?.spbu_nama || refueledInfo?.lastTransaction?.spbu_id" class="flex justify-between items-center">
                  <span class="text-gray-900 font-semibold">SPBU Pengisian</span>
                  <span class="font-semibold text-gray-900">
                    {{ refueledInfo?.lastTransaction?.spbu_nama || ('SPBU ' + refueledInfo?.lastTransaction?.spbu_id) }}
                  </span>
                </div>
              </template>

            </div>

            <!-- Riwayat Pengisian & Percobaan Hari Ini (Card Terpisah & Sangat Jelas) -->
            <div v-if="refueledInfo?.history_today && refueledInfo.history_today.length > 0" class="mt-3 bg-white border border-gray-200 rounded-2xl p-3.5 shadow-sm">
              <div class="text-[11px] font-extrabold text-gray-800 uppercase tracking-wider mb-2.5 flex items-center justify-between">
                <span class="flex items-center gap-1.5">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3.5 h-3.5 text-gray-500">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  RIWAYAT PENGISIAN HARI INI
                </span>
                <span class="px-2 py-0.5 bg-gray-100 text-gray-700 rounded-md text-[10px] font-bold border border-gray-200">
                  {{ refueledInfo.history_today.length }} AKTIVITAS
                </span>
              </div>

              <div class="space-y-2 max-h-52 overflow-y-auto pr-1 custom-scrollbar">
                <div
                  v-for="(item, idx) in refueledInfo.history_today"
                  :key="idx"
                  class="flex flex-col sm:flex-row sm:items-center justify-between gap-1 sm:gap-3 px-3 py-2 sm:py-2.5 rounded-xl border text-xs text-white transition-all shadow-xs"
                  :class="item.status === 'diterima' ? 'bg-[#143d2e] border-[#143d2e]' : 'bg-red-600 border-red-600'"
                >
                  <!-- KIRI (Baris 1 di HP, Kiri di Desktop): Waktu & SPBU ID -->
                  <div class="flex items-center gap-1.5 shrink-0 text-[11px] font-bold text-white">
                    <span class="font-mono font-extrabold text-white/90">{{ item.waktu }}</span>
                    <span class="text-white/40">·</span>
                    <span class="font-bold text-white">
                      {{ item.spbu_id ? (item.spbu_id.startsWith('SPBU') ? item.spbu_id : 'SPBU ' + item.spbu_id) : (item.spbu_nama || 'SPBU ini') }}
                    </span>
                  </div>

                  <!-- KANAN (Baris 2 di HP, Kanan di Desktop): Status & Alasan Penolakan -->
                  <div class="shrink-0 font-extrabold text-[11px] text-left sm:text-right text-white">
                    <template v-if="item.status === 'diterima'">
                      <span>Diterima ({{ item.liter }} L)</span>
                    </template>
                    <template v-else>
                      <span>Ditolak ({{ item.reason || 'Ditolak' }})</span>
                    </template>
                  </div>
                </div>
              </div>
            </div>

          </div>

          <!-- Action Buttons: pinned at bottom with clear separation line & top shadow -->
          <div class="shrink-0 p-3.5 sm:p-5 border-t-2 border-gray-100 bg-white shadow-[0_-6px_20px_rgba(0,0,0,0.06)] relative z-10">
            <div class="grid grid-cols-2 gap-2">
              <button
                @click="handleEditPlateNumber"
                class="w-full bg-gradient-to-r from-[#143d2e] via-[#1b4d3a] to-[#256a50] hover:from-[#1b4d3a] hover:to-[#258f62] text-white font-extrabold text-xs py-3 rounded-2xl shadow-md active:scale-95 transition-all flex items-center justify-center gap-1.5 cursor-pointer border border-white/10"
              >
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5 shrink-0">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0115.75 21H5.25A2.25 2.25 0 013 18.75V8.25A2.25 2.25 0 015.25 6H10" />
                </svg>
                <span class="uppercase tracking-wider">UBAH PLAT</span>
              </button>

              <button
                @click="handleResetVehicleSelection"
                class="w-full bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold text-xs py-3 rounded-2xl border border-gray-200 active:scale-95 transition-all flex items-center justify-center gap-1.5 cursor-pointer"
              >
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3.5 h-3.5 shrink-0">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
                </svg>
                <span class="uppercase tracking-wider">GANTI KATEGORI</span>
              </button>
            </div>
          </div>

        </div>
      </div>
    </Teleport>

    <!-- CAMERA SCANNER MODAL -->
    <Teleport to="body">
      <div v-if="isScanning" class="fixed inset-0 z-[9999] bg-black flex flex-col">

        <div class="absolute top-0 w-full p-4 flex justify-between items-center z-20 bg-gradient-to-b from-black/80 to-transparent">
          <button @click="stopCamera" class="w-10 h-10 bg-white/10 backdrop-blur-md rounded-full flex items-center justify-center text-white z-30">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-6 h-6">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
          <span class="text-white font-bold tracking-widest text-sm drop-shadow-md z-20">SCAN PLAT</span>
          <div class="w-10"></div>
        </div>

        <div class="flex-1 relative bg-black flex items-center justify-center overflow-hidden">

          <video
            ref="videoRef"
            autoplay
            playsinline
            muted
            class="absolute inset-0 w-full h-full object-cover"
          ></video>

          <div class="relative w-72 h-40 border-2 border-white/30 rounded-2xl z-10 pointer-events-none">
            <div class="absolute top-0 left-0 w-8 h-8 border-t-4 border-l-4 border-green-500 rounded-tl-xl -mt-[2px] -ml-[2px]"></div>
            <div class="absolute top-0 right-0 w-8 h-8 border-t-4 border-r-4 border-green-500 rounded-tr-xl -mt-[2px] -mr-[2px]"></div>
            <div class="absolute bottom-0 left-0 w-8 h-8 border-b-4 border-l-4 border-green-500 rounded-bl-xl -mb-[2px] -ml-[2px]"></div>
            <div class="absolute bottom-0 right-0 w-8 h-8 border-b-4 border-r-4 border-green-500 rounded-br-xl -mb-[2px] -mr-[2px]"></div>
            <div class="absolute top-0 left-0 w-full h-0.5 bg-green-400 shadow-[0_0_15px_rgba(74,222,128,0.8)] animate-scan"></div>
          </div>
        </div>

        <div class="h-28 bg-black/90 flex items-center justify-center pb-6 pt-2 z-20">
          <button
            @click.prevent="handleScan"
            type="button"
            :disabled="isProcessing"
            class="w-16 h-16 rounded-full border-[5px] border-white flex items-center justify-center active:scale-90 transition-transform disabled:opacity-50"
          >
            <div v-if="isProcessing" class="w-full h-full rounded-full border-4 border-transparent border-t-green-500 animate-spin"></div>
            <div v-else class="w-12 h-12 bg-white rounded-full"></div>
          </button>
        </div>
      </div>
    </Teleport>

  </div>
</template>

<style scoped>
@keyframes scan {
  0% { top: 10%; opacity: 0; }
  10% { opacity: 1; }
  90% { opacity: 1; }
  100% { top: 90%; opacity: 0; }
}
.animate-scan {
  animation: scan 2s linear infinite;
}

.plat-err-enter-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}
.plat-err-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}
.plat-err-enter-from {
  opacity: 0;
  transform: translateY(-4px);
}
.plat-err-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}
</style>
