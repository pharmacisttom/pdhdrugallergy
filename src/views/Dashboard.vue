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
            <button v-for="tab in visibleTabs" :key="tab.key" class="nav-link text-start" :class="{ active: activeTab === tab.key }" @click="activeTab = tab.key">
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
              <div class="small text-muted">{{ currentOrgName }}</div>
            </div>
          </div>

          <div v-if="setupError" class="alert alert-warning border-0 shadow-sm">
            <div class="fw-semibold mb-1">ยังเชื่อมต่อฐานข้อมูลไม่สำเร็จ</div>
            <div>{{ setupError }}</div>
            <div class="small mt-2">ให้นำไฟล์ <code>supabase/schema.sql</code> ไปรันใน Supabase SQL Editor ก่อนใช้งานหน้านี้</div>
          </div>

          <div v-if="!isApproved" class="alert alert-info border-0 shadow-sm">
            บัญชีนี้ยังรอแอดมินอนุมัติและผูกกับ รพ.สต. สามารถเข้าสู่ระบบได้ แต่สิทธิ์การบันทึกข้อมูลจะเปิดใช้หลังอนุมัติ
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
                    <th>รพ.สต.</th>
                    <th>ยา</th>
                    <th>อาการ</th>
                    <th>สถานะ</th>
                    <th class="text-end">จัดการ</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="record in recentAllergies" :key="record.id">
                    <td>{{ record.patients?.hn || '-' }}</td>
                    <td>{{ record.patients?.full_name || '-' }}</td>
                    <td>{{ orgName(record.patients?.hospcode) }}</td>
                    <td class="fw-semibold">{{ record.drug_name }}</td>
                    <td>{{ record.reaction }}</td>
                    <td><span class="badge" :class="statusClass(record.status)">{{ record.status }}</span></td>
                    <td class="text-end">
                      <button class="btn btn-sm btn-outline-primary me-2" @click="viewPhotos(record)" :disabled="photoCount(record) === 0">รูป {{ photoCount(record) }}</button>
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

          <section v-if="activeTab === 'network'" class="row g-3">
            <div class="col-12">
              <div class="dashboard-panel bg-white border p-4">
                <div class="d-flex flex-column flex-md-row justify-content-between gap-3 mb-3">
                  <div>
                    <h2 class="h5 fw-bold mb-1">ภาพรวมเครือข่าย รพ.สต.</h2>
                    <p class="text-muted">จำนวนผู้ป่วยแพ้ยารายหน่วยบริการ สถานะออนไลน์ และการใช้งานล่าสุด</p>
                  </div>
                  <button class="btn btn-outline-primary align-self-start" @click="exportNetworkCsv">Export Network</button>
                </div>

                <div class="table-responsive">
                  <table class="table table-hover align-middle">
                    <thead>
                      <tr>
                        <th>HOSPCODE</th>
                        <th>รพ.สต.</th>
                        <th>ผู้ป่วย</th>
                        <th>รายการแพ้ยา</th>
                        <th>รออนุมัติ</th>
                        <th>ผู้ใช้งาน</th>
                        <th>ออนไลน์</th>
                        <th>ล่าสุด</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="item in orgStats" :key="item.hospcode">
                        <td class="fw-semibold">{{ item.hospcode }}</td>
                        <td>{{ item.name }}</td>
                        <td>{{ item.patientCount }}</td>
                        <td>{{ item.allergyCount }}</td>
                        <td>{{ item.pendingCount }}</td>
                        <td>{{ item.userCount }}</td>
                        <td>
                          <span class="badge" :class="item.onlineCount > 0 ? 'bg-success' : 'bg-secondary'">
                            {{ item.onlineCount > 0 ? 'Online ' + item.onlineCount : 'Offline' }}
                          </span>
                        </td>
                        <td>{{ formatLastSeen(item.lastSeenAt) }}</td>
                      </tr>
                      <tr v-if="orgStats.length === 0">
                        <td colspan="8" class="text-center text-muted py-4">ยังไม่มีข้อมูล รพ.สต.</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>

            <div v-if="isAdmin" class="col-xl-5">
              <div class="dashboard-panel bg-white border p-4">
                <h2 class="h5 fw-bold mb-3">{{ orgForm.editing ? 'แก้ไข รพ.สต.' : 'เพิ่ม รพ.สต.' }}</h2>
                <form class="row g-3" @submit.prevent="saveOrganization">
                  <div class="col-md-5">
                    <label class="form-label">HOSPCODE</label>
                    <input v-model.trim="orgForm.hospcode" class="form-control" :disabled="orgForm.editing" required>
                  </div>
                  <div class="col-md-7">
                    <label class="form-label">ชื่อหน่วยบริการ</label>
                    <input v-model.trim="orgForm.name" class="form-control" required>
                  </div>
                  <div class="col-md-6">
                    <label class="form-label">ตำบล</label>
                    <input v-model.trim="orgForm.tambon" class="form-control">
                  </div>
                  <div class="col-md-6">
                    <label class="form-label">อำเภอ</label>
                    <input v-model.trim="orgForm.amphur" class="form-control">
                  </div>
                  <div class="col-12 d-flex gap-2">
                    <button class="btn btn-primary" type="submit">บันทึก</button>
                    <button class="btn btn-outline-secondary" type="button" @click="resetOrgForm">ล้างฟอร์ม</button>
                  </div>
                </form>
              </div>
            </div>

            <div v-if="isAdmin" class="col-xl-7">
              <div class="dashboard-panel bg-white border p-4">
                <h2 class="h5 fw-bold mb-3">ทะเบียน รพ.สต.</h2>
                <div class="table-responsive">
                  <table class="table table-hover align-middle">
                    <thead>
                      <tr>
                        <th>HOSPCODE</th>
                        <th>ชื่อ</th>
                        <th>พื้นที่</th>
                        <th class="text-end">จัดการ</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="org in organizations" :key="org.hospcode">
                        <td>{{ org.hospcode }}</td>
                        <td>{{ org.name }}</td>
                        <td>{{ [org.tambon, org.amphur].filter(Boolean).join(' / ') || '-' }}</td>
                        <td class="text-end">
                          <button class="btn btn-sm btn-outline-primary" @click="editOrganization(org)">แก้ไข</button>
                        </td>
                      </tr>
                      <tr v-if="organizations.length === 0">
                        <td colspan="4" class="text-center text-muted py-4">ยังไม่มีทะเบียน รพ.สต.</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </section>

          <section v-if="activeTab === 'users'" class="dashboard-panel bg-white border p-4">
            <div class="d-flex flex-column flex-md-row justify-content-between gap-3 mb-3">
              <div>
                <h2 class="h5 fw-bold mb-1">กำหนดสิทธิ์ผู้ใช้งาน</h2>
                <p class="text-muted">แอดมินอนุมัติผู้ใช้ กำหนดสิทธิ์ และผูกผู้ใช้กับ รพ.สต. ที่ใช้งาน</p>
              </div>
              <button class="btn btn-outline-primary align-self-start" @click="loadProfiles">Refresh</button>
            </div>

            <div class="table-responsive">
              <table class="table table-hover align-middle">
                <thead>
                  <tr>
                    <th>Email</th>
                    <th>ชื่อ</th>
                    <th>รพ.สต.</th>
                    <th>Role</th>
                    <th>อนุมัติ</th>
                    <th>สถานะ</th>
                    <th>ล่าสุด</th>
                    <th class="text-end">บันทึก</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="profile in profiles" :key="profile.id">
                    <td class="fw-semibold">{{ profile.email }}</td>
                    <td>{{ profile.full_name || '-' }}</td>
                    <td>
                      <select v-model="profile.hospcode" class="form-select form-select-sm">
                        <option value="">ไม่ระบุ</option>
                        <option v-for="org in organizations" :key="org.hospcode" :value="org.hospcode">{{ org.hospcode }} - {{ org.name }}</option>
                      </select>
                    </td>
                    <td>
                      <select v-model="profile.role" class="form-select form-select-sm">
                        <option value="staff">staff</option>
                        <option value="admin">admin</option>
                      </select>
                    </td>
                    <td class="text-center">
                      <input v-model="profile.approved" class="form-check-input" type="checkbox">
                    </td>
                    <td><span class="badge" :class="isProfileOnline(profile) ? 'bg-success' : 'bg-secondary'">{{ isProfileOnline(profile) ? 'Online' : 'Offline' }}</span></td>
                    <td>{{ formatLastSeen(profile.last_seen_at) }}</td>
                    <td class="text-end">
                      <button class="btn btn-sm btn-primary" @click="saveProfile(profile)">บันทึก</button>
                    </td>
                  </tr>
                  <tr v-if="profiles.length === 0">
                    <td colspan="8" class="text-center text-muted py-4">ยังไม่มีผู้ใช้งานในระบบ</td>
                  </tr>
                </tbody>
              </table>
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
                  <button class="btn btn-primary" @click="importRows" :disabled="importPreview.length === 0 || !canWrite">นำเข้าข้อมูล</button>
                  <button class="btn btn-outline-secondary" @click="importPreview = []">ล้างไฟล์</button>
                </div>
                <div class="small text-muted mt-3">
                  รองรับคอลัมน์ HOSPCODE, PID/CID, HN, NAME/FULLNAME, DRUGALLERGY/DRUG_NAME, DNAME, SYMPTOM/REACTION, ALEVEL/SEVERITY
                </div>
              </div>
            </div>

            <div class="col-xl-7">
              <div class="dashboard-panel bg-white border p-4">
                <div class="d-flex flex-column flex-md-row justify-content-between gap-3 mb-3">
                  <h2 class="h5 fw-bold mb-0">Preview ไฟล์นำเข้า</h2>
                  <button class="btn btn-outline-primary align-self-start" @click="exportStandardCsv">ส่งออก DRUGALLERGY</button>
                </div>
                <div class="table-responsive">
                  <table class="table table-hover align-middle">
                    <thead>
                      <tr>
                        <th>HN</th>
                        <th>ชื่อ</th>
                        <th>ยา</th>
                        <th>อาการ</th>
                        <th>HOSPCODE</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="(row, index) in importPreview.slice(0, 10)" :key="index">
                        <td>{{ row.hn || '-' }}</td>
                        <td>{{ row.full_name || '-' }}</td>
                        <td>{{ row.drug_name || '-' }}</td>
                        <td>{{ row.reaction || '-' }}</td>
                        <td>{{ row.hospcode || '-' }}</td>
                      </tr>
                      <tr v-if="importPreview.length === 0">
                        <td colspan="5" class="text-center text-muted py-4">ยังไม่ได้เลือกไฟล์</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
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
                    <div><strong>รพ.สต.:</strong> {{ orgName(selectedCard.patients?.hospcode) }}</div>
                    <div><strong>ยาที่แพ้:</strong> {{ selectedCard.drug_name }}</div>
                    <div><strong>อาการ:</strong> {{ selectedCard.reaction }}</div>
                    <div><strong>วันที่ออกบัตร:</strong> {{ new Date().toLocaleDateString('th-TH') }}</div>
                  </div>
                  <img v-if="cardQr" class="qr-code" :src="cardQr" alt="QR code">
                </div>
                <div v-else class="text-center text-muted py-5">เลือกรายการแพ้ยาที่ยืนยันแล้วเพื่อดูตัวอย่างบัตร</div>
              </div>
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
                    <label class="form-label">เพศ</label>
                    <select v-model="patientForm.sex" class="form-select">
                      <option>ไม่ระบุ</option>
                      <option>ชาย</option>
                      <option>หญิง</option>
                    </select>
                  </div>
                  <div class="col-md-6">
                    <label class="form-label">เบอร์โทร</label>
                    <input v-model.trim="patientForm.phone" class="form-control">
                  </div>
                  <div class="col-12 d-flex gap-2">
                    <button class="btn btn-primary" type="submit" :disabled="!canWrite || dataLoading">{{ patientForm.id ? 'บันทึก' : 'เพิ่มผู้ป่วย' }}</button>
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
                        <th>รพ.สต.</th>
                        <th class="text-end">จัดการ</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="patient in filteredPatients" :key="patient.id">
                        <td class="fw-semibold">{{ patient.hn }}</td>
                        <td>{{ patient.cid || '-' }}</td>
                        <td>{{ patient.full_name }}</td>
                        <td>{{ orgName(patient.hospcode) }}</td>
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
                    <label class="form-label">แหล่งข้อมูล</label>
                    <input v-model.trim="allergyForm.source" class="form-control" placeholder="เช่น รพ.สต. / OPD">
                  </div>
                  <div class="col-12">
                    <label class="form-label">รูปประกอบการประเมินแพ้ยา (สูงสุด 5 รูป)</label>
                    <input class="form-control" type="file" accept="image/*" multiple @change="handleAllergyPhotos">
                    <div class="small text-muted mt-1">ควรถ่ายผื่น/รอยโรค มุมใกล้ มุมกว้าง ยาที่สงสัย ฉลากยา หรือเอกสารประกอบ เพื่อให้เภสัชกรประเมินได้ง่ายขึ้น</div>
                    <div v-if="allergyPhotoFiles.length" class="photo-preview-row mt-2">
                      <div v-for="file in allergyPhotoFiles" :key="file.name" class="photo-preview">
                        <img :src="photoPreviewUrl(file)" alt="preview">
                        <span>{{ file.name }}</span>
                      </div>
                    </div>
                  </div>
                  <div class="col-12 d-flex gap-2">
                    <button class="btn btn-primary" type="submit" :disabled="!canWrite || dataLoading">บันทึกสงสัยแพ้ยา</button>
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
                        <th>รพ.สต.</th>
                        <th>ยา</th>
                        <th>อาการ</th>
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
                        <td>{{ orgName(record.patients?.hospcode) }}</td>
                        <td class="fw-semibold">{{ record.drug_name }}</td>
                        <td>{{ record.reaction }}</td>
                        <td><span class="badge" :class="statusClass(record.status)">{{ record.status }}</span></td>
                        <td class="text-end">
                          <button class="btn btn-sm btn-outline-primary me-2" @click="viewPhotos(record)" :disabled="photoCount(record) === 0">รูป {{ photoCount(record) }}</button>
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
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import Swal from 'sweetalert2'
import * as XLSX from 'xlsx'
import QRCode from 'qrcode'
import { supabase } from '../services/supabase'

