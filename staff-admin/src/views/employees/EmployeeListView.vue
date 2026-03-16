<template>
  <div class="space-y-5">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-bold text-gray-900">Employees</h1>
        <p class="text-sm text-gray-500">{{ employeeStore.employees.length }} total</p>
      </div>
      <router-link to="/employees/new" class="btn-primary">+ Add Employee</router-link>
    </div>

    <!-- Filters -->
    <div class="card">
      <div class="flex flex-wrap gap-3">
        <input v-model="search" type="search" placeholder="Search name, email, phone..." class="input max-w-xs" @input="debouncedFetch" />
        <select v-model="filterWorkplace" class="input max-w-[200px]" @change="fetchEmployees">
          <option value="">All Workplaces</option>
          <option v-for="w in workplaces" :key="w.id" :value="w.id">{{ w.name }}</option>
        </select>
        <select v-model="filterActive" class="input max-w-[160px]" @change="fetchEmployees">
          <option value="">All Status</option>
          <option value="true">Active</option>
          <option value="false">Inactive</option>
        </select>
        <button class="btn-secondary text-sm" @click="clearFilters">Clear</button>
      </div>
    </div>

    <!-- Table -->
    <div class="card p-0 overflow-hidden">
      <div v-if="employeeStore.isLoading" class="p-6 space-y-3">
        <div v-for="i in 5" :key="i" class="h-14 bg-gray-100 animate-pulse rounded-lg" />
      </div>
      <div v-else-if="employeeStore.employees.length === 0" class="text-center py-16 text-gray-400">
        <div class="text-4xl mb-3">👥</div>
        <p class="font-medium">No employees found</p>
        <p class="text-sm mt-1">Try adjusting your filters or add a new employee.</p>
      </div>
      <table v-else class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-200">
          <tr class="text-left text-gray-500">
            <th class="px-6 py-3 font-medium">Employee</th>
            <th class="px-4 py-3 font-medium hidden md:table-cell">Phone</th>
            <th class="px-4 py-3 font-medium hidden lg:table-cell">Workplace</th>
            <th class="px-4 py-3 font-medium">Status</th>
            <th class="px-4 py-3 font-medium">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          <tr v-for="emp in paginatedEmployees" :key="emp.id" class="hover:bg-gray-50 transition-colors">
            <td class="px-6 py-4">
              <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-full bg-primary-100 text-primary-700 font-bold text-sm flex items-center justify-center shrink-0"
                  :style="emp.profile_photo_url ? `background-image: url(${emp.profile_photo_url}); background-size: cover;` : ''">
                  {{ emp.profile_photo_url ? '' : emp.name?.charAt(0).toUpperCase() }}
                </div>
                <div>
                  <p class="font-medium text-gray-900">{{ emp.name }}</p>
                  <p class="text-xs text-gray-400">{{ emp.email }}</p>
                </div>
              </div>
            </td>
            <td class="px-4 py-4 text-gray-600 hidden md:table-cell">{{ emp.phone || '—' }}</td>
            <td class="px-4 py-4 hidden lg:table-cell">
              <span class="text-gray-600 text-xs bg-gray-100 px-2 py-1 rounded-md">{{ emp.workplace?.name || '—' }}</span>
            </td>
            <td class="px-4 py-4">
              <span :class="emp.is_active ? 'badge-green' : 'badge-red'">{{ emp.is_active ? 'Active' : 'Inactive' }}</span>
            </td>
            <td class="px-4 py-4">
              <div class="flex items-center gap-2">
                <button class="p-1.5 text-gray-400 hover:text-primary-600 hover:bg-primary-50 rounded-lg" title="View"
                  @click="router.push(`/employees/${emp.id}`)">👁</button>
                <button class="p-1.5 text-gray-400 hover:text-primary-600 hover:bg-primary-50 rounded-lg" title="Edit"
                  @click="router.push(`/employees/${emp.id}/edit`)">✏️</button>
                <button class="p-1.5 text-gray-400 hover:text-amber-600 hover:bg-amber-50 rounded-lg" title="Toggle Status"
                  @click="toggleStatus(emp)">{{ emp.is_active ? '🔴' : '🟢' }}</button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
      <!-- Pagination -->
      <div v-if="totalPages > 1" class="flex items-center justify-between px-6 py-3 border-t border-gray-100">
        <p class="text-sm text-gray-500">Page {{ page }} of {{ totalPages }}</p>
        <div class="flex gap-1">
          <button :disabled="page <= 1" class="btn-secondary py-1 px-3 text-xs" @click="page--">← Prev</button>
          <button :disabled="page >= totalPages" class="btn-secondary py-1 px-3 text-xs" @click="page++">Next →</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useEmployeeStore } from '@/stores/employees'
import { useWorkplaceStore } from '@/stores/workplaces'
import { useToast } from 'vue-toastification'
import api from '@/services/api'

const router = useRouter()
const toast = useToast()
const employeeStore = useEmployeeStore()
const workplaceStore = useWorkplaceStore()

const search = ref('')
const filterWorkplace = ref('')
const filterActive = ref('')
const page = ref(1)
const PER_PAGE = 10

const workplaces = ref([])
let debounceTimer = null

const paginatedEmployees = computed(() => {
  const start = (page.value - 1) * PER_PAGE
  return employeeStore.employees.slice(start, start + PER_PAGE)
})
const totalPages = computed(() => Math.ceil(employeeStore.employees.length / PER_PAGE))

function debouncedFetch() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(fetchEmployees, 350)
}

async function fetchEmployees() {
  page.value = 1
  const params = {}
  if (search.value)          params.search = search.value
  if (filterWorkplace.value) params.workplace_id = filterWorkplace.value
  if (filterActive.value !== '') params.is_active = filterActive.value
  await employeeStore.fetchAll(params)
}

function clearFilters() {
  search.value = ''
  filterWorkplace.value = ''
  filterActive.value = ''
  fetchEmployees()
}

async function toggleStatus(emp) {
  await employeeStore.toggleStatus(emp.id)
  toast.success(`${emp.name} ${emp.is_active ? 'deactivated' : 'activated'}`)
}

onMounted(async () => {
  await Promise.all([fetchEmployees(), workplaceStore.fetchAll()])
  workplaces.value = workplaceStore.workplaces
})
</script>
