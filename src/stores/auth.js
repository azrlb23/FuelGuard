import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabaseClient'

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
    const { data, error } = await supabase
      .from('user_roles')
      .select('role, spbu_id')
      .eq('user_id', (await supabase.auth.getUser()).data.user.id)
      .single()

    if (error) throw error
    return data
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
          role.value = meta.role
          spbuId.value = meta.spbu_id
          
          if (meta.role === 'operator' && meta.spbu_id) {
            await fetchKasirList(meta.spbu_id)
          }
        }
        isInitialized.value = true
      } finally {
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
      
      // Jika activeKasirId saat ini tidak ada di daftar terbaru, reset
      if (activeKasirId.value && !kasirList.value.find(k => k.id === activeKasirId.value)) {
        setActiveKasir(null)
      }
    } catch (err) {
      console.error('Failed to fetch kasir list:', err)
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
      const { data: { session }, error: signInError } = await supabase.auth.signInWithPassword({
        email,
        password,
      })
      if (signInError) throw signInError

      user.value = session.user

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
      window.location.href = '/'
    }
  }

  return { 
    user, role, spbuId, isLoading, isInitialized, 
    activeKasirId, kasirList, setActiveKasir, fetchKasirList,
    login, logout, initialize 
  }
})