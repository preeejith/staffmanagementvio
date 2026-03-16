<template>
  <!-- Sidebar -->
  <aside :class="['fixed inset-y-0 left-0 z-50 flex flex-col bg-gray-900 transition-all duration-300',
    isOpen ? 'w-64' : 'w-16', 'lg:translate-x-0',
    mobileOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0']">

    <!-- Logo -->
    <div class="flex items-center gap-3 px-4 py-5 border-b border-gray-800">
      <div class="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center shrink-0">
        <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
      </div>
      <span v-if="isOpen" class="text-white font-semibold text-sm leading-tight">Staff<br>Management</span>
      <button v-if="isOpen" @click="isOpen = false" class="ml-auto text-gray-400 hover:text-white lg:hidden">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg>
      </button>
    </div>

    <!-- Nav Items -->
    <nav class="flex-1 px-2 py-4 space-y-1 overflow-y-auto">
      <router-link v-for="item in navItems" :key="item.to" :to="item.to"
        :class="['flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-colors group',
          isActive(item.to)
            ? 'bg-primary-600 text-white'
            : 'text-gray-400 hover:bg-gray-800 hover:text-white']">
        <component :is="item.icon" class="w-5 h-5 shrink-0" />
        <span v-if="isOpen" class="font-medium truncate">{{ item.label }}</span>
      </router-link>
    </nav>

    <!-- User info + Logout -->
    <div class="border-t border-gray-800 p-3">
      <div v-if="isOpen" class="flex items-center gap-3 px-2 py-2 rounded-lg mb-2">
        <div class="w-8 h-8 bg-primary-600 rounded-full flex items-center justify-center text-white text-sm font-bold shrink-0">
          {{ authStore.userFullName.charAt(0).toUpperCase() }}
        </div>
        <div class="overflow-hidden">
          <p class="text-white text-sm font-medium truncate">{{ authStore.userFullName }}</p>
          <span class="badge-blue text-xs">{{ authStore.user?.role }}</span>
        </div>
      </div>
      <button @click="handleLogout"
        :class="['flex items-center gap-3 w-full px-3 py-2 rounded-lg text-red-400 hover:bg-gray-800 hover:text-red-300 text-sm transition-colors']">
        <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
        </svg>
        <span v-if="isOpen">Logout</span>
      </button>
    </div>
  </aside>
</template>

<script setup>
import { ref, defineComponent, h } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const props = defineProps({ mobileOpen: Boolean })
const emit = defineEmits(['close'])

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const isOpen = ref(true)

// Simple SVG icon components
const IconGrid = defineComponent({ render: () => h('svg', { fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zm10 0a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zm10 0a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z' })
]) })

const IconUsers = defineComponent({ render: () => h('svg', { fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z' })
]) })

const IconBuilding = defineComponent({ render: () => h('svg', { fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4' })
]) })

const IconReceipt = defineComponent({ render: () => h('svg', { fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2' })
]) })

const IconPhoto = defineComponent({ render: () => h('svg', { fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z' })
]) })

const IconBell = defineComponent({ render: () => h('svg', { fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, [
  h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9' })
]) })

const navItems = [
  { to: '/dashboard',     label: 'Dashboard',     icon: IconGrid },
  { to: '/employees',     label: 'Employees',     icon: IconUsers },
  { to: '/workplaces',    label: 'Workplaces',    icon: IconBuilding },
  { to: '/expenses',      label: 'Expenses',      icon: IconReceipt },
  { to: '/banners',       label: 'Banners',       icon: IconPhoto },
  { to: '/announcements', label: 'Announcements', icon: IconBell },
]

function isActive(to) {
  return route.path === to || route.path.startsWith(to + '/')
}

async function handleLogout() {
  await authStore.logout()
  router.push('/login')
}
</script>
