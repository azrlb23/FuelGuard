<script setup>
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabaseClient'
import { toast } from 'vue3-toastify'

import SupportForm from '@/components/support/SupportForm.vue'
import SupportContactCard from '@/components/support/SupportContactCard.vue'

const authStore = useAuthStore()
const loading = ref(false)

const form = ref({
  kategori: 'Bug Sistem',
  prioritas: 'Medium',
  subjek: '',
  deskripsi: ''
})

const handleSubmit = async () => {
  if (!form.value.subjek || !form.value.deskripsi) {
    toast.warn("Mohon lengkapi subjek dan deskripsi laporan.")
    return
  }

  loading.value = true

  try {
    const { error } = await supabase.from('support_tickets').insert({
      user_id: authStore.user.id,
      kategori: form.value.kategori,
      prioritas: form.value.prioritas,
      subjek: form.value.subjek,
      deskripsi: form.value.deskripsi,
      status: 'Open'
    })

    if (error) throw error

    toast.success("Laporan berhasil dikirim ke Tim IT!")
    form.value = { kategori: 'Bug Sistem', prioritas: 'Medium', subjek: '', deskripsi: '' }

  } catch (err) {
    console.error(err)
    toast.error("Gagal mengirim laporan: " + err.message)
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="flex flex-col gap-6 animate-enter bg-[#f8fafc] lg:bg-transparent pb-24">
    
    <div class="flex-none px-6 pt-6 md:px-8 md:pt-8 z-10">
      <h2 class="text-3xl md:text-4xl font-extrabold text-[#1e293b] tracking-tight mb-2">
        Pusat Bantuan IT
      </h2>
      <p class="text-slate-500 font-medium text-sm md:text-base max-w-2xl">
        Laporkan kendala sistem atau ajukan permintaan fitur baru.
      </p>
    </div>

    <div class="px-4 md:px-8">
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 lg:gap-8 items-start">
        
        <div class="lg:col-span-2">
          <SupportForm 
            v-model="form" 
            :loading="loading" 
            @submit="handleSubmit" 
          />
        </div>

        <div>
          <SupportContactCard />
        </div>

      </div>
    </div>
  </div>
</template>