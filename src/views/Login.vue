<template>
  <div class="login-page min-vh-100 d-flex align-items-center">
    <div class="container">
      <div class="row justify-content-center">
        <div class="col-12 col-md-8 col-lg-5">
          <div class="card auth-card shadow-lg border-0">
            <div class="card-body p-4 p-md-5">
              <div class="text-center mb-4">
                <div class="brand-mark mx-auto mb-3">PDH</div>
                <h1 class="h4 fw-bold text-primary mb-1">ระบบฐานข้อมูลแพ้ยา</h1>
                <p class="text-muted mb-0">โรงพยาบาลปลวกแดง</p>
              </div>

              <form @submit.prevent="login">
                <div class="mb-3 text-start">
                  <label class="form-label">Email</label>
                  <input v-model.trim="email" type="email" class="form-control form-control-lg" autocomplete="email" required>
                </div>

                <div class="mb-4 text-start">
                  <label class="form-label">Password</label>
                  <input v-model="password" type="password" class="form-control form-control-lg" autocomplete="current-password" required>
                </div>

                <button class="btn btn-primary btn-lg w-100" type="submit" :disabled="loading">
                  <span v-if="loading" class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>
                  เข้าสู่ระบบ
                </button>
              </form>

              <div class="text-center mt-4">
                <span class="text-muted">ยังไม่มีบัญชี?</span>
                <RouterLink class="fw-semibold text-decoration-none ms-1" to="/register">สมัครสมาชิก</RouterLink>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import Swal from 'sweetalert2'
import { supabase } from '../services/supabase'

const router = useRouter()
const email = ref('')
const password = ref('')
const loading = ref(false)

async function login() {
  if (!email.value || !password.value) {
    Swal.fire('แจ้งเตือน', 'กรุณากรอก Email และ Password', 'warning')
    return
  }

  loading.value = true

  const { error } = await supabase.auth.signInWithPassword({
    email: email.value,
    password: password.value
  })

  loading.value = false

  if (error) {
    Swal.fire('เข้าสู่ระบบไม่สำเร็จ', error.message, 'error')
    return
  }

  await Swal.fire({
    icon: 'success',
    title: 'เข้าสู่ระบบสำเร็จ',
    timer: 1200,
    showConfirmButton: false
  })

  router.push('/dashboard')
}
</script>

<style scoped>
.login-page {
  background: linear-gradient(135deg, #eef7ff 0%, #f8fbff 45%, #ffffff 100%);
}

.auth-card {
  border-radius: 8px;
}

.brand-mark {
  width: 72px;
  height: 72px;
  display: grid;
  place-items: center;
  border-radius: 8px;
  color: #fff;
  font-weight: 800;
  background: linear-gradient(135deg, #0d6efd, #0a58ca);
  letter-spacing: 0;
}
</style>
