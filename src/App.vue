<script setup>
import { onMounted, onUnmounted, computed, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { usePresence } from '@/composables/usePresence'
import { useRoute } from 'vue-router'
import AdminLayout from '@/layouts/AdminLayout.vue'
import OperatorLayout from '@/layouts/OperatorLayout.vue'

const authStore = useAuthStore()
const { initPresence, leavePresence } = usePresence()
const route = useRoute()

const layout = computed(() => route.meta.layout || 'auth')

onMounted(() => {
  // initialize() sudah ditangani oleh router guard (beforeEach)
  // sehingga tidak perlu dipanggil lagi di sini untuk menghindari race condition
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
  <AdminLayout v-if="layout === 'admin'">
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