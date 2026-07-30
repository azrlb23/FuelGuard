<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { toast } from 'vue3-toastify'

const router = useRouter()
const authStore = useAuthStore()

const email = ref('')
const password = ref('')
const loading = ref(false)

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
</script>

<template>
  <form @submit.prevent="handleLogin" class="space-y-5 animate-enter">

    <div class="space-y-1.5">
      <label for="email" class="text-[11px] font-bold text-gray-700 ml-1 uppercase tracking-wider">
        Email Address
      </label>
      <div class="relative group">
        <input
          id="email"
          v-model="email"
          type="email"
          placeholder="nama@fuelguard.com"
          class="w-full pl-11 pr-4 py-3.5 rounded-2xl
                 bg-gray-50 border border-gray-200 text-gray-900 placeholder-gray-400
                 focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] focus:bg-white
                 transition-all duration-200 text-sm font-medium"
          required
        />
        <span class="absolute left-4 top-3.5 text-gray-400 group-focus-within:text-[#143d2e] transition-colors">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
          </svg>
        </span>
      </div>
    </div>

    <div class="space-y-1.5">
      <div class="flex justify-between items-center ml-1">
        <label for="password" class="text-[11px] font-bold text-gray-700 uppercase tracking-wider">
          Password
        </label>
      </div>
      <div class="relative group">
        <input
          id="password"
          v-model="password"
          type="password"
          placeholder="••••••••"
          class="w-full pl-11 pr-4 py-3.5 rounded-2xl
                 bg-gray-50 border border-gray-200 text-gray-900 placeholder-gray-400
                 focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] focus:bg-white
                 transition-all duration-200 text-sm font-medium"
          required
        />
        <span class="absolute left-4 top-3.5 text-gray-400 group-focus-within:text-[#143d2e] transition-colors">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
          </svg>
        </span>
      </div>
    </div>

    <button
      type="submit"
      :disabled="loading"
      class="w-full font-black py-4 rounded-2xl shadow-lg shadow-green-900/15 transform hover:-translate-y-0.5 active:scale-95 transition-all duration-200 disabled:opacity-70 disabled:cursor-not-allowed disabled:transform-none
             bg-[#143d2e] text-white hover:bg-[#1e5c45] cursor-pointer"
    >
      <span v-if="loading" class="flex items-center justify-center gap-2">
        <svg class="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        Memproses...
      </span>
      <span v-else class="text-base">Masuk</span>
    </button>

    <div class="text-center pt-2">
      <p class="text-xs font-medium text-gray-500">
        Butuh bantuan akses? 
        <button
          id="btn-contact-admin"
          type="button"
          class="font-bold text-[#143d2e] hover:underline transition-all bg-transparent border-none cursor-pointer p-0 text-xs inline-block"
          @click="$emit('open-contact-modal')"
        >
          Hubungi Admin
        </button>
      </p>
    </div>

  </form>
</template>
