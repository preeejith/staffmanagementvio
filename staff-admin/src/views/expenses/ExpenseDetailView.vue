<template>
  <div v-if="expense" class="max-w-2xl mx-auto space-y-5">
    <div class="flex items-center gap-3">
      <button @click="router.back()" class="p-2 rounded-lg hover:bg-gray-100">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" /></svg>
      </button>
      <h1 class="text-xl font-bold text-gray-900">Expense Detail</h1>
      <span :class="statusBadge(expense.status)" class="ml-auto text-sm px-3 py-1">{{ expense.status }}</span>
    </div>

    <div class="card">
      <div class="flex items-center gap-3 mb-5">
        <div class="w-10 h-10 bg-primary-100 text-primary-700 font-bold rounded-full flex items-center justify-center">
          {{ expense.employee?.name?.charAt(0).toUpperCase() }}
        </div>
        <div>
          <p class="font-semibold text-gray-900">{{ expense.employee?.name }}</p>
          <p class="text-xs text-gray-400">{{ expense.workplace?.name }}</p>
        </div>
      </div>
      <div class="grid grid-cols-2 gap-4 text-sm">
        <div><p class="text-gray-400 text-xs">Date</p><p class="font-medium">{{ formatDate(expense.date) }}</p></div>
        <div><p class="text-gray-400 text-xs">Amount</p><p class="font-bold text-lg text-gray-900">₹{{ Number(expense.amount).toLocaleString('en-IN') }}</p></div>
        <div class="col-span-2"><p class="text-gray-400 text-xs">Description</p><p class="font-medium">{{ expense.description }}</p></div>
      </div>
    </div>

    <!-- Bill Images -->
    <div v-if="expense.bill_image_urls?.length" class="card">
      <h3 class="font-semibold text-gray-900 mb-3">Bills ({{ expense.bill_image_urls.length }})</h3>
      <div class="grid grid-cols-3 gap-3">
        <button v-for="(url, i) in expense.bill_image_urls" :key="i"
          class="aspect-square rounded-xl overflow-hidden border-2 border-gray-200 hover:border-primary-400 transition-colors"
          @click="lightboxIndex = i">
          <img :src="url" class="w-full h-full object-cover" :alt="`Bill ${i + 1}`" />
        </button>
      </div>
    </div>

    <!-- Admin Notes (if approved/rejected) -->
    <div v-if="expense.admin_notes" class="card border-l-4" :class="expense.status === 'rejected' ? 'border-red-400' : 'border-emerald-400'">
      <p class="text-xs text-gray-400 mb-1">Admin Notes</p>
      <p class="text-sm text-gray-700">{{ expense.admin_notes }}</p>
    </div>

    <!-- Action Buttons (pending only) -->
    <div v-if="expense.status === 'pending'" class="card">
      <h3 class="font-semibold text-gray-900 mb-3">Take Action</h3>
      <textarea v-model="adminNotes" rows="2" class="input mb-3" placeholder="Notes (optional for approval, recommended for rejection)" />
      <div class="flex gap-3">
        <button class="btn-success flex-1" @click="updateStatus('approved')">✓ Approve</button>
        <button class="btn-danger flex-1" @click="updateStatus('rejected')">✗ Reject</button>
      </div>
    </div>

    <!-- Lightbox -->
    <div v-if="lightboxIndex !== null" class="fixed inset-0 bg-black/90 flex items-center justify-center z-50"
      @click.self="lightboxIndex = null">
      <button class="absolute top-4 right-4 text-white text-2xl" @click="lightboxIndex = null">✕</button>
      <button v-if="lightboxIndex > 0" class="absolute left-4 text-white text-3xl" @click="lightboxIndex--">‹</button>
      <img :src="expense.bill_image_urls[lightboxIndex]" class="max-w-3xl max-h-[85vh] rounded-xl object-contain" />
      <button v-if="lightboxIndex < expense.bill_image_urls.length - 1" class="absolute right-4 text-white text-3xl" @click="lightboxIndex++">›</button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useExpenseStore } from '@/stores/expenses'
import { useToast } from 'vue-toastification'

const router = useRouter()
const route = useRoute()
const toast = useToast()
const expenseStore = useExpenseStore()

const expense = ref(null)
const adminNotes = ref('')
const lightboxIndex = ref(null)

onMounted(async () => {
  expense.value = await expenseStore.fetchById(route.params.id)
})

async function updateStatus(status) {
  await expenseStore.updateStatus(expense.value.id, status, adminNotes.value)
  expense.value.status = status
  expense.value.admin_notes = adminNotes.value
  toast.success(`Expense ${status}`)
}

function statusBadge(s) {
  return { pending: 'badge-amber', approved: 'badge-green', rejected: 'badge-red' }[s] || 'badge-gray'
}
function formatDate(d) {
  return new Date(d).toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' })
}
</script>