const router = useRouter()
const tabs = [
  { key: 'overview', label: 'หน้าหลัก' },
  { key: 'network', label: 'เครือข่าย รพ.สต.' },
  { key: 'patients', label: 'ทะเบียนผู้ป่วย' },
  { key: 'allergies', label: 'บันทึกสงสัยแพ้ยา' },
  { key: 'exchange', label: 'นำเข้า/ส่งออกไฟล์' },
  { key: 'cards', label: 'ออกบัตรแพ้ยา' },
  { key: 'users', label: 'กำหนดสิทธิ์ผู้ใช้', adminOnly: true }
]

const activeTab = ref('overview')
const userEmail = ref('')
const userId = ref('')
const userRole = ref('staff')
const userHospcode = ref('')
const isApproved = ref(false)
const authLoading = ref(false)
const dataLoading = ref(false)
const setupError = ref('')
const searchText = ref('')
const patients = ref([])
const allergies = ref([])
const organizations = ref([])
const profiles = ref([])
const heartbeatTimer = ref(null)
const importSource = ref('JHCIS')
const importPreview = ref([])
const selectedCardAllergyId = ref('')
const selectedCard = ref(null)
const cardQr = ref('')
const allergyPhotoFiles = ref([])

const patientForm = reactive(emptyPatient())
const allergyForm = reactive(emptyAllergy())
const orgForm = reactive(emptyOrg())

