import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const routes = [
  { path: '/', redirect: '/dashboard' },
  { path: '/login', name: 'login', component: () => import('@/views/LoginView.vue'), meta: { public: true } },

  {
    path: '/',
    component: () => import('@/components/layout/AppLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      { path: 'dashboard', name: 'dashboard', component: () => import('@/views/DashboardView.vue') },
      { path: 'employees', name: 'employees', component: () => import('@/views/employees/EmployeeListView.vue') },
      { path: 'employees/new', name: 'employee-new', component: () => import('@/views/employees/EmployeeFormView.vue') },
      { path: 'employees/:id', name: 'employee-detail', component: () => import('@/views/employees/EmployeeDetailView.vue') },
      { path: 'employees/:id/edit', name: 'employee-edit', component: () => import('@/views/employees/EmployeeFormView.vue') },
      { path: 'workplaces', name: 'workplaces', component: () => import('@/views/workplaces/WorkplaceListView.vue') },
      { path: 'workplaces/new', name: 'workplace-new', component: () => import('@/views/workplaces/WorkplaceFormView.vue') },
      { path: 'workplaces/:id/edit', name: 'workplace-edit', component: () => import('@/views/workplaces/WorkplaceFormView.vue') },
      { path: 'expenses', name: 'expenses', component: () => import('@/views/expenses/ExpenseListView.vue') },
      { path: 'expenses/:id', name: 'expense-detail', component: () => import('@/views/expenses/ExpenseDetailView.vue') },
      { path: 'banners', name: 'banners', component: () => import('@/views/banners/BannerListView.vue') },
      { path: 'announcements', name: 'announcements', component: () => import('@/views/announcements/AnnouncementListView.vue') },
    ],
  },

  { path: '/:pathMatch(.*)*', redirect: '/dashboard' },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// Navigation guard
router.beforeEach(async (to) => {
  const auth = useAuthStore()

  // Initialize auth state once
  if (auth.token && !auth.user) {
    try { await auth.initializeAuth() } catch (_) { }
  }

  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
  if (to.meta.public && auth.isAuthenticated) {
    return { name: 'dashboard' }
  }
})

export default router
