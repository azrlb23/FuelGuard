<script setup>
import { computed } from 'vue'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js'
import { Bar } from 'vue-chartjs'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, BarElement, ArcElement, Title, Tooltip, Legend, Filler)

const props = defineProps({
  weeklyVolumeByDay: {
    type: Array,
    default: () => [0, 0, 0, 0, 0, 0, 0]
  }
})

const barChartData = computed(() => {
  const volumes = props.weeklyVolumeByDay || [0, 0, 0, 0, 0, 0, 0]
  const maxVol = Math.max(...volumes, 0)
  const isKLiter = maxVol >= 1000

  const dataValues = volumes.map(v =>
    isKLiter ? Number((v / 1000).toFixed(2)) : Number((v || 0).toFixed(1))
  )

  const todayIdx = (new Date().getDay() + 6) % 7 // Current day index (0=Sen, 6=Min)

  return {
    labels: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
    datasets: [{
      label: isKLiter ? 'Volume (K Liters)' : 'Volume (Liters)',
      data: dataValues,
      backgroundColor: dataValues.map((_, i) => i === todayIdx ? '#258f62' : '#143d2e'),
      borderRadius: 6
    }]
  }
})

const barChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { display: false } },
  scales: {
    x: { grid: { display: false }, ticks: { font: { size: 10 } } },
    y: { grid: { color: '#f3f4f6' }, ticks: { font: { size: 10 } } }
  }
}
</script>

<template>
  <div class="bg-white rounded-[2rem] p-6 shadow-xl shadow-green-900/5 border border-gray-100 flex flex-col justify-between">
    <div>
      <h4 class="text-[#143d2e] font-black text-lg mb-4">Volume Transaksi Mingguan</h4>
    </div>
    <div class="h-44 w-full">
      <Bar :data="barChartData" :options="barChartOptions" />
    </div>
  </div>
</template>
