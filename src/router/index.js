import { createRouter, createWebHashHistory } from 'vue-router'
import { supabase } from '../services/supabase'
import Login from '../views/Login.vue'
import Register from '../views/Register.vue'
import Dashboard from '../views/Dashboard.vue'

const routes = [
  { path: '/', redirect: '/login' },
  { path: '/login', component: Login, meta: { guestOnly: true } },
  { path: '/register', component: Register, meta: { guestOnly: true } },
  { path: '/dashboard', component: Dashboard, meta: { requiresAuth: true } }
]

const OTP_VALID_MS = 12 * 60 * 60 * 1000

function hasRecentEmailOtp() {
  const verifiedAt = localStorage.getItem('emailOtpVerifiedAt')
  if (!verifiedAt) return false

  return Date.now() - new Date(verifiedAt).getTime() < OTP_VALID_MS
}

const router = createRouter({
  history: createWebHashHistory(),
  routes
})

router.beforeEach(async (to) => {
  const { data } = await supabase.auth.getSession()
  const isLoggedIn = Boolean(data.session)
  const otpVerified = hasRecentEmailOtp()

  if (to.meta.requiresAuth && !isLoggedIn) {
    return '/login'
  }

  if (to.meta.requiresAuth && isLoggedIn && !otpVerified) {
    await supabase.auth.signOut()
    localStorage.removeItem('emailOtpVerifiedAt')
    return '/login'
  }

  if (to.meta.guestOnly && isLoggedIn && otpVerified) {
    return '/dashboard'
  }

  return true
})

export default router
