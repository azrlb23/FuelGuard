<script setup>
import { computed } from 'vue'
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, Tooltip } from 'chart.js'
import { Bar } from 'vue-chartjs'

ChartJS.register(CategoryScale, LinearScale, BarElement, Tooltip)

const props = defineProps({ data: { type: Array, default: () => [] } })

const chartData = computed(() => {
  
  const order = ['Kecil (<2L)', 'Sedang (2-5L)', 'Besar (>5L)']
  const sortedData = order.map(cat => {
    const found = props.data.find(d => d.category === cat)
    return found ? found.count : 0
  })

  return {
    labels: ['Kecil', 'Sedang', 'Besar'],
    datasets: [{
      label: 'Transaksi',
      backgroundColor: ['#fbbf24', '#34d399', '#064e3b'], 
      borderRadius: 6,
      data: sortedData
    }]
  }
})

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { display: false } },
  scales: {
    x: { grid: { display: false } },
    y: { display: false }
  }
}
</script>

<template>
  <div class="bg-white rounded-[2rem] p-6 shadow-sm border border-gray-200 flex flex-col h-full min-w-0">
    <h4 class="font-bold text-lg text-gray-800 tracking-tight mb-4">Distribusi Pengisian</h4>
    <div class="flex-1 w-full min-h-[150px]">
      <Bar :data="chartData" :options="chartOptions" />
    </div>
  </div>
</template>