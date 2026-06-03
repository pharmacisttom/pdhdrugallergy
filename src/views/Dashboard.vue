<template>
  <div class="dashboard-page min-vh-100">
    <nav class="navbar navbar-expand-lg navbar-dark bg-primary shadow-sm">
      <div class="container-fluid">
        <span class="navbar-brand fw-bold">PDH Drug Allergy</span>
        <div class="d-flex align-items-center gap-3">
          <span class="badge bg-light text-primary">{{ roleLabel }}</span>
          <span class="text-white small d-none d-md-inline">{{ userEmail }}</span>
          <button class="btn btn-light btn-sm" @click="logout" :disabled="authLoading">Logout</button>
        </div>
      </div>
    </nav>

    <div class="container-fluid">
      <div class="row">
        <aside class="col-lg-2 sidebar p-3 d-none d-lg-block">
          <div class="fw-bold text-primary mb-3">ระบบฐานข้อมูลแพ้ยา</div>
          <div class="nav flex-column gap-1">
            <button class="nav-link text-start" :class="{ active: activeTab === 'overview' }" @click="activeTab = 'overview'">Dashboard</button>
            <button class="nav-link text-start" :class="{ active: activeTab === 'patients' }" @click="activeTab = 'patients'">Patients</button>
            <button class="nav-link text-start" :class="{ active: activeTab === 'allergies' }" @click="activeTab = 'allergies'">Drug Allergy</button>
          </div>
        </aside>

        <main class="col-lg-10 p-3 p-md-4">
          <div class="d-flex flex-column flex-md-row justify-content-between gap-3 mb-4">
            <div>
              <h1 class="h3 fw-bold text-primary mb-1">ระบบฐานข้อมูลแพ้ยา</h1>
              <p class="text-muted mb-0">โรงพยาบาลปลวกแดง</p>
            </div>
            <div class="user-box bg-white border px-3 py-2">
              <div class="small text-muted">ผู้ใช้งาน</div>
              <div class="fw-semibold">{{ userEmail }}</div>
            </div>
          </div>

          <div v-if="setupError" class="alert alert-warning border-0 shadow-sm">
            <div class="fw-semibold mb-1">ยังเชื่อมต่อฐานข้อมูลไม่สำเร็จ</div>
            <div>{{ setupError }}</div>
            <div class="small mt-2">ให้นำไฟล์ <code>supabase/schema.sql</code> ไปรันใน Supabase SQL Editor ก่อนใช้งานหน้านี้</div>
          </div>

          <div v-if="!isAdmin" class="alert alert-info border-0 shadow-sm">
            บัญชีนี้เป็นสิทธิ์เจ้าหน้าที่ สามารถบันทึกข้อมูลผู้ป่วยและรายการแพ้ยาได้ แต่การยืนยัน/ยกเลิก/ลบรายการจำกัดเฉพาะแอดมิน
          </div>

          <div class="row g-3 mb-4">
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

          <section v-if="activeTab === 'overview'" class="dashboard-panel bg-white border p-4">
            <div class="d-flex flex-column flex-md-row justify-content-between gap-3 mb-3">
              <div>
                <h2 class="h5 fw-bold mb-1">รายการแพ้ยาล่าสุด</h2>
                <p class="text-muted">ติดตามสถานะรายการรออนุมัติและรายการที่ยืนยันแล้ว</p>
              </div>
              <button class="btn btn-outline-primary align-self-start" @click="exportCsv">Export CSV</button>
            </div>

            <div class="table-responsive">
              <table class="table table-hover align-middle">
                <thead>
                  <tr>
                    <th>HN</th>
                    <th>ชื่อ-สกุล</th>
                    <th>ยา</th>
                    <th>อาการ</th>
                    <th>ความรุนแรง</th>
                    <th>สถานะ</th>
                    <th class="text-end">จัดการ</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="record in recentAllergies" :key="record.id">
                    <td>{{ record.patients?.hn || '-' }}</td>
                    <td>{{ record.patients?.full_name || '-' }}</td>
                    <td class="fw-semibold">{{ record.drug_name }}</td>
                    <td>{{ record.reaction }}</td>
                    <td>{{ record.severity }}</td>
                    <td><span class="badge" :class="statusClass(record.status)">{{ record.status }}</span></td>
                    <td class="text-end">
                      <button class="btn btn-sm btn-outline-success me-2" @click="reviewAllergy(record, 'ยืนยันแล้ว')" :disabled="!isAdmin || record.status === 'ยืนยันแล้ว'">ยืนยัน</button>
                      <button class="btn btn-sm btn-outline-secondary" @click="reviewAllergy(record, 'ยกเลิก')" :disabled="!isAdmin || record.status === 'ยกเลิก'">ยกเลิก</button>
                    </td>
                  </tr>
                  <tr v-if="recentAllergies.length === 0">
                    <td colspan="7" class="text-center text-muted py-4">ยังไม่มีรายการแพ้ยา</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          <section v-if="activeTab === 'patients'" class="row g-3">
            <div class="col-xl-4">
              <div class="dashboard-panel bg-white border p-4">
                <h2 class="h5 fw-bold mb-3">{{ patientForm.id ? 'แก้ไขข้อมูลผู้ป่วย' : 'เพิ่มผู้ป่วย' }}</h2>
                <form @submit.prevent="savePatient" class="row g-3">
                  <div class="col-md-6 col-xl-12">
                    <label class="form-label">HN</label>
                    <input v-model.trim="patientForm.hn" class="form-control" required>
                  </div>
                  <div class="col-md-6 col-xl-12">
                    <label class="form-label">เลขบัตรประชาชน</label>
                    <input v-model.trim="patientForm.cid" class="form-control">
                  </div>
                  <div class="col-12">
                    <label class="form-label">ชื่อ-สกุล</label>
                    <input v-model.trim="patientForm.full_name" class="form-control" required>
                  </div>
                  <div class="col-md-6">
                    <label class="form-label">วันเกิด</label>
                    <input v-model="patientForm.birth_date" type="date" class="form-control">
                  </div>
                  <div class="col-md-6">
                    <label class="form-label">เพศ</label>
                    <select v-model="patientForm.sex" class="form-select">
                      <option>ไม่ระบุ</option>
                      <option>ชาย</option>
                      <option>หญิง</option>
                    </select>
                  </div>
                  <div class="col-12">
                    <label class="form-label">เบอร์โทร</label>
                    <input v-model.trim="patientForm.phone" class="form-control">
                  </div>
                  <div class="col-12">
                    <label class="form-label">ที่อยู่</label>
                    <textarea v-model.trim="patientForm.address" class="form-control" rows="2"></textarea>
                  </div>
                  <div class="col-12 d-flex gap-2">
                    <button class="btn btn-primary" type="submit" :disabled="dataLoading">{{ patientForm.id ? 'บันทึก' : 'เพิ่มผู้ป่วย' }}</button>
                    <button class="btn btn-outline-secondary" type="button" @click="resetPatientForm">ล้างฟอร์ม</button>
                  </div>
                </form>
              </div>
            </div>

            <div class="col-xl-8">
              <div class="dashboard-panel bg-white border p-4">
                <div class="d-flex flex-column flex-md-row justify-content-between gap-3 mb-3">
                  <h2 class="h5 fw-bold mb-0">ทะเบียนผู้ป่วย</h2>
                  <input v-model.trim="searchText" class="form-control search-box" placeholder="ค้นหา HN, ชื่อ, เลขบัตร">
                </div>

                <div class="table-responsive">
                  <table class="table table-hover align-middle">
                    <thead>
                      <tr>
                        <th>HN</th>
                        <th>ชื่อ-สกุล</th>
                        <th>เพศ</th>
                        <th>เบอร์โทร</th>
                        <th class="text-end">จัดการ</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="patient in filteredPatients" :key="patient.id">
                        <td class="fw-semibold">{{ patient.hn }}</td>
                        <td>{{ patient.full_name }}</td>
                        <td>{{ patient.sex }}</td>
                        <td>{{ patient.phone || '-' }}</td>
                        <td class="text-end">
                          <button class="btn btn-sm btn-outline-primary me-2" @click="editPatient(patient)">แก้ไข</button>
                          <button class="btn btn-sm btn-outline-danger" @click="deletePatient(patient)" :disabled="!isAdmin">ลบ</button>
                        </td>
                      </tr>
                      <tr v-if="filteredPatients.length === 0">
                        <td colspan="5" class="text-center text-muted py-4">ยังไม่มีข้อมูลผู้ป่วย</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </section>

          <section v-if="activeTab === 'allergies'" class="row g-3">
            <div class="col-xl-4">
              <div class="dashboard-panel bg-white border p-4">
                <h2 class="h5 fw-bold mb-3">เพิ่มรายการแพ้ยา</h2>
                <form @submit.prevent="saveAllergy" class="row g-3">
                  <div class="col-12">
                    <label class="form-label">ผู้ป่วย</label>
                    <select v-model="allergyForm.patient_id" class="form-select" required>
                      <option value="" disabled>เลือกผู้ป่วย</option>
                      <option v-for="patient in patients" :key="patient.id" :value="patient.id">{{ patient.hn }} - {{ patient.full_name }}</option>
                    </select>
                  </div>
                  <div class="col-12">
                    <label class="form-label">ชื่อยา</label>
                    <input v-model.trim="allergyForm.drug_name" class="form-control" required>
                  </div>
                  <div class="col-12">
                    <label class="form-label">Generic name</label>
                    <input v-model.trim="allergyForm.generic_name" class="form-control">
                  </div>
                  <div class="col-12">
                    <label class="form-label">อาการแพ้</label>
                    <textarea v-model.trim="allergyForm.reaction" class="form-control" rows="2" required></textarea>
                  </div>
                  <div class="col-md-6">
                    <label class="form-label">ความรุนแรง</label>
                    <select v-model="allergyForm.severity" class="form-select">
                      <option>ไม่ระบุ</option>
                      <option>ไม่รุนแรง</option>
                      <option>ปานกลาง</option>
                      <option>รุนแรง</option>
                    </select>
                  </div>
                  <div class="col-md-6">
                    <label class="form-label">วันที่พบอาการ</label>
                    <input v-model="allergyForm.onset_date" type="date" class="form-control">
                  </div>
                  <div class="col-12">
                    <label class="form-label">แหล่งข้อมูล</label>
                    <input v-model.trim="allergyForm.source" class="form-control" placeholder="เช่น OPD, IPD, ผู้ป่วยแจ้ง">
                  </div>
                  <div class="col-12">
                    <label class="form-label">หมายเหตุ</label>
                    <textarea v-model.trim="allergyForm.note" class="form-control" rows="2"></textarea>
                  </div>
                  <div class="col-12 d-flex gap-2">
                    <button class="btn btn-primary" type="submit" :disabled="dataLoading">บันทึกรายการแพ้ยา</button>
                    <button class="btn btn-outline-secondary" type="button" @click="resetAllergyForm">ล้างฟอร์ม</button>
                  </div>
                </form>
              </div>
            </div>

            <div class="col-xl-8">
              <div class="dashboard-panel bg-white border p-4">
                <div class="d-flex flex-column flex-md-row justify-content-between gap-3 mb-3">
                  <h2 class="h5 fw-bold mb-0">ทะเบียนแพ้ยา</h2>
                  <input v-model.trim="searchText" class="form-control search-box" placeholder="ค้นหา HN, ชื่อผู้ป่วย, ชื่อยา">
                </div>

                <div class="table-responsive">
                  <table class="table table-hover align-middle">
                    <thead>
                      <tr>
                        <th>ผู้ป่วย</th>
                        <th>ยา</th>
                        <th>อาการ</th>
                        <th>ความรุนแรง</th>
                        <th>สถานะ</th>
                        <th class="text-end">จัดการ</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="record in filteredAllergies" :key="record.id">
                        <td>
                          <div class="fw-semibold">{{ record.patients?.hn || '-' }}</div>
                          <div class="small text-muted">{{ record.patients?.full_name || '-' }}</div>
                        </td>
                        <td>
                          <div class="fw-semibold">{{ record.drug_name }}</div>
                          <div class="small text-muted">{{ record.generic_name || '-' }}</div>
                        </td>
                        <td>{{ record.reaction }}</td>
                        <td>{{ record.severity }}</td>
                        <td><span class="badge" :class="statusClass(record.status)">{{ record.status }}</span></td>
                        <td class="text-end">
                          <button class="btn btn-sm btn-outline-success me-2" @click="reviewAllergy(record, 'ยืนยันแล้ว')" :disabled="!isAdmin">ยืนยัน</button>
                          <button class="btn btn-sm btn-outline-danger" @click="deleteAllergy(record)" :disabled="!isAdmin">ลบ</button>
                        </td>
                      </tr>
                      <tr v-if="filteredAllergies.length === 0">
                        <td colspan="6" class="text-center text-muted py-4">ยังไม่มีรายการแพ้ยา</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </section>
        </main>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import Swal from 'sweetalert2'
