<template>
  <div class="space-y-5">
    <div class="flex items-center justify-between">
      <h1 class="text-xl font-bold text-gray-900">Announcements</h1>
      <button class="btn-primary" @click="showForm = true">+ Add Announcement</button>
    </div>

    <div v-if="isLoading" class="space-y-3">
      <div v-for="i in 3" :key="i" class="h-20 bg-gray-100 animate-pulse rounded-xl" />
    </div>

    <div v-else-if="announcements.length === 0" class="text-center py-16 text-gray-400">
      <div class="text-4xl mb-3">📢</div><p class="font-medium">No announcements yet</p>
    </div>

    <div v-else class="space-y-3">
      <div v-for="a in announcements" :key="a.id" class="card hover:shadow-md transition-shadow">
        <div class="flex items-start justify-between gap-3">
          <div class="flex-1">
            <h3 class="font-semibold text-gray-900">{{ a.title }}</h3>
            <p class="text-sm text-gray-500 mt-1 line-clamp-2">{{ a.body }}</p>
            <p class="text-xs text-gray-400 mt-2">Target: {{ a.target_audience }} · {{ formatDate(a.created_at) }}</p>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            <span :class="a.is_active ? 'badge-green' : 'badge-gray'">{{ a.is_active ? 'Live' : 'Hidden' }}</span>
            <button class="p-1.5 rounded-lg hover:bg-gray-100 text-gray-400" @click="toggle(a)">{{ a.is_active ? '🔴' : '🟢' }}</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Add Modal -->
    <div v-if="showForm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-xl shadow-xl p-6 w-full max-w-md">
        <h3 class="font-semibold text-gray-900 mb-4">New Announcement</h3>
        <div class="space-y-4">
          <div>
            <label class="block text-xs text-gray-500 mb-1">Title *</label>
            <input v-model="form.title" type="text" class="input" />
          </div>
          <div>
            <label class="block text-xs text-gray-500 mb-1">Body *</label>
            <textarea v-model="form.body" rows="3" class="input" />
          </div>
          <div>
            <label class="block text-xs text-gray-500 mb-1">Target Audience</label>
            <select v-model="form.target_audience" class="input">
              <option value="all">All Employees</option>
            </select>
          </div>
        </div>
        <div class="flex gap-2 mt-5">
          <button class="btn-secondary flex-1" @click="showForm = false">Cancel</button>
          <button class="btn-primary flex-1" @click="save">Post</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useToast } from 'vue-toastification'
import api from '@/services/api'

const toast = useToast()
const announcements = ref([])
const isLoading = ref(false)
const showForm = ref(false)
const form = reactive({ title: '', body: '', target_audience: 'all' })

async function load() {
  isLoading.value = true
  try {
    const { data: res } = await api.get('/announcements')
    if (res.success) announcements.value = res.data
  } finally { isLoading.value = false }
}

async function save() {
  if (!form.title || !form.body) { toast.error('Title and body are required'); return }
  const { data: res } = await api.post('/announcements', { ...form })
  if (res.success) {
    announcements.value.unshift(res.data)
    toast.success('Announcement posted')
    showForm.value = false
    Object.assign(form, { title: '', body: '', target_audience: 'all' })
  }
}

async function toggle(a) {
  const { data: res } = await api.patch(`/announcements/${a.id}/toggle`)
  if (res.success) {
    const idx = announcements.value.findIndex(x => x.id === a.id)
    if (idx !== -1) announcements.value[idx] = res.data
  }
  toast.success('Updated')
}

function formatDate(d) {
  return new Date(d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
}

onMounted(load)
</script>
