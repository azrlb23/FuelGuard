<script setup>
import { ref, onMounted } from 'vue'
import { toast } from 'vue3-toastify'

const useCamera = ref(false)

onMounted(() => {
  useCamera.value = localStorage.getItem('hj_pref_camera') === 'true'
})

const toggleCamera = () => {
  localStorage.setItem('hj_pref_camera', useCamera.value)
  
  if (useCamera.value) {
    toast.success("Mode Scan Kamera: AKTIF")
    navigator.mediaDevices.getUserMedia({ video: true }).catch(() => {
       toast.error("Izin kamera ditolak browser")
       useCamera.value = false
    })
  } else {
    toast.info("Mode Scan Kamera: NON-AKTIF")
  }
}
</script>

<template>
  <div class="flex items-center justify-between">
    <div class="flex items-center gap-4">
      <div class="w-12 h-12 rounded-xl bg-green-50 flex items-center justify-center text-[#143d2e]">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="w-6 h-6">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6.827 6.175A2.31 2.31 0 0 1 5.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574v9.176c0 1.206.94 2.197 2.146 2.33 3.906.432 7.892.432 11.798 0 1.206-.133 2.146-1.124 2.146-2.33V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 0 0-1.134-.175 2.31 2.31 0 0 1-1.64-1.055l-.822-1.316a2.192 2.192 0 0 0-1.736-1.039 48.774 48.774 0 0 0-5.232 0 2.192 2.192 0 0 0-1.736 1.039l-.821 1.316Z" />
          <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 12.75a4.5 4.5 0 1 1-9 0 4.5 4.5 0 0 1 9 0ZM18.75 10.5h.008v.008h-.008V10.5Z" />
        </svg>
      </div>
      <div>
        <h3 class="font-bold text-gray-900">Scan Kamera</h3>
        <p class="text-xs text-gray-500 max-w-[200px]">Aktifkan tombol scanner di halaman transaksi.</p>
      </div>
    </div>

    <input 
      type="checkbox" 
      v-model="useCamera" 
      class="toggle toggle-success" 
      @change="toggleCamera"
    />
  </div>
</template>