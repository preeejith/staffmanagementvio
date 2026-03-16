<template>
  <div class="flex min-h-screen bg-gray-50">
    <!-- Mobile overlay -->
    <div v-if="mobileMenuOpen" class="fixed inset-0 bg-black/50 z-40 lg:hidden" @click="mobileMenuOpen = false" />

    <AppSidebar :mobile-open="mobileMenuOpen" @close="mobileMenuOpen = false" />

    <!-- Main content -->
    <div class="flex-1 lg:ml-64 min-w-0">
      <!-- Top bar -->
      <header class="sticky top-0 z-30 bg-white border-b border-gray-200 px-4 md:px-6 h-16 flex items-center gap-4">
        <button @click="mobileMenuOpen = !mobileMenuOpen" class="lg:hidden p-2 rounded-lg hover:bg-gray-100">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
          </svg>
        </button>
        <h1 class="font-semibold text-gray-800 text-lg">{{ pageTitle }}</h1>
        <div class="ml-auto flex items-center gap-3">
          <div class="w-8 h-8 bg-primary-600 rounded-full flex items-center justify-center text-white text-sm font-bold">
            {{ authStore.userFullName.charAt(0).toUpperCase() }}
          </div>
          <div class="hidden md:block">
            <p class="text-sm font-medium text-gray-800">{{ authStore.userFullName }}</p>
            <p class="text-xs text-gray-500 capitalize">{{ authStore.user?.role }}</p>
          </div>
        </div>
      </header>

      <main class="p-4 md:p-6">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import AppSidebar from './AppSidebar.vue'

const route = useRoute()
const authStore = useAuthStore()
const mobileMenuOpen = ref(false)

const titleMap = {
  '/dashboard':     'Dashboard',
  '/employees':     'Employees',
  '/workplaces':    'Workplaces',
  '/expenses':      'Expense Monitoring',
  '/banners':       'Banners',
  '/announcements': 'Announcements',
}

const pageTitle = computed(() => {
  const base = '/' + route.path.split('/')[1]
  return titleMap[base] || 'Staff Management'
})
</script>
