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
            <button v-for="tab in tabs" :key="tab.key" class="nav-link text-start" :class="{ active: activeTab === tab.key }" @click="activeTab = tab.key">
              {{ tab.label }}
            </button>
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
            บัญชีนี้เป็นสิทธิ์เจ้าหน้าที่ สามารถบันทึกข้อมูลและส่งเคสสงสัยแพ้ยาได้ แต่การยืนยัน/ยกเลิก/ลบรายการจำกัดเฉพาะแอดมิน
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
                <p class="text-muted">ติดตามรายการสงสัยแพ้ยา รออนุมัติ และรายการที่ยืนยันแล้ว</p>
              </div>
              <button class="btn btn-outline-primary align-self-start" @click="exportStandardCsv">Export DRUGALLERGY</button>
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
                    <label class="form-label">PID/CID</label>
                    <input v-model.trim="patientForm.cid" class="form-control">
                  </div>
                  <div class="col-md-6 col-xl-12">
                    <label class="form-label">HOSPCODE</label>
                    <input v-model.trim="patientForm.hospcode" class="form-control">
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
                  <input v-model.trim="searchText" class="form-control search-box" placeholder="ค้นหา HN, ชื่อ, PID/CID">
                </div>

                <div class="table-responsive">
                  <table class="table table-hover align-middle">
                    <thead>
                      <tr>
                        <th>HN</th>
                        <th>PID/CID</th>
                        <th>ชื่อ-สกุล</th>
                        <th>หน่วยบริการ</th>
                        <th class="text-end">จัดการ</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="patient in filteredPatients" :key="patient.id">
                        <td class="fw-semibold">{{ patient.hn }}</td>
                        <td>{{ patient.cid || '-' }}</td>
                        <td>{{ patient.full_name }}</td>
                        <td>{{ patient.hospcode || '-' }}</td>
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
                <h2 class="h5 fw-bold mb-3">บันทึกสงสัยแพ้ยา</h2>
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
                  <div class="col-md-6">
                    <label class="form-label">TYPEDX</label>
                    <select v-model="allergyForm.typedx" class="form-select">
                      <option value="">ไม่ระบุ</option>
                      <option value="1">1 - ผู้ป่วยให้ประวัติ</option>
                      <option value="2">2 - บุคลากรสังเกต/วินิจฉัย</option>
                    </select>
                  </div>
                  <div class="col-md-6">
                    <label class="form-label">RISK</label>
                    <select v-model="allergyForm.risk" class="form-select">
                      <option value="">ไม่ระบุ</option>
                      <option value="1">1 - เฝ้าระวัง</option>
                      <option value="2">2 - ห้ามใช้</option>
                    </select>
                  </div>
                  <div class="col-12">
                    <label class="form-label">แหล่งข้อมูล/รพ.สต.</label>
                    <input v-model.trim="allergyForm.source" class="form-control" placeholder="เช่น OPD, IPD, รพ.สต.">
                  </div>
                  <div class="col-12">
                    <label class="form-label">หมายเหตุ</label>
                    <textarea v-model.trim="allergyForm.note" class="form-control" rows="2"></textarea>
                  </div>
                  <div class="col-12 d-flex gap-2">
                    <button class="btn btn-primary" type="submit" :disabled="dataLoading">บันทึกสงสัยแพ้ยา</button>
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
                          <button class="btn btn-sm btn-outline-primary me-2" @click="makeCard(record)" :disabled="record.status !== 'ยืนยันแล้ว'">บัตร</button>
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

          <section v-if="activeTab === 'exchange'" class="row g-3">
            <div class="col-xl-5">
              <div class="dashboard-panel bg-white border p-4">
                <h2 class="h5 fw-bold mb-3">นำเข้าไฟล์มาตรฐาน</h2>
                <div class="mb-3">
                  <label class="form-label">ระบบต้นทาง</label>
                  <select v-model="importSource" class="form-select">
                    <option value="HIMPRO">HIMPRO/HIS</option>
                    <option value="JHCIS">JHCIS รพ.สต.</option>
                    <option value="DRUGALLERGY43">43 แฟ้ม DRUGALLERGY</option>
                  </select>
                </div>
                <input class="form-control mb-3" type="file" accept=".csv,.xlsx,.xls" @change="readImportFile">
                <div class="d-flex gap-2">
                  <button class="btn btn-primary" @click="importRows" :disabled="importPreview.length === 0 || dataLoading">นำเข้าข้อมูล</button>
                  <button class="btn btn-outline-secondary" @click="clearImport">ล้างไฟล์</button>
                </div>
                <div class="small text-muted mt-3">
                  รองรับคอลัมน์มาตรฐาน เช่น HOSPCODE, PID/CID, HN, NAME/FULLNAME, DRUGALLERGY/DRUG_NAME, DNAME, SYMPTOM/REACTION, ALEVEL/SEVERITY, TYPEDX, INFORMANT, INFORMHOSP, RISK
                </div>
              </div>
            </div>

            <div class="col-xl-7">
              <div class="dashboard-panel bg-white border p-4">
                <div class="d-flex flex-column flex-md-row justify-content-between gap-3 mb-3">
                  <h2 class="h5 fw-bold mb-0">Preview ไฟล์นำเข้า</h2>
                  <button class="btn btn-outline-primary align-self-start" @click="exportStandardCsv">ส่งออกไฟล์ให้ รพ.สต.</button>
                </div>
                <div class="table-responsive">
                  <table class="table table-hover align-middle">
                    <thead>
                      <tr>
                        <th>HN</th>
                        <th>ชื่อ</th>
                        <th>ยา</th>
                        <th>อาการ</th>
                        <th>หน่วยบริการ</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="(row, index) in importPreview.slice(0, 10)" :key="index">
                        <td>{{ row.hn || '-' }}</td>
                        <td>{{ row.full_name || '-' }}</td>
                        <td>{{ row.drug_name || '-' }}</td>
                        <td>{{ row.reaction || '-' }}</td>
                        <td>{{ row.hospcode || row.informhosp || '-' }}</td>
                      </tr>
                      <tr v-if="importPreview.length === 0">
                        <td colspan="5" class="text-center text-muted py-4">ยังไม่ได้เลือกไฟล์</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
                <div v-if="importPreview.length > 10" class="small text-muted mt-2">แสดง 10 รายการแรกจากทั้งหมด {{ importPreview.length }} รายการ</div>
              </div>
            </div>
          </section>

          <section v-if="activeTab === 'cards'" class="row g-3">
            <div class="col-xl-5">
              <div class="dashboard-panel bg-white border p-4">
                <h2 class="h5 fw-bold mb-3">ออกบัตรแพ้ยา</h2>
                <select v-model="selectedCardAllergyId" class="form-select mb-3" @change="renderSelectedCard">
                  <option value="">เลือกรายการแพ้ยาที่ยืนยันแล้ว</option>
                  <option v-for="record in confirmedAllergies" :key="record.id" :value="record.id">
                    {{ record.patients?.hn }} - {{ record.patients?.full_name }} - {{ record.drug_name }}
                  </option>
                </select>
                <div class="d-flex gap-2">
                  <button class="btn btn-primary" @click="printCard" :disabled="!selectedCard">พิมพ์บัตร</button>
                  <button class="btn btn-outline-primary" @click="exportStandardCsv">Export DRUGALLERGY</button>
                </div>
              </div>
            </div>

            <div class="col-xl-7">
              <div class="allergy-card bg-white border shadow-sm p-4" id="allergy-card-print">
                <div v-if="selectedCard" class="d-flex justify-content-between gap-3">
                  <div>
                    <div class="small text-muted">โรงพยาบาลปลวกแดง</div>
                    <h2 class="h4 fw-bold text-danger mb-3">บัตรแพ้ยา</h2>
                    <div><strong>HN:</strong> {{ selectedCard.patients?.hn || '-' }}</div>
                    <div><strong>ชื่อ:</strong> {{ selectedCard.patients?.full_name || '-' }}</div>
                    <div><strong>ยาที่แพ้:</strong> {{ selectedCard.drug_name }}</div>
                    <div><strong>อาการ:</strong> {{ selectedCard.reaction }}</div>
                    <div><strong>ความรุนแรง:</strong> {{ selectedCard.severity }}</div>
                    <div><strong>วันที่ออกบัตร:</strong> {{ todayText }}</div>
                  </div>
                  <img v-if="cardQr" class="qr-code" :src="cardQr" alt="QR code">
                </div>
                <div v-else class="text-center text-muted py-5">เลือกรายการแพ้ยาที่ยืนยันแล้วเพื่อดูตัวอย่างบัตร</div>
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
import * as XLSX from 'xlsx'
import QRCode from 'qrcode'
import { supabase } from '../services/supabase'

