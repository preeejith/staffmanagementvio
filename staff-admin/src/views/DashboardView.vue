<template>
  <div class="space-y-6">
    <!-- Stats Cards -->
    <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
      <div v-for="stat in stats" :key="stat.label"
        :class="['card flex items-center gap-4 cursor-pointer hover:shadow-md transition-shadow', stat.clickable ? 'cursor-pointer' : '']"
        @click="stat.clickable && router.push(stat.link)">
        <div :class="['w-12 h-12 rounded-xl flex items-center justify-center shrink-0', stat.bg]">
          <span class="text-2xl">{{ stat.icon }}</span>
        </div>
        <div>
          <p class="text-sm text-gray-500">{{ stat.label }}</p>
          <p class="text-2xl font-bold text-gray-900">
            <template v-if="isLoading"><span class="inline-block w-16 h-7 bg-gray-200 animate-pulse rounded" /></template>
            <template v-else>{{ stat.value }}</template>
          </p>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
      <!-- Recent Expenses -->
      <div class="xl:col-span-2 card">
        <div class="flex items-center justify-between mb-4">
          <h2 class="font-semibold text-gray-900">Recent Expenses</h2>
          <router-link to="/expenses" class="text-sm text-primary-600 hover:underline">View all →</router-link>
        </div>

        <div v-if="isLoading" class="space-y-3">
          <div v-for="i in 5" :key="i" class="h-12 bg-gray-100 animate-pulse rounded-lg" />
        </div>

        <div v-else-if="recentExpenses.length === 0" class="text-center py-8 text-gray-400">
          No expenses yet
        </div>

        <div v-else class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="text-left text-gray-500 border-b border-gray-100">
                <th class="pb-3 font-medium">Employee</th>
                <th class="pb-3 font-medium">Date</th>
                <th class="pb-3 font-medium">Amount</th>
                <th class="pb-3 font-medium">Status</th>
                <th class="pb-3 font-medium">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
              <tr v-for="exp in recentExpenses" :key="exp.id" class="hover:bg-gray-50 cursor-pointer"
                @click="router.push(`/expenses/${exp.id}`)">
                <td class="py-3 pr-4">
                  <p class="font-medium text-gray-900">{{ exp.employee?.name || '—' }}</p>
                  <p class="text-xs text-gray-400 truncate max-w-[140px]">{{ exp.description }}</p>
                </td>
                <td class="py-3 pr-4 text-gray-600">{{ formatDate(exp.date) }}</td>
                <td class="py-3 pr-4 font-semibold text-gray-900">₹{{ Number(exp.amount).toLocaleString('en-IN') }}</td>
                <td class="py-3 pr-4">
                  <span :class="statusBadge(exp.status)">{{ exp.status }}</span>
                </td>
                <td class="py-3" @click.stop>
                  <div v-if="exp.status === 'pending'" class="flex gap-1">
                    <button class="p-1.5 rounded-lg bg-emerald-50 text-emerald-600 hover:bg-emerald-100" title="Approve"
                      @click="quickAction(exp.id, 'approved')">✓</button>
                    <button class="p-1.5 rounded-lg bg-red-50 text-red-600 hover:bg-red-100" title="Reject"
                      @click="quickAction(exp.id, 'rejected')">✗</button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="space-y-4">
        <div class="card">
          <h2 class="font-semibold text-gray-900 mb-4">Quick Actions</h2>
          <div class="space-y-2">
            <router-link to="/employees/new" class="btn-primary w-full">+ Add Employee</router-link>
            <router-link to="/workplaces/new" class="btn-secondary w-full">+ Add Workplace</router-link>
            <router-link to="/announcements" class="btn-secondary w-full">📢 Announcements</router-link>
          </div>
        </div>

        <div class="card">
          <h2 class="font-semibold text-gray-900 mb-3">Active Employees</h2>
          <div v-if="isLoading" class="space-y-2">
            <div v-for="i in 4" :key="i" class="h-10 bg-gray-100 animate-pulse rounded-lg" />
          </div>
          <ul v-else class="space-y-2">
            <li v-for="emp in recentEmployees" :key="emp.id"
              class="flex items-center gap-3 p-2 rounded-lg hover:bg-gray-50 cursor-pointer"
              @click="router.push(`/employees/${emp.id}`)">
              <div class="w-8 h-8 rounded-full bg-primary-100 text-primary-700 text-sm font-bold flex items-center justify-center shrink-0">
                {{ emp.name?.charAt(0).toUpperCase() }}
              </div>
              <div class="overflow-hidden">
                <p class="text-sm font-medium text-gray-900 truncate">{{ emp.name }}</p>
                <p class="text-xs text-gray-400 truncate">{{ emp.workplace?.name || 'No workplace' }}</p>
              </div>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useExpenseStore } from '@/stores/expenses'
import { useEmployeeStore } from '@/stores/employees'
import { useToast } from 'vue-toastification'

const router = useRouter()
const toast = useToast()
const expenseStore = useExpenseStore()
const employeeStore = useEmployeeStore()
const isLoading = ref(false)

const recentExpenses  = ref([])
const recentEmployees = ref([])
const summaryData = ref({ employees: 0, workplaces: 0, pendingExpenses: 0, monthlyTotal: 0 })

const stats = computed(() => [
  { label: 'Total Employees',   icon: '👥', value: summaryData.value.employees,      bg: 'bg-blue-100',   clickable: false },
  { label: 'Pending Expenses',  icon: '⏳', value: summaryData.value.pendingExpenses, bg: 'bg-amber-100',  clickable: true, link: '/expenses?status=pending' },
  { label: "This Month's Total",icon: '₹',  value: `₹${Number(summaryData.value.monthlyTotal).toLocaleString('en-IN')}`, bg: 'bg-purple-100', clickable: false },
  { label: 'Active Workplaces', icon: '🏢', value: summaryData.value.workplaces,     bg: 'bg-emerald-100', clickable: false },
])

onMounted(async () => {
  isLoading.value = true
  try {
    await Promise.all([
      expenseStore.fetchAll({ limit: 10 }),
      employeeStore.fetchAll({ is_active: true }),
    ])
    recentExpenses.value  = expenseStore.expenses.slice(0, 10)
    recentEmployees.value = employeeStore.employees.slice(0, 5)
    summaryData.value = {
      employees: employeeStore.employees.length,
      pendingExpenses: expenseStore.summary.pending_count,
      monthlyTotal: expenseStore.summary.total_amount,
      workplaces: 0,
    }
  } finally {
    isLoading.value = false
  }
})

async function quickAction(id, status) {
  await expenseStore.updateStatus(id, status)
  recentExpenses.value = expenseStore.expenses.slice(0, 10)
  toast.success(`Expense ${status}`)
}

function statusBadge(status) {
  const map = { pending: 'badge-amber', approved: 'badge-green', rejected: 'badge-red' }
  return map[status] || 'badge-gray'
}

function formatDate(d) {
  return new Date(d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
}
</script>
