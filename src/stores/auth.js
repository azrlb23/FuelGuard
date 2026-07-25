import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabaseClient'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const role = ref(null)
  const isLoading = ref(false)
  const isInitialized = ref(false)

  // Singleton promise — mencegah double-fetch saat router guard & App.vue
  // sama-sama memanggil initialize() secara bersamaan saat refresh halaman
  let _initPromise = null

  const initialize = async () => {
    // Sudah selesai diinisialisasi sebelumnya, skip
    if (isInitialized.value) return

    // Sedang dalam proses init, kembalikan promise yang sama
    if (_initPromise) return _initPromise

    _initPromise = (async () => {
      isLoading.value = true
      try {
        const { data: { session } } = await supabase.auth.getSession()
        if (session) {
          user.value = session.user
          const { data: roleData } = await supabase.rpc('get_user_role')
          role.value = roleData
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

      const { data: roleData, error: roleError } = await supabase.rpc('get_user_role')
      if (roleError) console.error('Gagal ambil role:', roleError)

      role.value = roleData
      isInitialized.value = true
      return { success: true, role: roleData }
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
      isInitialized.value = false
      isLoading.value = false
      // Hapus token auth dari storage secara menyeluruh agar router.beforeEach tidak melakukan redirect ulang ke dashboard
      localStorage.clear()
      sessionStorage.clear()
      window.location.href = '/'
    }
  }

  return { user, role, isLoading, isInitialized, login, logout, initialize }
})