<template>
  <div class="register-page min-vh-100 d-flex align-items-center">
    <div class="container">
      <div class="row justify-content-center">
        <div class="col-12 col-md-9 col-lg-6">
          <div class="card auth-card shadow-lg border-0">
            <div class="card-body p-4 p-md-5">
              <div class="text-center mb-4">
                <div class="brand-mark mx-auto mb-3">PDH</div>
                <h1 class="h4 fw-bold text-primary mb-1">สมัครสมาชิก</h1>
                <p class="text-muted mb-0">ระบบฐานข้อมูลแพ้ยา โรงพยาบาลปลวกแดง</p>
              </div>

              <form @submit.prevent="register">
                <div class="row g-3 text-start">
                  <div class="col-12">
                    <label class="form-label">ชื่อ-สกุล</label>
                    <input v-model.trim="fullname" type="text" class="form-control form-control-lg" autocomplete="name" required>
                  </div>

                  <div class="col-12">
                    <label class="form-label">Email</label>
                    <input v-model.trim="email" type="email" class="form-control form-control-lg" autocomplete="email" required>
                  </div>

                  <div class="col-md-5">
                    <label class="form-label">HOSPCODE</label>
                    <input v-model.trim="hospcode" type="text" class="form-control form-control-lg" placeholder="รหัสหน่วยบริการ">
                  </div>

                  <div class="col-md-7">
                    <label class="form-label">หน่วยงาน/รพ.สต.</label>
                    <input v-model.trim="organization" type="text" class="form-control form-control-lg" placeholder="เช่น รพ.สต.บ้าน..." required>
                  </div>

                  <div class="col-md-6">
                    <label class="form-label">Password</label>
                    <input v-model="password" type="password" class="form-control form-control-lg" autocomplete="new-password" required>
                  </div>

                  <div class="col-md-6">
                    <label class="form-label">Confirm Password</label>
                    <input v-model="confirmPassword" type="password" class="form-control form-control-lg" autocomplete="new-password" required>
                  </div>
                </div>

                <button class="btn btn-primary btn-lg w-100 mt-4" type="submit" :disabled="loading">
                  <span v-if="loading" class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>
                  สมัครสมาชิก
                </button>
              </form>

              <div class="text-center mt-4">
                <span class="text-muted">มีบัญชีแล้ว?</span>
                <RouterLink class="fw-semibold text-decoration-none ms-1" to="/login">เข้าสู่ระบบ</RouterLink>
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
const fullname = ref('')
const email = ref('')
const hospcode = ref('')
const organization = ref('')
const password = ref('')
const confirmPassword = ref('')
const loading = ref(false)

async function register() {
  if (password.value !== confirmPassword.value) {
    Swal.fire('แจ้งเตือน', 'Password และ Confirm Password ไม่ตรงกัน', 'warning')
    return
  }

  if (password.value.length < 6) {
    Swal.fire('แจ้งเตือน', 'Password ต้องมีอย่างน้อย 6 ตัวอักษร', 'warning')
    return
  }

  loading.value = true

  const { error } = await supabase.auth.signUp({
    email: email.value,
    password: password.value,
    options: {
      data: {
        fullname: fullname.value,
        organization: organization.value,
        hospcode: hospcode.value
      }
    }
  })

  loading.value = false

  if (error) {
    Swal.fire('สมัครสมาชิกไม่สำเร็จ', error.message, 'error')
    return
  }

  await Swal.fire({
    icon: 'success',
    title: 'สมัครสมาชิกสำเร็จ',
    text: 'กรุณายืนยันอีเมล จากนั้นรอแอดมินอนุมัติสิทธิ์และผูกกับ รพ.สต.',
    confirmButtonText: 'ตกลง'
  })

  router.push('/login')
}
</script>

<style scoped>
.register-page {
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
