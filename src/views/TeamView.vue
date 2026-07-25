<script setup>
import { useTeam } from '@/composables/useTeam'
import TeamTable from '@/components/team/TeamTable.vue'

const { teamMembers, loading } = useTeam()
</script>

<template>
  <div class="flex flex-col gap-6 bg-[#f8fafc] lg:bg-transparent pb-24">
    
    <div class="flex-none px-6 pt-6 md:px-8 md:pt-8 flex flex-col md:flex-row md:items-end justify-between gap-4 z-10">
      <div>
        <h2 class="text-3xl md:text-4xl font-extrabold text-[#1e293b] tracking-tight mb-2">
          Team Management
        </h2>
        <p class="text-slate-500 font-medium text-sm md:text-base max-w-2xl">
          Daftar akun yang memiliki akses operasional ke sistem Habi Jaya.
        </p>
      </div>
    </div>

    <div class="px-4 md:px-8">
      <div class="bg-white rounded-[2.5rem] border border-slate-100 shadow-xl shadow-slate-200/50 overflow-hidden">
        <TeamTable :members="teamMembers" :loading="loading" />
      </div>
    </div>

  </div>
</template>