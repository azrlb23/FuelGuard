import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabaseClient'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const role = ref(null)
  const spbuId = ref(null)
  const isLoading = ref(false)
  const isInitialized = ref(false)

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
        }
        isInitialized.value = true
      } finally {
        isLoading.value = false
        _initPromise = null
      }
    })()

    return _initPromise
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
      isInitialized.value = false
      isLoading.value = false
      localStorage.clear()
      sessionStorage.clear()
      window.location.href = '/'
    }
  }

  return { user, role, spbuId, isLoading, isInitialized, login, logout, initialize }
})