# Supabase Email OTP Template

ใช้สำหรับระบบยืนยันตัวตนชั้นที่ 2 หลังจากผู้ใช้กรอก Email/Password ผ่านแล้ว

ไปที่ Supabase Dashboard > Authentication > Email Templates > Magic Link แล้วปรับเนื้อหาอีเมลให้แสดงรหัส OTP ด้วยตัวแปร `{{ .Token }}`

Subject:

```text
รหัสยืนยันเข้าสู่ระบบ PDH Drug Allergy
```

Body:

```html
<h2>รหัสยืนยันเข้าสู่ระบบ PDH Drug Allergy</h2>
<p>รหัส OTP ของคุณคือ</p>
<h1 style="letter-spacing: 6px;">{{ .Token }}</h1>
<p>กรุณานำรหัสนี้ไปกรอกในหน้าเข้าสู่ระบบ</p>
<p>หากคุณไม่ได้เป็นผู้ร้องขอรหัสนี้ กรุณาเพิกเฉยต่ออีเมลฉบับนี้</p>
```

หมายเหตุ:

- ระบบเรียก `signInWithOtp` หลังจากตรวจรหัสผ่านผ่านแล้ว
- หน้า Login ใช้ `verifyOtp` เพื่อตรวจรหัส 6 หลัก
- หากผู้ใช้ยังไม่ได้ยืนยันอีเมลสมัครสมาชิก จะต้องยืนยันอีเมลก่อน
