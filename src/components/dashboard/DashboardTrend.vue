<script setup>
import { computed } from 'vue'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js'
import { Line } from 'vue-chartjs'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend, Filler)

const props = defineProps({ data: { type: Array, default: () => [] } })

const chartData = computed(() => {
  return {
    labels: props.data.map(d => d.label),
    datasets: [{
      label: 'Pendapatan',
      backgroundColor: (ctx) => {
        const canvas = ctx.chart.ctx;
        const gradient = canvas.createLinearGradient(0, 0, 0, 200);
        gradient.addColorStop(0, 'rgba(52, 211, 153, 0.5)'); 
        gradient.addColorStop(1, 'rgba(52, 211, 153, 0)');
        return gradient;
      },
      borderColor: '#34d399',
      pointBackgroundColor: '#064e3b',
      borderWidth: 2,
      fill: true,
      data: props.data.map(d => d.total),
      tension: 0.4
    }]
  }
})

const formatRupiah = (val) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val)

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: {
      callbacks: {
        label: (context) => `Pendapatan: ${formatRupiah(context.raw || 0)}`
      }
    }
  },
  scales: {
    x: { grid: { display: false }, ticks: { font: { size: 10 } } },
    y: { display: false, beginAtZero: true } 
  }
}
</script>

<template>
  <div class="bg-white rounded-[2rem] p-6 shadow-sm border border-gray-200 flex flex-col h-full min-w-0">
    <div class="flex justify-between items-center mb-2">
      <h4 class="font-bold text-lg text-gray-800 tracking-tight">Tren 7 Hari</h4>
      <span class="bg-green-100 text-green-800 text-[10px] font-bold px-2 py-1 rounded-full">Revenue</span>
    </div>
    <div class="flex-1 w-full min-h-[150px]">
      <Line :data="chartData" :options="chartOptions" />
    </div>
  </div>
</template>