const router = useRouter()
const tabs = [
  { key: 'overview', label: 'Dashboard' },
  { key: 'patients', label: 'Patients' },
  { key: 'allergies', label: 'Suspected Allergy' },
  { key: 'exchange', label: 'Import/Export' },
  { key: 'cards', label: 'Allergy Card' }
]

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
const importSource = ref('JHCIS')
const importPreview = ref([])
const selectedCardAllergyId = ref('')
const selectedCard = ref(null)
const cardQr = ref('')

const patientForm = reactive(emptyPatient())
const allergyForm = reactive(emptyAllergy())

const isAdmin = computed(() => userRole.value === 'admin')
const roleLabel = computed(() => (isAdmin.value ? 'Admin' : 'Staff'))
const todayText = computed(() => new Date().toLocaleDateString('th-TH'))

const summaryCards = computed(() => [
  { label: 'ผู้ป่วยทั้งหมด', value: patients.value.length.toLocaleString('th-TH'), short: 'PT' },
  { label: 'รายการแพ้ยา', value: allergies.value.length.toLocaleString('th-TH'), short: 'DA' },
  { label: 'รออนุมัติ', value: allergies.value.filter((item) => item.status === 'รออนุมัติ').length.toLocaleString('th-TH'), short: 'RV' },
  { label: 'ยืนยันแล้ว', value: allergies.value.filter((item) => item.status === 'ยืนยันแล้ว').length.toLocaleString('th-TH'), short: 'OK' }
])

