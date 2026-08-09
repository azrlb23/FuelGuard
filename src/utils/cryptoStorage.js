// Modul Utilitas Enkripsi & Dekripsi Presisi untuk LocalStorage (CryptoStorage)
// Mengamankan data cache lokal dengan Hex-XOR Cipher (100% Bebas Alignment & Encoding Error)

const APP_SECRET_SALT = 'HJ_FUELGUARD_SECURE_KEY_2026'

/**
 * Meng-encode objek/string JSON menjadi cipher token Hex-XOR terenkripsi
 */
function encrypt(data) {
  if (data === null || data === undefined) return data
  try {
    const str = typeof data === 'object' ? JSON.stringify(data) : String(data)
    const hexCodes = []
    for (let i = 0; i < str.length; i++) {
      const code = str.charCodeAt(i) ^ APP_SECRET_SALT.charCodeAt(i % APP_SECRET_SALT.length)
      hexCodes.push(code.toString(16).padStart(4, '0'))
    }
    return 'enc_' + hexCodes.join('')
  } catch (e) {
    console.error('[cryptoStorage] Encryption failed:', e)
    return data
  }
}

/**
 * Meng-decode cipher token Hex-XOR kembali ke data asli (JSON / String)
 */
function decrypt(token) {
  if (!token || typeof token !== 'string') return token
  // Fallback kompatibilitas jika data belum terenkripsi (plain JSON)
  if (!token.startsWith('enc_')) {
    try { return JSON.parse(token) } catch (e) { return token }
  }

  try {
    const hex = token.substring(4)
    let result = ''
    for (let i = 0; i < hex.length; i += 4) {
      const charCode = parseInt(hex.substring(i, i + 4), 16) ^ APP_SECRET_SALT.charCodeAt((i / 4) % APP_SECRET_SALT.length)
      result += String.fromCharCode(charCode)
    }
    try {
      return JSON.parse(result)
    } catch (e) {
      return result
    }
  } catch (e) {
    console.error('[cryptoStorage] Decryption failed:', e)
    return null
  }
}

/**
 * Menyimpan data terenkripsi ke LocalStorage
 */
export function secureSetItem(key, data) {
  if (typeof window === 'undefined') return
  try {
    const encryptedData = encrypt(data)
    localStorage.setItem(key, encryptedData)
  } catch (e) {
    console.error('[cryptoStorage] secureSetItem error:', e)
  }
}

/**
 * Membaca & mengdekripsi data dari LocalStorage
 */
export function secureGetItem(key) {
  if (typeof window === 'undefined') return null
  try {
    const raw = localStorage.getItem(key)
    if (!raw) return null
    return decrypt(raw)
  } catch (e) {
    console.error('[cryptoStorage] secureGetItem error:', e)
    return null
  }
}

/**
 * Menghapus item dari LocalStorage
 */
export function secureRemoveItem(key) {
  if (typeof window === 'undefined') return
  try {
    localStorage.removeItem(key)
  } catch (e) {}
}
