<template>
  <div v-if="employee" class="space-y-6">
    <!-- Back + Actions -->
    <div class="flex items-center gap-3">
      <button @click="router.back()" class="p-2 rounded-lg hover:bg-gray-100">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" /></svg>
      </button>
      <div class="ml-auto flex gap-2">
        <router-link :to="`/employees/${employee.id}/edit`" class="btn-secondary text-sm">✏️ Edit</router-link>
        <button class="btn-secondary text-sm" @click="toggleStatus">{{ employee.is_active ? '🔴 Deactivate' : '🟢 Activate' }}</button>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Profile card -->
      <div class="card text-center">
        <div class="w-20 h-20 rounded-full bg-primary-100 text-primary-700 font-bold text-2xl flex items-center justify-center mx-auto mb-3">
          {{ employee.name?.charAt(0).toUpperCase() }}
        </div>
        <h2 class="text-lg font-bold text-gray-900">{{ employee.name }}</h2>
        <p class="text-sm text-gray-500 mb-2">{{ employee.email }}</p>
        <div class="flex justify-center gap-2">
          <span :class="employee.is_active ? 'badge-green' : 'badge-red'">{{ employee.is_active ? 'Active' : 'Inactive' }}</span>
          <span class="badge-blue capitalize">{{ employee.role }}</span>
        </div>

        <div class="mt-5 text-left space-y-3 border-t border-gray-100 pt-4">
          <div>
            <p class="text-xs text-gray-400">Phone</p>
            <p class="text-sm text-gray-800 font-medium">{{ employee.phone || '—' }}</p>
          </div>
          <div>
            <p class="text-xs text-gray-400">Aadhaar</p>
            <p class="text-sm text-gray-800 font-medium">
              {{ employee.aadhaar_number ? '•••• •••• ' + employee.aadhaar_number.slice(-4) : '—' }}
            </p>
          </div>
          <div>
            <p class="text-xs text-gray-400">Joined</p>
            <p class="text-sm text-gray-800">{{ formatDate(employee.created_at) }}</p>
          </div>
        </div>
      </div>

      <!-- Details -->
      <div class="lg:col-span-2 space-y-4">
        <!-- Workplace -->
        <div class="card">
          <h3 class="font-semibold text-gray-900 mb-3">Assigned Workplace</h3>
          <div v-if="employee.workplace">
            <p class="font-medium text-gray-900">{{ employee.workplace.name }}</p>
            <p class="text-sm text-gray-500">{{ employee.workplace.location }}</p>
          </div>
          <p v-else class="text-sm text-gray-400">No workplace assigned</p>
        </div>

        <!-- Documents -->
        <div class="card">
          <h3 class="font-semibold text-gray-900 mb-3">Documents</h3>
          <div class="flex gap-4">
            <div class="text-center">
              <div v-if="employee.aadhaar_url" class="w-24 h-16 rounded-lg overflow-hidden border border-gray-200 mb-1 cursor-pointer"
                @click="openImage(employee.aadhaar_url)">
                <img :src="employee.aadhaar_url" class="w-full h-full object-cover" alt="Aadhaar" />
              </div>
              <div v-else class="w-24 h-16 rounded-lg bg-gray-100 flex items-center justify-center mb-1">📄</div>
              <p class="text-xs text-gray-500">Aadhaar</p>
            </div>
            <div class="text-center">
              <div v-if="employee.driving_licence_url" class="w-24 h-16 rounded-lg overflow-hidden border border-gray-200 mb-1 cursor-pointer"
                @click="openImage(employee.driving_licence_url)">
                <img :src="employee.driving_licence_url" class="w-full h-full object-cover" alt="Licence" />
              </div>
              <div v-else class="w-24 h-16 rounded-lg bg-gray-100 flex items-center justify-center mb-1">📄</div>
              <p class="text-xs text-gray-500">Driving Licence</p>
            </div>
          </div>
        </div>

        <!-- Expense Summary -->
        <div class="card">
          <h3 class="font-semibold text-gray-900 mb-3">Expense Summary</h3>
          <div class="grid grid-cols-2 gap-3 text-center">
            <div class="bg-gray-50 rounded-lg p-3">
              <p class="text-xl font-bold text-gray-900">{{ employee.expense_count || 0 }}</p>
              <p class="text-xs text-gray-500">Total Expenses</p>
            </div>
            <div class="bg-gray-50 rounded-lg p-3">
              <p class="text-xl font-bold text-primary-700">₹{{ Number(employee.total_expenses || 0).toLocaleString('en-IN') }}</p>
              <p class="text-xs text-gray-500">Total Amount</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Image Lightbox -->
    <div v-if="lightboxUrl" class="fixed inset-0 bg-black/80 flex items-center justify-center z-50" @click="lightboxUrl = null">
      <img :src="lightboxUrl" class="max-w-2xl max-h-[80vh] rounded-xl object-contain" />
    </div>
  </div>
  <div v-else-if="isLoading" class="space-y-4">
    <div class="h-10 w-32 bg-gray-200 animate-pulse rounded-lg" />
    <div class="h-64 bg-gray-100 animate-pulse rounded-xl" />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useEmployeeStore } from '@/stores/employees'
import { useToast } from 'vue-toastification'

const router = useRouter()
const route = useRoute()
const toast = useToast()
const employeeStore = useEmployeeStore()

const employee = ref(null)
const isLoading = ref(false)
const lightboxUrl = ref(null)

onMounted(async () => {
  isLoading.value = true
  try {
    employee.value = await employeeStore.fetchById(route.params.id)
  } finally {
    isLoading.value = false
  }
})

function formatDate(d) {
  return d ? new Date(d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' }) : '—'
}
function openImage(url) { lightboxUrl.value = url }

async function toggleStatus() {
  await employeeStore.toggleStatus(employee.value.id)
  employee.value.is_active = !employee.value.is_active
  toast.success('Status updated')
}
</script>
