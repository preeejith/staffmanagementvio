<template>
  <div class="max-w-2xl mx-auto space-y-6">
    <div class="flex items-center gap-3">
      <button @click="router.back()" class="p-2 rounded-lg hover:bg-gray-100">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" /></svg>
      </button>
      <h1 class="text-xl font-bold text-gray-900">{{ isEdit ? 'Edit Employee' : 'Add Employee' }}</h1>
    </div>

    <div class="card space-y-5">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
        <!-- Name -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Full Name *</label>
          <input v-model="form.name" type="text" class="input" :class="{ 'border-red-400': errors.name }" placeholder="Employee name" />
          <p v-if="errors.name" class="mt-1 text-xs text-red-600">{{ errors.name }}</p>
        </div>

        <!-- Email -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Email *</label>
          <input v-model="form.email" type="email" class="input" :class="{ 'border-red-400': errors.email }"
            placeholder="employee@company.com" :disabled="isEdit" />
          <p v-if="errors.email" class="mt-1 text-xs text-red-600">{{ errors.email }}</p>
        </div>

        <!-- Phone -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Phone</label>
          <input v-model="form.phone" type="tel" class="input" placeholder="+91 98765 43210" />
        </div>

        <!-- Aadhaar -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Aadhaar Number</label>
          <input v-model="form.aadhaar_number" type="text" class="input" placeholder="XXXX XXXX XXXX" maxlength="14" />
        </div>

        <!-- Workplace -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Assign Workplace</label>
          <select v-model="form.assigned_workplace_id" class="input">
            <option value="">— Select Workplace —</option>
            <option v-for="w in workplaces" :key="w.id" :value="w.id">{{ w.name }}</option>
          </select>
        </div>

        <!-- Role -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">Role</label>
          <select v-model="form.role" class="input">
            <option value="employee">Employee</option>
            <option value="admin">Admin</option>
          </select>
        </div>

        <!-- Password -->
        <div class="md:col-span-2">
          <label class="block text-sm font-medium text-gray-700 mb-1.5">
            {{ isEdit ? 'New Password (leave blank to keep current)' : 'Initial Password *' }}
          </label>
          <input v-model="form.password" type="password" class="input" :class="{ 'border-red-400': errors.password }"
            :placeholder="isEdit ? 'Enter new password to change' : 'Min 6 characters'" />
          <p v-if="errors.password" class="mt-1 text-xs text-red-600">{{ errors.password }}</p>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex gap-3 pt-2">
        <button type="button" class="btn-secondary" @click="router.back()">Cancel</button>
        <button type="button" class="btn-primary" :disabled="isSaving" @click="handleSubmit">
          <svg v-if="isSaving" class="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
          </svg>
          {{ isSaving ? 'Saving...' : isEdit ? 'Save Changes' : 'Create Employee' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useEmployeeStore } from '@/stores/employees'
import { useWorkplaceStore } from '@/stores/workplaces'
import { useToast } from 'vue-toastification'

const router = useRouter()
const route = useRoute()
const toast = useToast()
const employeeStore = useEmployeeStore()
const workplaceStore = useWorkplaceStore()

const isEdit = computed(() => !!route.params.id)
const isSaving = ref(false)
const workplaces = ref([])

const form = reactive({ name: '', email: '', phone: '', aadhaar_number: '', role: 'employee', assigned_workplace_id: '', password: '' })
const errors = reactive({ name: '', email: '', password: '' })

onMounted(async () => {
  await workplaceStore.fetchAll()
  workplaces.value = workplaceStore.workplaces
  if (isEdit.value) {
    const emp = await employeeStore.fetchById(route.params.id)
    if (emp) {
      Object.assign(form, {
        name: emp.name || '', email: emp.email || '', phone: emp.phone || '',
        aadhaar_number: emp.aadhaar_number || '', role: emp.role || 'employee',
        assigned_workplace_id: emp.assigned_workplace_id || '',
      })
    }
  }
})

function validate() {
  let valid = true
  errors.name = errors.email = errors.password = ''
  if (!form.name) { errors.name = 'Name is required'; valid = false }
  if (!form.email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
    errors.email = 'Valid email required'; valid = false
  }
  if (!isEdit.value && (!form.password || form.password.length < 6)) {
    errors.password = 'Password must be at least 6 characters'; valid = false
  }
  if (isEdit.value && form.password && form.password.length < 6) {
    errors.password = 'Password must be at least 6 characters'; valid = false
  }
  return valid
}

async function handleSubmit() {
  if (!validate()) return
  isSaving.value = true
  try {
    const payload = { ...form }
    if (!payload.password) delete payload.password
    if (!payload.assigned_workplace_id) payload.assigned_workplace_id = null

    let res
    if (isEdit.value) {
      res = await employeeStore.update(route.params.id, payload)
    } else {
      res = await employeeStore.create(payload)
    }
    if (res.success) {
      toast.success(isEdit.value ? 'Employee updated!' : 'Employee created!')
      router.push('/employees')
    } else {
      toast.error(res.error || 'Failed to save')
    }
  } catch (e) {
    toast.error(e.response?.data?.error || 'Failed to save employee')
  } finally {
    isSaving.value = false
  }
}
</script>
