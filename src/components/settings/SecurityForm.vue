<script setup>
import { ref } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { toast } from 'vue3-toastify'

const loading = ref(false)
const form = ref({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const updatePassword = async () => {
  if (form.value.newPassword !== form.value.confirmPassword) {
    toast.error("Konfirmasi password baru tidak cocok!")
    return
  }
  if (form.value.newPassword.length < 6) {
    toast.warn("Password baru minimal 6 karakter")
    return
  }

  loading.value = true
  try {
    // 1. Verifikasi Password Saat Ini dengan Re-Authenticating
    const { data: { user }, error: userErr } = await supabase.auth.getUser()
    if (userErr || !user || !user.email) {
      throw new Error("Sesi pengguna tidak valid, silakan login kembali.")
    }

    const { error: signInErr } = await supabase.auth.signInWithPassword({
      email: user.email,
      password: form.value.currentPassword
    })

    if (signInErr) {
      throw new Error("Password saat ini salah. Mohon periksa kembali.")
    }

    // 2. Update Password Baru di auth.users
    const { error } = await supabase.auth.updateUser({
      password: form.value.newPassword
    })
    if (error) throw error

    toast.success("Password berhasil diperbarui!")
    form.value = { currentPassword: '', newPassword: '', confirmPassword: '' } // Reset form
  } catch (err) {
    toast.error(err.message || 'Gagal memperbarui password')
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
      <p class="text-gray-400 text-sm">Update password Anda secara berkala untuk menjaga keamanan akun.</p>
    </div>

    <form @submit.prevent="updatePassword" class="space-y-4 max-w-lg">
      <div>
        <label class="block text-xs font-bold text-gray-500 uppercase mb-1">Password Saat Ini</label>
        <input
          v-model="form.currentPassword"
          type="password"
          required
          placeholder="••••••••"
          class="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] transition-all"
        />
      </div>

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
        <label class="block text-xs font-bold text-gray-500 uppercase mb-1">Konfirmasi Password Baru</label>
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
          class="bg-gradient-to-r from-[#143d2e] via-[#1b4d3a] to-[#256a50] hover:from-[#1b4d3a] hover:to-[#258f62] text-white px-6 py-3 rounded-xl font-bold text-sm shadow-lg shadow-green-950/20 hover:shadow-green-900/30 transition-all active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 cursor-pointer border border-white/10 backdrop-blur-md"
        >
          <span v-if="loading" class="loading loading-spinner loading-xs"></span>
          Perbarui Password
        </button>
      </div>
    </form>
  </div>
</template>
