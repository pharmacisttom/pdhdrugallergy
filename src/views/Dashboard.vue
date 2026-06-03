<template>
  <div class="dashboard-page min-vh-100">
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary shadow-sm">
      <div class="container-fluid">
        <span class="navbar-brand fw-bold">PDH Drug Allergy</span>
        <div class="d-flex align-items-center gap-3">
          <span class="text-white small d-none d-md-inline">{{ userEmail }}</span>
          <button class="btn btn-light btn-sm" @click="logout" :disabled="loading">Logout</button>
        </div>
      </div>
    </nav>

    <div class="container-fluid">
      <div class="row">
        <aside class="col-lg-2 sidebar p-3 d-none d-lg-block">
          <div class="fw-bold text-primary mb-3">ระบบฐานข้อมูลแพ้ยา</div>
          <div class="nav flex-column gap-1">
            <span class="nav-link active">Dashboard</span>
            <span class="nav-link text-muted">Patients</span>
            <span class="nav-link text-muted">Drug Allergy</span>
            <span class="nav-link text-muted">Organizations</span>
          </div>
        </aside>

        <main class="col-lg-10 p-4">
          <div class="d-flex flex-column flex-md-row justify-content-between gap-3 mb-4">
            <div>
              <h1 class="h3 fw-bold text-primary mb-1">Dashboard</h1>
              <p class="text-muted mb-0">ระบบฐานข้อมูลแพ้ยา โรงพยาบาลปลวกแดง</p>
            </div>
            <div class="user-box bg-white border px-3 py-2">
              <div class="small text-muted">ผู้ใช้งาน</div>
              <div class="fw-semibold">{{ userEmail }}</div>
            </div>
          </div>

          <div class="row g-3">
            <div v-for="card in summaryCards" :key="card.label" class="col-12 col-md-6 col-xl-3">
              <div class="card summary-card border-0 shadow-sm h-100">
                <div class="card-body">
                  <div class="d-flex justify-content-between align-items-start">
                    <div>
                      <div class="text-muted small">{{ card.label }}</div>
                      <div class="display-6 fw-bold text-primary mb-0">{{ card.value }}</div>
                    </div>
                    <div class="summary-icon">{{ card.short }}</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <section class="mt-4 bg-white border dashboard-panel p-4">
            <h2 class="h5 fw-bold mb-2">ภาพรวม Phase 1</h2>
            <p class="text-muted mb-0">
              Login, Register, Logout และ Session Guard เชื่อมต่อ Supabase Auth แล้ว พร้อมต่อยอดฐานข้อมูลผู้ป่วยและรายการแพ้ยาใน Phase ถัดไป
            </p>
          </section>
        </main>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import Swal from 'sweetalert2'
import { supabase } from '../services/supabase'

const router = useRouter()
const userEmail = ref('')
const loading = ref(false)

const summaryCards = [
  { label: 'ผู้ป่วยทั้งหมด', value: '1,248', short: 'PT' },
  { label: 'รายการแพ้ยา', value: '326', short: 'DA' },
  { label: 'รออนุมัติ', value: '18', short: 'RV' },
  { label: 'หน่วยบริการ', value: '14', short: 'ORG' }
]

onMounted(async () => {
  const { data } = await supabase.auth.getUser()
  userEmail.value = data.user?.email || '-'
})

async function logout() {
  loading.value = true
  const { error } = await supabase.auth.signOut()
  loading.value = false

  if (error) {
    Swal.fire('ออกจากระบบไม่สำเร็จ', error.message, 'error')
    return
  }

  await Swal.fire({
    icon: 'success',
    title: 'ออกจากระบบแล้ว',
    timer: 1000,
    showConfirmButton: false
  })

  router.push('/login')
}
</script>

<style scoped>
.dashboard-page {
  background: #f4f8fc;
}

.sidebar {
  min-height: calc(100vh - 56px);
  background: #fff;
  border-right: 1px solid #e5edf5;
}

.nav-link {
  border-radius: 8px;
}

.nav-link.active {
  color: #0d6efd;
  background: #eef6ff;
  font-weight: 700;
}

.user-box,
.summary-card,
.dashboard-panel {
  border-radius: 8px;
}

.summary-icon {
  width: 44px;
  height: 44px;
  display: grid;
  place-items: center;
  border-radius: 8px;
  color: #0d6efd;
  background: #eef6ff;
  font-weight: 800;
  font-size: 0.82rem;
  letter-spacing: 0;
}
</style>
