import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { secureSetItem, secureGetItem } from '@/utils/cryptoStorage'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const role = ref(null)
  const spbuId = ref(null)
  const isLoading = ref(false)
  const isInitialized = ref(false)

  // Kasir / Operator Profile states (Shared Device)
  const activeKasirId = ref(localStorage.getItem('hj_active_kasir_id') || null)
  const kasirList = ref([])

  let _initPromise = null

  const fetchUserMeta = async () => {
    try {
      const userRes = await supabase.auth.getUser()
      const userId = userRes?.data?.user?.id
      if (!userId) throw new Error('No user id')

      const { data, error } = await supabase
        .from('user_roles')
        .select('role, spbu_id')
        .eq('user_id', userId)
        .single()

      if (error) throw error
      if (data) {
        secureSetItem('hj_cached_user_meta', data)
      }
      return data
    } catch (err) {
      console.warn('[fetchUserMeta] Network/auth error, reading cached user meta:', err)
      const cached = secureGetItem('hj_cached_user_meta')
      if (cached) {
        return cached
      }
      return { role: 'operator', spbu_id: null }
    }
  }

  const initialize = async () => {
    if (isInitialized.value) return
    if (_initPromise) return _initPromise

    _initPromise = (async () => {
      isLoading.value = true
      try {
        const { data: { session } } = await supabase.auth.getSession()
        if (session) {
          user.value = session.user
          const meta = await fetchUserMeta()
          role.value = meta?.role || null
          spbuId.value = meta?.spbu_id || null
          
          if (meta?.spbu_id) {
            await fetchKasirList(meta.spbu_id)
          }
        }
      } catch (err) {
        console.warn('[auth.initialize] Caught error during auth init:', err)
      } finally {
        isInitialized.value = true
        isLoading.value = false
        _initPromise = null
      }
    })()

    return _initPromise
  }

  const fetchKasirList = async (currentSpbuId) => {
    if (!currentSpbuId) return
    try {
      const { data, error } = await supabase
        .from('operator_profiles')
        .select('id, nama_operator, is_active')
        .eq('spbu_id', currentSpbuId)
        .eq('is_active', true)
        .order('nama_operator')
        
      if (error) throw error
      kasirList.value = data || []
      localStorage.setItem('hj_cache_operators_v1', JSON.stringify(kasirList.value))
      
      // Jika activeKasirId saat ini tidak ada di daftar terbaru, reset
      if (activeKasirId.value && !kasirList.value.find(k => k.id === activeKasirId.value)) {
        setActiveKasir(null)
      }
    } catch (err) {
      console.warn('Failed to fetch kasir list from network, fallback to cache:', err)
      const cached = localStorage.getItem('hj_cache_operators_v1')
      if (cached) {
        try { kasirList.value = JSON.parse(cached) } catch (e) {}
      }
    }
  }

  const setActiveKasir = (id) => {
    activeKasirId.value = id
    if (id) {
      localStorage.setItem('hj_active_kasir_id', id)
    } else {
      localStorage.removeItem('hj_active_kasir_id')
    }
  }

  const login = async (email, password) => {
    isLoading.value = true
    try {
      let isEdgeFunctionAuthenticated = false

      try {
        // 🟢 Panggil Edge Function super-service (rate-limiter-login) untuk proteksi Rate Limiting Upstash Redis
        const { data, error } = await supabase.functions.invoke('super-service', {
          body: { email, password }
        })

        if (error) {
          // Parse HTTP 400 / 429 Error Response dari Edge Function
          if (error.context && typeof error.context.json === 'function') {
            try {
              const errJson = await error.context.json()
              if (errJson && errJson.message) {
                throw new Error(errJson.message)
              }
            } catch (e) {
              if (e.message && e.message !== 'Unexpected end of JSON input') throw e
            }
          }

          // Jika Edge Function belum di-deploy (404/500/CORS) atau offline, fallback ke Supabase Auth langsung
          console.warn('Edge Function rate-limiter-login tidak terjangkau. Melakukan login langsung via Supabase Auth...', error.message)
          const { data: directData, error: directError } = await supabase.auth.signInWithPassword({ email, password })
          if (directError) throw directError
          isEdgeFunctionAuthenticated = true
        } else if (!data || !data.success) {
          throw new Error((data && data.message) || 'Login ditolak oleh sistem.')
        } else {
          if (data.session) {
            const { error: setSessionError } = await supabase.auth.setSession({
              access_token: data.session.access_token,
              refresh_token: data.session.refresh_token
            })
            if (setSessionError) throw setSessionError
          }
          isEdgeFunctionAuthenticated = true
        }
      } catch (err) {
        // Jika error berasal dari jaringan / CORS preflight (FunctionsFetchError / Failed to send request)
        if (err.name === 'FunctionsFetchError' || err.message?.includes('Failed to send a request') || err.message?.includes('CORS')) {
          console.warn('Edge Function CORS/Network Error. Fallback ke Supabase Auth langsung:', err.message)
          const { data: directData, error: directError } = await supabase.auth.signInWithPassword({ email, password })
          if (directError) throw directError
        } else {
          throw err
        }
      }

      const { data: { user: currentUser } } = await supabase.auth.getUser()
      user.value = currentUser

      const meta = await fetchUserMeta()
      role.value = meta.role
      spbuId.value = meta.spbu_id

      if (meta.role === 'operator' && meta.spbu_id) {
        await fetchKasirList(meta.spbu_id)
      }

      isInitialized.value = true
      return { success: true, role: meta.role }
    } catch (error) {
      return { success: false, error: error.message }
    } finally {
      isLoading.value = false
    }
  }

  const logout = async () => {
    isLoading.value = true
    try {
      await supabase.auth.signOut()
    } catch (error) {
      console.error('Error saat logout:', error)
    } finally {
      user.value = null
      role.value = null
      spbuId.value = null
      activeKasirId.value = null
      kasirList.value = []
      isInitialized.value = false
      isLoading.value = false
      localStorage.clear()
      sessionStorage.clear()
      try {
        const routerModule = await import('@/router')
        routerModule.default.push({ name: 'login' })
      } catch (e) {
        window.location.href = '/'
      }
    }
  }

  return { 
    user, role, spbuId, isLoading, isInitialized, 
    activeKasirId, kasirList, setActiveKasir, fetchKasirList,
    login, logout, initialize 
  }
})