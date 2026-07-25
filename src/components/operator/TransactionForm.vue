<script setup>
import { ref, computed, watch, onMounted, nextTick } from 'vue'
import { toast } from 'vue3-toastify'
import { useCameraScanner } from '@/composables/useCameraScanner'
import { useTransactionAction } from '@/composables/useTransactionAction'

const props = defineProps({
  vehicleType: String,
  loading: Boolean
})

const emit = defineEmits(['submit', 'back'])

const { isScanning, isProcessing, stream, startCamera, stopCamera, scanPlateNumber } = useCameraScanner()
const { checkPlateStatus, checkingPlate } = useTransactionAction()

const videoRef = ref(null)
const platInputRef = ref(null)
const literInputRef = ref(null)
const hargaInputRef = ref(null)

const isCameraFeatureEnabled = ref(false)

const subStep = ref('check_plate') // 'check_plate' | 'input_liter'
const showRefueledModal = ref(false)
const refueledInfo = ref(null)

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

const platError = ref('')  // pesan error validasi
const platTouched = ref(false)  // apakah user sudah pernah mengetik

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

// Status visual kolom plat
const platStatus = computed(() => {
  if (!platTouched.value || !form.value.plat_nomor) return 'idle'
  const formatted = formatPlatNomor(form.value.plat_nomor)
  return PLAT_REGEX.test(formatted.trim()) ? 'valid' : 'invalid'
})

// Sanitasi & auto-format input plat saat mengetik
const onPlatInput = (e) => {
  platTouched.value = true

  // Auto-format otomatis menjadi (KT 1234 AB) tanpa perlu ketik spasi manual
  const formatted = formatPlatNomor(e.target.value)

  form.value.plat_nomor = formatted

  // Paksa DOM langsung sinkron dengan format rapi
  e.target.value = formatted

  // Update pesan error
  const cleaned = formatted.trim()
  if (!cleaned) {
    platError.value = ''
  } else if (!PLAT_REGEX.test(cleaned)) {
    platError.value = 'Format tidak valid. Contoh: KT 1234 AB'
  } else {
    platError.value = ''
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

const handleCheckPlate = async () => {
  platTouched.value = true
  const formatted = formatPlatNomor(form.value.plat_nomor)
  const cleaned = formatted.trim()

  if (!cleaned) {
    platError.value = 'Mohon masukkan nomor plat kendaraan'
    toast.warn('Mohon masukkan nomor plat kendaraan!')
    return
  }

  if (!PLAT_REGEX.test(cleaned)) {
    platError.value = 'Format plat tidak valid. Contoh: KT 1234 AB'
    toast.warn('Format plat nomor tidak valid!')
    return
  }

  form.value.plat_nomor = cleaned
  platError.value = ''

  const res = await checkPlateStatus(form.value.plat_nomor, props.vehicleType)
  if (res.success) {
    form.value.plat_nomor = res.plat
    if (res.hasRefueledToday) {
      refueledInfo.value = res
      showRefueledModal.value = true
    } else {
      subStep.value = 'input_liter'
      form.value.liter = ''
      form.value.totalHarga = ''
      lastEdited.value = 'liter'
      await nextTick()
      if (literInputRef.value) {
        literInputRef.value.focus()
      }
    }
  }
}

const handleResetPlateCheck = () => {
  showRefueledModal.value = false
  refueledInfo.value = null
  form.value.plat_nomor = ''
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
    form.value.plat_nomor = result
    toast.success("Plat Terdeteksi: " + result)
    await handleCheckPlate()
  } else {
    toast.warn("Coba lagi, pastikan gambar jelas.")
  }
}

const hargaPerLiter = ref(10000)

const fetchActiveFuelPrice = async () => {
  try {
    const { data } = await supabase
      .from('fuel_prices')
      .select('price_per_liter')
      .ilike('fuel_type', '%pertalite%')
      .limit(1)

    if (data && data.length > 0 && Number(data[0].price_per_liter) > 0) {
      hargaPerLiter.value = Number(data[0].price_per_liter)
    }
  } catch (err) {
    console.warn("Gagal mengambil harga BBM dari database, menggunakan harga default (10.000):", err)
  }
}

onMounted(() => {
  fetchActiveFuelPrice()
})

const calculatedPrice = computed(() => {
  const liter = parseFloat(form.value.liter) || 0
  return liter * hargaPerLiter.value
})

const formatRupiah = (val) => {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val)
}

