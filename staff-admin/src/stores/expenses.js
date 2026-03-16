import { defineStore } from 'pinia'
import api from '@/services/api'

export const useExpenseStore = defineStore('expenses', {
  state: () => ({
    expenses: [],
    summary: { total_amount: 0, total_count: 0, pending_count: 0 },
    current: null,
    isLoading: false,
  }),

  actions: {
    async fetchAll(params = {}) {
      this.isLoading = true
      try {
        const { data: res } = await api.get('/expenses', { params })
        if (res.success) {
          this.expenses = res.data
          this.summary = res.summary
        }
      } finally { this.isLoading = false }
    },

    async fetchById(id) {
      const { data: res } = await api.get(`/expenses/${id}`)
      if (res.success) this.current = res.data
      return res.data
    },

    async updateStatus(id, status, adminNotes = '') {
      const { data: res } = await api.patch(`/expenses/${id}/status`, {
        status, admin_notes: adminNotes,
      })
      if (res.success) {
        const idx = this.expenses.findIndex(e => e.id === id)
        if (idx !== -1) this.expenses[idx] = res.data
      }
      return res
    },

    async exportCSV(params = {}) {
      const response = await api.get('/expenses/export', {
        params,
        responseType: 'blob',
      })
      const url = window.URL.createObjectURL(new Blob([response.data]))
      const link = document.createElement('a')
      link.href = url
      link.setAttribute('download', `expenses_${Date.now()}.csv`)
      document.body.appendChild(link)
      link.click()
      link.remove()
    },
  },
})
