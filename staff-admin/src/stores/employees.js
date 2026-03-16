import { defineStore } from 'pinia'
import api from '@/services/api'

export const useEmployeeStore = defineStore('employees', {
  state: () => ({
    employees: [],
    current: null,
    isLoading: false,
    error: null,
  }),

  actions: {
    async fetchAll(params = {}) {
      this.isLoading = true
      try {
        const { data: res } = await api.get('/employees', { params })
        if (res.success) this.employees = res.data
      } finally { this.isLoading = false }
    },

    async fetchById(id) {
      this.isLoading = true
      try {
        const { data: res } = await api.get(`/employees/${id}`)
        if (res.success) this.current = res.data
        return res.data
      } finally { this.isLoading = false }
    },

    async create(payload) {
      const { data: res } = await api.post('/employees', payload)
      if (res.success) this.employees.unshift(res.data)
      return res
    },

    async update(id, payload) {
      const { data: res } = await api.put(`/employees/${id}`, payload)
      if (res.success) {
        const idx = this.employees.findIndex(e => e.id === id)
        if (idx !== -1) this.employees[idx] = res.data
      }
      return res
    },

    async toggleStatus(id) {
      const { data: res } = await api.patch(`/employees/${id}/toggle-status`)
      if (res.success) {
        const idx = this.employees.findIndex(e => e.id === id)
        if (idx !== -1) this.employees[idx] = res.data
      }
      return res
    },

    async resetPassword(userId, newPassword) {
      const { data: res } = await api.post('/auth/reset-password', { userId, newPassword })
      return res
    },
  },
})
