<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const isSidebarOpen = ref(false)
const isCollapsed = ref(false)
const route = useRoute()
const authStore = useAuthStore()

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

const handleLogout = async () => {
  isSidebarOpen.value = false
  await authStore.logout()
}

const displayName = computed(() => {
  return authStore.user?.user_metadata?.full_name || authStore.user?.email?.split('@')[0] || 'Superadmin'
})

const menuItems = [
  {
    name: 'Dashboard',
    route: '/master/dashboard',
    iconPath: 'M3.75 6A2.25 2.25 0 016 3.75h2.25A2.25 2.25 0 0110.5 6v2.25a2.25 2.25 0 01-2.25 2.25H6a2.25 2.25 0 01-2.25-2.25V6zM3.75 15.75A2.25 2.25 0 016 13.5h2.25a2.25 2.25 0 012.25 2.25V18a2.25 2.25 0 01-2.25 2.25H6A2.25 2.25 0 013.75 18v-2.25zM13.5 6a2.25 2.25 0 012.25-2.25H18A2.25 2.25 0 0120.25 6v2.25A2.25 2.25 0 0118 10.5h-2.25a2.25 2.25 0 01-2.25-2.25V6zM13.5 15.75a2.25 2.25 0 012.25-2.25H18a2.25 2.25 0 012.25 2.25V18A2.25 2.25 0 0118 20.25h-2.25A2.25 2.25 0 0113.5 18v-2.25z'
  },
  {
    name: 'Riwayat Transaksi',
    route: '/master/history',
    iconPath: 'M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z'
  },
  {
    name: 'Transaksi Ditolak',
    route: '/master/repeated',
    iconPath: 'M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z'
  },
  {
    name: 'Laporan',
    route: '/master/analytics',
    iconPath: 'M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z'
  },
  {
    name: 'Kelola Operator',
    route: '/master/team',
    iconPath: 'M18 18.72a9.094 9.094 0 003.741-.479 3 3 0 00-4.682-2.72m.94 3.198l.001.031c0 .225-.012.447-.037.666A11.944 11.944 0 0112 21c-2.17 0-4.207-.576-5.963-1.584A6.062 6.062 0 016 18.719m12 0a5.971 5.971 0 00-.941-3.197m0 0A5.995 5.995 0 0012 12.75a5.995 5.995 0 00-5.058 2.772m0 0a3 3 0 00-4.681 2.72 8.986 8.986 0 003.74.477m.94-3.197a5.971 5.971 0 00-.94 3.197M15 6.75a3 3 0 11-6 0 3 3 0 016 0zm6 3a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0zm-13.5 0a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0z'
  },
]
</script>