const isAdmin = computed(() => userRole.value === 'admin')
const canWrite = computed(() => isAdmin.value || isApproved.value)
const roleLabel = computed(() => (isAdmin.value ? 'Admin' : 'Staff'))
const visibleTabs = computed(() => tabs.filter((tab) => !tab.adminOnly || isAdmin.value))
const currentOrgName = computed(() => orgName(userHospcode.value))

const summaryCards = computed(() => [
  { label: 'ผู้ป่วยทั้งหมด', value: patients.value.length.toLocaleString('th-TH'), short: 'PT' },
  { label: 'รายการแพ้ยา', value: allergies.value.length.toLocaleString('th-TH'), short: 'DA' },
  { label: 'รออนุมัติ', value: allergies.value.filter((item) => item.status === 'รออนุมัติ').length.toLocaleString('th-TH'), short: 'RV' },
  { label: 'รพ.สต. ออนไลน์', value: orgStats.value.filter((item) => item.onlineCount > 0).length.toLocaleString('th-TH'), short: 'ON' }
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
    patient.hospcode
  ].some((value) => String(value || '').toLowerCase().includes(keyword)))
})

const filteredAllergies = computed(() => {
  const keyword = searchText.value.toLowerCase()
  if (!keyword) return allergies.value
  return allergies.value.filter((record) => [
    record.drug_name,
    record.reaction,
    record.status,
    record.patients?.hn,
    record.patients?.full_name,
    record.patients?.hospcode
  ].some((value) => String(value || '').toLowerCase().includes(keyword)))
})

