<script setup>
import { ref } from 'vue'
import VehicleSelector from '@/components/operator/VehicleSelector.vue'
import TransactionForm from '@/components/operator/TransactionForm.vue'
import TransactionSuccess from '@/components/operator/TransactionSuccess.vue'
import { useTransactionAction } from '@/composables/useTransactionAction'

const step = ref(1)
const selectedVehicle = ref('')

const { loading, submitTransaction } = useTransactionAction()

const handleVehicleSelect = (type) => {
  selectedVehicle.value = type
  step.value = 2
}

const handleBack = () => {
  selectedVehicle.value = ''
  step.value = 1
}

const handleReset = () => {
  selectedVehicle.value = ''
  step.value = 1
}

const handleProcess = async (formData) => {
  const success = await submitTransaction(formData, selectedVehicle.value)
  if (success) {
    step.value = 3
    setTimeout(() => {
      if (step.value === 3) handleReset()
    }, 2000)
  }
}
</script>

<template>
  <div class="flex-1 h-full flex flex-col items-center justify-center w-full gap-6 animate-enter">
    
    <div class="w-full max-w-2xl bg-gradient-to-br from-[#143d2e] to-[#1e5c45] rounded-[1.5rem] md:rounded-[2.5rem] p-5 md:p-8 text-white shadow-2xl relative overflow-hidden min-h-[350px] flex flex-col justify-center transition-all duration-300">
      
      <div class="absolute top-0 right-0 w-60 h-60 bg-white/5 rounded-full blur-3xl -translate-y-10 translate-x-10 pointer-events-none"></div>

      <VehicleSelector v-if="step === 1" @select="handleVehicleSelect" />

      <TransactionForm 
        v-if="step === 2"
        :vehicle-type="selectedVehicle"
        :loading="loading"
        @submit="handleProcess" 
        @back="handleBack"
      />

      <TransactionSuccess v-if="step === 3" @reset="handleReset" />
    </div>

    <router-link 
      to="/operator/history" 
      class="group w-full max-w-2xl bg-white hover:bg-green-50 rounded-2xl p-4 md:p-5 shadow-sm border border-green-100 flex items-center justify-between transition-all duration-300 hover:shadow-md hover:-translate-y-1"
    >
      <div class="flex items-center gap-4">
        <div class="w-10 h-10 md:w-12 md:h-12 bg-green-100 text-green-700 rounded-full flex items-center justify-center text-xl md:text-2xl group-hover:scale-110 transition-transform">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 002.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 00-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25zM6.75 12h.008v.008H6.75V12zm0 3h.008v.008H6.75V15zm0 3h.008v.008H6.75V18z" />
          </svg>
        </div>
        <div class="text-left">
          <h3 class="text-base md:text-lg font-bold text-gray-800 group-hover:text-green-800 transition-colors">
            Riwayat Transaksi
          </h3>
          <p class="text-xs md:text-sm text-gray-500">
            Lihat data hari ini
          </p>
        </div>
      </div>
      
      <div class="w-8 h-8 md:w-10 md:h-10 flex items-center justify-center rounded-full bg-gray-50 text-gray-400 group-hover:bg-green-500 group-hover:text-white transition-all">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4 md:w-5 md:h-5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
        </svg>
      </div>
    </router-link>

  </div>
</template>