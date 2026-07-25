<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { toast } from 'vue3-toastify'

const loading = ref(false)
const prices = ref([])

const fetchPrices = async () => {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('fuel_prices')
      .select('*')
      .order('fuel_type')
    
    if (error || !data || data.length === 0) {
      // Jika database kosong / belum ada data harga, sediakan data default agar form tetap muncul
      prices.value = [
        { fuel_type: 'Pertalite', price_per_liter: 10000 },
        { fuel_type: 'Pertamax', price_per_liter: 12950 },
        { fuel_type: 'Solar', price_per_liter: 6800 }
      ]
    } else {
      prices.value = data
    }
  } catch (err) {
    console.error('Error fetchPrices:', err)
  } finally {
    loading.value = false
  }
}

const addNewFuelType = () => {
  prices.value.push({
    fuel_type: 'BBM Baru',
    price_per_liter: 10000
  })
}

const savePrices = async () => {
  loading.value = true
  try {
    const updates = prices.value.map(p => {
      const row = {
        fuel_type: p.fuel_type,
        price_per_liter: Number(p.price_per_liter) || 0,
        updated_at: new Date()
      }
      if (p.id) row.id = p.id
      return row
    })

    const { data, error } = await supabase
      .from('fuel_prices')
      .upsert(updates)
      .select()

    if (error) throw error
    if (data && data.length > 0) {
      prices.value = data
    }
    toast.success("Harga BBM berhasil diperbarui!")
  } catch (err) {
    toast.error("Gagal menyimpan harga: " + err.message)
  } finally {
    loading.value = false
  }
}

onMounted(() => fetchPrices())
</script>

<template>
  <div class="bg-white rounded-[2rem] p-6 border border-gray-100 shadow-sm relative overflow-hidden h-full flex flex-col">
    
    <div class="mb-6">
      <h3 class="text-lg font-bold text-gray-800 flex items-center gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5 text-[#143d2e]">
          <path fill-rule="evenodd" d="M12.97 3.97a.75.75 0 011.06 0l7.5 7.5a.75.75 0 010 1.06l-7.5 7.5a.75.75 0 11-1.06-1.06l6.22-6.22H3a.75.75 0 010-1.5h16.19l-6.22-6.22a.75.75 0 010-1.06z" clip-rule="evenodd" />
        </svg>
        Pengaturan Harga BBM
      </h3>
      <p class="text-gray-400 text-sm">Update harga per liter untuk kalkulasi pendapatan.</p>
    </div>

    <form @submit.prevent="savePrices" class="space-y-4 flex-1 flex flex-col">
      
      <div v-if="loading && prices.length === 0" class="text-center py-6 text-gray-400 my-auto">
        <span class="loading loading-dots loading-sm"></span> Memuat harga...
      </div>

      <div v-else class="space-y-4">
        <div 
          v-for="item in prices" 
          :key="item.id" 
          class="flex items-center justify-between gap-4 p-4 bg-gray-50 rounded-2xl border border-gray-100 hover:border-gray-200 transition-colors"
        >
          
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-white flex items-center justify-center shadow-sm border border-gray-100 text-[#143d2e]">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.362 5.214A8.252 8.252 0 0112 2.176L15.681.424 17.686 4.312l-2.324.902zM12 2.176c-3.111 2.37-5.362 5.922-5.918 10.038a8.25 8.25 0 0011.836 0c-.556-4.116-2.807-7.668-5.918-10.038zM6.5 13.5h11" />
              </svg>
            </div>
            <div>
              <span class="text-xs font-bold text-gray-400 uppercase tracking-wider block mb-0.5">Jenis BBM</span>
              <div class="font-bold text-gray-800 text-lg">{{ item.fuel_type }}</div>
            </div>
          </div>

          <div class="w-1/2 md:w-1/3">
            <label class="text-xs font-bold text-gray-500 uppercase block mb-1 text-right md:text-left">Harga / Liter</label>
            <div class="relative group">
                <span class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 font-bold text-sm">Rp</span>
                
                <input 
                    v-model="item.price_per_liter"
                    type="number" 
                    class="no-spinner w-full bg-white border border-gray-200 rounded-xl pl-9 pr-8 py-2.5 text-sm font-mono font-bold text-gray-800 focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] transition-all text-right md:text-left"
                />

                <div class="absolute right-1 top-1/2 -translate-y-1/2 flex flex-col gap-0.5 p-0.5 bg-gray-50 rounded-lg border border-gray-100 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                    <button 
                        @click="item.price_per_liter += 50"
                        type="button"
                        class="text-gray-400 hover:text-[#143d2e] hover:bg-green-100 rounded px-0.5 transition-colors"
                    >
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-3 h-3">
                            <path fill-rule="evenodd" d="M14.77 12.79a.75.75 0 01-1.06-.02L10 8.832 6.29 12.77a.75.75 0 11-1.08-1.04l4.25-4.5a.75.75 0 011.08 0l4.25 4.5a.75.75 0 01-.02 1.06z" clip-rule="evenodd" />
                        </svg>
                    </button>

                    <button 
                        @click="item.price_per_liter -= 50"
                        type="button"
                        class="text-gray-400 hover:text-[#143d2e] hover:bg-green-100 rounded px-0.5 transition-colors"
                    >
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-3 h-3">
                            <path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clip-rule="evenodd" />
                        </svg>
                    </button>
                </div>
            </div>
        </div>

        </div>
      </div>

      <div class="pt-4 mt-auto text-right">
        <button 
          type="submit" 
          :disabled="loading"
          class="bg-[#143d2e] hover:bg-[#1e5c45] text-white px-6 py-3 rounded-xl font-bold text-sm shadow-lg shadow-green-900/10 transition-all active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed inline-flex items-center gap-2"
        >
          <span v-if="loading" class="loading loading-spinner loading-xs"></span>
          Simpan Harga
        </button>
      </div>
    </form>
  </div>
</template>