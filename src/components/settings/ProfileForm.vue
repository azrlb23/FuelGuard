<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { useAuthStore } from '@/stores/auth'
import { toast } from 'vue3-toastify'

const authStore = useAuthStore()
const loading = ref(false)
const fullName = ref('')

onMounted(() => {
  fullName.value = authStore.user?.user_metadata?.full_name || ''
})

const updateProfile = async () => {
  loading.value = true
  try {
    const { data, error } = await supabase.auth.updateUser({
      data: { full_name: fullName.value }
    })

    if (error) throw error

    authStore.user = data.user
    
    toast.success("Profil berhasil diperbarui!")
  } catch (err) {
    toast.error("Gagal update profil: " + err.message)
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
          <path fill-rule="evenodd" d="M7.5 6a4.5 4.5 0 119 0 4.5 4.5 0 01-9 0zM3.751 20.105a8.25 8.25 0 0116.498 0 .75.75 0 01-.437.695A18.683 18.683 0 0112 22.5c-2.786 0-5.433-.608-7.812-1.7a.75.75 0 01-.437-.695z" clip-rule="evenodd" />
        </svg>
        Data Diri
      </h3>
      <p class="text-gray-400 text-sm">Informasi identitas Anda di sistem.</p>
    </div>

    <form @submit.prevent="updateProfile" class="flex flex-col md:flex-row gap-4 items-end">
      <div class="w-full">
        <label class="block text-xs font-bold text-gray-500 uppercase mb-1">Nama Lengkap</label>
        <input 
          v-model="fullName"
          type="text" 
          placeholder="Nama Anda"
          class="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e]"
        />
      </div>

      <button 
        type="submit" 
        :disabled="loading"
        class="w-full md:w-auto bg-gray-100 hover:bg-gray-200 text-gray-700 px-6 py-3 rounded-xl font-bold text-sm transition-all disabled:opacity-50 flex justify-center items-center"
      >
        <span v-if="loading">Saving...</span>
        <span v-else>Simpan Perubahan</span>
      </button>
    </form>
  </div>
</template>