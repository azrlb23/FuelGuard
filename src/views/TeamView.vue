<script setup>
import { ref } from 'vue'
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
  toggleOperatorStatus,
  resetOperatorAccountPassword
} = useTeam()

const activeTab = ref('operators') // 'operators' | 'accounts'

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
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
      <div>
        <h1 class="text-3xl md:text-4xl font-extrabold text-[#143d2e] tracking-tight">
          Kelola Operator
        </h1>
      </div>

      <div class="bg-[#143d2e] p-1.5 rounded-full flex shadow-md self-start md:self-auto">
        <button
          @click="activeTab = 'operators'"
          class="px-4 py-2 md:px-5 md:py-2 rounded-full text-xs md:text-sm font-medium transition-all duration-200 cursor-pointer select-none"
          :class="activeTab === 'operators' ? 'bg-white/20 border border-white/30 text-white shadow-sm font-bold' : 'text-white/70 hover:text-white border border-transparent'"
        >
          Profil Operator Shift ({{ teamMembers.length }})
        </button>
        <button
          @click="activeTab = 'accounts'"
          class="px-4 py-2 md:px-5 md:py-2 rounded-full text-xs md:text-sm font-medium transition-all duration-200 cursor-pointer select-none"
          :class="activeTab === 'accounts' ? 'bg-white/20 border border-white/30 text-white shadow-sm font-bold' : 'text-white/70 hover:text-white border border-transparent'"
        >
          Akun Login SPBU ({{ spbuAccounts.length }})
        </button>
      </div>
    </div>

    <!-- Row 2: Team Table & Actions Container -->
    <TeamTable
      :members="teamMembers"
      :accounts="spbuAccounts"
      :spbuList="spbuList"
      :loading="loading"
      :isSubmitting="isSubmitting"
      :resetAccountPassword="resetOperatorAccountPassword"
      v-model:searchQuery="searchQuery"
      v-model:selectedSpbuId="selectedSpbuId"
      v-model:activeTab="activeTab"
      @createOperator="handleCreateOperator"
      @updateOperator="handleUpdateOperator"
      @toggleStatus="handleToggleStatus"
    />

  </div>
</template>
