<script setup>
import { onMounted, onUnmounted, computed, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { usePresence } from '@/composables/usePresence'
import { useRoute } from 'vue-router'
import MasterLayout from '@/layouts/MasterLayout.vue'
import AdminLayout from '@/layouts/AdminLayout.vue'
import OperatorLayout from '@/layouts/OperatorLayout.vue'

const authStore = useAuthStore()
const { initPresence, leavePresence } = usePresence()
const route = useRoute()

const layout = computed(() => route.meta.layout || 'auth')

onMounted(() => {
  if (authStore.user) {
    initPresence()
  }
})

watch(() => authStore.user, (newUser) => {
  if (newUser) {
    initPresence() 
  } else {
    leavePresence() 
  }
})

onUnmounted(() => {
  leavePresence()
})
</script>

<template>
  <MasterLayout v-if="layout === 'master'">
    <RouterView v-slot="{ Component }">
      <Transition name="content" mode="out-in">
        <component :is="Component" :key="route.fullPath" />
      </Transition>
    </RouterView>
  </MasterLayout>

  <AdminLayout v-else-if="layout === 'admin'">
    <RouterView v-slot="{ Component }">
      <Transition name="content" mode="out-in">
        <component :is="Component" :key="route.fullPath" />
      </Transition>
    </RouterView>
  </AdminLayout>

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