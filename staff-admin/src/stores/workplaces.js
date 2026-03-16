import { defineStore } from 'pinia'
import api from '@/services/api'

export const useWorkplaceStore = defineStore('workplaces', {
  state: () => ({ workplaces: [], current: null, isLoading: false }),

  actions: {
    async fetchAll() {
      this.isLoading = true
      try {
        const { data: res } = await api.get('/workplaces')
        if (res.success) this.workplaces = res.data
      } finally { this.isLoading = false }
    },

    async fetchById(id) {
      const { data: res } = await api.get(`/workplaces/${id}`)
      if (res.success) this.current = res.data
      return res.data
    },

    async create(payload) {
      const { data: res } = await api.post('/workplaces', payload)
      if (res.success) this.workplaces.unshift(res.data)
      return res
    },

    async update(id, payload) {
      const { data: res } = await api.put(`/workplaces/${id}`, payload)
      if (res.success) {
        const idx = this.workplaces.findIndex(w => w.id === id)
        if (idx !== -1) this.workplaces[idx] = res.data
      }
      return res
    },

    async assign(id, employeeIds) {
      const { data: res } = await api.patch(`/workplaces/${id}/assign`, { employee_ids: employeeIds })
      return res
    },

    async toggleStatus(id) {
      const { data: res } = await api.patch(`/workplaces/${id}/toggle-status`)
      if (res.success) {
        const idx = this.workplaces.findIndex(w => w.id === id)
        if (idx !== -1) this.workplaces[idx] = res.data
      }
      return res
    },
  },
})
