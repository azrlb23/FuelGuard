<script setup>
import { ref, computed, onMounted, watch } from 'vue'

import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const isSidebarOpen = ref(false)
const isCollapsed = ref(false)
const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const globalSearch = ref('')

// Close mobile sidebar on route navigation
watch(() => route.path, () => {
  isSidebarOpen.value = false
})

onMounted(() => {
  if (typeof window !== 'undefined' && window.innerWidth >= 1280) {
    const savedState = localStorage.getItem('fuelguard_sidebar_collapsed')
    if (savedState !== null) {
      isCollapsed.value = savedState === 'true'
    }
  }
})

const toggleCollapse = () => {
  if (typeof window !== 'undefined' && window.innerWidth >= 1280) {
    isCollapsed.value = !isCollapsed.value
    localStorage.setItem('fuelguard_sidebar_collapsed', isCollapsed.value)
  }
}

const userEmail = computed(() => authStore.user?.email || 'User')
const userRole = computed(() => authStore.role || 'Administrator')
const userName = computed(() => userEmail.value.split('@')[0])

const handleLogout = async () => {
  isSidebarOpen.value = false
  await authStore.logout()
}

const handleGlobalSearch = () => {
  if (globalSearch.value.trim()) {
    router.push({ path: '/riwayat', query: { q: globalSearch.value.trim() } })
  }
}

const navItems = [
  {
    name: 'Dashboard',
    route: '/dashboard',
    iconPath: 'M3.75 6A2.25 2.25 0 016 3.75h2.25A2.25 2.25 0 0110.5 6v2.25a2.25 2.25 0 01-2.25 2.25H6a2.25 2.25 0 01-2.25-2.25V6zM3.75 15.75A2.25 2.25 0 016 13.5h2.25a2.25 2.25 0 012.25 2.25V18a2.25 2.25 0 01-2.25 2.25H6A2.25 2.25 0 013.75 18v-2.25zM13.5 6a2.25 2.25 0 012.25-2.25H18A2.25 2.25 0 0120.25 6v2.25A2.25 2.25 0 0118 10.5h-2.25a2.25 2.25 0 01-2.25-2.25V6zM13.5 15.75a2.25 2.25 0 012.25-2.25H18a2.25 2.25 0 012.25 2.25V18A2.25 2.25 0 0118 20.25h-2.25A2.25 2.25 0 0113.5 18v-2.25z'
  },
  {
    name: 'Pengisian BBM',
    route: '/pengisian',
    iconPath: 'M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z'
  },
  {
    name: 'Audit Pengetap',
    route: '/pengetap',
    iconPath: 'M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z'
  },
  {
    name: 'Riwayat Transaksi',
    route: '/riwayat',
    iconPath: 'M8.25 6.75h12M8.25 12h12m-12 5.25h12M3.75 6.75h.008v.008H3.75V6.75Zm0 5.25h.008v.008H3.75V12Zm0 5.25h.008v.008H3.75v-.008Z'
  },
  {
    name: 'Laporan',
    route: '/laporan',
    iconPath: 'M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z'
  },
]
</script>

