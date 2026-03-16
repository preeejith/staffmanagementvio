import { defineStore } from 'pinia'
import api from '@/services/api'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null,
    token: null,
    isLoading: false,
    error: null,
  }),

  getters: {
    isAuthenticated: (state) => !!state.token && !!state.user,
    isAdmin: (state) => ['admin', 'superadmin'].includes(state.user?.role),
    isSuperAdmin: (state) => state.user?.role === 'superadmin',
    userFullName: (state) => state.user?.name || state.user?.email || 'User',
  },

  actions: {
    async login(email, password) {
      this.isLoading = true
      this.error = null
      try {
        const { data: res } = await api.post('/auth/login', { email, password })
        if (!res.success) throw new Error(res.error || 'Login failed')

        this.user = res.data.user
        this.token = res.data.session.access_token

        localStorage.setItem('staff_token', this.token)
        localStorage.setItem('staff_user', JSON.stringify(this.user))
        return true
      } catch (err) {
        this.error = err.response?.data?.error || err.message || 'Login failed'
        return false
      } finally {
        this.isLoading = false
      }
    },

    async logout() {
      try { await api.post('/auth/logout') } catch (_) { /* ignore */ }
      this.user = null
      this.token = null
      localStorage.removeItem('staff_token')
      localStorage.removeItem('staff_user')
    },

    async fetchMe() {
      const { data: res } = await api.get('/auth/me')
      if (res.success) this.user = res.data
    },

    async initializeAuth() {
      const token = localStorage.getItem('staff_token')
      const savedUser = localStorage.getItem('staff_user')
      if (!token) return

      this.token = token
      this.user = savedUser ? JSON.parse(savedUser) : null

      try {
        await this.fetchMe()
      } catch (_) {
        // Token expired — clear session
        this.token = null
        this.user = null
        localStorage.removeItem('staff_token')
        localStorage.removeItem('staff_user')
      }
    },

    clearError() { this.error = null },
  },
})