import { supabase } from '../services/supabase'

const router = useRouter()
const activeTab = ref('overview')
const userEmail = ref('')
const userId = ref('')
const userRole = ref('staff')
const authLoading = ref(false)
const dataLoading = ref(false)
const setupError = ref('')
const searchText = ref('')
const patients = ref([])
const allergies = ref([])

const patientForm = reactive(emptyPatient())
const allergyForm = reactive(emptyAllergy())

const isAdmin = computed(() => userRole.value === 'admin')
const roleLabel = computed(() => (isAdmin.value ? 'Admin' : 'Staff'))

const summaryCards = computed(() => [
  { label: 'ผู้ป่วยทั้งหมด', value: patients.value.length.toLocaleString('th-TH'), short: 'PT' },
  { label: 'รายการแพ้ยา', value: allergies.value.length.toLocaleString('th-TH'), short: 'DA' },
  { label: 'รออนุมัติ', value: allergies.value.filter((item) => item.status === 'รออนุมัติ').length.toLocaleString('th-TH'), short: 'RV' },
  { label: 'ยืนยันแล้ว', value: allergies.value.filter((item) => item.status === 'ยืนยันแล้ว').length.toLocaleString('th-TH'), short: 'OK' }
])

const recentAllergies = computed(() => allergies.value.slice(0, 10))

