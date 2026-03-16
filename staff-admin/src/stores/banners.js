import { defineStore } from 'pinia'
import api from '@/services/api'

export const useBannerStore = defineStore('banners', {
  state: () => ({ banners: [], isLoading: false }),

  actions: {
    async fetchAll() {
      this.isLoading = true
      try {
        const { data: res } = await api.get('/banners')
        if (res.success) this.banners = res.data
      } finally { this.isLoading = false }
    },

    async create(payload) {
      const { data: res } = await api.post('/banners', payload)
      if (res.success) this.banners.push(res.data)
      return res
    },

    async update(id, payload) {
      const { data: res } = await api.put(`/banners/${id}`, payload)
      if (res.success) {
        const idx = this.banners.findIndex(b => b.id === id)
        if (idx !== -1) this.banners[idx] = res.data
      }
      return res
    },

    async toggle(id) {
      const { data: res } = await api.patch(`/banners/${id}/toggle`)
      if (res.success) {
        const idx = this.banners.findIndex(b => b.id === id)
        if (idx !== -1) this.banners[idx] = res.data
      }
      return res
    },

    async reorder(orderedIds) {
      await api.patch('/banners/reorder', { ordered_ids: orderedIds })
    },

    async remove(id) {
      await api.delete(`/banners/${id}`)
      this.banners = this.banners.filter(b => b.id !== id)
    },
  },
})