const orgStats = computed(() => {
  const known = new Map(organizations.value.map((org) => [org.hospcode, org]))
  for (const patient of patients.value) {
    if (patient.hospcode && !known.has(patient.hospcode)) {
      known.set(patient.hospcode, { hospcode: patient.hospcode, name: patient.hospcode })
    }
  }

  return Array.from(known.values()).map((org) => {
    const orgPatients = patients.value.filter((patient) => patient.hospcode === org.hospcode)
    const orgAllergies = allergies.value.filter((record) => record.patients?.hospcode === org.hospcode)
    const orgProfiles = profiles.value.filter((profile) => profile.hospcode === org.hospcode)
    const onlineProfiles = orgProfiles.filter(isProfileOnline)
    const latest = orgProfiles
      .map((profile) => profile.last_seen_at)
      .filter(Boolean)
      .sort()
      .at(-1)

    return {
      hospcode: org.hospcode,
      name: org.name,
      patientCount: orgPatients.length,
      allergyCount: orgAllergies.length,
      pendingCount: orgAllergies.filter((item) => item.status === 'รออนุมัติ').length,
      userCount: orgProfiles.length,
      onlineCount: onlineProfiles.length,
      lastSeenAt: latest || null
    }
  }).sort((a, b) => b.allergyCount - a.allergyCount || a.hospcode.localeCompare(b.hospcode))
})

