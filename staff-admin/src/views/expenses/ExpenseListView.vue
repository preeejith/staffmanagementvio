<template>
  <div class="space-y-5">
    <div class="flex items-center justify-between">
      <h1 class="text-xl font-bold text-gray-900">Expense Monitoring</h1>
      <button class="btn-secondary text-sm" @click="exportCSV">⬇ Export CSV</button>
    </div>

    <!-- Summary bar -->
    <div class="grid grid-cols-3 gap-4">
      <div class="card text-center py-3">
        <p class="text-xl font-bold text-gray-900">₹{{ Number(expenseStore.summary.total_amount).toLocaleString('en-IN') }}</p>
        <p class="text-xs text-gray-500 mt-0.5">Total Amount</p>
      </div>
      <div class="card text-center py-3">
        <p class="text-xl font-bold text-gray-900">{{ expenseStore.summary.total_count }}</p>
        <p class="text-xs text-gray-500 mt-0.5">Total Expenses</p>
      </div>
      <div class="card text-center py-3 cursor-pointer" @click="filters.status = 'pending'; fetchExpenses()">
        <p class="text-xl font-bold text-amber-600">{{ expenseStore.summary.pending_count }}</p>
        <p class="text-xs text-gray-500 mt-0.5">Pending</p>
      </div>
    </div>

    <!-- Filters -->
    <div class="card">
      <div class="flex flex-wrap gap-3">
        <input v-model="filters.search" type="search" placeholder="Search description..." class="input max-w-[200px]" @input="debouncedFetch" />
        <select v-model="filters.status" class="input max-w-[160px]" @change="fetchExpenses">
          <option value="">All Status</option>
          <option value="pending">Pending</option>
          <option value="approved">Approved</option>
          <option value="rejected">Rejected</option>
        </select>
        <input v-model="filters.from_date" type="date" class="input max-w-[160px]" @change="fetchExpenses" />
        <input v-model="filters.to_date" type="date" class="input max-w-[160px]" @change="fetchExpenses" />
        <button class="btn-secondary text-sm" @click="clearFilters">Clear</button>
      </div>
    </div>

    <!-- Table -->
    <div class="card p-0 overflow-hidden">
      <div v-if="expenseStore.isLoading" class="p-6 space-y-3">
        <div v-for="i in 6" :key="i" class="h-12 bg-gray-100 animate-pulse rounded-lg" />
      </div>
      <div v-else-if="expenseStore.expenses.length === 0" class="text-center py-16 text-gray-400">
        <div class="text-4xl mb-3">🧾</div>
        <p class="font-medium">No expenses found</p>
      </div>
      <table v-else class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-200">
          <tr class="text-left text-gray-500">
            <th class="px-6 py-3 font-medium">Employee</th>
            <th class="px-4 py-3 font-medium hidden md:table-cell">Date</th>
            <th class="px-4 py-3 font-medium">Amount</th>
            <th class="px-4 py-3 font-medium">Status</th>
            <th class="px-4 py-3 font-medium">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          <tr v-for="exp in expenseStore.expenses" :key="exp.id" class="hover:bg-gray-50 cursor-pointer"
            @click="router.push(`/expenses/${exp.id}`)">
            <td class="px-6 py-4">
              <p class="font-medium text-gray-900">{{ exp.employee?.name || '—' }}</p>
              <p class="text-xs text-gray-400 truncate max-w-[200px]">{{ exp.description }}</p>
            </td>
            <td class="px-4 py-4 text-gray-600 hidden md:table-cell">{{ formatDate(exp.date) }}</td>
            <td class="px-4 py-4 font-semibold text-gray-900">₹{{ Number(exp.amount).toLocaleString('en-IN') }}</td>
            <td class="px-4 py-4"><span :class="statusBadge(exp.status)">{{ exp.status }}</span></td>
            <td class="px-4 py-4" @click.stop>
              <div v-if="exp.status === 'pending'" class="flex gap-1">
                <button class="p-1.5 rounded-lg bg-emerald-50 text-emerald-600 hover:bg-emerald-100" @click="quickUpdate(exp.id, 'approved')">✓</button>
                <button class="p-1.5 rounded-lg bg-red-50 text-red-600 hover:bg-red-100" @click="rejectModal = exp; rejectNotes = ''">✗</button>
              </div>
              <router-link v-else :to="`/expenses/${exp.id}`" class="text-xs text-primary-600 hover:underline">View</router-link>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Reject Modal -->
    <div v-if="rejectModal" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div class="bg-white rounded-xl shadow-xl p-6 w-full max-w-md">
        <h3 class="font-semibold text-gray-900 mb-4">Reject Expense</h3>
        <textarea v-model="rejectNotes" rows="3" class="input mb-4" placeholder="Reason for rejection (optional)" />
        <div class="flex gap-2">
          <button class="btn-secondary flex-1" @click="rejectModal = null">Cancel</button>
          <button class="btn-danger flex-1" @click="confirmReject">Reject</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useExpenseStore } from '@/stores/expenses'
import { useToast } from 'vue-toastification'

const router = useRouter()
const toast = useToast()
const expenseStore = useExpenseStore()

const rejectModal = ref(null)
const rejectNotes = ref('')
const filters = reactive({ search: '', status: '', from_date: '', to_date: '' })
let debounceTimer = null

function debouncedFetch() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(fetchExpenses, 350)
}

async function fetchExpenses() {
  const params = {}
  if (filters.search)    params.search    = filters.search
  if (filters.status)    params.status    = filters.status
  if (filters.from_date) params.from_date = filters.from_date
  if (filters.to_date)   params.to_date   = filters.to_date
  await expenseStore.fetchAll(params)
}

function clearFilters() {
  Object.assign(filters, { search: '', status: '', from_date: '', to_date: '' })
  fetchExpenses()
}

async function quickUpdate(id, status) {
  await expenseStore.updateStatus(id, status)
  toast.success(`Expense ${status}`)
}

async function confirmReject() {
  await expenseStore.updateStatus(rejectModal.value.id, 'rejected', rejectNotes.value)
  toast.success('Expense rejected')
  rejectModal.value = null
}

async function exportCSV() {
  const params = {}
  if (filters.status)    params.status    = filters.status
  if (filters.from_date) params.from_date = filters.from_date
  if (filters.to_date)   params.to_date   = filters.to_date
  await expenseStore.exportCSV(params)
}

function statusBadge(s) {
  return { pending: 'badge-amber', approved: 'badge-green', rejected: 'badge-red' }[s] || 'badge-gray'
}
function formatDate(d) {
  return new Date(d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })
}

onMounted(fetchExpenses)
</script>
