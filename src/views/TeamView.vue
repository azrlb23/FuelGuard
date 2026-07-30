<script setup>
import { useTeam } from '@/composables/useTeam'
import TeamTable from '@/components/team/TeamTable.vue'

const {
  teamMembers,
  spbuAccounts,
  spbuList,
  loading,
  isSubmitting,
  searchQuery,
  selectedSpbuId,
  createOperator,
  updateOperator,
  toggleOperatorStatus
} = useTeam()

const handleCreateOperator = async (payload) => {
  await createOperator(payload)
}

const handleUpdateOperator = async (id, payload) => {
  await updateOperator(id, payload)
}

const handleToggleStatus = async (id) => {
  await toggleOperatorStatus(id)
}
</script>

<template>
  <div class="space-y-6 pb-12 max-w-7xl mx-auto">

    <!-- Page Header & Summary Section -->
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
      <div>
        <h1 class="text-2xl sm:text-3xl font-black text-[#143d2e] tracking-tight">
          Kelola Tim & Akun SPBU
        </h1>
        <p class="text-gray-500 text-xs sm:text-sm font-medium mt-1">
          Manajemen profil petugas shift operator dan akun autentikasi unit SPBU jaringan Habi Jaya
        </p>
      </div>
    </div>

    <!-- Row 2: Team Table & Actions Container -->
    <TeamTable
      :members="teamMembers"
      :accounts="spbuAccounts"
      :spbuList="spbuList"
      :loading="loading"
      :isSubmitting="isSubmitting"
      v-model:searchQuery="searchQuery"
      v-model:selectedSpbuId="selectedSpbuId"
      @createOperator="handleCreateOperator"
      @updateOperator="handleUpdateOperator"
      @toggleStatus="handleToggleStatus"
    />

  </div>
</template>