onMounted(async () => {
  const { data } = await supabase.auth.getUser()
  userEmail.value = data.user?.email || '-'
  userId.value = data.user?.id || ''
  await loadOrganizations()
  await loadProfile(data.user?.user_metadata || {})
  await updateHeartbeat()
  await loadData()
  heartbeatTimer.value = window.setInterval(updateHeartbeat, 60000)
})

onBeforeUnmount(() => {
  if (heartbeatTimer.value) window.clearInterval(heartbeatTimer.value)
})

function emptyPatient() {
  return {
    id: '',
    hn: '',
    cid: '',
    hospcode: '',
    full_name: '',
    sex: 'ไม่ระบุ',
    phone: ''
  }
}

function emptyAllergy() {
  return {
    patient_id: '',
    drug_name: '',
    reaction: '',
    severity: 'ไม่ระบุ',
    source: ''
  }
}

function emptyOrg() {
  return {
    editing: false,
    hospcode: '',
    name: '',
    tambon: '',
    amphur: ''
  }
}

async function loadOrganizations() {
  const { data, error } = await supabase.from('organizations').select('*').order('hospcode')
  if (error) {
    setupError.value = error.message
    return
  }
  organizations.value = data || []
}

async function loadProfile(metadata = {}) {
  if (!userId.value) return
  const { data, error } = await supabase.from('user_profiles').select('*').eq('id', userId.value).maybeSingle()
  if (!error && data) {
    userRole.value = data.role || 'staff'
    userHospcode.value = data.hospcode || ''
    isApproved.value = Boolean(data.approved)
    return
  }

  const profile = {
    id: userId.value,
    email: userEmail.value,
    full_name: metadata.fullname || metadata.full_name || '',
    organization: metadata.organization || '',
    hospcode: metadata.hospcode || null,
    role: 'staff',
    approved: false,
    status: 'online',
    last_seen_at: new Date().toISOString()
  }

  await supabase.from('user_profiles').upsert(profile)
  userHospcode.value = profile.hospcode || ''
}

