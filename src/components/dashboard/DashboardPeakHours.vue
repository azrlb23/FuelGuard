<script setup>
import { computed } from 'vue'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
} from 'chart.js'
import { Bar } from 'vue-chartjs'

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend)

const props = defineProps({
  data: { type: Array, default: () => [] }
})

const chartData = computed(() => {
  
  const hours = Array.from({ length: 24 }, (_, i) => i)
  
  
  const counts = hours.map(h => {
    const found = props.data.find(d => d.hour === h)
    return found ? found.count : 0
  })

  return {
    labels: hours.map(h => `${h}:00`),
    datasets: [{
      label: 'Kendaraan',
      backgroundColor: '#34d399',
      borderRadius: 4,
      data: counts
    }]
  }
})

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { display: false } },
  scales: {
    x: { grid: { display: false }, ticks: { color: '#ffffff90', font: { size: 10 } } },
    y: { grid: { color: '#ffffff10' }, ticks: { color: '#ffffff90', font: { size: 10 } } }
  }
}
</script>

<template>
  <div class="bg-gradient-to-br from-[#143d2e] to-[#1e5c45] rounded-[2rem] p-6 text-white shadow-xl shadow-green-900/20 flex flex-col relative overflow-hidden h-full min-w-0">
    
    <div class="flex justify-between items-center mb-4 z-10">
      <h4 class="font-bold text-lg tracking-tight">Analisis Jam Sibuk</h4>
      <span class="bg-white/10 px-3 py-1 rounded-full text-[10px] font-bold text-green-100 uppercase tracking-wider">Live Trend</span>
    </div>

    <div class="flex-1 relative w-full min-h-[200px] z-10">
      <Bar :data="chartData" :options="chartOptions" />
    </div>

    <div class="absolute bottom-0 right-0 w-32 h-32 bg-white/5 rounded-full blur-3xl translate-y-10 translate-x-10 pointer-events-none"></div>
  </div>
</template>