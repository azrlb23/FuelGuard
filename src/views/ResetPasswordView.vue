<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabaseClient'
import { toast } from 'vue3-toastify'

const router = useRouter()

const newPassword = ref('')
const confirmPassword = ref('')
const loading = ref(false)
const isValidSession = ref(false)
const checkingSession = ref(true)

onMounted(async () => {
  try {
    const { data: { session } } = await supabase.auth.getSession()
    if (session) {
      isValidSession.value = true
    } else {
      // Supabase auth handles recovery link automatically in URL hash
      supabase.auth.onAuthStateChange((event, session) => {
        if (event === 'PASSWORD_RECOVERY' || session) {
          isValidSession.value = true
        }
      })
    }
  } catch (err) {
    console.error('[ResetPasswordView] Sesi recovery error:', err)
  } finally {
    checkingSession.value = false
  }
})

const handleResetPassword = async () => {
  if (newPassword.value !== confirmPassword.value) {
    toast.error('Konfirmasi password tidak cocok!')
    return
  }

  if (newPassword.value.length < 6) {
    toast.warn('Password baru minimal 6 karakter')
    return
  }

  loading.value = true
  try {
    const { error } = await supabase.auth.updateUser({
      password: newPassword.value
    })

    if (error) throw error

    toast.success('Password berhasil diperbarui! Mengalihkan ke aplikasi...')
    
    // Auto redirect to dashboard after short delay
    setTimeout(() => {
      router.push('/')
    }, 1500)

  } catch (err) {
    console.error('[ResetPasswordView] Gagal update password:', err)
    toast.error(err.message || 'Gagal memperbarui password')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-[#143d2e] flex items-center justify-center p-4 relative overflow-hidden">
    <!-- Ambient Glow Background Orbs -->
    <div class="absolute -top-32 -left-32 w-96 h-96 bg-emerald-400/20 rounded-full blur-3xl pointer-events-none"></div>
    <div class="absolute -bottom-32 -right-32 w-96 h-96 bg-green-300/15 rounded-full blur-3xl pointer-events-none"></div>

    <div class="w-full max-w-md bg-white rounded-3xl p-8 shadow-2xl space-y-6 relative z-10 border border-gray-100 animate-enter">
      <div class="text-center space-y-2">
        <div class="w-14 h-14 rounded-2xl bg-emerald-50 text-[#143d2e] mx-auto flex items-center justify-center font-black text-2xl shadow-sm border border-emerald-100">
          🔐
        </div>
        <h2 class="text-2xl font-black text-[#143d2e] tracking-tight">Atur Password Baru</h2>
        <p class="text-xs text-gray-500 font-medium leading-relaxed">
          Silakan masukkan password baru untuk pemulihan akun FuelGuard Anda.
        </p>
      </div>

      <div v-if="checkingSession" class="py-8 text-center text-gray-400 animate-pulse text-xs font-semibold">
        Memverifikasi sesi pemulihan akun...
      </div>

      <form v-else @submit.prevent="handleResetPassword" class="space-y-4">
        <div>
          <label class="block text-xs font-bold text-gray-700 uppercase mb-1.5">Password Baru</label>
          <input
            v-model="newPassword"
            type="password"
            required
            minlength="6"
            placeholder="••••••••"
            class="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 text-sm font-semibold text-gray-800 focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] transition-all"
          />
        </div>

        <div>
          <label class="block text-xs font-bold text-gray-700 uppercase mb-1.5">Konfirmasi Password Baru</label>
          <input
            v-model="confirmPassword"
            type="password"
            required
            minlength="6"
            placeholder="••••••••"
            class="w-full px-4 py-3 rounded-2xl bg-gray-50 border border-gray-200 text-sm font-semibold text-gray-800 focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] transition-all"
          />
        </div>

        <button
          type="submit"
          :disabled="loading"
          class="w-full mt-2 py-3.5 rounded-2xl bg-[#143d2e] hover:bg-[#1e5c45] text-white font-bold text-sm shadow-lg shadow-green-900/10 transition-all active:scale-95 disabled:opacity-50 cursor-pointer flex items-center justify-center gap-2"
        >
          <span v-if="loading" class="loading loading-spinner loading-xs"></span>
          Simpan Password Baru
        </button>
      </form>

      <div class="text-center pt-2">
        <button
          @click="router.push('/')"
          class="text-xs font-bold text-gray-400 hover:text-gray-600 transition-colors cursor-pointer"
        >
          ← Kembali ke Halaman Login
        </button>
      </div>
    </div>
  </div>
</template>