async function loadProfiles() {
  if (!isAdmin.value) return
  const { data, error } = await supabase.from('user_profiles').select('*').order('last_seen_at', { ascending: false, nullsFirst: false })
  if (error) {
    Swal.fire('โหลดผู้ใช้งานไม่สำเร็จ', error.message, 'error')
    return
  }
  profiles.value = data || []
}

async function updateHeartbeat() {
  if (!userId.value) return
  await supabase
    .from('user_profiles')
    .update({ status: 'online', last_seen_at: new Date().toISOString(), email: userEmail.value })
    .eq('id', userId.value)
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
  await loadProfiles()
}

async function saveOrganization() {
  const payload = {
    hospcode: orgForm.hospcode,
    name: orgForm.name,
    org_type: 'รพ.สต.',
    tambon: orgForm.tambon || null,
    amphur: orgForm.amphur || null
  }
  const { error } = await supabase.from('organizations').upsert(payload)
  if (error) {
    Swal.fire('บันทึก รพ.สต. ไม่สำเร็จ', error.message, 'error')
    return
  }
  resetOrgForm()
  await loadOrganizations()
}

function editOrganization(org) {
  Object.assign(orgForm, {
    editing: true,
    hospcode: org.hospcode,
    name: org.name,
    tambon: org.tambon || '',
    amphur: org.amphur || ''
  })
}

function resetOrgForm() {
  Object.assign(orgForm, emptyOrg())
}

async function saveProfile(profile) {
  const { error } = await supabase
    .from('user_profiles')
    .update({
      role: profile.role,
      approved: profile.approved,
      hospcode: profile.hospcode || null,
      organization: orgName(profile.hospcode)
    })
    .eq('id', profile.id)

  if (error) {
    Swal.fire('บันทึกสิทธิ์ไม่สำเร็จ', error.message, 'error')
    return
  }
  await loadProfiles()
  Swal.fire({ icon: 'success', title: 'บันทึกสิทธิ์แล้ว', timer: 1000, showConfirmButton: false })
}

async function savePatient() {
  if (!canWrite.value) return
  const payload = {
    hn: patientForm.hn,
    cid: patientForm.cid || null,
    hospcode: patientForm.hospcode || userHospcode.value || null,
    full_name: patientForm.full_name,
    sex: patientForm.sex,
    phone: patientForm.phone || null,
    created_by: userId.value || null
  }

  const query = patientForm.id
    ? supabase.from('patients').update(payload).eq('id', patientForm.id)
    : supabase.from('patients').insert(payload)
  const { error } = await query
  if (error) {
    Swal.fire('บันทึกไม่สำเร็จ', error.message, 'error')
    return
  }
  resetPatientForm()
  await loadData()
}

function editPatient(patient) {
  Object.assign(patientForm, { ...emptyPatient(), ...patient })
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
  if (error) Swal.fire('ลบไม่สำเร็จ', error.message, 'error')
  await loadData()
}

async function saveAllergy() {
  if (!canWrite.value) return
  dataLoading.value = true
  const photoPaths = await uploadAllergyPhotos()
  const { error } = await supabase.from('drug_allergies').insert({
    patient_id: allergyForm.patient_id,
    drug_name: allergyForm.drug_name,
    reaction: allergyForm.reaction,
    severity: allergyForm.severity,
    source: allergyForm.source || orgName(userHospcode.value),
    photo_paths: photoPaths,
    status: 'รออนุมัติ',
    created_by: userId.value || null
  })
  dataLoading.value = false
  if (error) {
    Swal.fire('บันทึกไม่สำเร็จ', error.message, 'error')
    return
  }
  resetAllergyForm()
  await loadData()
}

function handleAllergyPhotos(event) {
  const files = Array.from(event.target.files || [])
  const images = files.filter((file) => file.type.startsWith('image/'))

  if (files.length !== images.length) {
    Swal.fire('แจ้งเตือน', 'แนบได้เฉพาะไฟล์รูปภาพเท่านั้น', 'warning')
  }

  if (images.length > 5) {
    Swal.fire('แจ้งเตือน', 'แนบรูปได้สูงสุด 5 รูปต่อรายการ', 'warning')
  }

  allergyPhotoFiles.value = images.slice(0, 5)
}

