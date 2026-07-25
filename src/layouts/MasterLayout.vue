<script setup>
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const isSidebarOpen = ref(true)
const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const globalSearch = ref('')

const userEmail = computed(() => authStore.user?.email || 'superadmin@habijaya.com')
const userName = computed(() => authStore.user?.user_metadata?.full_name || 'Super Admin')
const userRole = computed(() => authStore.role || 'Master / Superadmin')

const handleLogout = async () => {
  await authStore.logout()
}

const handleGlobalSearch = () => {
  if (globalSearch.value.trim()) {
    router.push({
      name: 'master-dashboard',
      query: { q: globalSearch.value }
    })
  }
}

const menuItems = [
  {
    name: 'Dashboard Master',
    route: '/master/dashboard',
    iconPath: 'M3.75 6A2.25 2.25 0 016 3.75h2.25A2.25 2.25 0 0110.5 6v2.25a2.25 2.25 0 01-2.25 2.25H6a2.25 2.25 0 01-2.25-2.25V6zM3.75 15.75A2.25 2.25 0 016 13.5h2.25a2.25 2.25 0 012.25 2.25V18a2.25 2.25 0 01-2.25 2.25H6A2.25 2.25 0 013.75 18v-2.25zM13.5 6a2.25 2.25 0 012.25-2.25H18A2.25 2.25 0 0120.25 6v2.25A2.25 2.25 0 0118 10.5h-2.25a2.25 2.25 0 01-2.25-2.25V6zM13.5 15.75a2.25 2.25 0 012.25-2.25H18a2.25 2.25 0 012.25 2.25V18A2.25 2.25 0 0118 20.25h-2.25A2.25 2.25 0 0113.5 18v-2.25z'
  },
  {
    name: 'History Transaksi',
    route: '/master/history',
    iconPath: 'M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z'
  },
  {
    name: 'Analisis & Laporan',
    route: '/master/analytics',
    iconPath: 'M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z'
  },
  {
    name: 'Kelola Tim & Manajer',
    route: '/master/team',
    iconPath: 'M18 18.72a9.094 9.094 0 003.741-.479 3 3 0 00-4.682-2.72m.94 3.198l.001.031c0 .225-.012.447-.037.666A11.944 11.944 0 0112 21c-2.17 0-4.207-.576-5.963-1.584A6.062 6.062 0 016 18.719m12 0a5.971 5.971 0 00-.941-3.197m0 0A5.995 5.995 0 0012 12.75a5.995 5.995 0 00-5.058 2.772m0 0a3 3 0 00-4.681 2.72 8.986 8.986 0 003.74.477m.94-3.197a5.971 5.971 0 00-.94 3.197M15 6.75a3 3 0 11-6 0 3 3 0 016 0zm6 3a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0zm-13.5 0a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0z'
  },
]
</script>

