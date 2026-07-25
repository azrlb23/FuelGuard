<script setup>
import { usePresence } from '@/composables/usePresence'

defineProps({
  members: Array,
  loading: Boolean
})

const { onlineUserIds } = usePresence()

const getRoleBadge = (role) => {
  // Update fallback ke nuansa Emerald agar tidak abu-abu kusam
  if (!role) return 'bg-emerald-50 text-emerald-600 border-emerald-200'
  return role.toLowerCase() === 'manajer' 
    ? 'bg-purple-50 text-purple-700 border-purple-200 shadow-sm shadow-purple-100' 
    : 'bg-blue-50 text-blue-700 border-blue-200 shadow-sm shadow-blue-100'
}

const isUserOnline = (userId) => {
  return onlineUserIds.value.has(userId)
}

const formatDate = (dateString) => {
  if (!dateString) return 'Belum Login'
  return new Date(dateString).toLocaleDateString('id-ID', {
    day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit'
  })
}
</script>

<template>
  <div class="w-full">
    
    <div class="block md:hidden space-y-3 p-3">
      
      <div v-if="loading" class="py-10 text-center">
        <span class="loading loading-dots loading-md text-emerald-400"></span>
      </div>

      <div v-else-if="members.length === 0" class="py-10 text-center text-emerald-600/50 italic">
        Tidak ada data tim.
      </div>

      <div 
        v-else
        v-for="member in members" 
        :key="member.id" 
        class="bg-white rounded-2xl p-4 border border-emerald-100 shadow-sm flex flex-col gap-3 relative overflow-hidden"
      >
        <div class="absolute left-0 top-0 bottom-0 w-1.5" 
             :class="member.role === 'manajer' ? 'bg-purple-500' : 'bg-blue-500'">
        </div>

        <div class="flex items-center gap-3 pl-2">
          <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-50 to-emerald-100 flex items-center justify-center font-bold text-emerald-700 border border-emerald-200/50 text-sm shadow-sm">
            {{ member.email?.charAt(0).toUpperCase() || '?' }}
          </div>
          <div class="min-w-0 flex-1">
            <p class="font-bold text-emerald-950 truncate text-sm">{{ member.email?.split('@')[0] }}</p>
            <p class="text-xs text-emerald-600/70 truncate">{{ member.email }}</p>
          </div>
          
          <div class="flex items-center gap-1.5 bg-emerald-50/50 px-2 py-1 rounded-full border border-emerald-100">
            <span 
              class="w-2 h-2 rounded-full transition-all duration-300" 
              :class="isUserOnline(member.id) ? 'bg-emerald-500 shadow-[0_0_6px_rgba(16,185,129,0.6)]' : 'bg-slate-300'"
            ></span>
            <span 
              class="text-[10px] font-bold uppercase transition-colors"
              :class="isUserOnline(member.id) ? 'text-emerald-700' : 'text-slate-400'"
            >
              {{ isUserOnline(member.id) ? 'Online' : 'Offline' }}
            </span>
          </div>
        </div>

        <div class="h-px bg-emerald-50 w-full ml-2"></div>

        <div class="flex justify-between items-center pl-2">
          <span 
            class="px-2.5 py-1 rounded-lg text-xs font-bold border capitalize"
            :class="getRoleBadge(member.role)"
          >
            {{ member.role || 'No Role' }}
          </span>
          
          <div class="text-right">
            <p class="text-[10px] text-emerald-400 font-bold uppercase tracking-wider mb-0.5">Last Login</p>
            <span class="inline-block px-2 py-0.5 bg-emerald-50 rounded text-[11px] font-medium text-emerald-700 border border-emerald-100">
              {{ formatDate(member.last_sign_in_at) }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <div class="hidden md:block overflow-x-auto">
      <table class="w-full text-left border-collapse">
        <thead class="bg-emerald-50/90 backdrop-blur-sm sticky top-0 z-10">
          <tr class="text-emerald-700/70 text-xs font-bold uppercase tracking-wider border-b border-emerald-100">
            <th class="py-5 pl-6">User / Email</th>
            <th class="py-5">Role Access</th>
            <th class="py-5">Status</th>
            <th class="py-5 pr-6 text-right">Terakhir Login</th>
          </tr>
        </thead>
        
        <tbody class="text-sm divide-y divide-emerald-50 bg-white">
          <tr v-if="loading">
            <td colspan="4" class="py-12 text-center text-emerald-400">
              <span class="loading loading-dots loading-lg text-emerald-500"></span>
            </td>
          </tr>
          
          <tr v-else-if="members.length === 0">
            <td colspan="4" class="py-12 text-center text-emerald-600/60 italic">
              Tidak ada data tim ditemukan.
            </td>
          </tr>

          <tr 
            v-for="member in members" 
            :key="member.id" 
            class="hover:bg-emerald-50/40 transition-colors group"
          >
            <td class="py-4 pl-6">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-50 to-emerald-100 flex items-center justify-center font-bold text-emerald-700 border border-emerald-200/50 shadow-sm group-hover:scale-105 transition-transform duration-300">
                  {{ member.email?.charAt(0).toUpperCase() || '?' }}
                </div>
                <div class="min-w-0">
                  <p class="font-bold text-emerald-950 truncate">{{ member.email?.split('@')[0] }}</p>
                  <p class="text-xs text-emerald-600/60 font-medium truncate">{{ member.email }}</p>
                </div>
              </div>
            </td>
            
            <td class="py-4">
              <span 
                class="px-3 py-1 rounded-full text-xs font-bold border capitalize inline-flex items-center gap-1"
                :class="getRoleBadge(member.role)"
              >
                {{ member.role || 'No Role' }}
              </span>
            </td>

            <td class="py-4">
              <div class="flex items-center gap-2">
                <span class="relative flex h-2.5 w-2.5">
                  <span v-if="isUserOnline(member.id)" class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                  <span 
                    class="relative inline-flex rounded-full h-2.5 w-2.5 transition-colors duration-300" 
                    :class="isUserOnline(member.id) ? 'bg-emerald-500' : 'bg-slate-300'"
                  ></span>
                </span>
                <span 
                  class="font-medium capitalize text-xs transition-colors"
                  :class="isUserOnline(member.id) ? 'text-emerald-700 font-bold' : 'text-slate-400'"
                >
                  {{ isUserOnline(member.id) ? 'Online' : 'Offline' }}
                </span>
              </div>
            </td>

            <td class="py-4 pr-6 text-right">
              <span class="inline-flex items-center px-2.5 py-1 rounded-md bg-emerald-50/50 border border-emerald-100 text-emerald-700 text-[11px] font-medium tracking-wide shadow-sm">
                {{ formatDate(member.last_sign_in_at) }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

  </div>
</template>