import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('⚠️ Supabase URL atau Key belum diset di file .env!')
}

// Fallback lock handler untuk mencegah error "Acquiring an exclusive Navigator LockManager lock immediately failed" pada browser
const customLock = async (name, acquireTimeout, fn) => {
  if (typeof navigator !== 'undefined' && navigator.locks && typeof navigator.locks.request === 'function') {
    try {
      return await navigator.locks.request(name, { ifAvailable: true }, async (lock) => {
        return await fn()
      })
    } catch (e) {
      return await fn()
    }
  }
  return await fn()
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    lock: customLock,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  }
})
