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

              <div class="pdpa-notice border bg-light p-3 mb-4">
                <div class="fw-bold text-danger mb-1">ประกาศคุ้มครองข้อมูลส่วนบุคคลและความลับผู้ป่วย</div>
                <div class="small text-muted">
                  ระบบนี้มีข้อมูลสุขภาพและข้อมูลแพ้ยาซึ่งเป็นข้อมูลอ่อนไหวตามกฎหมายคุ้มครองข้อมูลส่วนบุคคล ผู้ใช้งานต้องเข้าถึง ใช้ เปิดเผย หรือส่งต่อข้อมูลเฉพาะเท่าที่จำเป็นต่อการดูแลรักษาและงานบริการสุขภาพเท่านั้น
                </div>
                <button class="btn btn-link btn-sm p-0 mt-2 text-decoration-none" type="button" @click="showPdpaNotice">
                  อ่านรายละเอียดการใช้งานตาม PDPA
                </button>
              </div>

              <form @submit.prevent="login">
                <div class="mb-3 text-start">
                  <label class="form-label">Email</label>
                  <input v-model.trim="email" type="email" class="form-control form-control-lg" autocomplete="email" required>
                </div>

                <div class="mb-3 text-start">
                  <label class="form-label">Password</label>
                  <input v-model="password" type="password" class="form-control form-control-lg" autocomplete="current-password" required>
                </div>

                <div class="form-check text-start mb-4">
                  <input id="pdpaAccepted" v-model="pdpaAccepted" class="form-check-input" type="checkbox">
                  <label class="form-check-label small" for="pdpaAccepted">
                    ข้าพเจ้ารับทราบและยินยอมปฏิบัติตามประกาศ PDPA การรักษาความลับผู้ป่วย และการใช้งานข้อมูลเฉพาะตามหน้าที่
                  </label>
                </div>

                <button class="btn btn-primary btn-lg w-100" type="submit" :disabled="loading || !pdpaAccepted">
                  <span v-if="loading" class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>
                  เข้าสู่ระบบ
                </button>
              </form>

              <button class="btn btn-link w-100 mt-3 text-decoration-none" type="button" @click="resendConfirmation" :disabled="loading || !email">
                ส่งอีเมลยืนยันอีกครั้ง
              </button>

              <div class="text-center mt-3">
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
const pdpaAccepted = ref(false)
const loading = ref(false)

async function login() {
  if (!email.value || !password.value) {
    Swal.fire('แจ้งเตือน', 'กรุณากรอก Email และ Password', 'warning')
    return
  }

  if (!pdpaAccepted.value) {
    Swal.fire('กรุณารับทราบประกาศ PDPA', 'ต้องรับทราบประกาศคุ้มครองข้อมูลส่วนบุคคลก่อนเข้าสู่ระบบ', 'warning')
    return
  }

  loading.value = true

  const { error } = await supabase.auth.signInWithPassword({
    email: email.value,
    password: password.value
  })

  loading.value = false

  if (error) {
    if (error.message === 'Email not confirmed') {
      const result = await Swal.fire({
        icon: 'warning',
        title: 'ยังไม่ได้ยืนยันอีเมล',
        text: 'กรุณาตรวจสอบอีเมลและกดลิงก์ยืนยันก่อนเข้าสู่ระบบ',
        showCancelButton: true,
        confirmButtonText: 'ส่งอีเมลยืนยันอีกครั้ง',
        cancelButtonText: 'ปิด'
      })

      if (result.isConfirmed) {
        await resendConfirmation()
      }
      return
    }

    Swal.fire('เข้าสู่ระบบไม่สำเร็จ', error.message, 'error')
    return
  }

  localStorage.setItem('pdpaAcceptedAt', new Date().toISOString())

  await Swal.fire({
    icon: 'success',
    title: 'เข้าสู่ระบบสำเร็จ',
    timer: 1200,
    showConfirmButton: false
  })

  router.push('/dashboard')
}

async function resendConfirmation() {
  if (!email.value) {
    Swal.fire('แจ้งเตือน', 'กรุณากรอก Email ก่อนส่งอีเมลยืนยัน', 'warning')
    return
  }

  loading.value = true
  const { error } = await supabase.auth.resend({
    type: 'signup',
    email: email.value
  })
  loading.value = false

  if (error) {
    Swal.fire('ส่งอีเมลยืนยันไม่สำเร็จ', error.message, 'error')
    return
  }

  Swal.fire('ส่งอีเมลแล้ว', 'กรุณาตรวจสอบ Inbox หรือ Spam แล้วกดลิงก์ยืนยันอีเมล', 'success')
}

function showPdpaNotice() {
  Swal.fire({
    icon: 'info',
    title: 'ประกาศการใช้งานข้อมูลตาม PDPA',
    width: 780,
    html: `
      <div class="text-start">
        <p><strong>1. ข้อมูลในระบบเป็นข้อมูลสุขภาพและข้อมูลอ่อนไหว</strong><br>
        ห้ามนำไปใช้ เปิดเผย ถ่ายภาพหน้าจอ ส่งต่อ หรือเผยแพร่ให้บุคคลที่ไม่มีหน้าที่เกี่ยวข้อง</p>

        <p><strong>2. ใช้ข้อมูลเท่าที่จำเป็น</strong><br>
        เข้าถึงข้อมูลเฉพาะเพื่อการดูแลรักษา การประเมินแพ้ยา การออกบัตรแพ้ยา การส่งต่อข้อมูลตามมาตรฐาน และงานคุณภาพบริการสุขภาพเท่านั้น</p>

        <p><strong>3. รักษาความลับผู้ป่วย</strong><br>
        ผู้ใช้งานต้องไม่เปิดเผยชื่อ เลขบัตรประชาชน HN รูปถ่าย อาการ โรคประจำตัว หรือข้อมูลอื่นที่ระบุตัวผู้ป่วยได้โดยไม่จำเป็น</p>

        <p><strong>4. รูปถ่ายประกอบการประเมิน</strong><br>
        รูปถ่ายควรใช้เพื่อประกอบการประเมินแพ้ยาโดยเภสัชกรเท่านั้น และควรหลีกเลี่ยงการถ่ายใบหน้า/ข้อมูลระบุตัวตน เว้นแต่จำเป็นต่อการรักษา</p>

        <p><strong>5. บัญชีผู้ใช้เป็นรายบุคคล</strong><br>
        ห้ามใช้บัญชีร่วมกัน ห้ามบอกรหัสผ่านแก่ผู้อื่น และควรออกจากระบบทุกครั้งหลังใช้งาน</p>

        <p class="mb-0"><strong>6. การใช้งานอาจถูกตรวจสอบย้อนหลัง</strong><br>
        หากพบการใช้งานผิดวัตถุประสงค์ อาจมีการระงับสิทธิ์และดำเนินการตามระเบียบของหน่วยงาน</p>
      </div>
    `,
    confirmButtonText: 'รับทราบ'
  })
}
</script>

<style scoped>
.login-page {
  background: linear-gradient(135deg, #eef7ff 0%, #f8fbff 45%, #ffffff 100%);
}

.auth-card,
.pdpa-notice {
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
