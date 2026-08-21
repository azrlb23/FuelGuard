<script setup>
import { ref, onMounted, onUnmounted, computed, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { usePresence } from '@/composables/common/usePresence'
import { useRoute } from 'vue-router'
import MasterLayout from '@/layouts/MasterLayout.vue'
import OperatorLayout from '@/layouts/OperatorLayout.vue'
import DomainMigrationModal from '@/components/common/DomainMigrationModal.vue'

const authStore = useAuthStore()
const { initPresence, leavePresence } = usePresence()
const route = useRoute()

const isOldDomain = ref(false)

const TARGET_DOMAIN = 'fuelguard.id'

onMounted(() => {
  if (typeof window !== 'undefined') {
    const hostname = window.location.hostname.toLowerCase()
    if (hostname !== TARGET_DOMAIN && hostname !== `www.${TARGET_DOMAIN}`) {
      isOldDomain.value = true
    }
  }

  if (!isOldDomain.value && authStore.user) {
    initPresence()
  }
})

watch(() => authStore.user, (newUser) => {
  if (isOldDomain.value) return
  if (newUser) {
    initPresence()
  } else {
    leavePresence()
  }
})

onUnmounted(() => {
  if (!isOldDomain.value) {
    leavePresence()
  }
})

const layout = computed(() => route.meta.layout || 'auth')
</script>

<template>
  <!-- Jika di domain lama, HANYA tampilkan Modal Migrasi. Jangan mount RouterView/Form Login sama sekali! -->
  <DomainMigrationModal v-if="isOldDomain" />

  <!-- Jika di domain resmi fuelguard.id, jalankan aplikasi secara normal -->
  <template v-else>
    <MasterLayout v-if="layout === 'master'">
      <RouterView v-slot="{ Component }">
        <Transition name="content" mode="out-in">
          <component :is="Component" :key="route.fullPath" />
        </Transition>
      </RouterView>
    </MasterLayout>

    <OperatorLayout v-else-if="layout === 'operator'">
      <RouterView v-slot="{ Component }">
        <Transition name="content" mode="out-in">
          <component :is="Component" :key="route.fullPath" />
        </Transition>
      </RouterView>
    </OperatorLayout>

    <RouterView v-else v-slot="{ Component }">
      <Transition name="content" mode="out-in">
        <component :is="Component" />
      </Transition>
    </RouterView>
  </template>
</template>
