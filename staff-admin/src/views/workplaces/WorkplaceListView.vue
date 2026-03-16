<template>
  <div class="space-y-5">
    <div class="flex items-center justify-between">
      <h1 class="text-xl font-bold text-gray-900">Workplaces</h1>
      <router-link to="/workplaces/new" class="btn-primary">+ Add Workplace</router-link>
    </div>

    <div class="flex gap-3">
      <label class="flex items-center gap-2 text-sm text-gray-600 cursor-pointer">
        <input type="checkbox" v-model="activeOnly" @change="fetchWorkplaces" class="rounded" />
        Active only
      </label>
    </div>

    <div v-if="workplaceStore.isLoading" class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
      <div v-for="i in 3" :key="i" class="h-48 bg-gray-100 animate-pulse rounded-xl" />
    </div>

    <div v-else-if="workplaceStore.workplaces.length === 0" class="text-center py-16 text-gray-400">
      <div class="text-4xl mb-3">🏢</div>
      <p class="font-medium">No workplaces yet</p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
      <div v-for="w in workplaceStore.workplaces" :key="w.id" class="card hover:shadow-md transition-shadow">
        <!-- Banner image -->
        <div v-if="w.banner_image_url" class="h-32 -mx-6 -mt-6 mb-5 rounded-t-xl overflow-hidden">
          <img :src="w.banner_image_url" class="w-full h-full object-cover" :alt="w.name" />
        </div>
        <div v-if="w.is_featured" class="-mt-1 mb-2">
          <span class="badge-blue text-xs">⭐ Featured</span>
        </div>

        <div class="flex items-start justify-between mb-1">
          <h3 class="font-semibold text-gray-900">{{ w.name }}</h3>
          <span :class="w.is_active ? 'badge-green' : 'badge-red'">{{ w.is_active ? 'Active' : 'Inactive' }}</span>
        </div>
        <p v-if="w.location" class="text-xs text-gray-400 mb-1">📍 {{ w.location }}</p>
        <p class="text-sm text-gray-500 line-clamp-2 mb-4">{{ w.description || 'No description' }}</p>
        <p class="text-xs text-gray-400 mb-4">{{ (w.assigned_employees || []).length }} employee(s) assigned</p>

        <div class="flex gap-2">
          <router-link :to="`/workplaces/${w.id}/edit`" class="btn-secondary text-xs flex-1">✏️ Edit</router-link>
          <button class="btn-secondary text-xs" @click="toggleStatus(w)">{{ w.is_active ? '🔴' : '🟢' }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useWorkplaceStore } from '@/stores/workplaces'
import { useToast } from 'vue-toastification'

const workplaceStore = useWorkplaceStore()
const toast = useToast()
const activeOnly = ref(false)

async function fetchWorkplaces() {
  await workplaceStore.fetchAll()
}

async function toggleStatus(w) {
  await workplaceStore.toggleStatus(w.id)
  toast.success('Status updated')
}

onMounted(fetchWorkplaces)
</script>