const formatAngka = (val) => {
  if (!val && val !== 0) return ''
  return new Intl.NumberFormat('id-ID').format(val)
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
  form.value.liter = harga > 0 ? String((harga / hargaPerLiter.value).toFixed(2)) : ''
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

const handleSubmit = () => {
  const liter = parseFloat(form.value.liter)
  if (!liter || liter <= 0) {
    toast.warn('Mohon masukkan jumlah liter atau total harga!')
    return
  }

  emit('submit', {
    plat_nomor: form.value.plat_nomor,
    liter: form.value.liter,
    total_harga: liter * hargaPerLiter.value
  })
}
</script>

<template>
  <div class="w-full max-w-lg mx-auto animate-enter relative">

    <!-- HEADER BAR -->
    <div class="flex items-center justify-between mb-4 md:mb-6">
      <button
        @click="$emit('back')"
        class="w-12 h-12 rounded-2xl bg-white/10 hover:bg-white/20 border border-white/20 flex items-center justify-center text-white active:scale-95 transition-all shadow-md"
        title="Kembali ke Pilih Kendaraan"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-6 h-6">
          <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
        </svg>
      </button>
      <span class="px-4 py-1.5 rounded-full text-xs md:text-sm font-bold bg-white/10 border border-white/20 text-white capitalize tracking-wide shadow-sm">
        {{ vehicleType }}
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
            <div v-if="platError" class="flex items-center gap-2 px-1">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4 text-red-400 shrink-0">
                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-8-5a.75.75 0 01.75.75v4.5a.75.75 0 01-1.5 0v-4.5A.75.75 0 0110 5zm0 10a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd" />
              </svg>
              <span class="text-red-300 text-xs font-semibold">{{ platError }}</span>
            </div>
            <div v-else-if="platStatus === 'valid'" class="flex items-center gap-2 px-1">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4 text-emerald-400 shrink-0">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clip-rule="evenodd" />
              </svg>
              <span class="text-emerald-300 text-xs font-semibold">Format plat valid</span>
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
              <span>CEK PLAT (ENTER)</span>
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
    <form v-else-if="subStep === 'input_liter'" @submit.prevent="handleSubmit" class="space-y-5 animate-enter">

      <!-- Info Plat Terverifikasi -->
      <div class="bg-white/10 border border-white/20 rounded-2xl p-4 flex items-center justify-between shadow-lg">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center text-white">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-6 h-6">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div>
            <div class="text-xs text-white/70 font-bold uppercase tracking-wider">Plat Terverifikasi</div>
            <div class="text-xl font-black text-white tracking-wide">{{ form.plat_nomor }}</div>
          </div>
        </div>

        <button
          type="button"
          @click="handleBackToPlateCheck"
          class="px-3 py-1.5 rounded-lg bg-white/10 hover:bg-white/20 text-xs font-bold text-white border border-white/20 transition-all active:scale-95"
        >
          Ubah Plat
        </button>
      </div>

      <!-- Input Liter & Total Harga (2 arah) -->
      <div class="grid grid-cols-2 gap-3 md:gap-4">
        <!-- Kolom Liter -->
        <div class="space-y-1.5">
          <label class="text-green-100 text-xs md:text-sm font-bold ml-1 uppercase flex items-center gap-1">
            Jumlah Liter
            <span class="text-white/40 font-normal normal-case text-[10px]">(L)</span>
          </label>
          <input
            ref="literInputRef"
            v-model="form.liter"
            @input="onLiterInput"
            @keydown="onLiterKeydown"
            type="number"
            step="0.01"
            min="0"
            placeholder="0.00"
            class="w-full bg-white/10 border-2 border-white/30 rounded-2xl px-4 py-3 md:py-4 text-xl md:text-2xl font-black text-white placeholder-white/30 focus:outline-none focus:bg-white/20 focus:border-white text-center transition-all"
          />
        </div>

        <!-- Kolom Total Harga -->
        <div class="space-y-1.5">
          <label class="text-green-100 text-xs md:text-sm font-bold ml-1 uppercase flex items-center gap-1">
            Total (Rp)
            <span class="text-white/40 font-normal normal-case text-[10px]">(opsional)</span>
          </label>
          <input
            ref="hargaInputRef"
            :value="form.totalHarga"
            @input="onHargaInput"
            @keydown="onHargaKeydown"
            type="text"
            inputmode="numeric"
            placeholder="0"
            class="w-full bg-white/10 border-2 border-white/30 rounded-2xl px-4 py-3 md:py-4 text-xl md:text-2xl font-black text-white placeholder-white/30 focus:outline-none focus:bg-white/20 focus:border-white text-center transition-all"
          />
        </div>
      </div>

      <!-- Hint 2 arah -->
      <p class="text-center text-white/50 text-[11px] -mt-2">
        Isi salah satu kolom
      </p>

      <!-- Submit Button -->
      <button
        type="submit"
        :disabled="loading || !form.liter"
        class="w-full bg-white hover:bg-emerald-50 text-[#143d2e] font-black text-lg md:text-xl py-4 rounded-2xl shadow-xl transform active:scale-95 transition-all mt-2 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <span v-if="loading" class="loading loading-spinner loading-md"></span>
        <span v-else>PROSES TRANSAKSI</span>
      </button>
    </form>

    <!-- MODAL POPUP KENDARAAN SUDAH MENGISI -->
    <Teleport to="body">
      <div v-if="showRefueledModal" class="fixed inset-0 z-[9999] flex items-center justify-center p-4 md:p-6 bg-black/80 backdrop-blur-xl animate-enter">
        <div class="bg-gradient-to-br from-[#143d2e] via-[#1e5c45] to-[#143d2e] border-2 border-white/30 rounded-[2rem] md:rounded-[2.5rem] max-w-md w-full p-6 md:p-8 text-white shadow-[0_25px_60px_-15px_rgba(0,0,0,0.9)] flex flex-col items-center text-center relative overflow-hidden">

          <div class="absolute -top-12 -right-12 w-48 h-48 bg-white/10 rounded-full blur-3xl pointer-events-none"></div>
          <div class="absolute -bottom-12 -left-12 w-48 h-48 bg-emerald-400/20 rounded-full blur-3xl pointer-events-none"></div>

          <div class="w-16 h-16 md:w-20 md:h-20 rounded-2xl md:rounded-3xl bg-white/10 border-2 border-white/30 flex items-center justify-center text-white mb-4 shadow-xl">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-10 h-10 md:w-12 md:h-12 text-white">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
            </svg>
          </div>

          <span class="px-3.5 py-1 rounded-full text-[11px] font-extrabold bg-white/10 border border-white/20 text-white uppercase tracking-widest mb-2">
            Peringatan Pengisian Ganda
          </span>
          <h3 class="text-2xl md:text-3xl font-black text-white tracking-tight">
            KENDARAAN SUDAH MENGISI!
          </h3>
          <p class="text-xs md:text-sm text-white/80 mt-1 mb-5 leading-relaxed">
            Sistem mendeteksi transaksi pengisian BBM untuk kendaraan ini pada hari yang sama. Transaksi ditolak.
          </p>

          <div class="w-full bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl md:rounded-3xl p-4 md:p-5 text-left space-y-3 shadow-inner mb-6">
            <div class="flex justify-between items-center border-b border-white/15 pb-2.5">
              <span class="text-xs font-medium text-white/70">Nomor Polisi</span>
              <span class="text-xl font-black text-white tracking-wider">{{ refueledInfo?.plat }}</span>
            </div>
            <div class="flex justify-between items-center border-b border-white/15 pb-2.5">
              <span class="text-xs font-medium text-white/70">Pengisian Hari Ini</span>
              <span class="text-sm font-bold text-white">{{ refueledInfo?.countToday }} Kali</span>
            </div>
            <div class="flex justify-between items-center border-b border-white/15 pb-2.5">
              <span class="text-xs font-medium text-white/70">Pengisian Terakhir</span>
              <span class="text-sm font-bold text-white">{{ refueledInfo?.lastTransaction?.liter }} Liter (Rp {{ formatRupiah(refueledInfo?.lastTransaction?.harga) }})</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-xs font-medium text-white/70">Waktu Terakhir</span>
              <span class="text-sm font-bold text-white">{{ refueledInfo?.timeFormatted }} WITA</span>
            </div>
          </div>

          <button
            @click="handleResetPlateCheck"
            class="w-full bg-white hover:bg-emerald-50 text-[#143d2e] font-black text-base md:text-lg py-4 rounded-2xl shadow-xl hover:shadow-white/20 transform active:scale-95 transition-all flex items-center justify-center gap-2"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-5 h-5 text-[#143d2e]">
              <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
            </svg>
            <span>PILIH KENDARAAN LAIN</span>
          </button>

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
