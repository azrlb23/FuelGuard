<script setup>
import { ref } from 'vue'
import VehicleSelector from '@/components/operator/VehicleSelector.vue'
import TransactionForm from '@/components/operator/TransactionForm.vue'
import TransactionSuccess from '@/components/operator/TransactionSuccess.vue'
import { useTransactionAction } from '@/composables/operator/useTransactionAction'
import { useAuthStore } from '@/stores/auth'

const step = ref(1)
const selectedVehicle = ref('')
const isOjol = ref(false)

const authStore = useAuthStore()
const { loading, submitTransaction } = useTransactionAction()

const handleVehicleSelect = (payload) => {
  if (typeof payload === 'object' && payload !== null) {
    selectedVehicle.value = payload.type || 'Ojol'
    isOjol.value = !!payload.isOjol
  } else {
    selectedVehicle.value = payload
    isOjol.value = payload === 'Ojol'
  }
  step.value = 2
}

const handleBack = () => {
  selectedVehicle.value = ''
  isOjol.value = false
  step.value = 1
}

const handleReset = () => {
  selectedVehicle.value = ''
  isOjol.value = false
  step.value = 1
}

const handleProcess = async (res) => {
  const isSuccess = res && typeof res === 'object' ? res.success : res
  if (isSuccess) {
    step.value = 3
    setTimeout(() => {
      if (step.value === 3) handleReset()
    }, 2000)
  }
}
</script>

<template>
  <div class="flex-1 my-auto flex flex-col items-center justify-center w-full gap-4 sm:gap-6 animate-enter">
    
    <div class="w-full max-w-2xl bg-gradient-to-br from-[#143d2e] to-[#1e5c45] rounded-[1.5rem] md:rounded-[2.5rem] p-4 sm:p-5 md:p-8 text-white shadow-2xl relative overflow-y-auto hide-scrollbar transition-all duration-300">
      
      <div class="absolute top-0 right-0 w-60 h-60 bg-white/5 rounded-full blur-3xl -translate-y-10 translate-x-10 pointer-events-none"></div>



      <div class="w-full flex-1 flex flex-col justify-center">
        <div v-if="!authStore.activeKasirId" class="text-center animate-enter">
          <div class="w-16 h-16 md:w-20 md:h-20 bg-white/10 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-8 h-8 md:w-10 md:h-10 text-white/50">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
            </svg>
          </div>
          <h2 class="text-xl md:text-2xl font-bold mb-2">Pilih Kasir</h2>
          <p class="text-sm text-white/70">Silakan pilih nama Anda pada menu di kanan atas sebelum memulai transaksi.</p>
        </div>

        <template v-else>
          <VehicleSelector v-if="step === 1" @select="handleVehicleSelect" />

      <TransactionForm 
        v-if="step === 2"
        :vehicle-type="selectedVehicle"
        :is-ojol="isOjol"
        :loading="loading"
        @submit="handleProcess" 
        @back="handleBack"
      />

        <TransactionSuccess v-if="step === 3" @reset="handleReset" />
        </template>
      </div>
    </div>

  </div>
</template>