<template>
  <div class="flex h-screen w-full bg-[#f5f5f5] font-sans text-gray-800 overflow-hidden">

    <!-- Mobile Backdrop -->
    <div
      v-if="isSidebarOpen"
      class="fixed inset-0 bg-black/50 z-30 xl:hidden transition-opacity"
      @click="isSidebarOpen = false"
    ></div>

    <!-- Sidebar Master -->
    <aside
      class="fixed inset-y-0 left-0 z-40 flex flex-col transition-all duration-300 xl:static h-full overflow-y-auto hide-scrollbar shadow-2xl xl:shadow-none"
      :class="[
        isSidebarOpen ? 'w-64 translate-x-0' : '-translate-x-full xl:translate-x-0 xl:w-20'
      ]"
      style="background: linear-gradient(180deg, #0f2e23 0%, #143d2e 50%, #1a4a38 100%)"
    >
      <!-- Logo Header -->
      <div class="flex items-center gap-3 px-5 py-6 border-b border-white/10 flex-none">
        <div class="w-10 h-10 rounded-2xl flex-shrink-0 flex items-center justify-center shadow-lg" style="background: linear-gradient(135deg, #22c55e, #4ade80)">
          <img src="@/assets/HJ_dark.png" alt="Logo" class="w-6 h-6 brightness-0 invert" />
        </div>
        <div v-if="isSidebarOpen" class="transition-all">
          <h1 class="text-white font-black text-sm leading-tight tracking-tight">HABI JAYA</h1>
          <p class="text-green-400 text-[10px] font-bold uppercase tracking-wider">Master Console</p>
        </div>
        <button
          @click="isSidebarOpen = !isSidebarOpen"
          class="ml-auto text-green-300/60 hover:text-white transition-colors cursor-pointer"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
            <path stroke-linecap="round" stroke-linejoin="round" :d="isSidebarOpen ? 'M6 18L18 6M6 6l12 12' : 'M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5'" />
          </svg>
        </button>
      </div>

      <!-- Navigation -->
      <nav class="flex-1 px-3 py-4 space-y-1.5 overflow-y-auto hide-scrollbar">
        <router-link
          v-for="item in menuItems"
          :key="item.name"
          :to="item.route"
          class="flex items-center gap-3 px-3.5 py-3 rounded-2xl transition-all duration-200 group cursor-pointer"
          :class="route.path === item.route ? 'bg-white/15 text-white font-bold shadow-lg shadow-black/10' : 'text-green-200/70 hover:bg-white/10 hover:text-white font-medium'"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="w-5 h-5 flex-shrink-0">
            <path stroke-linecap="round" stroke-linejoin="round" :d="item.iconPath" />
          </svg>
          <span v-if="isSidebarOpen" class="text-sm tracking-tight truncate">{{ item.name }}</span>
          <div v-if="isSidebarOpen && route.path === item.route" class="ml-auto w-1.5 h-1.5 rounded-full bg-green-400"></div>
        </router-link>

        <div v-if="isSidebarOpen" class="pt-6 pb-2 px-3">
          <p class="text-[10px] font-bold text-green-300/50 uppercase tracking-widest">Pengaturan</p>
        </div>

        <router-link
          to="/master/settings"
          class="flex items-center gap-3 px-3.5 py-3 rounded-2xl transition-all duration-200 group cursor-pointer"
          :class="route.path.includes('/master/settings') ? 'bg-white/15 text-white font-bold shadow-lg' : 'text-green-200/70 hover:bg-white/10 hover:text-white font-medium'"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="w-5 h-5 flex-shrink-0">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z" />
            <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          <span v-if="isSidebarOpen" class="text-sm tracking-tight truncate">Pengaturan Master</span>
        </router-link>
      </nav>

      <!-- Logout Button -->
      <div class="p-3 border-t border-white/10 flex-none">
        <button
          @click="handleLogout"
          class="w-full flex items-center gap-3 px-3.5 py-3 rounded-2xl text-red-400/80 hover:bg-red-500/10 hover:text-red-400 transition-all font-medium cursor-pointer"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="w-5 h-5 flex-shrink-0">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9" />
          </svg>
          <span v-if="isSidebarOpen" class="text-sm tracking-tight">Keluar Sesi</span>
        </button>
      </div>
    </aside>

    <!-- Main Workspace -->
    <div class="flex-1 flex flex-col h-full overflow-hidden relative w-full min-w-0">

      <!-- Top Bar Header -->
      <header class="flex-none bg-[#f5f5f5] px-6 py-4 flex items-center justify-between gap-4 z-20">

        <div class="flex items-center gap-3">
          <button
            @click="isSidebarOpen = !isSidebarOpen"
            class="p-2 text-gray-500 hover:bg-gray-200/60 rounded-xl transition-colors cursor-pointer xl:hidden"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="w-6 h-6">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
            </svg>
          </button>
        </div>

        <div class="flex items-center gap-3">
          <!-- Profile Badge Pill (Matching screenshot design) -->
          <div class="flex items-center gap-2.5 p-1.5 pl-2 pr-3 bg-white rounded-full border border-gray-100 shadow-md shadow-gray-200/50 cursor-pointer hover:shadow-lg transition-all">
            <div class="w-8 h-8 bg-[#143d2e] rounded-full flex items-center justify-center text-white font-bold text-xs shadow-sm">
              M
            </div>
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-gray-400">
              <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
            </svg>
          </div>
        </div>
      </header>

      <!-- Scrollable Main Content -->
      <main class="flex-1 w-full p-4 md:p-6 lg:p-8 overflow-y-auto relative bg-[#f5f5f5] hide-scrollbar">
        <slot></slot>
      </main>

    </div>
  </div>
</template>