<template>
  <div class="h-screen w-full bg-[#f5f5f5] font-sans text-gray-800 flex flex-col xl:flex-row overflow-hidden relative">

    <!-- DESKTOP SIDEBAR -->
    <aside
      class="hidden xl:flex flex-col h-full bg-[#f5f5f5] py-6 px-4 border-r border-gray-200/50 flex-none overflow-y-auto hide-scrollbar overflow-x-hidden transition-all duration-300 ease-in-out"
      :class="isCollapsed ? 'w-20' : 'w-64'"
    >
        <div class="mb-8 flex items-center justify-between px-1 flex-none transition-all duration-300 overflow-hidden whitespace-nowrap">
            <div 
              @click="toggleCollapse" 
              class="flex items-center cursor-pointer group overflow-hidden select-none" 
              :title="isCollapsed ? 'Perluas Sidebar' : 'Ciutkan Sidebar'"
            >
              <div class="w-10 h-10 rounded-2xl bg-gradient-to-br from-[#143d2e] via-[#1b4d3a] to-[#256a50] flex items-center justify-center p-2 shadow-md shadow-emerald-950/20 group-hover:scale-105 transition-transform border border-white/10 flex-shrink-0">
                <img src="@/assets/fuelguard_logo.png" alt="FuelGuard Logo" class="w-full h-full object-contain brightness-0 invert" />
              </div>
              <div 
                class="transition-all duration-300 ease-in-out overflow-hidden"
                :class="isCollapsed ? 'opacity-0 max-w-0 ml-0' : 'opacity-100 max-w-xs ml-3'"
              >
                <h1 class="font-black text-lg tracking-tight text-[#143d2e] leading-none">FuelGuard</h1>
                <p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mt-0.5">Admin Console</p>
              </div>
            </div>
        </div>

        <nav class="flex-1 space-y-2">
            <router-link
              v-for="item in navItems"
              :key="item.name"
              :to="item.route"
              class="flex items-center px-4 py-3 rounded-2xl font-medium transition-all duration-300 ease-in-out group cursor-pointer overflow-hidden whitespace-nowrap"
              :class="[
                route.path === item.route 
                  ? 'bg-gradient-to-r from-[#143d2e] via-[#1b4d3a] to-[#256a50] text-white shadow-lg shadow-green-900/20 font-bold' 
                  : 'text-gray-500 hover:text-[#143d2e] hover:bg-gray-200/50'
              ]"
              :title="isCollapsed ? item.name : ''"
            >
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="w-6 h-6 flex-shrink-0">
                <path stroke-linecap="round" stroke-linejoin="round" :d="item.iconPath" />
              </svg>

              <span 
                class="text-sm tracking-tight truncate transition-all duration-300 ease-in-out overflow-hidden"
                :class="isCollapsed ? 'opacity-0 max-w-0 ml-0' : 'opacity-100 max-w-xs ml-4'"
              >
                {{ item.name }}
              </span>
            </router-link>

            <router-link 
              to="/settings" 
              class="flex items-center px-4 py-3 rounded-2xl font-medium transition-all duration-300 ease-in-out group cursor-pointer overflow-hidden whitespace-nowrap"
              :class="[
                route.path === '/settings' 
                  ? 'bg-gradient-to-r from-[#143d2e] via-[#1b4d3a] to-[#256a50] text-white shadow-lg shadow-green-900/20 font-bold' 
                  : 'text-gray-500 hover:text-[#143d2e] hover:bg-gray-200/50'
              ]"
              :title="isCollapsed ? 'Settings' : ''"
            >
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6 flex-shrink-0">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z" />
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              <span 
                class="text-sm tracking-tight truncate transition-all duration-300 ease-in-out overflow-hidden"
                :class="isCollapsed ? 'opacity-0 max-w-0 ml-0' : 'opacity-100 max-w-xs ml-4'"
              >
                Settings
              </span>
            </router-link>

            <button 
              @click="handleLogout" 
              class="w-full flex items-center px-4 py-3 rounded-2xl font-medium text-red-500 hover:bg-red-50 text-left cursor-pointer transition-all duration-300 ease-in-out overflow-hidden whitespace-nowrap"
            >
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6 flex-shrink-0">
                  <path d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9" />
              </svg>
              <span 
                class="text-sm tracking-tight truncate transition-all duration-300 ease-in-out overflow-hidden"
                :class="isCollapsed ? 'opacity-0 max-w-0 ml-0' : 'opacity-100 max-w-xs ml-4'"
              >
                Logout
              </span>
            </button>
        </nav>
    </aside>

    <!-- MOBILE & TABLET TOP HEADER BAR (Solid Flat Rectangular Navbar) -->
    <header class="xl:hidden flex-none w-full bg-white border-b border-gray-200 px-4 sm:px-6 h-16 flex items-center justify-between shadow-xs z-40">
      <div @click="isSidebarOpen = true" class="flex items-center gap-3 cursor-pointer group select-none">
        <div class="w-10 h-10 rounded-2xl bg-gradient-to-br from-[#143d2e] via-[#1b4d3a] to-[#256a50] flex items-center justify-center p-2 shadow-md shadow-emerald-950/20 group-hover:scale-105 transition-transform border border-white/10">
          <img src="@/assets/fuelguard_logo.png" alt="FuelGuard Logo" class="w-full h-full object-contain brightness-0 invert" />
        </div>
        <div>
          <h1 class="font-black text-lg tracking-tight text-[#143d2e] leading-none">FuelGuard</h1>
          <p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mt-0.5">Admin Console</p>
        </div>
      </div>

      <button 
        @click="isSidebarOpen = !isSidebarOpen"
        class="w-10 h-10 rounded-2xl bg-gray-100 hover:bg-gray-200 text-[#143d2e] flex items-center justify-center transition-colors cursor-pointer"
        aria-label="Toggle Navigation Menu"
      >
        <svg v-if="!isSidebarOpen" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-6 h-6">
          <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
        </svg>
        <svg v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-6 h-6">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </header>

    <!-- TELEPORTED MOBILE DRAWER OVERLAY -->
    <Teleport to="body">
      <div 
        v-if="isSidebarOpen" 
        @click="isSidebarOpen = false"
        class="fixed inset-0 bg-slate-900/60 backdrop-blur-xs z-[999] xl:hidden transition-opacity"
      ></div>

      <aside
        class="fixed top-0 left-0 bottom-0 w-72 bg-white z-[1000] xl:hidden shadow-2xl flex flex-col justify-between transition-transform duration-300 ease-out border-r border-gray-100"
        :class="isSidebarOpen ? 'translate-x-0' : '-translate-x-full'"
      >
        <div class="p-5 border-b border-gray-100 flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="w-9 h-9 rounded-xl bg-gradient-to-br from-[#143d2e] via-[#1b4d3a] to-[#256a50] flex items-center justify-center p-1.5 shadow-xs border border-white/10">
              <img src="@/assets/fuelguard_logo.png" alt="FuelGuard Logo" class="w-full h-full object-contain brightness-0 invert" />
            </div>
            <div>
              <h2 class="font-black text-base text-[#143d2e]">FuelGuard</h2>
              <p class="text-[9px] font-bold text-gray-400 uppercase tracking-widest">Admin Console</p>
            </div>
          </div>
          <button @click="isSidebarOpen = false" class="text-gray-400 hover:text-gray-700 p-1">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div class="p-4 border-b border-gray-100 bg-emerald-50/50">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-full bg-gradient-to-br from-[#143d2e] to-[#1e5c45] text-white flex items-center justify-center font-black text-sm shadow-xs">
              {{ userName.charAt(0).toUpperCase() }}
            </div>
            <div>
              <p class="text-xs font-black uppercase text-[#143d2e]">{{ userName }}</p>
              <p class="text-[10px] font-bold uppercase text-emerald-700">{{ userRole }}</p>
            </div>
          </div>
        </div>

        <nav class="flex-1 p-4 space-y-2 overflow-y-auto">
          <router-link
            v-for="item in navItems"
            :key="item.name"
            :to="item.route"
            @click="isSidebarOpen = false"
            class="flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all text-gray-700 hover:bg-gray-100"
            active-class="bg-gradient-to-r from-[#143d2e] via-[#1b4d3a] to-[#256a50] text-white shadow-md"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" :d="item.iconPath" />
            </svg>
            <span>{{ item.name }}</span>
          </router-link>

          <router-link
            to="/settings"
            @click="isSidebarOpen = false"
            class="flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all text-gray-700 hover:bg-gray-100"
            active-class="bg-gradient-to-r from-[#143d2e] via-[#1b4d3a] to-[#256a50] text-white shadow-md"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z" />
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <span>Pengaturan</span>
          </router-link>
        </nav>

        <div class="p-4 border-t border-gray-100">
          <button
            @click="handleLogout"
            class="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-red-50 hover:bg-red-100 text-red-600 font-bold text-xs transition-colors cursor-pointer"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9" />
            </svg>
            <span>Keluar Sesi</span>
          </button>
        </div>
      </aside>
    </Teleport>

    <!-- Main Workspace Content -->
    <div class="flex-1 flex flex-col h-full overflow-hidden relative w-full">

      <header class="flex-none flex items-center justify-between p-4 md:px-8 md:py-6 bg-[#f5f5f5] z-10 gap-4">

        <div class="hidden md:flex items-center bg-gradient-to-r from-[#143d2e] to-[#1e5c45] rounded-full px-4 py-2 md:px-6 md:py-3 flex-1 max-w-md shadow-lg shadow-green-900/20 transition-all mx-auto lg:mx-0">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5 text-white/70 mr-3">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
          <input
            v-model="globalSearch"
            @keyup.enter="handleGlobalSearch"
            type="text"
            placeholder="Cari Plat Nomor..."
            class="bg-transparent text-white placeholder-white/70 outline-none w-full text-sm font-medium"
          />
        </div>

        <div class="flex items-center gap-3 flex-none ml-auto">
          <div
            @click="router.push('/settings')"
            class="flex items-center gap-3 bg-white pl-1.5 pr-4 py-1.5 rounded-full border border-gray-200 shadow-sm hover:shadow-md transition-all cursor-pointer active:scale-95 select-none"
          >
            <div class="w-9 h-9 bg-gradient-to-br from-[#143d2e] to-[#258f62] rounded-full flex items-center justify-center text-white font-bold text-sm shadow-inner ring-2 ring-white">
               {{ userName.charAt(0).toUpperCase() }}
            </div>

            <div class="hidden xs:block text-left">
              <p class="text-sm font-bold leading-tight text-gray-800 capitalize">{{ userName }}</p>
              <p class="text-[10px] font-bold text-gray-400 uppercase tracking-wide">{{ userRole }}</p>
            </div>

            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-gray-400 hidden sm:block">
              <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
            </svg>
          </div>
        </div>

      </header>

      <main class="flex-1 overflow-y-auto p-4 md:p-6 lg:p-8 relative hide-scrollbar">
        <slot></slot>
      </main>

    </div>
  </div>
</template>
