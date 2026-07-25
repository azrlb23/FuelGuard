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
  <div class="bg-white rounded-2xl p-5 border border-gray-100 shadow-sm">
    <div class="flex items-center justify-between">
      
      <div class="flex items-center gap-4">
        <div class="w-12 h-12 rounded-xl bg-green-50 flex items-center justify-center text-[#143d2e]">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-6 h-6">
            <path d="M12 9a3.75 3.75 0 100 7.5A3.75 3.75 0 0012 9z" />
            <path fill-rule="evenodd" d="M9.375 3a.75.75 0 01.75.75 4.5 4.5 0 019 0 .75.75 0 01.75-.75h2.25a.75.75 0 01.75.75v16.5a.75.75 0 01-.75.75h-16.5a.75.75 0 01-.75-.75V3.75a.75.75 0 01.75-.75h2.25zm.375 0a.75.75 0 01.75.75 1.5 1.5 0 01-3 0 .75.75 0 01.75-.75h1.5z" clip-rule="evenodd" />
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
  </div>
</template>