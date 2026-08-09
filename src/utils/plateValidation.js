import { supabase } from '@/lib/supabaseClient'

// Daftar 57 Kode Wilayah Plat Nomor Resmi Indonesia (Sama persis dengan seeder PostgreSQL)
export const DEFAULT_REGION_CODES = [
  'A', 'B', 'D', 'E', 'F', 'T', 'Z', 'G', 'H', 'K', 'R', 
  'AA', 'AB', 'AD', 'AE', 'AG', 'L', 'M', 'N', 'P', 'S', 'W', 
  'BL', 'BB', 'BK', 'BA', 'BM', 'BP', 'BG', 'BN', 'BE', 'BD', 'BH', 
  'KB', 'DA', 'KH', 'KT', 'KU', 
  'DB', 'DL', 'DM', 'DN', 'DT', 'DD', 'DP', 'DC', 
  'DK', 'DR', 'EA', 'DH', 'EB', 'ED', 
  'DE', 'DG', 'DS', 'PA', 'PB'
]

const STORAGE_KEY_REGIONS = 'hj_cache_region_codes'

/**
 * Mengambil dan menyimpan cache kode wilayah dari Supabase saat online
 */
export async function fetchAndCacheRegionCodes() {
  if (typeof window === 'undefined' || !navigator.onLine) return getCachedRegionCodes()
  try {
    const { data, error } = await supabase
      .from('region_codes')
      .select('code')
      
    if (error) throw error
    if (data && data.length > 0) {
      const codes = data.map(item => item.code.toUpperCase())
      localStorage.setItem(STORAGE_KEY_REGIONS, JSON.stringify(codes))
      return codes
    }
  } catch (err) {
    console.warn('[plateValidation] Gagal memuat region_codes dari server, gunakan cache:', err)
  }
  return getCachedRegionCodes()
}

/**
 * Mengambil daftar kode wilayah dari LocalStorage atau default fallback
 */
export function getCachedRegionCodes() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY_REGIONS)
    if (raw) {
      const parsed = JSON.parse(raw)
      if (Array.isArray(parsed) && parsed.length > 0) return parsed
    }
  } catch (e) {}
  return DEFAULT_REGION_CODES
}

/**
 * Validasi ketat format plat nomor kendaraan Indonesia
 * 100% Sejalur dengan Stored Procedure PostgreSQL `fn_check_plate_status`
 */
export function validatePlateFormat(rawPlat) {
  if (!rawPlat || !String(rawPlat).trim()) {
    return {
      isValid: false,
      reason: 'empty',
      message: 'Nomor plat kendaraan tidak boleh kosong.',
      platClean: ''
    }
  }

  // 1. Sanitasi spasi ganda & ubah ke huruf kapital
  const platClean = String(rawPlat).trim().toUpperCase().replace(/\s+/g, ' ')

  // 2. Strict ASCII Regex Plat Indonesia: 1-2 Huruf Wilayah + 1-4 Angka + opsional 1-3 Huruf Seri
  // Contoh valid: KT 1234 AB, B 1, L 9999 XYZ
  const plateRegex = /^[A-Z]{1,2}\s\d{1,4}(\s[A-Z]{1,3})?$/

  if (!plateRegex.test(platClean)) {
    return {
      isValid: false,
      reason: 'invalid_format',
      message: 'Format plat nomor tidak valid (Contoh valid: KT 1234 AB, B 1234 A).',
      platClean
    }
  }

  // 3. Ekstrak Kode Wilayah (Token pertama sebelum spasi)
  const regionPrefix = platClean.split(' ')[0]
  const validRegions = getCachedRegionCodes()

  if (!validRegions.includes(regionPrefix)) {
    return {
      isValid: false,
      reason: 'invalid_region',
      message: `Kode wilayah plat (${regionPrefix}) tidak terdaftar di Indonesia.`,
      platClean
    }
  }

  // Plat valid!
  return {
    isValid: true,
    reason: 'valid',
    message: 'Plat nomor valid.',
    platClean
  }
}