function photoPreviewUrl(file) {
  return URL.createObjectURL(file)
}

async function uploadAllergyPhotos() {
  if (allergyPhotoFiles.value.length === 0) return []

  const uploaded = []
  const folder = `${userId.value || 'unknown'}/${Date.now()}`

  for (const [index, file] of allergyPhotoFiles.value.entries()) {
    const extension = file.name.split('.').pop() || 'jpg'
    const path = `${folder}/photo-${index + 1}.${extension}`
    const { error } = await supabase.storage.from('allergy-photos').upload(path, file, {
      cacheControl: '3600',
      upsert: false
    })

    if (error) {
      Swal.fire('อัปโหลดรูปไม่สำเร็จ', error.message, 'error')
      continue
    }

    const { data } = supabase.storage.from('allergy-photos').getPublicUrl(path)
    uploaded.push({
      path,
      url: data.publicUrl,
      name: file.name,
      size: file.size
    })
  }

  return uploaded
}

function normalizePhotoPaths(record) {
  if (!record?.photo_paths) return []
  if (Array.isArray(record.photo_paths)) return record.photo_paths
  try {
    return JSON.parse(record.photo_paths)
  } catch {
    return []
  }
}

function photoCount(record) {
  return normalizePhotoPaths(record).length
}

async function viewPhotos(record) {
  const photos = normalizePhotoPaths(record)
  if (photos.length === 0) return

  const html = `
    <div class="swal-photo-grid">
      ${photos.map((photo, index) => `
        <a href="${photo.url}" target="_blank" rel="noreferrer">
          <img src="${photo.url}" alt="รูปประกอบ ${index + 1}">
        </a>
      `).join('')}
    </div>
  `

  await Swal.fire({
    title: 'รูปประกอบการประเมินแพ้ยา',
    html,
    width: 900,
    confirmButtonText: 'ปิด'
  })
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
    const key = keys.find((item) => row[item] !== undefined && row[item] !== null && String(row[item]).trim() !== '')
    return key ? String(row[key]).trim() : ''
  }

  return {
    hospcode: value('HOSPCODE', 'hospcode', 'HOSP_CODE'),
    cid: value('PID', 'CID', 'cid', 'pid'),
    hn: value('HN', 'hn', 'PERSON_ID'),
    full_name: value('FULLNAME', 'NAME', 'PATIENT_NAME'),
    drug_name: value('DRUGALLERGY', 'DRUG_NAME', 'DNAME'),
    reaction: value('SYMPTOM', 'REACTION'),
    severity: normalizeSeverity(value('ALEVEL', 'SEVERITY')),
    source: importSource.value
  }
}

function normalizeSeverity(value) {
  const text = String(value || '').toLowerCase()
  if (['1', 'mild'].includes(text)) return 'ไม่รุนแรง'
  if (['2', 'moderate'].includes(text)) return 'ปานกลาง'
  if (['3', 'severe'].includes(text)) return 'รุนแรง'
  return value || 'ไม่ระบุ'
}

async function importRows() {
  if (!canWrite.value) return
  let imported = 0

  for (const row of importPreview.value) {
    const { data: patient, error: patientError } = await supabase
      .from('patients')
      .upsert({
        hn: row.hn || row.cid,
        cid: row.cid || null,
        hospcode: row.hospcode || userHospcode.value || null,
        full_name: row.full_name || 'ไม่ทราบชื่อ',
        sex: 'ไม่ระบุ',
        created_by: userId.value || null
      }, { onConflict: 'hn' })
      .select('id')
      .single()

    if (patientError || !patient?.id || !row.drug_name) continue

    const { error } = await supabase.from('drug_allergies').insert({
      patient_id: patient.id,
      drug_name: row.drug_name,
      reaction: row.reaction || 'ไม่ระบุ',
      severity: row.severity || 'ไม่ระบุ',
      source: row.source,
      status: 'รออนุมัติ',
      created_by: userId.value || null
    })
    if (!error) imported += 1
  }

  await loadData()
  Swal.fire('นำเข้าเสร็จสิ้น', `นำเข้าสำเร็จ ${imported} รายการ`, 'success')
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
  if (error) Swal.fire('ลบไม่สำเร็จ', error.message, 'error')
  await loadData()
}

