<script setup>
import { computed } from 'vue'
import {
  Chart as ChartJS,
  ArcElement,
  Tooltip,
  Legend
} from 'chart.js'
import { Doughnut } from 'vue-chartjs'


ChartJS.register(ArcElement, Tooltip, Legend)


const props = defineProps({
  shiftData: {
    type: Array,
    default: () => []
  },
  vehicleData: {
    type: Array,
    default: () => []
  }
})


const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  cutout: '75%', 
  borderRadius: 20, 
  borderWidth: 0,   
  plugins: {
    legend: {
      display: false 
    },
    tooltip: {
      backgroundColor: '#064e3b',
      titleColor: '#fff',
      bodyFont: { family: 'sans-serif' },
      callbacks: {
        label: function(context) {
          return ` ${context.label}: ${context.raw} Unit`
        }
      }
    }
  }
}


const shiftChartData = computed(() => {
  
  const labels = props.shiftData.map(item => `Shift ${item.shift}`)
  const dataValues = props.shiftData.map(item => item.count)

  return {
    labels: labels,
    datasets: [
      {
        backgroundColor: ['#34d399', '#ffffff', '#fbbf24'], 
        data: dataValues.length ? dataValues : [1] 
      }
    ]
  }
})


const vehicleChartData = computed(() => {
  
  const labels = props.vehicleData.map(item => item.label || 'Unknown') 
  const dataValues = props.vehicleData.map(item => item.count)

  return {
    labels: labels,
    datasets: [
      {
        backgroundColor: ['#ffffff', '#34d399', '#10b981'], 
        data: dataValues.length ? dataValues : [1]
      }
    ]
  }
})
</script>

<template>
  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 w-full">
    
    <div class="bg-gradient-to-br from-[#143d2e] to-[#1e5c45] rounded-[2.5rem] p-8 text-white shadow-xl shadow-green-900/20 flex flex-col items-center relative overflow-hidden group">
      <div class="absolute top-0 right-0 w-32 h-32 bg-white/5 rounded-full blur-3xl -translate-y-10 translate-x-10 pointer-events-none"></div>

      <div class="w-full flex justify-between items-center mb-6 z-10">
        <h4 class="font-bold text-xl tracking-tight">Shift Distribution</h4>
        <span class="bg-white/10 px-3 py-1 rounded-full text-xs font-medium text-green-100">Today</span>
      </div>
      
      <div class="relative w-48 h-48 md:w-56 md:h-56 z-10">
        <Doughnut :data="shiftChartData" :options="chartOptions" />
        
        <div class="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
          <span class="text-3xl font-black text-white">
            {{ props.shiftData.reduce((a, b) => a + b.count, 0) }}
          </span>
          <span class="text-xs text-green-200 uppercase tracking-widest font-bold">Total</span>
        </div>
      </div>
      
      <div class="flex flex-wrap justify-center gap-4 mt-8 z-10">
        <div v-for="(item, index) in props.shiftData" :key="index" class="flex items-center gap-2">
          <span class="w-3 h-3 rounded-full shadow-sm" :style="{ backgroundColor: shiftChartData.datasets[0].backgroundColor[index] }"></span>
          <span class="text-sm font-medium text-green-50">Shift {{ item.shift }}</span>
          <span class="text-xs text-white/60 font-bold">({{ item.count }})</span>
        </div>
      </div>
    </div>

    <div class="bg-gradient-to-br from-[#143d2e] to-[#1e5c45] rounded-[2.5rem] p-8 text-white shadow-xl shadow-green-900/20 flex flex-col items-center relative overflow-hidden">
       <div class="absolute bottom-0 left-0 w-40 h-40 bg-black/10 rounded-full blur-3xl translate-y-10 -translate-x-10 pointer-events-none"></div>

      <div class="w-full flex justify-between items-center mb-6 z-10">
        <h4 class="font-bold text-xl tracking-tight">Vehicle Type</h4>
        <span class="bg-white/10 px-3 py-1 rounded-full text-xs font-medium text-green-100">Live</span>
      </div>
      
      <div class="relative w-48 h-48 md:w-56 md:h-56 z-10">
        <Doughnut :data="vehicleChartData" :options="chartOptions" />

        <div class="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
          <span class="text-3xl font-black text-white">
             {{ props.vehicleData.reduce((a, b) => a + b.count, 0) }}
          </span>
          <span class="text-xs text-green-200 uppercase tracking-widest font-bold">Vehicles</span>
        </div>
      </div>

      <div class="flex flex-wrap justify-center gap-4 mt-8 z-10">
        <div v-for="(item, index) in props.vehicleData" :key="index" class="flex items-center gap-2">
          <span class="w-3 h-3 rounded-full shadow-sm" :style="{ backgroundColor: vehicleChartData.datasets[0].backgroundColor[index] }"></span>
          <span class="text-sm font-medium text-green-50 capitalize">{{ item.label }}</span>
           <span class="text-xs text-white/60 font-bold">({{ item.count }})</span>
        </div>
      </div>
    </div>

  </div>
</template>