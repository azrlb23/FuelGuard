<script setup>
defineProps({
  modelValue: {
    type: Object,
    required: true
  },
  loading: Boolean
})

const emit = defineEmits(['update:modelValue', 'submit'])


const updateField = (field, value) => {
  emit('update:modelValue', { ...props.modelValue, [field]: value })
}
</script>

<template>
  <div class="bg-white rounded-[2rem] p-6 md:p-8 shadow-xl border border-gray-100 relative overflow-hidden h-full">
    <div class="absolute top-0 right-0 w-32 h-32 bg-green-50 rounded-full blur-3xl -translate-y-10 translate-x-10 pointer-events-none"></div>

    <form @submit.prevent="$emit('submit')" class="relative z-10 space-y-6">
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        
        <div class="space-y-2">
          <label class="text-xs font-bold text-gray-400 uppercase tracking-wider ml-1">Kategori</label>
          <div class="relative">
            <select 
              :value="modelValue.kategori"
              @input="$emit('update:modelValue', { ...modelValue, kategori: $event.target.value })"
              class="w-full bg-gray-50 border border-gray-200 text-gray-700 font-bold rounded-xl px-4 py-3 appearance-none focus:outline-none focus:ring-2 focus:ring-green-500/20 focus:border-green-500 transition-all cursor-pointer"
            >
              <option>Bug Sistem</option>
              <option>Request Fitur</option>
              <option>Masalah Akun</option>
              <option>Masalah Hardware</option>
              <option>Lainnya</option>
            </select>
            <div class="absolute right-4 top-3.5 pointer-events-none text-gray-500">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5">
                <path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clip-rule="evenodd" />
              </svg>
            </div>
          </div>
        </div>

        <div class="space-y-2">
          <label class="text-xs font-bold text-gray-400 uppercase tracking-wider ml-1">Prioritas</label>
          <div class="flex gap-2">
            <button type="button" 
              @click="$emit('update:modelValue', { ...modelValue, prioritas: 'Low' })"
              class="flex-1 py-3 rounded-xl text-sm font-bold border transition-all"
              :class="modelValue.prioritas === 'Low' ? 'bg-blue-50 border-blue-200 text-blue-600' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-50'"
            >Low</button>
            <button type="button" 
              @click="$emit('update:modelValue', { ...modelValue, prioritas: 'Medium' })"
              class="flex-1 py-3 rounded-xl text-sm font-bold border transition-all"
              :class="modelValue.prioritas === 'Medium' ? 'bg-yellow-50 border-yellow-200 text-yellow-600' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-50'"
            >Normal</button>
            <button type="button" 
              @click="$emit('update:modelValue', { ...modelValue, prioritas: 'High' })"
              class="flex-1 py-3 rounded-xl text-sm font-bold border transition-all"
              :class="modelValue.prioritas === 'High' ? 'bg-red-50 border-red-200 text-red-600' : 'bg-white border-gray-200 text-gray-400 hover:bg-gray-50'"
            >Urgent</button>
          </div>
        </div>
      </div>

      <div class="space-y-2">
        <label class="text-xs font-bold text-gray-400 uppercase tracking-wider ml-1">Subjek Masalah</label>
        <input 
          :value="modelValue.subjek"
          @input="$emit('update:modelValue', { ...modelValue, subjek: $event.target.value })"
          type="text" 
          placeholder="Contoh: Tidak bisa export data excel" 
          class="w-full bg-gray-50 border border-gray-200 text-gray-800 font-medium rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-green-500/20 focus:border-green-500 transition-all placeholder-gray-400"
        />
      </div>

      <div class="space-y-2">
        <label class="text-xs font-bold text-gray-400 uppercase tracking-wider ml-1">Deskripsi Detail</label>
        <textarea 
          :value="modelValue.deskripsi"
          @input="$emit('update:modelValue', { ...modelValue, deskripsi: $event.target.value })"
          rows="5"
          placeholder="Jelaskan kronologi masalah atau detail fitur yang diinginkan..." 
          class="w-full bg-gray-50 border border-gray-200 text-gray-800 font-medium rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-green-500/20 focus:border-green-500 transition-all placeholder-gray-400 resize-none"
        ></textarea>
      </div>

      <div class="pt-2">
        <button 
          type="submit" 
          :disabled="loading"
          class="w-full bg-[#143d2e] hover:bg-[#0f2e23] text-white font-bold py-4 rounded-xl shadow-lg hover:shadow-xl transform active:scale-[0.98] transition-all disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center gap-3"
        >
          <span v-if="loading" class="loading loading-spinner loading-sm"></span>
          <span v-else class="flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 12L3.269 3.126A59.768 59.768 0 0121.485 12 59.77 59.77 0 013.27 20.876L5.999 12zm0 0h7.5" />
            </svg>
            Kirim Laporan
          </span>
        </button>
      </div>

    </form>
  </div>
</template>