<template>
  <div class="max-w-2xl mx-auto space-y-6">
    <div class="flex items-center gap-3">
      <button @click="router.back()" class="p-2 rounded-lg hover:bg-gray-100">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" /></svg>
      </button>
      <h1 class="text-xl font-bold text-gray-900">{{ isEdit ? 'Edit Workplace' : 'Add Workplace' }}</h1>
    </div>

    <div class="card space-y-5">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
        <div class="md:col-span-2">
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Workplace Name *</label>
          <input v-model="form.name" type="text" class="input" placeholder="Site name or address" />
        </div>
        <div class="md:col-span-2">
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Description</label>
          <textarea v-model="form.description" rows="3" class="input" placeholder="What work happens here..." />
        </div>
        <div class="md:col-span-2">
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Location / Address</label>
          <input v-model="form.location" type="text" class="input" placeholder="City, area or full address" />
        </div>
        <div class="md:col-span-2">
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Employee Instructions</label>
          <textarea v-model="form.instructions" rows="3" class="input" placeholder="What employees should know when arriving..." />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Contact Name</label>
          <input v-model="form.contact_name" type="text" class="input" />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Contact Phone</label>
          <input v-model="form.contact_phone" type="tel" class="input" />
        </div>
        <div class="md:col-span-2">
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Contact Email</label>
          <input v-model="form.contact_email" type="email" class="input" />
        </div>
        <div class="md:col-span-2 flex items-center gap-3">
          <input type="checkbox" v-model="form.is_featured" id="featured" class="rounded" />
          <label for="featured" class="text-sm font-medium text-gray-700 cursor-pointer">Featured Workplace (show in employee app)</label>
        </div>
      </div>

      <div class="flex gap-3 pt-2">
        <button class="btn-secondary" @click="router.back()">Cancel</button>
        <button class="btn-primary" :disabled="isSaving" @click="handleSubmit">
          {{ isSaving ? 'Saving...' : isEdit ? 'Save Changes' : 'Create Workplace' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useWorkplaceStore } from '@/stores/workplaces'
import { useToast } from 'vue-toastification'

const router = useRouter()
const route = useRoute()
const toast = useToast()
const workplaceStore = useWorkplaceStore()

const isEdit = computed(() => !!route.params.id)
const isSaving = ref(false)
const form = reactive({ name: '', description: '', location: '', instructions: '', contact_name: '', contact_phone: '', contact_email: '', is_featured: false })

onMounted(async () => {
  if (isEdit.value) {
    const w = await workplaceStore.fetchById(route.params.id)
    if (w) Object.assign(form, { name: w.name, description: w.description, location: w.location, instructions: w.instructions, contact_name: w.contact_name, contact_phone: w.contact_phone, contact_email: w.contact_email, is_featured: w.is_featured })
  }
})

async function handleSubmit() {
  if (!form.name) { toast.error('Workplace name is required'); return }
  isSaving.value = true
  try {
    const res = isEdit.value
      ? await workplaceStore.update(route.params.id, form)
      : await workplaceStore.create(form)
    if (res.success) {
      toast.success(isEdit.value ? 'Workplace updated!' : 'Workplace created!')
      router.push('/workplaces')
    } else {
      toast.error(res.error || 'Failed to save')
    }
  } finally {
    isSaving.value = false
  }
}
</script>
