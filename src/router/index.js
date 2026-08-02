import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabaseClient'
import LoginView from '../views/LoginView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'login',
      component: LoginView,
      meta: { requiresAuth: false, layout: 'auth' }
    },
    {
      path: '/reset-password',
      name: 'reset-password',
      component: () => import('../views/ResetPasswordView.vue'),
      meta: { requiresAuth: false, layout: 'auth' }
    },
    {
      path: '/master',
      redirect: '/master/dashboard'
    },
    {
      path: '/master/dashboard',
      name: 'master-dashboard',
      component: () => import('../views/MasterDashboardView.vue'),
      meta: { requiresAuth: true, role: 'master', layout: 'master' }
    },
    {
      path: '/master/history',
      name: 'master-history',
      component: () => import('../views/MasterHistoryView.vue'),
      meta: { requiresAuth: true, role: 'master', layout: 'master' }
    },
    {
      path: '/master/analytics',
      name: 'master-analytics',
      component: () => import('../views/MasterAnalyticsView.vue'),
      meta: { requiresAuth: true, role: 'master', layout: 'master' }
    },
    {
      path: '/master/repeated',
      name: 'master-repeated',
      component: () => import('../views/MasterRepeatedView.vue'),
      meta: { requiresAuth: true, role: 'master', layout: 'master' }
    },
    {
      path: '/master/network',
      redirect: '/master/history'
    },
    {
      path: '/master/team',
      name: 'master-team',
      component: () => import('../views/TeamView.vue'),
      meta: { requiresAuth: true, role: 'master', layout: 'master' }
    },
    {
      path: '/master/settings',
      name: 'master-settings',
      component: () => import('../views/MasterSettingsView.vue'),
      meta: { requiresAuth: true, role: 'master', layout: 'master' }
    },
    {
      path: '/dashboard',
      name: 'dashboard',
      component: () => import('../views/DashboardView.vue'),
      meta: { requiresAuth: true, role: 'operator', layout: 'admin' }
    },
    {
      path: '/history',
      name: 'history',
      component: () => import('../views/HistoryView.vue'),
      meta: { requiresAuth: true, role: 'operator', layout: 'admin' }
    },
    {
      path: '/operator',
      name: 'operator',
      component: () => import('../views/HomeView.vue'),
      meta: { requiresAuth: true, role: 'operator', layout: 'operator' }
    },
    {
      path: '/operator/history',
      name: 'operator-history',
      component: () => import('../views/OperatorHistoryView.vue'),
      meta: { requiresAuth: true, role: 'operator', layout: 'operator' }
    },
    {
      path: '/laporan',
      name: 'laporan',
      component: () => import('../views/ReportView.vue'),
      meta: { requiresAuth: true, role: 'operator', layout: 'admin' }
    },
    {
      path: '/support',
      name: 'support',
      component: () => import('../views/SupportView.vue'),
      meta: { requiresAuth: true, role: 'operator', layout: 'admin' }
    },
    {
      path: '/team',
      name: 'team',
      component: () => import('../views/TeamView.vue'),
      meta: { requiresAuth: true, role: 'operator', layout: 'admin' }
    },
    {
      path: '/settings',
      name: 'settings',
      component: () => import('../views/SettingsView.vue'),
      meta: { requiresAuth: true, layout: 'admin' }
    },
    {
      path: '/operator/settings',
      name: 'operator-settings',
      component: () => import('../views/OperatorSettingsView.vue'),
      meta: { requiresAuth: true, role: 'operator', layout: 'operator' }
    },
  ],
})

router.beforeEach(async (to, from, next) => {
  if (to.name === 'reset-password') return next()

  const authStore = useAuthStore()

  const { data: { session } } = await supabase.auth.getSession()

  if (to.meta.requiresAuth && !session) {
    authStore.user = null
    authStore.role = null
    return next({ name: 'login' })
  }

  if (session && !authStore.user) {
    await authStore.initialize()
  }

  const userRole = authStore.role

  if (to.meta.requiresAuth) {
    if (to.meta.role && to.meta.role !== userRole) {
      if (userRole === 'master') return next({ name: 'master-dashboard' })
      if (userRole === 'operator') return next({ name: 'operator' })

      await supabase.auth.signOut()
      return next({ name: 'login' })
    }
  }

  if (to.name === 'login' && session) {
    if (userRole === 'master') return next({ name: 'master-dashboard' })
    if (userRole === 'operator') return next({ name: 'operator' })
  }
  next()
})

export default router