<template>
  <div class="h-screen w-full bg-[#f5f5f5] font-sans text-gray-800 flex flex-col xl:flex-row overflow-hidden relative">

    <!-- DESKTOP SIDEBAR (xl:flex hidden on < xl) -->
    <aside
      class="hidden xl:flex flex-col h-full overflow-y-auto hide-scrollbar flex-none overflow-x-hidden relative bg-gradient-to-b from-[#143d2e] via-[#1b4d3a] to-[#256a50] border-r border-white/10 transition-all duration-300 ease-in-out"
      :class="isCollapsed ? 'w-20' : 'w-64'"
    >
      <div class="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full blur-3xl -translate-y-20 translate-x-20 pointer-events-none"></div>

      <!-- Desktop Logo Header -->
      <div class="flex items-center justify-between px-4 py-5 border-b border-white/10 flex-none transition-all duration-300 overflow-hidden whitespace-nowrap z-10">
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
            <h1 class="font-black text-lg tracking-tight text-white leading-none">FuelGuard</h1>
            <p class="text-[10px] font-bold text-green-300 uppercase tracking-widest mt-0.5">Master Management</p>
          </div>
        </div>
      </div>

      <!-- Desktop Navigation Menu -->
      <nav class="flex-1 px-3 py-4 space-y-1.5 overflow-y-auto hide-scrollbar overflow-x-hidden">
        <router-link
          v-for="item in menuItems"
          :key="item.name"
          :to="item.route"
          class="flex items-center px-3.5 py-3 rounded-2xl transition-all duration-300 ease-in-out group cursor-pointer overflow-hidden whitespace-nowrap"
          :class="[
            route.path === item.route ? 'bg-white/15 text-white font-bold shadow-lg shadow-black/10' : 'text-green-200/70 hover:bg-white/10 hover:text-white font-medium'
          ]"
          :title="isCollapsed ? item.name : ''"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="w-5 h-5 flex-shrink-0">
            <path stroke-linecap="round" stroke-linejoin="round" :d="item.iconPath" />
          </svg>
          <span
            class="text-sm tracking-tight truncate transition-all duration-300 ease-in-out overflow-hidden"
            :class="isCollapsed ? 'opacity-0 max-w-0 ml-0' : 'opacity-100 max-w-xs ml-3'"
          >
            {{ item.name }}
          </span>
        </router-link>

        <router-link
          to="/master/settings"
          class="flex items-center px-3.5 py-3 rounded-2xl transition-all duration-300 ease-in-out group cursor-pointer overflow-hidden whitespace-nowrap"
          :class="[
            route.path.includes('/master/settings') ? 'bg-white/15 text-white font-bold shadow-lg' : 'text-green-200/70 hover:bg-white/10 hover:text-white font-medium'
          ]"
          :title="isCollapsed ? 'Pengaturan' : ''"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="w-5 h-5 flex-shrink-0">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z" />
            <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          <span
            class="text-sm tracking-tight truncate transition-all duration-300 ease-in-out overflow-hidden"
            :class="isCollapsed ? 'opacity-0 max-w-0 ml-0' : 'opacity-100 max-w-xs ml-3'"
          >
            Pengaturan
          </span>
        </router-link>
      </nav>

      <!-- Desktop Logout Button -->
      <div class="p-3 border-t border-white/10 flex-none overflow-hidden whitespace-nowrap">
        <button
          @click="handleLogout"
          class="w-full flex items-center px-3.5 py-3 rounded-xl bg-red-500/15 hover:bg-red-500/25 border border-red-500/30 text-red-300 hover:text-red-200 font-bold text-xs tracking-wide transition-all duration-300 ease-in-out shadow-sm active:scale-98 cursor-pointer overflow-hidden"
          :title="isCollapsed ? 'Keluar Sesi' : ''"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 flex-shrink-0">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9" />
          </svg>
          <span
            class="text-xs font-bold truncate transition-all duration-300 ease-in-out overflow-hidden"
            :class="isCollapsed ? 'opacity-0 max-w-0 ml-0' : 'opacity-100 max-w-xs ml-3'"
          >
            Keluar Sesi
          </span>
        </button>
      </div>
    </aside>

    <!-- MOBILE & TABLET TOP HEADER BAR (Solid Flat Rectangular Navbar) -->
    <header class="xl:hidden flex-none w-full bg-white border-b border-gray-200 px-4 sm:px-6 h-16 flex items-center justify-between shadow-xs z-40">
      <!-- Logo & Brand (Clickable to open drawer) -->
      <div @click="isSidebarOpen = true" class="flex items-center gap-3 cursor-pointer group select-none">
        <div class="w-10 h-10 rounded-2xl bg-gradient-to-br from-[#143d2e] via-[#1b4d3a] to-[#256a50] flex items-center justify-center p-2 shadow-md shadow-emerald-950/20 group-hover:scale-105 transition-transform border border-white/10">
          <img src="@/assets/fuelguard_logo.png" alt="FuelGuard Logo" class="w-full h-full object-contain brightness-0 invert" />
        </div>
        <div>
          <h1 class="font-black text-lg tracking-tight text-[#143d2e] leading-none">FuelGuard</h1>
          <p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mt-0.5">Master Management</p>
        </div>
      </div>

      <!-- Mobile Hamburger Button -->
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

    <!-- TELEPORTED MOBILE DRAWER OVERLAY (Operator-style exact smooth slide animation) -->
    <Teleport to="body">
      <!-- Backdrop overlay with fade transition -->
      <Transition
        enter-active-class="transition-opacity duration-300 ease-out"
        enter-from-class="opacity-0"
        enter-to-class="opacity-100"
        leave-active-class="transition-opacity duration-300 ease-in"
        leave-from-class="opacity-100"
        leave-to-class="opacity-0"
      >
        <div
          v-if="isSidebarOpen"
          @click="isSidebarOpen = false"
          class="fixed inset-0 bg-slate-900/60 backdrop-blur-xs z-[999] xl:hidden"
        ></div>
      </Transition>

      <!-- Mobile Drawer Aside always in DOM for CSS transition-transform duration-300 ease-out -->
      <aside
        class="fixed top-0 left-0 bottom-0 h-full w-72 bg-gradient-to-b from-[#143d2e] via-[#1b4d3a] to-[#256a50] z-[1000] xl:hidden shadow-2xl flex flex-col justify-between transition-transform duration-300 ease-out border-r border-white/10 text-white overflow-hidden"
        :class="isSidebarOpen ? 'translate-x-0' : '-translate-x-full'"
      >
        <div class="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full blur-3xl -translate-y-20 translate-x-20 pointer-events-none"></div>

        <!-- Mobile Drawer Header -->
        <div class="p-5 border-b border-white/10 flex items-center justify-between z-10">
          <div class="flex items-center gap-3">
            <div class="w-9 h-9 rounded-xl bg-gradient-to-br from-[#143d2e] via-[#1b4d3a] to-[#256a50] flex items-center justify-center p-1.5 shadow-xs border border-white/10">
              <img src="@/assets/fuelguard_logo.png" alt="FuelGuard Logo" class="w-full h-full object-contain brightness-0 invert" />
            </div>
            <div>
              <h2 class="font-black text-base text-white">FuelGuard</h2>
              <p class="text-[9px] font-bold text-green-300 uppercase tracking-widest">Master Management</p>
            </div>
          </div>

          <button @click="isSidebarOpen = false" class="text-green-300/60 hover:text-white p-1 cursor-pointer">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Mobile Drawer Menu -->
        <nav class="flex-1 p-4 space-y-2 overflow-y-auto z-10">
          <router-link
            v-for="item in menuItems"
            :key="item.name"
            :to="item.route"
            @click="isSidebarOpen = false"
            class="flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all text-green-200/70 hover:bg-white/10 hover:text-white"
            active-class="bg-white/15 text-white font-extrabold shadow-lg shadow-black/10 border border-white/10"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" :d="item.iconPath" />
            </svg>
            <span>{{ item.name }}</span>
          </router-link>

          <router-link
            to="/master/settings"
            @click="isSidebarOpen = false"
            class="flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all text-green-200/70 hover:bg-white/10 hover:text-white"
            active-class="bg-white/15 text-white font-extrabold shadow-lg shadow-black/10 border border-white/10"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z" />
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <span>Pengaturan</span>
          </router-link>
        </nav>

        <!-- Mobile Drawer Bottom Logout -->
        <div class="p-4 border-t border-white/10 z-10">
          <button
            @click="handleLogout"
            class="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-red-500/15 hover:bg-red-500/25 border border-red-500/30 text-red-300 hover:text-red-200 font-bold text-xs transition-colors cursor-pointer"
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
    <main class="flex-1 w-full p-4 md:p-6 lg:p-8 overflow-y-auto relative bg-[#f5f5f5] hide-scrollbar">
      <slot></slot>
    </main>

  </div>
</template>