function resetPatientForm() {
  Object.assign(patientForm, emptyPatient())
}

function resetAllergyForm() {
  Object.assign(allergyForm, emptyAllergy())
  allergyPhotoFiles.value = []
}

function orgName(hospcode) {
  if (!hospcode) return 'ไม่ระบุหน่วย'
  return organizations.value.find((org) => org.hospcode === hospcode)?.name || hospcode
}

function isProfileOnline(profile) {
  if (!profile?.last_seen_at || profile.status !== 'online') return false
  return Date.now() - new Date(profile.last_seen_at).getTime() < 10 * 60 * 1000
}

function formatLastSeen(value) {
  if (!value) return '-'
  return new Date(value).toLocaleString('th-TH', { dateStyle: 'short', timeStyle: 'short' })
}

function statusClass(status) {
  if (status === 'ยืนยันแล้ว') return 'bg-success'
  if (status === 'ยกเลิก') return 'bg-secondary'
  return 'bg-warning text-dark'
}

function exportStandardCsv() {
  const header = ['HOSPCODE', 'PID', 'HN', 'DATERECORD', 'DRUGALLERGY', 'SYMPTOM', 'STATUS']
  const rows = allergies.value.map((record) => [
    record.patients?.hospcode || '',
    record.patients?.cid || '',
    record.patients?.hn || '',
    String(record.created_at || '').slice(0, 10).replaceAll('-', ''),
    record.drug_name,
    record.reaction,
    record.status
  ])
  downloadCsv('DRUGALLERGY_EXPORT.csv', [header, ...rows])
}

function exportNetworkCsv() {
  const header = ['HOSPCODE', 'NAME', 'PATIENTS', 'ALLERGIES', 'PENDING', 'USERS', 'ONLINE', 'LAST_SEEN']
  const rows = orgStats.value.map((item) => [
    item.hospcode,
    item.name,
    item.patientCount,
    item.allergyCount,
    item.pendingCount,
    item.userCount,
    item.onlineCount,
    item.lastSeenAt || ''
  ])
  downloadCsv('NETWORK_STATUS.csv', [header, ...rows])
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

async function renderSelectedCard() {
  const record = allergies.value.find((item) => item.id === selectedCardAllergyId.value)
  selectedCard.value = record || null
  if (!record) {
    cardQr.value = ''
    return
  }
  const payload = `HN:${record.patients?.hn || ''}\nNAME:${record.patients?.full_name || ''}\nORG:${orgName(record.patients?.hospcode)}\nDRUG:${record.drug_name}\nREACTION:${record.reaction}`
  cardQr.value = await QRCode.toDataURL(payload, { width: 140, margin: 1 })
}

function printCard() {
  window.print()
}

async function logout() {
  authLoading.value = true
  await supabase.from('user_profiles').update({ status: 'offline', last_seen_at: new Date().toISOString() }).eq('id', userId.value)
  localStorage.removeItem('emailOtpVerifiedAt')
  const { error } = await supabase.auth.signOut()
  authLoading.value = false

  if (error) {
    Swal.fire('ออกจากระบบไม่สำเร็จ', error.message, 'error')
    return
  }
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

.photo-preview-row {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 10px;
}

.photo-preview {
  border: 1px solid #d9e2ef;
  border-radius: 8px;
  padding: 6px;
  background: #fff;
}

.photo-preview img {
  width: 100%;
  aspect-ratio: 1;
  object-fit: cover;
  border-radius: 6px;
}

.photo-preview span {
  display: block;
  margin-top: 4px;
  font-size: 0.75rem;
  color: #6c757d;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

:global(.swal-photo-grid) {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 12px;
}

:global(.swal-photo-grid img) {
  width: 100%;
  max-height: 260px;
  object-fit: contain;
  border: 1px solid #d9e2ef;
  border-radius: 8px;
  background: #f8fbff;
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
