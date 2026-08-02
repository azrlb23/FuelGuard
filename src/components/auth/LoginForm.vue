<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabaseClient'
import { toast } from 'vue3-toastify'

const router = useRouter()
const authStore = useAuthStore()

const email = ref('')
const password = ref('')
const loading = ref(false)

// Lupa Password Modal State
const isForgotModalOpen = ref(false)
const resetEmail = ref('')
const resetLoading = ref(false)

const handleLogin = async () => {
  if (!email.value || !password.value) {
    toast.warn('Mohon isi email dan password')
    return
  }

  loading.value = true

  try {
    const { error, role } = await authStore.login(email.value, password.value)

    if (error) throw error

    toast.success('Login Berhasil!')

    setTimeout(() => {
      if (role === 'master') router.push('/master/dashboard')
      else if (role === 'operator') router.push('/operator')
      else router.push('/')
    }, 1000)

  } catch (err) {
    console.error(err)
    toast.error(err.message || 'Login gagal.')
  } finally {
    loading.value = false
  }
}

const handleSendResetEmail = async () => {
  if (!resetEmail.value) {
    toast.warn('Masukkan email akun Anda')
    return
  }

  resetLoading.value = true
  try {
    const redirectUrl = `${window.location.origin}/reset-password`
    const { error } = await supabase.auth.resetPasswordForEmail(resetEmail.value, {
      redirectTo: redirectUrl
    })

    if (error) throw error

    toast.success('Tautan pemulihan password telah dikirim ke email Anda!')
    isForgotModalOpen.value = false
    resetEmail.value = ''
  } catch (err) {
    console.error('[ResetPassword] Gagal:', err)
    toast.error(err.message || 'Gagal mengirim email pemulihan')
  } finally {
    resetLoading.value = false
  }
}
</script>

<template>
  <div>
    <form @submit.prevent="handleLogin" class="space-y-6 animate-enter">

      <div class="space-y-2">
        <label for="email" class="text-sm font-bold text-green-100 lg:text-gray-700 ml-1 uppercase tracking-wider text-[11px]">
          Email Address
        </label>
        <div class="relative group">
          <input
            id="email"
            v-model="email"
            type="email"
            placeholder="nama@habijaya.com"
            class="w-full pl-11 pr-4 py-4 rounded-2xl
                   bg-white/10 border border-white/20 text-white placeholder-white/40
                   lg:bg-gray-50 lg:border-gray-200 lg:text-gray-900 lg:placeholder-gray-400
                   focus:outline-none focus:ring-2 focus:ring-green-400/50 lg:focus:ring-[#143d2e]/20 focus:border-transparent
                   transition-all duration-300"
            required
          />
          <span class="absolute left-4 top-4 text-green-200 lg:text-gray-400 group-focus-within:text-white lg:group-focus-within:text-[#143d2e] transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
            </svg>
          </span>
        </div>
      </div>

      <div class="space-y-2">
        <div class="flex justify-between items-center ml-1">
          <label for="password" class="text-sm font-bold text-green-100 lg:text-gray-700 uppercase tracking-wider text-[11px]">
            Password
          </label>
          <button
            type="button"
            @click="isForgotModalOpen = true"
            class="text-xs font-semibold text-green-200 lg:text-[#143d2e] hover:underline cursor-pointer transition-colors"
          >
            Lupa Password?
          </button>
        </div>
        <div class="relative group">
          <input
            id="password"
            v-model="password"
            type="password"
            placeholder="••••••••"
            class="w-full pl-11 pr-4 py-4 rounded-2xl
                   bg-white/10 border border-white/20 text-white placeholder-white/40
                   lg:bg-gray-50 lg:border-gray-200 lg:text-gray-900 lg:placeholder-gray-400
                   focus:outline-none focus:ring-2 focus:ring-green-400/50 lg:focus:ring-[#143d2e]/20 focus:border-transparent
                   transition-all duration-300"
            required
          />
          <span class="absolute left-4 top-4 text-green-200 lg:text-gray-400 group-focus-within:text-white lg:group-focus-within:text-[#143d2e] transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
            </svg>
          </span>
        </div>
      </div>

      <button
        type="submit"
        :disabled="loading"
        class="w-full font-black py-4 rounded-2xl shadow-lg transform hover:-translate-y-0.5 transition-all duration-200 disabled:opacity-70 disabled:cursor-not-allowed disabled:transform-none
               bg-white text-[#143d2e] hover:bg-green-50
               lg:bg-[#143d2e] lg:text-white lg:hover:bg-[#0f2e23]"
      >
        <span v-if="loading" class="flex items-center justify-center gap-2">
          <svg class="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          Memproses...
        </span>
        <span v-else class="text-lg">Masuk</span>
      </button>

    </form>

    <!-- Modal Lupa Password -->
    <div v-if="isForgotModalOpen" class="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-3xl p-6 md:p-8 max-w-md w-full shadow-2xl space-y-5 border border-gray-100 animate-enter text-left text-gray-800">
        <div class="flex items-center justify-between border-b border-gray-100 pb-4">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center font-bold">
              🔑
            </div>
            <div>
              <h3 class="text-lg font-black text-[#143d2e]">Reset Password</h3>
              <p class="text-xs text-gray-500 font-medium">Pemulihan kata sandi via Email</p>
            </div>
          </div>
          <button @click="isForgotModalOpen = false" class="p-1 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
          </button>
        </div>

        <p class="text-xs text-gray-600 leading-relaxed">
          Masukkan alamat email terdaftar milik Anda. Tautan pemulihan kata sandi akan dikirimkan secara otomatis ke kotak masuk email Anda.
        </p>

        <form @submit.prevent="handleSendResetEmail" class="space-y-4">
          <div>
            <label class="block text-xs font-bold text-gray-700 uppercase mb-1.5">Alamat Email Terdaftar</label>
            <input
              v-model="resetEmail"
              type="email"
              required
              placeholder="nama@habijaya.com"
              class="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 text-sm font-semibold text-gray-800 focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] transition-all"
            />
          </div>

          <div class="flex justify-end gap-3 pt-2">
            <button
              type="button"
              @click="isForgotModalOpen = false"
              class="px-5 py-2.5 rounded-xl border border-gray-200 text-gray-600 hover:bg-gray-50 text-xs font-bold transition-all cursor-pointer"
            >
              Batal
            </button>
            <button
              type="submit"
              :disabled="resetLoading"
              class="px-5 py-2.5 rounded-xl bg-[#143d2e] hover:bg-[#1a4a38] text-white text-xs font-bold transition-all shadow-md active:scale-95 disabled:opacity-50 cursor-pointer flex items-center gap-2"
            >
              <span v-if="resetLoading" class="loading loading-spinner loading-xs"></span>
              Kirim Link Reset
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>
