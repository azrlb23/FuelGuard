<script setup>
import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'

const authStore = useAuthStore()
const router = useRouter()

const userEmail = computed(() => authStore.user?.email || 'Operator')
const userName = computed(() => userEmail.value.split('@')[0])

const handleLogout = async () => {
  await authStore.logout()
}
</script>

<template>
  <div class="h-screen w-full bg-[#f5f5f5] font-sans text-gray-800 flex flex-col overflow-hidden">
    
    <header class="bg-[#f5f5f5] backdrop-blur-md border-b border-gray-200/60 flex-none z-50">
      <div class="max-w-7xl mx-auto px-4 md:px-8 h-16 flex items-center justify-between">
        
        <router-link to="/" class="flex items-center gap-3 cursor-pointer group">
          <img src="@/assets/HJ_dark.png" alt="Logo" class="w-8 h-8 group-hover:scale-110 transition-transform" />
          <div>
            <h1 class="font-black text-lg tracking-tight text-[#143d2e] leading-none">HABI JAYA</h1>
            <p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest">Operator Console</p>
          </div>
        </router-link>

        <div class="flex items-center gap-2 md:gap-4">
          
          <div class="hidden md:block text-right mr-2">
            <p class="text-sm font-bold capitalize">{{ userName }}</p>
            <p class="text-xs text-gray-500">Shift Operasional</p>
          </div>

          <div class="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center text-green-700 font-bold border border-green-200 shadow-sm">
            {{ userName.charAt(0).toUpperCase() }}
          </div>

          <div class="h-8 w-px bg-gray-200 mx-1"></div>

          <router-link 
            to="/operator/settings"
            class="p-2 text-gray-400 hover:text-[#143d2e] hover:bg-gray-200/50 rounded-full transition-all active:scale-95"
            title="Settings"
            active-class="bg-gray-200 text-[#143d2e]" 
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z" />
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          </router-link>

          <button 
            @click="handleLogout"
            class="p-2 text-red-400 hover:text-red-600 hover:bg-red-50 rounded-full transition-colors cursor-pointer"
            title="Logout"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9" />
            </svg>
          </button>

        </div>
      </div>
    </header>

    <main class="flex-1 w-full max-w-7xl mx-auto p-4 md:p-8 flex flex-col overflow-y-auto relative">
      <slot></slot>
    </main>

    <footer class="flex-none text-center py-4 text-xs text-gray-400 bg-[#f5f5f5]">
      &copy; {{ new Date().getFullYear() }} Habi Jaya System
    </footer>
  </div>
</template>