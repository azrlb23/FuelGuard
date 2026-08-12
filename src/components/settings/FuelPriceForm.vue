<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { toast } from 'vue3-toastify'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

const loading = ref(false)
const pertalitePrice = ref(10000)
const rowId = ref(null)

const fetchPrices = async () => {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('fuel_prices')
      .select('*')
      .ilike('fuel_type', '%pertalite%')
      .order('updated_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (error) throw error

    if (data) {
      pertalitePrice.value = Number(data.price_per_liter) || 10000
      rowId.value = data.id
    } else {
      pertalitePrice.value = 10000
    }
  } catch (err) {
    console.error('Error fetchPrices:', err)
  } finally {
    loading.value = false
  }
}

const savePrice = async () => {
  loading.value = true
  try {
    const payload = {
      fuel_type: 'Pertalite',
      price_per_liter: Number(pertalitePrice.value) || 10000,
      updated_at: new Date().toISOString()
    }

    if (authStore.user?.id) {
      payload.updated_by = authStore.user.id
    }

    if (rowId.value) {
      payload.id = rowId.value
    }

    const { data, error } = await supabase
      .from('fuel_prices')
      .upsert([payload])
      .select()

    if (error) throw error
    if (data && data[0]) {
      rowId.value = data[0].id
      pertalitePrice.value = Number(data[0].price_per_liter)
    }
    toast.success("Harga Pertalite berhasil diperbarui & tersinkronisasi ke Operator!")
  } catch (err) {
    console.error("Gagal menyimpan harga:", err)
    toast.error("Gagal menyimpan harga: " + (err.message || 'Error tidak diketahui'))
  } finally {
    loading.value = false
  }
}

const formatAngka = (val) => {
  return new Intl.NumberFormat('id-ID').format(val || 0)
}

onMounted(() => fetchPrices())
</script>

<template>
  <div class="space-y-4">

    <div class="flex items-center justify-between gap-4 p-4 bg-gray-50/80 rounded-2xl border border-gray-100">
      <div class="flex items-center gap-3.5">
        <div>
          <h4 class="font-black text-gray-900 text-base md:text-lg leading-tight">Pertalite</h4>
        </div>
      </div>
    </div>

    <form @submit.prevent="savePrice" class="space-y-4">
      <div class="p-4 bg-white rounded-2xl border border-gray-200/80 shadow-2xs space-y-3">
        <label class="text-xs font-bold text-gray-500 uppercase tracking-wider block">Harga Pertalite / Liter (Rp)</label>

        <div class="relative flex items-center">
          <span class="absolute left-4 text-gray-400 font-black text-base">Rp</span>
          <input
            v-model="pertalitePrice"
            type="number"
            min="0"
            class="no-spinner w-full bg-gray-50/50 border border-gray-200 rounded-xl pl-11 pr-4 py-3 text-lg font-mono font-black text-gray-900 focus:outline-none focus:bg-white focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] transition-all"
            placeholder="10000"
          />
        </div>
      </div>

      <div class="flex justify-end pt-2">
        <button
          type="submit"
          :disabled="loading"
          class="bg-gradient-to-r from-[#143d2e] via-[#1b4d3a] to-[#256a50] hover:from-[#1b4d3a] hover:to-[#258f62] text-white px-6 py-3 rounded-xl font-bold text-sm shadow-lg shadow-green-950/20 hover:shadow-green-900/30 transition-all active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 cursor-pointer border border-white/10 backdrop-blur-md"
        >
          <span v-if="loading" class="loading loading-spinner loading-xs"></span>
          <span>Simpan Harga Pertalite</span>
        </button>
      </div>
    </form>
  </div>
</template>