const filteredPatients = computed(() => {
  const keyword = searchText.value.toLowerCase()
  if (!keyword) return patients.value

  return patients.value.filter((patient) => [
    patient.hn,
    patient.cid,
    patient.full_name,
    patient.phone
  ].some((value) => String(value || '').toLowerCase().includes(keyword)))
})

const filteredAllergies = computed(() => {
  const keyword = searchText.value.toLowerCase()
  if (!keyword) return allergies.value

  return allergies.value.filter((record) => [
    record.drug_name,
    record.generic_name,
    record.reaction,
    record.status,
    record.patients?.hn,
    record.patients?.full_name
  ].some((value) => String(value || '').toLowerCase().includes(keyword)))
})

onMounted(async () => {
  const { data } = await supabase.auth.getUser()
  userEmail.value = data.user?.email || '-'
  userId.value = data.user?.id || ''
  await loadProfile()
  await loadData()
})

function emptyPatient() {
  return {
    id: '',
    hn: '',
    cid: '',
    full_name: '',
    birth_date: '',
    sex: 'ไม่ระบุ',
    phone: '',
    address: ''
  }
}

function emptyAllergy() {
  return {
    patient_id: '',
    drug_name: '',
    generic_name: '',
    reaction: '',
    severity: 'ไม่ระบุ',
    onset_date: '',
    source: '',
    note: ''
  }
}

