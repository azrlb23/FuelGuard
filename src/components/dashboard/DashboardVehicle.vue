<script setup>
import { computed } from 'vue'
import { Chart as ChartJS, ArcElement, Tooltip, Legend } from 'chart.js'
import { Doughnut } from 'vue-chartjs'

ChartJS.register(ArcElement, Tooltip, Legend)

const props = defineProps({ data: { type: Array, default: () => [] } })

const chartData = computed(() => {
  return {
    labels: props.data.map(d => d.label),
    datasets: [{
      backgroundColor: ['#ffffff', '#34d399', '#10b981'],
      borderWidth: 0,
      data: props.data.map(d => d.count)
    }]
  }
})

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  cutout: '65%', 
  plugins: { legend: { display: false } }
}

const totalVehicle = computed(() => props.data.reduce((acc, curr) => acc + curr.count, 0))
</script>

<template>
  <div class="bg-gradient-to-br from-[#143d2e] to-[#064e3b] rounded-[2rem] p-6 text-white shadow-xl shadow-green-900/20 flex flex-col h-full min-w-0 relative overflow-hidden">
    
    <div class="flex justify-between items-center mb-4 z-10">
      <h4 class="font-bold text-lg tracking-tight">Vehicle Type</h4>
      <span class="bg-white/10 px-2 py-1 rounded-full text-[10px]">Live</span>
    </div>
    
    <div class="relative flex-1 min-h-[160px] z-10">
      <Doughnut :data="chartData" :options="chartOptions" />
      <div class="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
        <span class="text-3xl font-black">{{ totalVehicle }}</span>
        <span class="text-[10px] uppercase opacity-70">Units</span>
      </div>
    </div>
    
    <div class="flex flex-wrap justify-center gap-3 mt-4 z-10">
      <div v-for="(item, i) in props.data" :key="i" class="flex items-center gap-1.5">
        <div class="w-2 h-2 rounded-full" :style="{ background: chartData.datasets[0].backgroundColor[i] }"></div>
        <span class="text-xs font-medium capitalize">{{ item.label }}</span>
        <span class="text-[10px] opacity-60">({{ item.count }})</span>
      </div>
    </div>

    <div class="absolute bottom-0 left-0 w-32 h-32 bg-black/10 rounded-full blur-3xl translate-y-10 -translate-x-10 pointer-events-none"></div>
  </div>
</template>