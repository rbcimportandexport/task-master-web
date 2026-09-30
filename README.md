# 📋 RBC Task Master & Operations Management

A comprehensive, role-based application designed for task management, cross-team delegation, leave approvals, and photo-verified geo-attendance tracking.

---

## 🌟 Key Features

### 1. 🔐 Role-Based Access Control (RBAC) & Hierarchy
- **Super Admin:**
  - Full company-wide visibility across all departments.
  - Department-wise Manager & Employee breakdown with drill-down views.
  - Ability to designate, add, and manage company managers directly from the admin dashboard.
- **Manager:**
  - Add and manage department employees.
  - **Cross-Manager & Hierarchy Task Assignment:** Assign tasks to own team members or delegate to other managers/departments.
  - **Task Re-Assign / Transfer:** Seamlessly transfer tasks from absent/unavailable employees to other team members with optional remarks.
  - **Daily Team Attendance Alert:** Scheduled alert summarizing team presence.
  - **Leave Requests Review:** Approve or Reject leave requests with mandatory rejection remarks.
  - Monitor live team attendance (Check-in/Check-out, selfie, GPS location, work duration).
- **Employee (Standard):**
  - Default secure onboarding role for all new signups.
  - Manage personal tasks and view tasks assigned by managers.
  - Mark daily attendance with selfie and GPS location.
  - Apply for Leaves (Casual, Sick, Emergency, Vacation) and view manager approval status & remarks.
  - Monthly Attendance Calendar View with Present, Weekly Off, and Absent/Leave breakdown.

---

### 2. 📸 Attendance & Work-Hours Analytics
- **Selfie + GPS Punch In / Punch Out:**
  - Front-camera photo verification for attendance.
  - Geo-location coordinates recorded on check-in/out.
  - **Single Punch-In Rule:** Prevents duplicate entries on the same date.
- **Detailed Analytics & Calendar View:**
  - Month & Year Selector for easy historical inspection.
  - Date-by-date breakdown with exact duration calculation.
  - Total Present count, Total Off days, and Total Leaves / Absent count.

---

### 3. 🔄 Task Management & Transfer System
- **Create, Prioritize, & Assign:**
  - Category tags (Work, Personal, Fitness, Custom Categories).
  - Priority Flags (High, Medium, Low) & Color Coding.
  - Subtask checklists and progress percentage calculation.
  - Starred Tasks, Due Date Filters, and Grid/List views.

---

### 4. 📝 Leave Management System
- Employees can apply for leaves specifying date ranges and reasons.
- Managers receive instant notifications to Approve or Reject applications with feedback remarks.

---

## 🚀 Getting Started

### Run Locally
```bash
# 1. Install dependencies
flutter pub get

# 2. Run on Chrome
flutter run -d chrome --web-port=5000

# 3. Run on Android Device / Emulator
flutter run -d android
```

### Build Release Bundle
```bash
flutter build web --release
```