async function loadProfile() {
  if (!userId.value) return

  const { data, error } = await supabase
    .from('user_profiles')
    .select('role')
    .eq('id', userId.value)
    .maybeSingle()

  if (!error && data?.role) {
    userRole.value = data.role
    return
  }

  await supabase.from('user_profiles').upsert({
    id: userId.value,
    email: userEmail.value,
    role: 'staff'
  })
}

async function loadData() {
  dataLoading.value = true
  setupError.value = ''

  const { data: patientRows, error: patientError } = await supabase
    .from('patients')
    .select('*')
    .order('created_at', { ascending: false })

  if (patientError) {
    setupError.value = patientError.message
    dataLoading.value = false
    return
  }

  const { data: allergyRows, error: allergyError } = await supabase
    .from('drug_allergies')
    .select('*, patients(hn, full_name)')
    .order('created_at', { ascending: false })

  if (allergyError) {
    setupError.value = allergyError.message
    dataLoading.value = false
    return
  }

  patients.value = patientRows || []
  allergies.value = allergyRows || []
  dataLoading.value = false
}

async function savePatient() {
  const payload = {
    hn: patientForm.hn,
    cid: patientForm.cid || null,
    full_name: patientForm.full_name,
    birth_date: patientForm.birth_date || null,
    sex: patientForm.sex,
    phone: patientForm.phone || null,
    address: patientForm.address || null,
    created_by: userId.value || null
  }

  dataLoading.value = true
  const query = patientForm.id
    ? supabase.from('patients').update(payload).eq('id', patientForm.id)
    : supabase.from('patients').insert(payload)

  const { error } = await query
  dataLoading.value = false

  if (error) {
    Swal.fire('บันทึกไม่สำเร็จ', error.message, 'error')
    return
  }

  await loadData()
  resetPatientForm()
  Swal.fire({ icon: 'success', title: 'บันทึกข้อมูลผู้ป่วยแล้ว', timer: 1000, showConfirmButton: false })
}

function editPatient(patient) {
  Object.assign(patientForm, {
    ...emptyPatient(),
    ...patient,
    birth_date: patient.birth_date || ''
  })
  activeTab.value = 'patients'
}