const recentAllergies = computed(() => allergies.value.slice(0, 10))
const confirmedAllergies = computed(() => allergies.value.filter((item) => item.status === 'ยืนยันแล้ว'))

const filteredPatients = computed(() => {
  const keyword = searchText.value.toLowerCase()
  if (!keyword) return patients.value
  return patients.value.filter((patient) => [
    patient.hn,
    patient.cid,
    patient.full_name,
    patient.phone,
    patient.hospcode
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
    record.source,
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
    hospcode: '',
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
    note: '',
    typedx: '',
    informant: '',
    informhosp: '',
    risk: ''
  }
}

async function loadProfile() {
  if (!userId.value) return
  const { data, error } = await supabase.from('user_profiles').select('role').eq('id', userId.value).maybeSingle()
  if (!error && data?.role) {
    userRole.value = data.role
    return
  }
  await supabase.from('user_profiles').upsert({ id: userId.value, email: userEmail.value, role: 'staff' })
}

async function loadData() {
  dataLoading.value = true
  setupError.value = ''

  const { data: patientRows, error: patientError } = await supabase.from('patients').select('*').order('created_at', { ascending: false })
  if (patientError) {
    setupError.value = patientError.message
    dataLoading.value = false
    return
  }

  const { data: allergyRows, error: allergyError } = await supabase
    .from('drug_allergies')
    .select('*, patients(hn, cid, hospcode, full_name)')
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
    hospcode: patientForm.hospcode || null,
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
  Object.assign(patientForm, { ...emptyPatient(), ...patient, birth_date: patient.birth_date || '' })
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
    typedx: allergyForm.typedx || null,
    informant: allergyForm.informant || null,
    informhosp: allergyForm.informhosp || null,
    risk: allergyForm.risk || null,
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
  Swal.fire({ icon: 'success', title: 'บันทึกสงสัยแพ้ยาแล้ว', timer: 1000, showConfirmButton: false })
}

async function reviewAllergy(record, status) {
  if (!isAdmin.value) return
  const { error } = await supabase
    .from('drug_allergies')
    .update({ status, reviewed_by: userId.value || null, reviewed_at: new Date().toISOString() })
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

async function readImportFile(event) {
  const file = event.target.files?.[0]
  if (!file) return

  const buffer = await file.arrayBuffer()
  const workbook = XLSX.read(buffer, { type: 'array' })
  const sheet = workbook.Sheets[workbook.SheetNames[0]]
  const rows = XLSX.utils.sheet_to_json(sheet, { defval: '' })
  importPreview.value = rows.map(normalizeImportRow).filter((row) => row.hn || row.cid || row.drug_name)
}

function normalizeImportRow(row) {
  const value = (...keys) => {
    const match = keys.find((key) => row[key] !== undefined && row[key] !== null && String(row[key]).trim() !== '')
    return match ? String(row[match]).trim() : ''
  }

  return {
    hospcode: value('HOSPCODE', 'hospcode', 'HOSP_CODE', 'หน่วยบริการ'),
    cid: value('PID', 'CID', 'cid', 'pid', 'เลขบัตรประชาชน'),
    hn: value('HN', 'hn', 'PERSON_ID', 'รหัสผู้ป่วย'),
    full_name: value('FULLNAME', 'NAME', 'PATIENT_NAME', 'ชื่อ-สกุล', 'ชื่อผู้ป่วย'),
    drug_name: value('DRUGALLERGY', 'DRUG_NAME', 'DNAME', 'ยา', 'ชื่อยา'),
    generic_name: value('GENERIC_NAME', 'GENERIC', 'ชื่อสามัญ'),
    reaction: value('SYMPTOM', 'REACTION', 'อาการ', 'อาการแพ้'),
    severity: normalizeSeverity(value('ALEVEL', 'SEVERITY', 'ความรุนแรง')),
    onset_date: normalizeDate(value('DATERECORD', 'ONSET_DATE', 'วันที่พบอาการ')),
    typedx: value('TYPEDX', 'typedx'),
    informant: value('INFORMANT', 'ผู้ให้ข้อมูล'),
    informhosp: value('INFORMHOSP', 'informhosp', 'รหัสหน่วยแจ้ง'),
    risk: value('RISK', 'risk'),
    source: importSource.value,
    note: value('NOTE', 'หมายเหตุ')
  }
}

function normalizeSeverity(value) {
  if (!value) return 'ไม่ระบุ'
  if (['3', 'รุนแรง', 'severe'].includes(value.toLowerCase?.() || value)) return 'รุนแรง'
  if (['2', 'ปานกลาง', 'moderate'].includes(value.toLowerCase?.() || value)) return 'ปานกลาง'
  if (['1', 'ไม่รุนแรง', 'mild'].includes(value.toLowerCase?.() || value)) return 'ไม่รุนแรง'
  return value
}

function normalizeDate(value) {
  if (!value) return ''
  const text = String(value)
  if (/^\d{8}$/.test(text)) return `${text.slice(0, 4)}-${text.slice(4, 6)}-${text.slice(6, 8)}`
  if (/^\d{4}-\d{2}-\d{2}$/.test(text)) return text
  return ''
}

async function importRows() {
  dataLoading.value = true
  let imported = 0

  for (const row of importPreview.value) {
    const patientPayload = {
      hn: row.hn || row.cid,
      cid: row.cid || null,
      hospcode: row.hospcode || row.informhosp || null,
      full_name: row.full_name || 'ไม่ทราบชื่อ',
      sex: 'ไม่ระบุ',
      created_by: userId.value || null
    }

    const { data: patient, error: patientError } = await supabase
      .from('patients')
      .upsert(patientPayload, { onConflict: 'hn' })
      .select('id')
      .single()

    if (patientError || !patient?.id || !row.drug_name) continue

    const { error: allergyError } = await supabase.from('drug_allergies').insert({
      patient_id: patient.id,
      drug_name: row.drug_name,
      generic_name: row.generic_name || null,
      reaction: row.reaction || 'ไม่ระบุ',
      severity: row.severity || 'ไม่ระบุ',
      onset_date: row.onset_date || null,
      source: row.source || importSource.value,
      note: row.note || null,
      typedx: row.typedx || null,
      informant: row.informant || null,
      informhosp: row.informhosp || row.hospcode || null,
      risk: row.risk || null,
      status: 'รออนุมัติ',
      created_by: userId.value || null
    })

    if (!allergyError) imported += 1
  }

  dataLoading.value = false
  await loadData()
  Swal.fire('นำเข้าเสร็จสิ้น', `นำเข้าสำเร็จ ${imported} รายการ`, 'success')
}

function clearImport() {
  importPreview.value = []
}

function exportStandardCsv() {
  const header = ['HOSPCODE', 'PID', 'HN', 'DATERECORD', 'DRUGALLERGY', 'DNAME', 'TYPEDX', 'ALEVEL', 'SYMPTOM', 'INFORMANT', 'INFORMHOSP', 'RISK', 'STATUS']
  const rows = allergies.value.map((record) => [
    record.patients?.hospcode || record.informhosp || '',
    record.patients?.cid || '',
    record.patients?.hn || '',
    formatDate43(record.onset_date || record.created_at),
    record.drug_name,
    record.generic_name || record.drug_name,
    record.typedx || '',
    severityCode(record.severity),
    record.reaction,
    record.informant || '',
    record.informhosp || record.patients?.hospcode || '',
    record.risk || '',
    record.status
  ])
  downloadCsv('DRUGALLERGY_EXPORT.csv', [header, ...rows])
}

function downloadCsv(filename, rows) {
  const csv = rows.map((row) => row.map((cell) => `"${String(cell ?? '').replaceAll('"', '""')}"`).join(',')).join('\n')
  const blob = new Blob([`\ufeff${csv}`], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  link.click()
  URL.revokeObjectURL(url)
}

function formatDate43(value) {
  if (!value) return ''
  return String(value).slice(0, 10).replaceAll('-', '')
}

function severityCode(value) {
  if (value === 'ไม่รุนแรง') return '1'
  if (value === 'ปานกลาง') return '2'
  if (value === 'รุนแรง') return '3'
  return ''
}

async function makeCard(record) {
  selectedCardAllergyId.value = record.id
  await renderCard(record)
  activeTab.value = 'cards'
}

async function renderSelectedCard() {
  const record = allergies.value.find((item) => item.id === selectedCardAllergyId.value)
  await renderCard(record)
}

async function renderCard(record) {
  selectedCard.value = record || null
  if (!record) {
    cardQr.value = ''
    return
  }
  const payload = `HN:${record.patients?.hn || ''}\nNAME:${record.patients?.full_name || ''}\nDRUG:${record.drug_name}\nREACTION:${record.reaction}`
  cardQr.value = await QRCode.toDataURL(payload, { width: 140, margin: 1 })
}

function printCard() {
  window.print()
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

async function logout() {
  authLoading.value = true
  const { error } = await supabase.auth.signOut()
  authLoading.value = false

  if (error) {
    Swal.fire('ออกจากระบบไม่สำเร็จ', error.message, 'error')
    return
  }

  await Swal.fire({ icon: 'success', title: 'ออกจากระบบแล้ว', timer: 1000, showConfirmButton: false })
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
.dashboard-panel,
.allergy-card {
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

.qr-code {
  width: 140px;
  height: 140px;
}

@media (max-width: 767.98px) {
  .search-box {
    max-width: none;
  }
}

@media print {
  nav,
  aside,
  main > *:not(#allergy-card-print) {
    display: none !important;
  }

  #allergy-card-print {
    display: block !important;
    border: 2px solid #222 !important;
    box-shadow: none !important;
    width: 86mm;
    min-height: 54mm;
  }
}
</style>
