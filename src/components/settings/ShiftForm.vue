<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { toast } from 'vue3-toastify'

const loading = ref(false)
const shifts = ref([])

const fetchShifts = async () => {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('shift_config')
      .select('*')
      .order('shift_name')
    
    if (error || !data || data.length === 0) {
      // Jika database kosong / belum ada data shift, gunakan jadwal default
      shifts.value = [
        { shift_name: 'Shift 1', start_time: '06:00', end_time: '14:00' },
        { shift_name: 'Shift 2', start_time: '14:00', end_time: '22:00' },
        { shift_name: 'Shift 3', start_time: '22:00', end_time: '06:00' }
      ]
    } else {
      shifts.value = data.sort((a, b) => a.shift_name.localeCompare(b.shift_name))
    }
  } catch (err) {
    console.error('Error fetchShifts:', err)
  } finally {
    loading.value = false
  }
}

const saveShifts = async () => {
  loading.value = true
  try {
    const updates = shifts.value.map(s => {
      const row = {
        shift_name: s.shift_name,
        start_time: s.start_time,
        end_time: s.end_time,
        updated_at: new Date()
      }
      if (s.id) row.id = s.id
      return row
    })

    const { data, error } = await supabase
      .from('shift_config')
      .upsert(updates)
      .select()

    if (error) throw error
    if (data && data.length > 0) {
      shifts.value = data.sort((a, b) => a.shift_name.localeCompare(b.shift_name))
    }
    toast.success("Jam operasional shift berhasil diperbarui!")
  } catch (err) {
    toast.error("Gagal menyimpan: " + err.message)
  } finally {
    loading.value = false
  }
}

onMounted(() => fetchShifts())
</script>

<template>
  <div class="bg-white rounded-[2rem] p-6 border border-gray-100 shadow-sm relative overflow-hidden">
    
    <div class="mb-6">
      <h3 class="text-lg font-bold text-gray-800 flex items-center gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5 text-[#143d2e]">
          <path fill-rule="evenodd" d="M12 2.25c-5.385 0-9.75 4.365-9.75 9.75s4.365 9.75 9.75 9.75 9.75-4.365 9.75-9.75S17.385 2.25 12 2.25zM12.75 6a.75.75 0 00-1.5 0v6c0 .414.336.75.75.75h4.5a.75.75 0 000-1.5h-3.75V6z" clip-rule="evenodd" />
        </svg>
        Jadwal Operasional Shift
      </h3>
      <p class="text-gray-400 text-sm">Atur jam kerja untuk setiap shift secara otomatis.</p>
    </div>

    <form @submit.prevent="saveShifts" class="space-y-4">
      
      <div v-if="loading && shifts.length === 0" class="text-center py-6 text-gray-400">
        <span class="loading loading-dots loading-sm"></span> Memuat jadwal...
      </div>

      <div v-else class="space-y-4">
        <div v-for="item in shifts" :key="item.id" class="flex flex-col md:flex-row items-center gap-4 p-4 bg-gray-50 rounded-2xl border border-gray-100">
          
          <div class="w-full md:w-1/4">
            <span class="text-xs font-bold text-gray-400 uppercase tracking-wider block mb-1">Nama Shift</span>
            <div class="font-bold text-gray-800 text-lg">{{ item.shift_name }}</div>
          </div>

          <div class="w-full md:w-1/3">
            <label class="text-xs font-bold text-gray-500 uppercase block mb-1">Jam Mulai</label>
            <input 
              v-model="item.start_time"
              type="time" 
              class="w-full bg-white border border-gray-200 rounded-xl px-4 py-2.5 text-sm font-bold text-gray-800 focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] transition-all cursor-pointer"
            />
          </div>

          <div class="hidden md:block text-gray-300 pt-5">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M17.25 8.25L21 12m0 0l-3.75 3.75M21 12H3" />
            </svg>
          </div>

          <div class="w-full md:w-1/3">
            <label class="text-xs font-bold text-gray-500 uppercase block mb-1">Jam Selesai</label>
            <input 
              v-model="item.end_time"
              type="time" 
              class="w-full bg-white border border-gray-200 rounded-xl px-4 py-2.5 text-sm font-bold text-gray-800 focus:outline-none focus:ring-2 focus:ring-[#143d2e]/20 focus:border-[#143d2e] transition-all cursor-pointer"
            />
          </div>

        </div>
      </div>

      <div class="pt-4 text-right">
        <button 
          type="submit" 
          :disabled="loading"
          class="bg-[#143d2e] hover:bg-[#1e5c45] text-white px-6 py-3 rounded-xl font-bold text-sm shadow-lg shadow-green-900/10 transition-all active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed inline-flex items-center gap-2"
        >
          <span v-if="loading" class="loading loading-spinner loading-xs"></span>
          Simpan Jadwal
        </button>
      </div>
    </form>
  </div>
</template>