async function deletePatient(patient) {
  if (!isAdmin.value) return

  const result = await Swal.fire({
    icon: 'warning',
    title: 'ลบข้อมูลผู้ป่วย?',
    text: `HN ${patient.hn} - ${patient.full_name}`,
    showCancelButton: true,
    confirmButtonText: 'ลบ',
    cancelButtonText: 'ยกเลิก',
    confirmButtonColor: '#dc3545'
  })

  if (!result.isConfirmed) return

  const { error } = await supabase.from('patients').delete().eq('id', patient.id)
  if (error) {
    Swal.fire('ลบไม่สำเร็จ', error.message, 'error')
    return
  }

  await loadData()
  Swal.fire({ icon: 'success', title: 'ลบข้อมูลแล้ว', timer: 1000, showConfirmButton: false })
}

async function saveAllergy() {
  const payload = {
    patient_id: allergyForm.patient_id,
    drug_name: allergyForm.drug_name,
    generic_name: allergyForm.generic_name || null,
    reaction: allergyForm.reaction,
    severity: allergyForm.severity,
    onset_date: allergyForm.onset_date || null,
    source: allergyForm.source || null,
    note: allergyForm.note || null,
    status: 'รออนุมัติ',
    created_by: userId.value || null
  }

  dataLoading.value = true
  const { error } = await supabase.from('drug_allergies').insert(payload)
  dataLoading.value = false

  if (error) {
    Swal.fire('บันทึกไม่สำเร็จ', error.message, 'error')
    return
  }

  await loadData()
  resetAllergyForm()
  Swal.fire({ icon: 'success', title: 'บันทึกรายการแพ้ยาแล้ว', timer: 1000, showConfirmButton: false })
}

async function reviewAllergy(record, status) {
  if (!isAdmin.value) return

  const { error } = await supabase
    .from('drug_allergies')
    .update({
      status,
      reviewed_by: userId.value || null,
      reviewed_at: new Date().toISOString()
    })
    .eq('id', record.id)

  if (error) {
    Swal.fire('อัปเดตไม่สำเร็จ', error.message, 'error')
    return
  }

  await loadData()
}

async function deleteAllergy(record) {
  if (!isAdmin.value) return

  const result = await Swal.fire({
    icon: 'warning',
    title: 'ลบรายการแพ้ยา?',
    text: `${record.drug_name} - ${record.reaction}`,
    showCancelButton: true,
    confirmButtonText: 'ลบ',
    cancelButtonText: 'ยกเลิก',
    confirmButtonColor: '#dc3545'
  })

  if (!result.isConfirmed) return

  const { error } = await supabase.from('drug_allergies').delete().eq('id', record.id)
  if (error) {
    Swal.fire('ลบไม่สำเร็จ', error.message, 'error')
    return
  }

  await loadData()
}

function resetPatientForm() {
  Object.assign(patientForm, emptyPatient())
}

function resetAllergyForm() {
  Object.assign(allergyForm, emptyAllergy())
}

function statusClass(status) {
  if (status === 'ยืนยันแล้ว') return 'bg-success'
  if (status === 'ยกเลิก') return 'bg-secondary'
  return 'bg-warning text-dark'
}

function exportCsv() {
  const header = ['HN', 'ชื่อ-สกุล', 'ยา', 'Generic', 'อาการ', 'ความรุนแรง', 'สถานะ']
  const rows = allergies.value.map((record) => [
    record.patients?.hn || '',
    record.patients?.full_name || '',
    record.drug_name,
    record.generic_name || '',
    record.reaction,
    record.severity,
    record.status
  ])
  const csv = [header, ...rows]
    .map((row) => row.map((cell) => `"${String(cell).replaceAll('"', '""')}"`).join(','))
    .join('\n')

  const blob = new Blob([`\ufeff${csv}`], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `drug-allergy-${new Date().toISOString().slice(0, 10)}.csv`
  link.click()
  URL.revokeObjectURL(url)
}

async function logout() {
  authLoading.value = true
  const { error } = await supabase.auth.signOut()
  authLoading.value = false

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
  text-align: left;
}

.sidebar {
  min-height: calc(100vh - 56px);
  background: #fff;
  border-right: 1px solid #e5edf5;
}

.nav-link {
  border: 0;
  border-radius: 8px;
  color: #6c757d;
  background: transparent;
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

.search-box {
  max-width: 340px;
}

.table {
  margin-bottom: 0;
}

@media (max-width: 767.98px) {
  .search-box {
    max-width: none;
  }
}
</style>
