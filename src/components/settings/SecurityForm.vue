<script setup>
import { ref } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { toast } from 'vue3-toastify'

const loading = ref(false)
const form = ref({
  newPassword: '',
  confirmPassword: ''
})

const updatePassword = async () => {
  if (form.value.newPassword !== form.value.confirmPassword) {
    toast.error("Konfirmasi password tidak cocok!")
    return
  }
  if (form.value.newPassword.length < 6) {
    toast.warn("Password minimal 6 karakter")
    return
  }

  loading.value = true
  try {
    const { error } = await supabase.auth.updateUser({
      password: form.value.newPassword
    })
    if (error) throw error

    toast.success("Password berhasil diperbarui!")
    form.value = { newPassword: '', confirmPassword: '' } // Reset form
  } catch (err) {
    toast.error(err.message)
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="bg-white rounded-[2rem] p-6 border border-gray-100 shadow-sm">
    <div class="mb-6">
      <h3 class="text-lg font-bold text-gray-800 flex items-center gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5 text-[#143d2e]">
          <path fill-rule="evenodd" d="M12 1.5a5.25 5.25 0 00-5.25 5.25v3a3 3 0 00-3 3v6.75a3 3 0 003 3h10.5a3 3 0 003-3v-6.75a3 3 0 00-3-3v-3c0-2.9-2.35-5.25-5.25-5.25zm3.75 8.25v-3a3.75 3.75 0 10-7.5 0v3h7.5z" clip-rule="evenodd" />
        </svg>
        Keamanan Akun
      </h3>
      <p class="text-gray-400 text-sm">Update password Anda secara berkala untuk keamanan.</p>
    </div>

    <form @submit.prevent="updatePassword" class="space-y-4 max-w-lg">
      <div>
        <label class="block text-xs font-bold text-gray-500 uppercase mb-1">Password Baru</label>
        <input 
          v-model="form.newPassword"
          type="password" 
          required
          minlength="6"
          placeholder="••••••••"
          class="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] transition-all"
        />
      </div>

      <div>
        <label class="block text-xs font-bold text-gray-500 uppercase mb-1">Konfirmasi Password</label>
        <input 
          v-model="form.confirmPassword"
          type="password" 
          required
          minlength="6"
          placeholder="••••••••"
          class="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] transition-all"
        />
      </div>

      <div class="pt-2">
        <button 
          type="submit" 
          :disabled="loading"
          class="bg-[#143d2e] hover:bg-[#1e5c45] text-white px-6 py-3 rounded-xl font-bold text-sm shadow-lg shadow-green-900/10 transition-all active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
        >
          <span v-if="loading" class="loading loading-spinner loading-xs"></span>
          Update Password
        </button>
      </div>
    </form>
  </div>
</template>