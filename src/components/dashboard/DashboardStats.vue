<script setup>
import { computed } from 'vue'
import { useFormatters } from '@/composables/useFormatters' 

const props = defineProps({
  stats: Object,
  filter: String,
  loading: Boolean
})

const { formatRupiah } = useFormatters() 
const { formatDate } = useFormatters()
const { formatTimeAgo } = useFormatters()


const getGrowthStyle = (value) => {
  if (value > 0) return { color: 'text-green-200', bg: 'bg-green-500/20', icon: '↗' }
  if (value < 0) return { color: 'text-red-200', bg: 'bg-red-500/20', icon: '↘' }
  return { color: 'text-gray-200', bg: 'bg-white/10', icon: '-' }
}
</script>

<template>
  <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
    
    <div class="relative overflow-hidden bg-gradient-to-br from-[#143d2e] to-[#258f62] rounded-[2rem] p-6 md:p-8 text-white shadow-xl shadow-green-900/10 hover:scale-[1.02] transition-transform duration-300">
      <Transition name="fade" mode="out-in">
        
        <div v-if="loading" class="animate-pulse space-y-4" key="skeleton">
          <div class="h-4 w-24 bg-white/20 rounded-full"></div> 
          <div class="h-10 w-48 bg-white/20 rounded-lg"></div>  
          <div class="h-6 w-32 bg-white/20 rounded-full"></div> 
        </div>

        <div v-else key="content">
          <p class="text-green-100 text-sm font-bold mb-2 uppercase tracking-wide">Total Volume</p>
          <h3 class="text-4xl md:text-5xl font-bold mb-4">
            {{ stats.volume?.toLocaleString() || 0 }} 
            <span class="text-2xl font-normal opacity-70">L</span>
          </h3>
          <div v-if="filter !== 'all-time'" 
               class="text-xs inline-flex items-center px-3 py-1 rounded-full backdrop-blur-sm transition-colors"
               :class="[getGrowthStyle(stats.volume_growth).bg, getGrowthStyle(stats.volume_growth).color]"
          >
            <span class="mr-1 font-bold">{{ getGrowthStyle(stats.volume_growth).icon }}</span> 
            {{ Math.abs(stats.volume_growth || 0) }}% vs last period
          </div>
          <div v-else class="text-xs text-green-200/50 italic mt-2">Lifetime Data</div>
        </div>

      </Transition>
      <div class="absolute -right-6 -bottom-10 w-32 h-32 bg-white/10 rounded-full blur-2xl"></div>
    </div>

    <div class="relative overflow-hidden bg-gradient-to-br from-[#143d2e] to-[#258f62] rounded-[2rem] p-6 md:p-8 text-white shadow-xl shadow-green-900/10 hover:scale-[1.02] transition-transform duration-300">
      <Transition name="fade" mode="out-in">
        
        <div v-if="loading" class="animate-pulse space-y-4" key="skeleton">
          <div class="h-4 w-24 bg-white/20 rounded-full"></div>
          <div class="h-10 w-40 bg-white/20 rounded-lg"></div>
          <div class="h-6 w-32 bg-white/20 rounded-full"></div>
        </div>

        <div v-else key="content">
          <p class="text-green-100 text-sm font-bold mb-2 uppercase tracking-wide">Total Revenue</p>
          <h3 class="text-3xl md:text-4xl font-bold mb-4 truncate">
            {{ formatRupiah(stats.revenue || 0) }}
          </h3>
          <div v-if="filter !== 'all-time'"
               class="text-xs inline-flex items-center px-3 py-1 rounded-full backdrop-blur-sm transition-colors"
               :class="[getGrowthStyle(stats.revenue_growth).bg, getGrowthStyle(stats.revenue_growth).color]"
          >
            <span class="mr-1 font-bold">{{ getGrowthStyle(stats.revenue_growth).icon }}</span>
            {{ Math.abs(stats.revenue_growth || 0) }}% vs last period
          </div>
          <div v-else class="text-xs text-green-200/50 italic mt-2">Lifetime Data</div>
        </div>

      </Transition>
      <div class="absolute -right-6 -bottom-10 w-32 h-32 bg-white/10 rounded-full blur-2xl"></div>
    </div>

    <div class="relative overflow-hidden bg-white text-black rounded-[2rem] p-6 md:p-8 shadow-xl hover:scale-[1.02] transition-transform duration-300 border border-gray-100">
      <Transition name="fade" mode="out-in">
        
        <div v-if="loading" class="animate-pulse space-y-4" key="skeleton">
          <div class="h-4 w-24 bg-gray-200 rounded-full"></div>
          <div class="h-10 w-20 bg-gray-200 rounded-lg"></div>
          <div class="h-6 w-28 bg-gray-200 rounded-full"></div>
        </div>

        <div v-else key="content">
          <p class="text-gray-500 text-sm font-bold mb-2 uppercase tracking-wide">transactions</p>
          <h3 class="text-4xl md:text-5xl font-extrabold mb-4 text-[#143d2e]">
            {{ stats.vehicle || 0 }}
          </h3>
           <div class="text-xs text-gray-400 bg-gray-100 inline-block px-3 py-1 rounded-full">
             Recorded Data
           </div>
        </div>
        
      </Transition>
    </div>

  </div>
</template>