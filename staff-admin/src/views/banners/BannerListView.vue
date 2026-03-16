<template>
  <div class="space-y-5">
    <div class="flex items-center justify-between">
      <h1 class="text-xl font-bold text-gray-900">Banners</h1>
      <button class="btn-primary" @click="showForm = true">+ Add Banner</button>
    </div>
    <p class="text-sm text-gray-500">Drag to reorder. Order is saved automatically.</p>

    <div v-if="bannerStore.isLoading" class="space-y-3">
      <div v-for="i in 3" :key="i" class="h-24 bg-gray-100 animate-pulse rounded-xl" />
    </div>

    <div v-else class="space-y-3">
      <div v-for="banner in bannerStore.banners" :key="banner.id"
        class="card flex items-center gap-4 hover:shadow-md transition-shadow">
        <div class="w-20 h-14 rounded-lg overflow-hidden bg-gray-100 shrink-0">
          <img v-if="banner.image_url" :src="banner.image_url" class="w-full h-full object-cover" />
          <div v-else class="w-full h-full flex items-center justify-center text-gray-400 text-2xl">🖼</div>
        </div>
        <div class="flex-1 overflow-hidden">
          <p class="font-semibold text-gray-900 truncate">{{ banner.title }}</p>
          <p class="text-xs text-gray-400 truncate">{{ banner.subtitle }}</p>
        </div>
        <span :class="banner.is_active ? 'badge-green' : 'badge-gray'">{{ banner.is_active ? 'Active' : 'Hidden' }}</span>
        <div class="flex gap-1 shrink-0">
          <button class="p-1.5 rounded-lg hover:bg-gray-100 text-gray-400" @click="toggleBanner(banner)">{{ banner.is_active ? '🔴' : '🟢' }}</button>
          <button class="p-1.5 rounded-lg hover:bg-red-50 text-red-400" @click="deleteBanner(banner)">🗑</button>
        </div>
      </div>
    </div>

    <!-- Add Banner Modal -->
    <div v-if="showForm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-xl shadow-xl p-6 w-full max-w-md">
        <h3 class="font-semibold text-gray-900 mb-4">Add Banner</h3>
        <div class="space-y-4">
          <div>
            <label class="block text-xs text-gray-500 mb-1">Title *</label>
            <input v-model="bannerForm.title" type="text" class="input" />
          </div>
          <div>
            <label class="block text-xs text-gray-500 mb-1">Subtitle</label>
            <input v-model="bannerForm.subtitle" type="text" class="input" />
          </div>
          <div>
            <label class="block text-xs text-gray-500 mb-1">Image URL</label>
            <input v-model="bannerForm.image_url" type="url" class="input" placeholder="https://..." />
          </div>
        </div>
        <div class="flex gap-2 mt-5">
          <button class="btn-secondary flex-1" @click="showForm = false">Cancel</button>
          <button class="btn-primary flex-1" @click="saveBanner">Save Banner</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useBannerStore } from '@/stores/banners'
import { useToast } from 'vue-toastification'

const bannerStore = useBannerStore()
const toast = useToast()
const showForm = ref(false)
const bannerForm = reactive({ title: '', subtitle: '', image_url: '' })

onMounted(() => bannerStore.fetchAll())

async function saveBanner() {
  if (!bannerForm.title) { toast.error('Title is required'); return }
  await bannerStore.create({ ...bannerForm, display_order: bannerStore.banners.length })
  toast.success('Banner added')
  showForm.value = false
  Object.assign(bannerForm, { title: '', subtitle: '', image_url: '' })
}

async function toggleBanner(b) {
  await bannerStore.toggle(b.id)
  toast.success('Banner updated')
}

async function deleteBanner(b) {
  if (!confirm(`Delete banner "${b.title}"?`)) return
  await bannerStore.remove(b.id)
  toast.success('Banner deleted')
}
</script>
