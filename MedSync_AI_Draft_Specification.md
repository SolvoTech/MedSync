# MedSync — AI Model Draft Specification
> Dokumen ini adalah brief lengkap untuk AI model yang akan membangun aplikasi MedSync.
> Baca seluruh dokumen sebelum menulis satu baris kode pun.

---

## 0. RINGKASAN PROYEK

**Nama Aplikasi:** MedSync  
**Tagline:** Your Personal Health Companion  
**Platform:** Android only (Flutter)  
**Backend:** Supabase (Auth + Database + Storage + Realtime)  
**Target User:** Individu yang ingin mengelola jadwal obat, pengukuran kesehatan, dan aktivitas fisik, termasuk sebagai caregiver untuk orang lain.

---

## 1. TECH STACK

| Layer | Teknologi |
|-------|-----------|
| Framework | Flutter (Dart), Android SDK min 26 (Android 8.0) |
| Backend | Supabase (PostgreSQL, Auth, Storage, Edge Functions) |
| State Management | Riverpod (flutter_riverpod + hooks_riverpod) |
| Local DB | Drift (sqlite) — untuk cache offline |
| Notifications | flutter_local_notifications + android_alarm_manager_plus |
| Health Integration | health (Health Connect Android) |
| Navigation | go_router |
| Charts | fl_chart |
| PDF Export | pdf + printing |
| Theming | Material 3 (light + dark mode) |
| Storage lokal | shared_preferences + flutter_secure_storage |
| Dependency Injection | Riverpod providers |
| Env management | flutter_dotenv |
| Connectivity | connectivity_plus |
| Permission handling | permission_handler |
| Image | cached_network_image |
| DateTime | intl |
| UUID | uuid |
| Logging | logger |

### pubspec.yaml dependencies utama (referensi versi terkini):
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.x.x
  flutter_riverpod: ^2.x.x
  hooks_riverpod: ^2.x.x
  flutter_hooks: ^0.x.x
  go_router: ^13.x.x
  drift: ^2.x.x
  sqlite3_flutter_libs: ^0.x.x
  flutter_local_notifications: ^17.x.x
  android_alarm_manager_plus: ^3.x.x
  health: ^10.x.x
  fl_chart: ^0.x.x
  pdf: ^3.x.x
  printing: ^5.x.x
  shared_preferences: ^2.x.x
  flutter_secure_storage: ^9.x.x
  permission_handler: ^11.x.x
  connectivity_plus: ^6.x.x
  cached_network_image: ^3.x.x
  intl: ^0.x.x
  uuid: ^4.x.x
  logger: ^2.x.x
  flutter_dotenv: ^5.x.x
  lottie: ^3.x.x          # animasi splash & empty state
  shimmer: ^3.x.x         # loading skeleton
  gap: ^3.x.x             # spacing helper
  animations: ^2.x.x      # page transitions
  image_picker: ^1.x.x
```

---

## 2. STRUKTUR FOLDER & FILE

```
medsync/
├── android/
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml          ← permissions: SCHEDULE_EXACT_ALARM, RECEIVE_BOOT_COMPLETED, VIBRATE, dll
│   │   │   └── kotlin/com/medsync/
│   │   │       └── MainActivity.kt
│   └── build.gradle
├── assets/
│   ├── animations/                          ← file .json Lottie
│   │   ├── splash_pill.json
│   │   ├── empty_state.json
│   │   └── success_check.json
│   ├── images/
│   │   ├── onboarding_1.png
│   │   ├── onboarding_2.png
│   │   └── onboarding_3.png
│   └── .env                                 ← SUPABASE_URL, SUPABASE_ANON_KEY
├── lib/
│   ├── main.dart                            ← entry point, init Supabase, Riverpod, Notifications
│   ├── app.dart                             ← MaterialApp.router, theme setup
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   └── app_sizes.dart
│   │   ├── errors/
│   │   │   ├── app_exception.dart
│   │   │   └── failure.dart
│   │   ├── extensions/
│   │   │   ├── datetime_ext.dart
│   │   │   ├── string_ext.dart
│   │   │   └── context_ext.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart               ← light & dark ThemeData
│   │   │   ├── app_text_styles.dart
│   │   │   └── app_colors.dart
│   │   ├── router/
│   │   │   ├── app_router.dart              ← GoRouter config, guards auth
│   │   │   └── app_routes.dart              ← route name constants
│   │   ├── utils/
│   │   │   ├── date_utils.dart
│   │   │   ├── notification_utils.dart
│   │   │   └── permission_utils.dart
│   │   └── widgets/                         ← shared widgets lintas fitur
│   │       ├── app_button.dart
│   │       ├── app_card.dart
│   │       ├── app_text_field.dart
│   │       ├── app_bottom_sheet.dart
│   │       ├── app_dialog.dart
│   │       ├── app_badge.dart
│   │       ├── app_empty_state.dart
│   │       ├── app_loading_skeleton.dart
│   │       ├── streak_badge.dart
│   │       └── warning_banner.dart          ← peringatan fitur native
│   │
│   ├── services/
│   │   ├── notification_service.dart        ← flutter_local_notifications wrapper
│   │   ├── alarm_service.dart               ← android_alarm_manager_plus wrapper
│   │   ├── health_connect_service.dart      ← health package wrapper
│   │   ├── permission_service.dart          ← permission_handler wrapper
│   │   └── pdf_export_service.dart          ← pdf generation
│   │
│   ├── data/
│   │   ├── local/
│   │   │   ├── drift/
│   │   │   │   ├── app_database.dart        ← Drift DB definition
│   │   │   │   ├── tables/
│   │   │   │   │   ├── medicine_table.dart
│   │   │   │   │   ├── schedule_table.dart
│   │   │   │   │   ├── task_log_table.dart
│   │   │   │   │   └── notification_log_table.dart
│   │   │   │   └── daos/
│   │   │   │       ├── medicine_dao.dart
│   │   │   │       ├── schedule_dao.dart
│   │   │   │       └── task_log_dao.dart
│   │   │   └── preferences/
│   │   │       └── app_preferences.dart     ← SharedPreferences wrapper
│   │   │
│   │   └── remote/
│   │       ├── supabase_client.dart         ← Supabase client singleton
│   │       └── datasources/
│   │           ├── auth_remote_datasource.dart
│   │           ├── profile_remote_datasource.dart
│   │           ├── medicine_remote_datasource.dart
│   │           ├── schedule_remote_datasource.dart
│   │           ├── task_log_remote_datasource.dart
│   │           ├── measurement_remote_datasource.dart
│   │           └── physical_activity_remote_datasource.dart
│   │
│   ├── domain/
│   │   ├── models/
│   │   │   ├── user_profile.dart
│   │   │   ├── care_person.dart             ← profil orang yang dirawat
│   │   │   ├── medicine.dart
│   │   │   ├── medicine_schedule.dart
│   │   │   ├── schedule_time_slot.dart
│   │   │   ├── task_log.dart
│   │   │   ├── measurement_reminder.dart
│   │   │   ├── measurement_log.dart
│   │   │   ├── physical_activity_reminder.dart
│   │   │   ├── physical_activity_log.dart
│   │   │   └── notification_item.dart
│   │   │
│   │   └── repositories/
│   │       ├── auth_repository.dart
│   │       ├── profile_repository.dart
│   │       ├── medicine_repository.dart
│   │       ├── schedule_repository.dart
│   │       ├── task_log_repository.dart
│   │       ├── measurement_repository.dart
│   │       └── physical_activity_repository.dart
│   │
│   └── features/
│       ├── splash/
│       │   ├── splash_screen.dart
│       │   └── onboarding/
│       │       ├── onboarding_screen.dart
│       │       └── onboarding_page_model.dart
│       │
│       ├── auth/
│       │   ├── login/
│       │   │   ├── login_screen.dart
│       │   │   └── login_controller.dart
│       │   ├── register/
│       │   │   ├── register_screen.dart
│       │   │   └── register_controller.dart
│       │   ├── forgot_password/
│       │   │   └── forgot_password_screen.dart
│       │   └── onboarding_profile/
│       │       ├── onboarding_profile_screen.dart  ← isi profil awal: nama, usia, kondisi
│       │       └── onboarding_profile_controller.dart
│       │
│       ├── home/
│       │   ├── home_screen.dart             ← dashboard utama
│       │   ├── home_controller.dart
│       │   └── widgets/
│       │       ├── today_task_card.dart
│       │       ├── streak_card.dart
│       │       ├── quick_stats_row.dart
│       │       └── upcoming_reminder_card.dart
│       │
│       ├── medicine/
│       │   ├── medicine_list_screen.dart    ← daftar obat per profil
│       │   ├── medicine_form_screen.dart    ← tambah/edit obat
│       │   ├── medicine_detail_screen.dart
│       │   ├── schedule/
│       │   │   ├── schedule_list_screen.dart      ← jadwal dikelompokkan per obat
│       │   │   ├── schedule_form_screen.dart      ← atur jadwal minum obat
│       │   │   ├── time_slot_picker_widget.dart   ← UI interaktif pilih jam minum
│       │   │   └── stock_reminder_sheet.dart      ← atur custom reminder stok
│       │   ├── medicine_controller.dart
│       │   └── widgets/
│       │       ├── medicine_card.dart
│       │       ├── schedule_timeline_widget.dart   ← timeline harian per obat
│       │       └── stock_indicator_widget.dart
│       │
│       ├── measurement/
│       │   ├── measurement_list_screen.dart
│       │   ├── measurement_form_screen.dart
│       │   ├── measurement_log_screen.dart
│       │   ├── measurement_controller.dart
│       │   └── widgets/
│       │       ├── measurement_card.dart
│       │       └── measurement_chart_widget.dart
│       │
│       ├── physical_activity/
│       │   ├── activity_list_screen.dart
│       │   ├── activity_form_screen.dart
│       │   ├── activity_log_screen.dart
│       │   ├── activity_controller.dart
│       │   └── widgets/
│       │       ├── activity_card.dart
│       │       └── activity_progress_widget.dart
│       │
│       ├── health_connect/
│       │   ├── health_connect_screen.dart
│       │   ├── health_connect_controller.dart
│       │   └── widgets/
│       │       ├── health_metric_card.dart
│       │       └── health_sync_status_widget.dart
│       │
│       ├── notifications/
│       │   ├── notification_screen.dart     ← halaman navbar notifikasi
│       │   ├── notification_controller.dart
│       │   └── widgets/
│       │       ├── notification_group_header.dart  ← grouping per hari
│       │       └── notification_item_tile.dart
│       │
│       ├── reports/
│       │   ├── report_screen.dart
│       │   ├── report_controller.dart
│       │   └── widgets/
│       │       ├── report_filter_bar.dart    ← filter per hari/minggu/bulan
│       │       ├── adherence_chart.dart
│       │       ├── measurement_trend_chart.dart
│       │       └── activity_summary_chart.dart
│       │
│       └── profile/
│           ├── profile_screen.dart
│           ├── profile_controller.dart
│           ├── care_persons/
│           │   ├── care_person_list_screen.dart
│           │   └── care_person_form_screen.dart
│           └── settings/
│               ├── settings_screen.dart
│               └── theme_toggle_widget.dart
│
└── test/
    ├── unit/
    └── widget/
```

---

## 3. SKEMA DATABASE SUPABASE (PostgreSQL)

### 3.1 Tabel `profiles`
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  birth_date DATE,
  avatar_url TEXT,
  theme_mode TEXT DEFAULT 'system', -- 'light', 'dark', 'system'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- RLS: user hanya bisa akses row miliknya sendiri
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own profile"
  ON profiles FOR ALL USING (auth.uid() = id);
```

### 3.2 Tabel `care_persons`
```sql
-- Profil orang yang dirawat (caregiver mode)
CREATE TABLE care_persons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,            -- nama custom, e.g. "Ayah", "Ibu"
  relationship TEXT,                     -- e.g. "Ayah", "Ibu", "Nenek"
  birth_date DATE,
  notes TEXT,
  avatar_color TEXT,                     -- hex color untuk avatar initials
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE care_persons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owner manages their care persons"
  ON care_persons FOR ALL USING (auth.uid() = owner_id);
```

### 3.3 Tabel `medicines`
```sql
CREATE TABLE medicines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  care_person_id UUID REFERENCES care_persons(id) ON DELETE CASCADE,
  -- NULL = obat untuk diri sendiri, diisi = obat untuk care person
  name TEXT NOT NULL,
  dosage TEXT,                           -- e.g. "500mg", "1 tablet"
  medicine_type TEXT DEFAULT 'tablet',   -- 'tablet', 'kapsul', 'sirup', 'injeksi', 'salep', 'tetes', 'lainnya'
  stock_current INTEGER DEFAULT 0,       -- stok saat ini
  stock_unit TEXT DEFAULT 'tablet',      -- 'tablet', 'kapsul', 'ml', 'sachet'
  stock_low_threshold INTEGER DEFAULT 5, -- batas warning stok rendah
  stock_reminder_at INTEGER DEFAULT 3,   -- kirim reminder ketika stok tinggal x
  notes TEXT,
  color TEXT,                            -- hex color untuk UI card
  icon TEXT,                             -- nama icon
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE medicines ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owner manages medicines"
  ON medicines FOR ALL USING (auth.uid() = owner_id);
```

### 3.4 Tabel `medicine_schedules`
```sql
CREATE TABLE medicine_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  schedule_name TEXT,                    -- e.g. "Pagi", "Siang", "Malam"
  repeat_type TEXT DEFAULT 'daily',      -- 'daily', 'specific_days', 'interval_days', 'one_time'
  repeat_days INTEGER[],                 -- [1,2,3,4,5] = Senin-Jumat (hanya untuk specific_days)
  interval_days INTEGER DEFAULT 1,       -- interval hari (untuk interval_days)
  start_date DATE NOT NULL,
  end_date DATE,                         -- NULL = tidak ada batas
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE medicine_schedules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owner manages schedules"
  ON medicine_schedules FOR ALL USING (auth.uid() = owner_id);
```

### 3.5 Tabel `schedule_time_slots`
```sql
-- Satu schedule bisa punya banyak time slot dalam sehari
CREATE TABLE schedule_time_slots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  schedule_id UUID NOT NULL REFERENCES medicine_schedules(id) ON DELETE CASCADE,
  time_of_day TIME NOT NULL,             -- jam minum, e.g. 08:00:00
  dosage_amount NUMERIC DEFAULT 1,       -- jumlah dosis pada slot ini
  dosage_unit TEXT DEFAULT 'tablet',
  with_food BOOLEAN DEFAULT FALSE,
  notes TEXT,
  notification_enabled BOOLEAN DEFAULT TRUE,
  notification_before_minutes INTEGER DEFAULT 0, -- notifikasi X menit sebelum
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 3.6 Tabel `task_logs`
```sql
-- Log setiap kali user menandai task selesai/tidak
CREATE TABLE task_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  care_person_id UUID REFERENCES care_persons(id),
  task_type TEXT NOT NULL,               -- 'medicine', 'measurement', 'physical_activity'
  reference_id UUID NOT NULL,            -- ID dari medicine_schedule/measurement_reminder/activity
  time_slot_id UUID REFERENCES schedule_time_slots(id),
  scheduled_at TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ,
  status TEXT DEFAULT 'pending',         -- 'pending', 'done', 'skipped', 'missed'
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE task_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owner manages task logs"
  ON task_logs FOR ALL USING (auth.uid() = owner_id);

-- Index untuk query performa
CREATE INDEX task_logs_scheduled_at_idx ON task_logs(owner_id, scheduled_at DESC);
CREATE INDEX task_logs_date_idx ON task_logs(owner_id, DATE(scheduled_at));
```

### 3.7 Tabel `measurement_reminders`
```sql
CREATE TABLE measurement_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  care_person_id UUID REFERENCES care_persons(id),
  measurement_type TEXT NOT NULL,        -- 'blood_pressure', 'blood_sugar', 'weight', 'heart_rate', 'oxygen_saturation', 'temperature', 'custom'
  custom_name TEXT,                      -- untuk tipe 'custom'
  repeat_type TEXT DEFAULT 'daily',
  repeat_days INTEGER[],
  interval_days INTEGER DEFAULT 1,
  time_of_day TIME NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  target_value TEXT,                     -- target nilai opsional, e.g. "120/80"
  unit TEXT,                             -- satuan, e.g. "mmHg", "mg/dL", "kg"
  is_active BOOLEAN DEFAULT TRUE,
  notification_enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE measurement_reminders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owner manages measurement reminders"
  ON measurement_reminders FOR ALL USING (auth.uid() = owner_id);
```

### 3.8 Tabel `measurement_logs`
```sql
CREATE TABLE measurement_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  care_person_id UUID REFERENCES care_persons(id),
  reminder_id UUID REFERENCES measurement_reminders(id),
  measurement_type TEXT NOT NULL,
  value_primary NUMERIC NOT NULL,        -- nilai utama (atau systolic untuk tekanan darah)
  value_secondary NUMERIC,              -- nilai kedua (diastolic untuk tekanan darah)
  unit TEXT,
  notes TEXT,
  measured_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  source TEXT DEFAULT 'manual',         -- 'manual', 'health_connect'
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE measurement_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owner manages measurement logs"
  ON measurement_logs FOR ALL USING (auth.uid() = owner_id);
```

### 3.9 Tabel `physical_activity_reminders`
```sql
CREATE TABLE physical_activity_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL,           -- 'walking', 'water_intake', 'exercise', 'stretching', 'custom'
  custom_name TEXT,
  icon TEXT,
  color TEXT,
  repeat_type TEXT DEFAULT 'daily',
  repeat_days INTEGER[],
  time_of_day TIME NOT NULL,
  duration_minutes INTEGER,             -- durasi target
  target_value NUMERIC,                 -- target nilai (misal: 8 gelas air, 10000 langkah)
  target_unit TEXT,                     -- 'steps', 'glasses', 'minutes'
  start_date DATE NOT NULL,
  end_date DATE,
  is_active BOOLEAN DEFAULT TRUE,
  notification_enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE physical_activity_reminders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owner manages activity reminders"
  ON physical_activity_reminders FOR ALL USING (auth.uid() = owner_id);
```

### 3.10 Tabel `physical_activity_logs`
```sql
CREATE TABLE physical_activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reminder_id UUID REFERENCES physical_activity_reminders(id),
  activity_type TEXT NOT NULL,
  actual_value NUMERIC,
  unit TEXT,
  duration_minutes INTEGER,
  notes TEXT,
  performed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  source TEXT DEFAULT 'manual',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE physical_activity_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owner manages activity logs"
  ON physical_activity_logs FOR ALL USING (auth.uid() = owner_id);
```

### 3.11 Tabel `notification_logs`
```sql
CREATE TABLE notification_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL,       -- 'medicine', 'measurement', 'activity', 'stock_warning', 'streak'
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  reference_id UUID,                     -- ID referensi ke entitas terkait
  reference_type TEXT,                   -- tabel referensi
  is_read BOOLEAN DEFAULT FALSE,
  action_taken TEXT,                     -- 'done', 'skipped', 'dismissed', NULL
  scheduled_at TIMESTAMPTZ NOT NULL,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owner manages notification logs"
  ON notification_logs FOR ALL USING (auth.uid() = owner_id);

CREATE INDEX notif_logs_created_at_idx ON notification_logs(owner_id, created_at DESC);
```

### 3.12 Tabel `user_streaks`
```sql
CREATE TABLE user_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID UNIQUE NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_completed_date DATE,
  streak_start_date DATE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE user_streaks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owner manages their streak"
  ON user_streaks FOR ALL USING (auth.uid() = owner_id);
```

### 3.13 Supabase Edge Function: `calculate-daily-streak`
```typescript
// Dipanggil setiap tengah malam via cron atau dipicu dari client
// Cek apakah semua task hari ini selesai, update streak
// Kirim push notification jika streak tercapai
```

---

## 4. ANDROID MANIFEST PERMISSIONS

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_HEALTH"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<!-- Health Connect -->
<uses-permission android:name="android.permission.health.READ_STEPS"/>
<uses-permission android:name="android.permission.health.READ_HEART_RATE"/>
<uses-permission android:name="android.permission.health.READ_BLOOD_PRESSURE"/>
<uses-permission android:name="android.permission.health.READ_BLOOD_GLUCOSE"/>
<uses-permission android:name="android.permission.health.READ_BODY_WEIGHT"/>
<uses-permission android:name="android.permission.health.READ_OXYGEN_SATURATION"/>
<uses-permission android:name="android.permission.health.WRITE_STEPS"/>
<!-- Tambahkan sesuai kebutuhan Health Connect -->
```

---

## 5. DAFTAR SEMUA SCREEN & NAVIGASI FLOW

### 5.1 Auth Flow
```
SplashScreen (2 detik animasi logo)
  → [pertama kali] → OnboardingScreen (3 halaman, bisa skip)
  → [belum login] → LoginScreen
       → RegisterScreen
       → ForgotPasswordScreen
  → [login berhasil, profil belum lengkap] → OnboardingProfileScreen
  → [login berhasil] → MainShell (Bottom Nav)
```

### 5.2 MainShell — Bottom Navigation (5 Tab)
```
Tab 1: HomeScreen         (icon: home)
Tab 2: ScheduleScreen     (icon: medication / pill)
Tab 3: ReportScreen       (icon: bar_chart)
Tab 4: NotificationScreen (icon: notifications, dengan badge count)
Tab 5: ProfileScreen      (icon: person)
```

### 5.3 Home Screen
- Header: nama user + tanggal hari ini
- **Streak Card**: badge streak hari berturut, animasi api jika streak > 7 hari
- **Today's Tasks**: daftar semua task hari ini (obat + pengukuran + aktivitas), bisa ditandai selesai langsung dari card
- Task dikelompokkan per waktu (Pagi / Siang / Sore / Malam)
- **Quick Stats Row**: persentase task selesai hari ini, total minum obat, total aktivitas
- **Upcoming Reminder Card**: reminder berikutnya (countdown)
- Warning Banner jika ada izin yang belum diberikan

### 5.4 Schedule Screen (Tab 2)
Sub-navigasi dengan TabBar:
```
[Obat] [Pengukuran] [Aktivitas Fisik]
```

**Tab Obat:**
- Dropdown/Chips pilih profil (Saya / nama care person)
- List obat yang aktif, dikelompokkan per obat
- Setiap card obat expandable → tampilkan jadwal time slots
- FAB: tambah obat baru
- Long press card obat → edit / hapus / nonaktifkan
- Tap time slot → edit time slot

**Form Tambah/Edit Obat:**
- Nama obat (text field)
- Tipe obat (chip selector: Tablet, Kapsul, Sirup, dll)
- Dosage (text field)
- Stok saat ini (number field + stepper)
- Satuan stok
- Warna card (color picker)
- Icon obat (icon picker grid)
- Tombol: Lanjut ke Jadwal

**Form Jadwal:**
- Nama jadwal (opsional, auto: "Jadwal 1")
- Tipe pengulangan: Setiap hari / Hari tertentu / Interval / Sekali
- Pilih hari (jika Hari tertentu): toggle chips Sen-Min
- Tanggal mulai (date picker)
- Tanggal berakhir (optional date picker)
- Daftar Time Slots (minimum 1):
  - Setiap slot: jam (time picker) + jumlah dosis + catatan + toggle notifikasi
  - Tombol "+ Tambah Waktu Minum" untuk tambah slot baru
  - Slot bisa dihapus (swipe atau tombol X)
- Pengaturan Stok Reminder:
  - Toggle: aktifkan reminder stok
  - Input: kirim reminder ketika stok tinggal X (default 3)
  - Preview: "Notifikasi akan dikirim ketika stok kurang dari 3 tablet"

**Tab Pengukuran:**
- List pengingat pengukuran aktif
- Tipe: Tekanan Darah, Gula Darah, Berat Badan, Denyut Nadi, Saturasi Oksigen, Suhu, + Custom
- Setiap card: ikon tipe, nama, jadwal, nilai terakhir + tanggal
- FAB: tambah pengingat pengukuran
- Swipe → edit / hapus

**Form Tambah Pengukuran:**
- Pilih tipe (grid icon selector, atau custom)
- Nama custom (jika Custom)
- Waktu pengukuran (time picker)
- Pengulangan (sama dengan obat)
- Target nilai (opsional)
- Satuan
- Toggle notifikasi

**Tab Aktivitas Fisik:**
- List reminder aktivitas aktif
- Tipe: Jalan Kaki, Minum Air, Olahraga, Stretching, + Custom
- Setiap card: ikon, nama, jadwal, target, progres hari ini
- FAB: tambah aktivitas
- Form mirip dengan pengukuran + field target nilai (opsional)

### 5.5 Report Screen (Tab 3)
- **Filter Bar**: toggle Harian / Mingguan / Bulanan + date picker
- **Adherence Overview Card**: persentase kepatuhan keseluruhan + progress ring
- **Medicine Adherence Chart** (bar chart per obat, fl_chart)
- **Measurement Trend Chart** (line chart per tipe pengukuran)
- **Activity Summary Chart** (bar/area chart per aktivitas)
- **Streak History Card**: kalender mini highlight hari-hari sukses
- Tombol Export PDF (bottom): generate laporan PDF dengan filter aktif

### 5.6 Notification Screen (Tab 4)
- Badge merah di ikon navbar jika ada notifikasi belum dibaca
- List notifikasi dikelompokkan per hari (header: "Hari ini", "Kemarin", "Tanggal X")
- Setiap item: ikon tipe, judul, body, jam, status (tindakan yang diambil)
- Swipe kanan: tandai sudah dibaca
- Swipe kiri: hapus notifikasi
- Tombol "Tandai Semua Dibaca" di AppBar action

### 5.7 Profile Screen (Tab 5)
- Avatar + nama + email
- Card: Profil Saya (edit nama, avatar, tanggal lahir)
- Card: Kelola Anggota (list care persons + tambah baru)
- Card: Pengaturan Notifikasi (toggle per kategori)
- Card: Tampilan (toggle Light/Dark/System)
- Card: Health Connect (status koneksi + tombol kelola)
- Card: Akun (ganti password, logout)
- Card: Tentang Aplikasi (versi, privacy policy, dll)

### 5.8 Health Connect Screen
- Status koneksi Health Connect
- Daftar data yang disinkronisasi: Steps, Heart Rate, Blood Pressure, Blood Glucose, Weight, SpO2
- Per item: status (tersinkronisasi/belum), nilai terakhir, tombol sync manual
- Tombol: Berikan Izin / Cabut Izin
- Warning jika Health Connect tidak terpasang (link ke Play Store)

---

## 6. SISTEM NOTIFIKASI & ALARM

### 6.1 Tipe Notifikasi
| ID | Tipe | Channel |
|----|------|---------|
| 1000+ | Reminder minum obat | medicine_reminders |
| 2000+ | Reminder pengukuran | measurement_reminders |
| 3000+ | Reminder aktivitas fisik | activity_reminders |
| 4000+ | Peringatan stok obat rendah | stock_warnings |
| 5000+ | Streak notification | streak_notifications |
| 6000+ | Ringkasan harian (daily summary) | daily_summary |

### 6.2 Notification Channels (Android)
```dart
// Buat channel terpisah untuk setiap kategori
// Importance: medicine = HIGH, activity = DEFAULT, summary = LOW
AndroidNotificationChannel medicineChannel = AndroidNotificationChannel(
  'medicine_reminders',
  'Pengingat Obat',
  description: 'Notifikasi jadwal minum obat',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);
```

### 6.3 Exact Alarm
- Gunakan `android_alarm_manager_plus` untuk alarm yang tepat waktu
- Jadwalkan ulang setelah reboot (RECEIVE_BOOT_COMPLETED)
- Jadwalkan ulang setelah user kembali dari pengaturan izin
- Tangani `ACTION_REQUEST_SCHEDULE_EXACT_ALARM` untuk Android 12+

### 6.4 Warning Native Permissions
Tampilkan `WarningBanner` widget di HomeScreen jika:
- **Exact Alarm diblokir**: "Alarm mungkin tidak tepat waktu. Aktifkan izin Alarm di pengaturan."
- **Battery Optimization aktif**: "Hemat baterai aktif. Notifikasi mungkin tertunda. Kecualikan MedSync."
- **Notification Permission ditolak**: "Izin notifikasi diperlukan. Aktifkan di pengaturan."
- **Health Connect tidak terpasang**: "Health Connect tidak ditemukan. Pasang untuk sinkronisasi data kesehatan."

Setiap warning punya tombol "Perbaiki" yang langsung membuka intent ke pengaturan yang relevan.

---

## 7. FITUR STREAK

### Logika Streak
```
streak_day++ jika:
  - Semua task yang dijadwalkan hari ini sudah berstatus 'done' atau 'skipped' (bukan 'missed')
  - Pengecekan dilakukan pada pukul 23:59 atau saat user membuka app keesokan harinya

streak_day = 0 jika:
  - Ada minimal 1 task berstatus 'missed' di hari sebelumnya

longest_streak diperbarui jika current_streak > longest_streak
```

### UI Streak
- **Streak Card** di home: angka besar + label "hari berturut-turut"
- Icon api (🔥) yang animasi ketika streak >= 7 hari (gunakan Lottie)
- Jika streak = 0: motivasi teks "Mulai hari pertamamu hari ini!"
- Jika streak 1-6: "Bagus! Pertahankan!"
- Jika streak 7+: "Luar biasa! {streak} hari berturut-turut!"

---

## 8. FITUR PDF EXPORT

### Konten Laporan PDF
```
Header: Logo MedSync + nama user + periode laporan
Ringkasan: Total task, persentase selesai, streak saat ini
Tabel Jadwal Obat: Nama obat, dosis, jadwal, status per hari
Tabel Pengukuran: Tipe, nilai, tanggal, catatan
Tabel Aktivitas: Tipe, durasi, target vs aktual
Grafik Kepatuhan: Bar chart (gambar PNG dari fl_chart di-export)
Footer: Digenerate oleh MedSync + tanggal export
```

### Implementasi
- Gunakan package `pdf` (dart_pdf) untuk generate
- Gunakan package `printing` untuk preview dan share/print
- Chart di-render ke PNG terlebih dahulu sebelum di-embed ke PDF
- Progress indicator saat generate

---

## 9. DESIGN SYSTEM & THEMING

### Color Palette (Material 3)
```dart
// Primary: biru-hijau medis yang bersih
// Light Mode
primaryColor: Color(0xFF0077B6)         // biru medis
secondaryColor: Color(0xFF00B4D8)       // biru muda
tertiaryColor: Color(0xFF48CAE4)
backgroundColor: Color(0xFFF8FAFC)
surfaceColor: Color(0xFFFFFFFF)
errorColor: Color(0xFFDC2626)
successColor: Color(0xFF16A34A)
warningColor: Color(0xFFEA580C)

// Dark Mode (auto-generate via ColorScheme.fromSeed dengan brightness: Brightness.dark)
```

### Typography
- Font: Inter (via Google Fonts)
- Heading: Bold/SemiBold
- Body: Regular
- Caption: 12sp, warna secondary

### Card Design
- BorderRadius: 16px
- Elevation: 0 (flat) dengan border 1px atau shadow sangat subtle
- Padding: 16px

### Animasi & Transisi
- Page transition: FadeTransition + SlideTransition (go_router custom transition)
- Card tap: InkWell dengan splash
- Loading: Shimmer skeleton (shimmer package)
- Empty state: Lottie animation
- Streak: Lottie fire animation
- Task selesai: check animation + haptic feedback

---

## 10. STATE MANAGEMENT (RIVERPOD)

### Contoh Provider Structure
```dart
// Provider untuk daftar obat aktif user
final medicinesProvider = StreamProvider.family<List<Medicine>, String?>((ref, carePersonId) {
  return ref.watch(medicineRepositoryProvider).watchMedicines(carePersonId: carePersonId);
});

// Provider untuk task hari ini
final todayTasksProvider = FutureProvider<List<TaskItem>>((ref) async {
  return ref.watch(scheduleRepositoryProvider).getTodayTasks();
});

// Provider untuk streak
final streakProvider = StreamProvider<UserStreak>((ref) {
  return ref.watch(streakRepositoryProvider).watchStreak();
});

// Provider untuk notifikasi unread count
final unreadNotifCountProvider = StreamProvider<int>((ref) {
  return ref.watch(notificationRepositoryProvider).watchUnreadCount();
});
```

---

## 11. OFFLINE SUPPORT

### Strategi Cache
- Data jadwal, obat, dan task disimpan di Drift (local SQLite)
- Supabase Realtime untuk sinkronisasi otomatis ketika online
- Queue aksi offline (task_log ditandai lokal, di-sync ke Supabase ketika online)
- `connectivity_plus` untuk deteksi status jaringan
- Tampilkan offline banner jika tidak ada koneksi

---

## 12. CATATAN PENTING UNTUK AI MODEL

### DO:
1. **Baca dulu seluruh spesifikasi ini** sebelum mulai menulis kode
2. Implementasikan **RLS Supabase** di semua tabel — keamanan adalah prioritas
3. Gunakan **Riverpod** konsisten, hindari setState kecuali untuk widget lokal kecil
4. **Tangani error secara graceful** — setiap operasi async harus punya try/catch
5. Tampilkan **loading state** dan **empty state** di semua list screen
6. Implementasikan **permission check** sebelum menjadwalkan notifikasi
7. **Test di berbagai Android API level** — API 26, 31 (Android 12 exact alarm), 33 (notification permission)
8. Semua teks user-facing dalam **Bahasa Indonesia**
9. Gunakan **go_router** untuk semua navigasi, hindari Navigator.push langsung
10. Setiap screen harus support **light dan dark mode**

### DON'T:
1. Jangan hard-code warna — gunakan `Theme.of(context).colorScheme`
2. Jangan panggil Supabase langsung dari widget — selalu lewat repository
3. Jangan jadwalkan alarm tanpa mengecek izin terlebih dahulu
4. Jangan lupa handle kasus `care_person_id = null` (artinya untuk diri sendiri)
5. Jangan gunakan `BuildContext` di luar widget tree (async gap)
6. Jangan lupa `dispose` controller dan subscription

### PRIORITAS PENGEMBANGAN:
```
Phase 1 (Core):
  ✓ Auth (login/register/forgot password)
  ✓ Onboarding splash
  ✓ Home screen + today tasks
  ✓ Fitur obat + jadwal (CRUD lengkap)
  ✓ Notifikasi alarm dasar

Phase 2 (Extended):
  ✓ Pengukuran kesehatan
  ✓ Aktivitas fisik
  ✓ Streak system
  ✓ Caregiver mode (care persons)
  ✓ Halaman notifikasi

Phase 3 (Advanced):
  ✓ Laporan + chart
  ✓ PDF export
  ✓ Health Connect integration
  ✓ Offline support
  ✓ Peringatan native permission
```

---

## 13. CONTOH UI INTERAKTIF — SCHEDULE FORM

Pada form jadwal obat, gunakan pendekatan berikut untuk UI yang interaktif:

```
┌─────────────────────────────────────┐
│ 💊 Paracetamol 500mg               │
│ Stok: 30 tablet  ⚠️ Sisa 3 = notif │
├─────────────────────────────────────┤
│ Pengulangan: [Setiap Hari ▾]       │
│ Mulai: 17 Mar 2025                  │
│ Berakhir: [Tidak ada batas]         │
├─────────────────────────────────────┤
│ WAKTU MINUM                         │
│ ┌──────────────────────────────┐    │
│ │ 🕗 07:00  •  1 tablet        │    │ ← Card per slot, bisa swipe hapus
│ │    Sebelum makan             │    │
│ └──────────────────────────────┘    │
│ ┌──────────────────────────────┐    │
│ │ 🕐 13:00  •  1 tablet        │    │
│ │    Sesudah makan             │    │
│ └──────────────────────────────┘    │
│ ┌──────────────────────────────┐    │
│ │ 🌙 21:00  •  1 tablet        │    │
│ └──────────────────────────────┘    │
│                                     │
│ [+ Tambah Waktu Minum]              │ ← Outlined button
└─────────────────────────────────────┘
```

Time slot picker menggunakan bottom sheet dengan `CupertinoTimerPicker` atau custom time picker.

---

## 14. DEPENDENCY SUPABASE EDGE FUNCTION

```typescript
// supabase/functions/daily-task-check/index.ts
// Dipanggil setiap 23:55 via cron
// Tugasnya:
// 1. Buat task_logs dengan status 'missed' untuk task yang belum selesai
// 2. Update streak user
// 3. Kirim notifikasi push ringkasan harian
```

---

---

## 15. FITUR TAMBAHAN — RIWAYAT PER OBAT & CATATAN GEJALA

### 15.1 Riwayat Detail Per Obat

Setiap obat memiliki halaman riwayat tersendiri yang bisa diakses dari `MedicineDetailScreen`. Halaman ini menampilkan semua riwayat konsumsi obat tersebut, tren kepatuhan, dan log gejala/catatan yang terkait.

**Screen Baru:** `medicine_history_screen.dart`
```
lib/features/medicine/history/
  ├── medicine_history_screen.dart
  ├── medicine_history_controller.dart
  └── widgets/
      ├── adherence_mini_chart.dart      ← bar chart 7 hari/30 hari
      ├── history_log_tile.dart          ← item per sesi minum
      └── symptom_summary_card.dart      ← ringkasan catatan gejala
```

**Konten Screen:**
- Header: nama obat + ikon + stok saat ini
- **Statistik Ringkas**: % kepatuhan 7 hari / 30 hari / semua waktu (toggle chips)
- **Mini Bar Chart** (fl_chart): kepatuhan per hari dalam periode terpilih
- **List Log Riwayat**: dikelompokkan per hari, setiap item menampilkan:
  - Jam terjadwal vs jam aktual diminum
  - Status: ✅ Selesai / ⏭️ Dilewati / ❌ Terlewat
  - Catatan gejala (jika ada, tampilkan sebagai chip kecil)
- Filter: semua status / hanya selesai / hanya terlewat

### 15.2 Catatan Gejala Harian

**Alur:** Setelah user menandai task minum obat sebagai selesai, muncul **optional bottom sheet** dengan animasi slide-up:

```
┌─────────────────────────────────────┐
│  ✅ Paracetamol berhasil dicatat     │
│  Tambahkan catatan? (opsional)       │
│                                     │
│  Bagaimana kondisimu sekarang?       │
│  😊 Baik  😐 Biasa  😔 Kurang baik  │ ← emoji chip selector
│                                     │
│  Catatan singkat (opsional):         │
│  ┌─────────────────────────────┐    │
│  │ e.g. sedikit pusing, mual.. │    │
│  └─────────────────────────────┘    │
│                                     │
│  [Lewati]          [Simpan Catatan] │
└─────────────────────────────────────┘
```

**Perubahan Database — tambah kolom ke `task_logs`:**
```sql
ALTER TABLE task_logs
  ADD COLUMN mood TEXT,              -- 'good', 'neutral', 'bad'
  ADD COLUMN symptom_notes TEXT;     -- catatan gejala bebas
```

**Tampilkan di laporan PDF:** Sertakan kolom "Catatan Gejala" di tabel riwayat obat jika ada data gejala.

---

## 16. FITUR TAMBAHAN — FOTO OBAT & RESEP

### 16.1 Overview
User dapat mengambil/mengupload foto untuk setiap obat:
- **Foto Kemasan Obat**: tampilan fisik obat/kemasan
- **Foto Resep Dokter**: foto resep asli dari dokter

Foto disimpan di **Supabase Storage** bucket `medicine-photos`.

### 16.2 Perubahan Database
```sql
-- Tambah kolom ke tabel medicines
ALTER TABLE medicines
  ADD COLUMN photo_url TEXT,           -- foto kemasan obat
  ADD COLUMN prescription_url TEXT;    -- foto resep dokter

-- Supabase Storage bucket policy
-- Bucket: medicine-photos
-- Path: {owner_id}/{medicine_id}/photo.jpg
-- Path: {owner_id}/{medicine_id}/prescription.jpg
-- RLS: hanya owner yang bisa baca/tulis
```

### 16.3 UI Implementation
**Di `MedicineFormScreen`**, tambahkan section foto:
```
┌─────────────────────────────────────┐
│  FOTO OBAT                          │
│  ┌──────────┐  ┌──────────┐         │
│  │  [📷]    │  │  [📄]    │         │
│  │  Kemasan │  │  Resep   │         │
│  └──────────┘  └──────────┘         │
└─────────────────────────────────────┘
```
- Tap foto → bottom sheet pilihan: Kamera / Galeri
- Foto ditampilkan sebagai thumbnail 80x80dp, tap untuk lihat full screen
- Upload ke Supabase Storage menggunakan `image_picker` + `supabase_flutter` storage API
- Kompresi foto sebelum upload (max 1MB) menggunakan `flutter_image_compress`

**Di `MedicineDetailScreen`**: tampilkan foto kemasan di hero area, ikon dokumen untuk resep.

### 16.4 Package Tambahan
```yaml
# Tambahkan ke pubspec.yaml
image_picker: ^1.x.x          # sudah ada di spec awal
flutter_image_compress: ^2.x.x # kompresi sebelum upload
photo_view: ^0.x.x             # full screen viewer
```

---

## 17. FITUR TAMBAHAN — WIDGET HOME SCREEN ANDROID

### 17.1 Overview
Widget Android yang menampilkan ringkasan task hari ini langsung dari home screen perangkat, tanpa membuka aplikasi.

**Package:** `home_widget` (flutter/home_widget)

```yaml
home_widget: ^0.x.x
```

### 17.2 Tipe Widget (2 ukuran)

**Widget Kecil (2x2):**
```
┌────────────────────┐
│  MedSync      🔥3  │
│  ──────────────── │
│  3/5 selesai       │
│  ████████░░  60%   │
│  Task berikutnya:  │
│  💊 08:00 Paraset. │
└────────────────────┘
```

**Widget Sedang (4x2):**
```
┌──────────────────────────────────────┐
│  MedSync 🔥 3 hari    Hari ini: 60% │
│  ──────────────────────────────────  │
│  ✅ 07:00  Paracetamol               │
│  ✅ 07:30  Cek Tekanan Darah         │
│  ⏰ 12:00  Amoxicillin  ← berikutnya │
│  ○  19:00  Vitamin C                 │
└──────────────────────────────────────┘
```

### 17.3 Implementasi
```
android/app/src/main/
  ├── res/
  │   ├── layout/
  │   │   ├── medsync_widget_small.xml
  │   │   └── medsync_widget_medium.xml
  │   └── xml/
  │       ├── medsync_widget_small_info.xml
  │       └── medsync_widget_medium_info.xml
  └── kotlin/com/medsync/
      ├── MedSyncWidgetSmall.kt
      └── MedSyncWidgetMedium.kt

lib/
  └── features/widget/
      └── home_widget_service.dart     ← update data widget dari Flutter
```

**Update Widget:** Panggil `HomeWidget.saveWidgetData()` setiap kali:
- User menandai task selesai
- App dibuka (refresh data terbaru)
- Alarm notifikasi dipicu

### 17.4 Data yang Disimpan ke Widget
```dart
// home_widget_service.dart
Future<void> updateWidget() async {
  await HomeWidget.saveWidgetData('streak', currentStreak);
  await HomeWidget.saveWidgetData('progress_percent', progressPercent);
  await HomeWidget.saveWidgetData('tasks_done', tasksDone);
  await HomeWidget.saveWidgetData('tasks_total', tasksTotal);
  await HomeWidget.saveWidgetData('next_task_name', nextTaskName);
  await HomeWidget.saveWidgetData('next_task_time', nextTaskTime);
  await HomeWidget.updateWidget(
    name: 'MedSyncWidgetSmall',
    iOSName: 'MedSyncWidgetSmall',
  );
}
```

---

## 18. FITUR TAMBAHAN — NOTIFIKASI FOLLOW-UP (PENGINGAT KEDUA)

### 18.1 Logika
Jika user **tidak menandai task dalam X menit** setelah alarm pertama, sistem secara otomatis mengirimkan notifikasi pengingat kedua dengan pesan yang lebih personal.

### 18.2 Konfigurasi
**Setting per time slot** (bisa diatur di form jadwal):
```
Toggle: Aktifkan pengingat kedua
Kirim ulang setelah: [15] menit  ← default 15 menit, bisa diubah 5-60 menit
```

**Perubahan Database:**
```sql
-- Tambah kolom ke schedule_time_slots
ALTER TABLE schedule_time_slots
  ADD COLUMN followup_enabled BOOLEAN DEFAULT FALSE,
  ADD COLUMN followup_after_minutes INTEGER DEFAULT 15;
```

### 18.3 Implementasi
```dart
// notification_service.dart
Future<void> scheduleFollowUpNotification({
  required String taskLogId,
  required String medicineName,
  required DateTime scheduledAt,
  required int followupAfterMinutes,
}) async {
  // Jadwalkan follow-up alarm
  final followupTime = scheduledAt.add(Duration(minutes: followupAfterMinutes));
  
  // Cek dulu apakah task sudah selesai — jika sudah, batalkan follow-up
  // Jika belum, kirim notifikasi kedua
}
```

**Teks Notifikasi Follow-up:**
- Alarm 1: *"Waktunya minum Paracetamol 500mg 💊"*
- Alarm 2 (jika belum ditandai): *"Sudahkah kamu minum Paracetamol? Jangan lupa ya! 🔔"*

**Notifikasi kedua harus:**
- Dibatalkan otomatis jika task sudah ditandai selesai/skip sebelum follow-up dikirim
- Gunakan ID notifikasi berbeda: `original_id + 10000`
- Masuk ke log notifikasi dengan `notification_type = 'followup'`

### 18.4 Cancellation Flow
```dart
// Ketika user tap "Selesai" atau "Lewati" pada task:
await notificationService.cancelNotification(followupNotificationId);
await alarmService.cancelAlarm(followupAlarmId);
```

---

## 19. FITUR TAMBAHAN — SHARED VIEW KELUARGA (READ-ONLY)

### 19.1 Overview
User (caregiver) bisa membuat **link/kode unik** yang dapat dibagikan ke anggota keluarga lain. Penerima link bisa melihat status task orang yang dirawat secara **real-time**, **tanpa perlu membuat akun**.

### 19.2 Alur User
```
ProfileScreen → Kelola Anggota → [Nama Anggota] → "Bagikan Akses"
  → Pilih care person yang ingin dibagikan
  → Generate kode 6 karakter unik (e.g. "MED-4X7K")
  → Tampilkan QR Code + kode teks + tombol Share
  → Penerima buka app → Masuk sebagai "Penonton" → Input kode
  → Akses Read-Only Dashboard care person tersebut
```

### 19.3 Database
```sql
CREATE TABLE shared_access_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  care_person_id UUID NOT NULL REFERENCES care_persons(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,            -- kode 6 karakter, e.g. "MED4X7K"
  token_display TEXT NOT NULL,           -- format tampilan, e.g. "MED-4X7K"
  viewer_name TEXT,                      -- nama penonton (diisi saat join)
  is_active BOOLEAN DEFAULT TRUE,
  expires_at TIMESTAMPTZ,               -- NULL = tidak expired
  last_accessed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS: hanya owner bisa CRUD token-nya
ALTER TABLE shared_access_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owner manages their tokens"
  ON shared_access_tokens FOR ALL USING (auth.uid() = owner_id);

-- Policy read-only untuk anonymous (pakai Supabase anon key + RPC function)
-- Gunakan Edge Function untuk validasi token dan return data
```

### 19.4 Supabase Edge Function: `shared-view`
```typescript
// supabase/functions/shared-view/index.ts
// POST body: { token: "MED4X7K" }
// Returns:
// - care_person info (nama, relation)
// - today's tasks dengan status (tanpa info sensitif owner)
// - streak saat ini
// - progress hari ini
// Tidak return: data owner, data obat detail, history lengkap
```

### 19.5 Screen Baru
```
lib/features/shared_view/
  ├── shared_view_entry_screen.dart     ← input kode token
  ├── shared_view_dashboard_screen.dart ← read-only dashboard
  ├── shared_view_controller.dart
  └── widgets/
      ├── shared_task_card.dart         ← versi read-only task card
      └── shared_progress_ring.dart
```

**Shared View Dashboard menampilkan:**
- Nama + avatar care person
- Progress ring hari ini (X/Y task selesai)
- Streak badge
- List task hari ini dengan status (✅ / ⏰ / ❌)
- Refresh otomatis setiap 5 menit (Supabase Realtime optional)
- Watermark kecil: "Dibagikan via MedSync"

### 19.6 Manajemen Token (di ProfileScreen)
```
┌─────────────────────────────────────┐
│  Akses Dibagikan                    │
│  ──────────────────────────────────  │
│  👁️ Mama — MED-4X7K               │
│     Terakhir dilihat: 2 jam lalu    │  ← info last access
│     [Salin Link]  [Nonaktifkan]      │
│                                     │
│  [+ Buat Akses Baru]                │
└─────────────────────────────────────┘
```

---

## 20. RINGKASAN PERUBAHAN DARI FITUR TAMBAHAN

### Package Baru (tambahkan ke pubspec.yaml)
```yaml
flutter_image_compress: ^2.x.x    # kompresi foto sebelum upload
photo_view: ^0.x.x                # full screen photo viewer
home_widget: ^0.x.x               # Android home screen widget
qr_flutter: ^4.x.x                # generate QR code untuk shared view
```

### Tabel Database Baru
- `shared_access_tokens` — token akses shared view

### Kolom Database Baru
- `task_logs`: `mood`, `symptom_notes`
- `medicines`: `photo_url`, `prescription_url`
- `schedule_time_slots`: `followup_enabled`, `followup_after_minutes`

### Edge Function Baru
- `shared-view` — validasi token & return data read-only

### Screen Baru
- `medicine_history_screen.dart`
- `shared_view_entry_screen.dart`
- `shared_view_dashboard_screen.dart`

### Phase Pengembangan (Update)
```
Phase 1 (Core) — tidak berubah
Phase 2 (Extended) — tambahkan:
  ✓ Foto obat & resep
  ✓ Catatan gejala setelah task selesai
  ✓ Notifikasi follow-up (pengingat kedua)
Phase 3 (Advanced) — tambahkan:
  ✓ Riwayat detail per obat
  ✓ Home screen widget Android
  ✓ Shared view keluarga (read-only)
```

---

---

## 21. CI/CD — GITHUB ACTIONS

### 21.1 Overview & Strategi Versioning

Setiap push ke branch `main` atau `develop`, dan setiap Pull Request, akan memicu workflow GitHub Actions yang men-build APK release dan mendorong artifact ke **GitHub Packages (GitHub Container Registry)** sebagai Docker image yang berisi APK.

**Strategi Versioning:**
```
Format tag image:
  ghcr.io/<org>/medsync:<commit-sha-7>   ← selalu ada, immutable
  ghcr.io/<org>/medsync:latest           ← hanya pada push ke main
  ghcr.io/<org>/medsync:develop          ← hanya pada push ke develop

Contoh:
  ghcr.io/username/medsync:a1b2c3d       ← commit hash 7 karakter
  ghcr.io/username/medsync:latest        ← build terbaru dari main
```

**Versi APK** juga di-inject dari `pubspec.yaml` + commit hash:
```
MedSync-1.0.0+build.a1b2c3d.apk
```

### 21.2 Struktur File CI/CD
```
.github/
├── workflows/
│   ├── build-android.yml          ← workflow utama: build + push to GHCR
│   └── pull-request-check.yml     ← workflow untuk PR: build saja, tidak push
└── CODEOWNERS                     ← (opsional) assign reviewer otomatis
```

### 21.3 Workflow Utama: `build-android.yml`
```yaml
# .github/workflows/build-android.yml
name: Build & Publish Android APK

on:
  push:
    branches:
      - main
      - develop
  workflow_dispatch:              # bisa trigger manual dari GitHub UI

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository_owner }}/medsync

jobs:
  build-and-publish:
    name: Build APK & Push to GHCR
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      # 1. Checkout kode
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0            # butuh full history untuk versioning

      # 2. Ambil commit hash (7 karakter)
      - name: Get short commit SHA
        id: vars
        run: echo "sha_short=$(git rev-parse --short=7 HEAD)" >> $GITHUB_OUTPUT

      # 3. Baca versi dari pubspec.yaml
      - name: Extract version from pubspec.yaml
        id: pubspec
        run: |
          VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1)
          echo "app_version=$VERSION" >> $GITHUB_OUTPUT

      # 4. Setup Java
      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      # 5. Setup Flutter
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'   # ganti ke versi Flutter yang digunakan
          channel: 'stable'
          cache: true               # cache Flutter SDK untuk percepat build

      # 6. Cache pub packages
      - name: Cache pub packages
        uses: actions/cache@v4
        with:
          path: |
            ~/.pub-cache
            .dart_tool
          key: ${{ runner.os }}-pub-${{ hashFiles('pubspec.lock') }}
          restore-keys: |
            ${{ runner.os }}-pub-

      # 7. Buat file .env dari GitHub Secrets
      - name: Create .env file
        run: |
          cat > assets/.env << EOF
          SUPABASE_URL=${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
          EOF

      # 8. Setup keystore untuk signing APK release
      - name: Decode & setup keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/medsync.jks
          cat > android/key.properties << EOF
          storePassword=${{ secrets.KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=medsync.jks
          EOF

      # 9. Install dependencies
      - name: Flutter pub get
        run: flutter pub get

      # 10. Build APK release
      - name: Build APK
        run: |
          flutter build apk --release \
            --dart-define=APP_VERSION=${{ steps.pubspec.outputs.app_version }}+${{ steps.vars.outputs.sha_short }}

      # 11. Rename APK dengan versi lengkap
      - name: Rename APK
        run: |
          mv build/app/outputs/flutter-apk/app-release.apk \
             build/app/outputs/flutter-apk/MedSync-${{ steps.pubspec.outputs.app_version }}+build.${{ steps.vars.outputs.sha_short }}.apk

      # 12. Upload APK sebagai workflow artifact (bisa didownload dari GitHub)
      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: MedSync-APK-${{ steps.vars.outputs.sha_short }}
          path: build/app/outputs/flutter-apk/MedSync-*.apk
          retention-days: 30

      # 13. Build Docker image yang membungkus APK
      - name: Build Docker image
        run: |
          docker build \
            --build-arg APK_PATH="build/app/outputs/flutter-apk/MedSync-${{ steps.pubspec.outputs.app_version }}+build.${{ steps.vars.outputs.sha_short }}.apk" \
            --build-arg APP_VERSION="${{ steps.pubspec.outputs.app_version }}" \
            --build-arg COMMIT_SHA="${{ steps.vars.outputs.sha_short }}" \
            --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.vars.outputs.sha_short }} \
            .

      # 14. Login ke GitHub Container Registry
      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      # 15. Push dengan commit hash tag
      - name: Push image with commit SHA tag
        run: |
          docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.vars.outputs.sha_short }}

      # 16. Tag dan push 'latest' jika di branch main, 'develop' jika di branch develop
      - name: Tag and push branch tag
        run: |
          if [ "${{ github.ref_name }}" = "main" ]; then
            docker tag ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.vars.outputs.sha_short }} \
                       ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
            docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          elif [ "${{ github.ref_name }}" = "develop" ]; then
            docker tag ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.vars.outputs.sha_short }} \
                       ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:develop
            docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:develop
          fi

      # 17. Summary output di GitHub Actions UI
      - name: Write job summary
        run: |
          echo "## ✅ Build Sukses" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Info | Value |" >> $GITHUB_STEP_SUMMARY
          echo "|------|-------|" >> $GITHUB_STEP_SUMMARY
          echo "| **Versi App** | ${{ steps.pubspec.outputs.app_version }} |" >> $GITHUB_STEP_SUMMARY
          echo "| **Commit SHA** | \`${{ steps.vars.outputs.sha_short }}\` |" >> $GITHUB_STEP_SUMMARY
          echo "| **Branch** | ${{ github.ref_name }} |" >> $GITHUB_STEP_SUMMARY
          echo "| **Image** | \`ghcr.io/${{ env.IMAGE_NAME }}:${{ steps.vars.outputs.sha_short }}\` |" >> $GITHUB_STEP_SUMMARY
          echo "| **APK** | \`MedSync-${{ steps.pubspec.outputs.app_version }}+build.${{ steps.vars.outputs.sha_short }}.apk\` |" >> $GITHUB_STEP_SUMMARY
```

### 21.4 Workflow PR Check: `pull-request-check.yml`
```yaml
# .github/workflows/pull-request-check.yml
name: Pull Request — Build Check

on:
  pull_request:
    branches:
      - main
      - develop

jobs:
  build-check:
    name: Build APK (PR Check)
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Get short commit SHA
        id: vars
        run: echo "sha_short=$(git rev-parse --short=7 HEAD)" >> $GITHUB_OUTPUT

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'
          cache: true

      - name: Cache pub packages
        uses: actions/cache@v4
        with:
          path: |
            ~/.pub-cache
            .dart_tool
          key: ${{ runner.os }}-pub-${{ hashFiles('pubspec.lock') }}

      - name: Create .env file (pakai dummy/staging secrets untuk PR)
        run: |
          cat > assets/.env << EOF
          SUPABASE_URL=${{ secrets.SUPABASE_URL_STAGING || secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY_STAGING || secrets.SUPABASE_ANON_KEY }}
          EOF

      - name: Setup keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/medsync.jks
          cat > android/key.properties << EOF
          storePassword=${{ secrets.KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=medsync.jks
          EOF

      - name: Flutter pub get
        run: flutter pub get

      - name: Build APK (PR check — tidak di-push ke GHCR)
        run: flutter build apk --release

      - name: Upload APK artifact (untuk review oleh reviewer)
        uses: actions/upload-artifact@v4
        with:
          name: PR-${{ github.event.pull_request.number }}-APK-${{ steps.vars.outputs.sha_short }}
          path: build/app/outputs/flutter-apk/app-release.apk
          retention-days: 7        # disimpan 7 hari saja untuk PR

      - name: Write PR summary
        run: |
          echo "## 🔍 PR Build Check Sukses" >> $GITHUB_STEP_SUMMARY
          echo "APK berhasil di-build untuk PR #${{ github.event.pull_request.number }}." >> $GITHUB_STEP_SUMMARY
          echo "Artifact tersedia selama 7 hari. **Tidak** dipush ke registry." >> $GITHUB_STEP_SUMMARY
```

### 21.5 Dockerfile (untuk membungkus APK ke image)
```dockerfile
# Dockerfile
FROM alpine:3.19

# Metadata OCI labels
LABEL org.opencontainers.image.title="MedSync Android APK"
LABEL org.opencontainers.image.description="MedSync health companion app APK artifact"
LABEL org.opencontainers.image.source="https://github.com/<username>/medsync"
LABEL org.opencontainers.image.licenses="MIT"

ARG APK_PATH
ARG APP_VERSION
ARG COMMIT_SHA
ARG BUILD_DATE

LABEL org.opencontainers.image.version="${APP_VERSION}"
LABEL org.opencontainers.image.revision="${COMMIT_SHA}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"

# Salin APK ke dalam image
COPY ${APK_PATH} /apk/MedSync.apk

# Metadata tambahan
RUN echo "${APP_VERSION}+${COMMIT_SHA}" > /apk/VERSION && \
    echo "${BUILD_DATE}" > /apk/BUILD_DATE

# Default command: tampilkan info APK
CMD ["sh", "-c", "echo 'MedSync APK v'$(cat /apk/VERSION)' — Build: '$(cat /apk/BUILD_DATE) && ls -lh /apk/"]
```

### 21.6 GitHub Secrets yang Harus Dikonfigurasi
```
Repository Settings → Secrets and Variables → Actions → New repository secret

SUPABASE_URL              → URL project Supabase production
SUPABASE_ANON_KEY         → Anon key Supabase production
SUPABASE_URL_STAGING      → URL project Supabase staging (opsional, untuk PR check)
SUPABASE_ANON_KEY_STAGING → Anon key Supabase staging (opsional)
KEYSTORE_BASE64           → Base64 dari file .jks keystore (perintah: base64 -w 0 medsync.jks)
KEYSTORE_PASSWORD         → Password keystore
KEY_PASSWORD              → Password key alias
KEY_ALIAS                 → Nama key alias
```

### 21.7 android/app/build.gradle — Signing Config
```groovy
// android/app/build.gradle
// Baca key.properties yang dibuat oleh CI/CD atau lokal developer
def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 21.8 .gitignore — Jangan Commit Secrets
```gitignore
# Keystore & signing — JANGAN PERNAH COMMIT
android/app/*.jks
android/app/*.keystore
android/key.properties

# Environment variables
assets/.env
.env

# Build output
build/
```

### 21.9 Cara Unduh APK dari GHCR
```bash
# Pull image
docker pull ghcr.io/<username>/medsync:latest

# Salin APK keluar dari container
docker create --name medsync-apk ghcr.io/<username>/medsync:latest
docker cp medsync-apk:/apk/MedSync.apk ./MedSync.apk
docker rm medsync-apk
```

---

## 22. HALAMAN PROFIL — FITUR LENGKAP

### 22.1 Struktur Screen
```
lib/features/profile/
├── profile_screen.dart                 ← halaman utama profil (Tab 5)
├── profile_controller.dart
│
├── edit_profile/
│   ├── edit_profile_screen.dart        ← edit nama, tgl lahir, kondisi
│   └── edit_profile_controller.dart
│
├── edit_avatar/
│   ├── edit_avatar_screen.dart         ← pilih/upload foto profil
│   └── edit_avatar_controller.dart
│
├── change_password/
│   ├── change_password_screen.dart     ← ganti password
│   └── change_password_controller.dart
│
├── change_email/
│   ├── change_email_screen.dart        ← ganti email (butuh verifikasi)
│   └── change_email_controller.dart
│
├── care_persons/
│   ├── care_person_list_screen.dart
│   └── care_person_form_screen.dart
│
├── notification_settings/
│   └── notification_settings_screen.dart
│
├── appearance/
│   └── appearance_screen.dart          ← tema, ukuran font
│
├── data_management/
│   ├── data_management_screen.dart     ← backup, restore, hapus data
│   └── data_management_controller.dart
│
├── shared_access/
│   ├── shared_access_screen.dart       ← kelola token shared view
│   └── shared_access_controller.dart
│
└── settings/
    └── settings_screen.dart            ← pengaturan umum
```

### 22.2 `profile_screen.dart` — Layout Utama
```
┌─────────────────────────────────────┐
│  ← Profil                    ⚙️    │  ← AppBar (⚙️ ke settings)
├─────────────────────────────────────┤
│                                     │
│    ┌──────┐                         │
│    │  👤  │  Budi Santoso           │  ← avatar + nama
│    │  [✏️]│  budi@email.com         │  ← foto bisa di-tap untuk edit
│    └──────┘  📅 Bergabung Mar 2025  │
│                                     │
│    [  Streak: 🔥 12 hari  ]         │  ← streak badge kecil
│                                     │
├─────────────────────────────────────┤
│  AKUN                               │
│  ┌─────────────────────────────┐    │
│  │ 👤  Edit Profil          ›  │    │
│  │ 🔒  Ganti Kata Sandi      ›  │    │
│  │ 📧  Ganti Email           ›  │    │
│  │ 🖼️  Foto Profil           ›  │    │
│  └─────────────────────────────┘    │
│                                     │
│  KELOLA ANGGOTA                     │
│  ┌─────────────────────────────┐    │
│  │ 👨‍👩‍👧 Daftar Anggota        ›  │    │
│  │ 🔗  Akses Dibagikan        ›  │    │
│  └─────────────────────────────┘    │
│                                     │
│  PREFERENSI                         │
│  ┌─────────────────────────────┐    │
│  │ 🔔  Pengaturan Notifikasi  ›  │    │
│  │ 🎨  Tampilan & Tema        ›  │    │
│  │ 💾  Data & Cadangan        ›  │    │
│  └─────────────────────────────┘    │
│                                     │
│  INTEGRASI                          │
│  ┌─────────────────────────────┐    │
│  │ 🏥  Health Connect         ›  │    │
│  └─────────────────────────────┘    │
│                                     │
│  INFORMASI                          │
│  ┌─────────────────────────────┐    │
│  │ ℹ️  Tentang MedSync        ›  │    │
│  │ 🔏  Kebijakan Privasi      ›  │    │
│  │ 📋  Syarat & Ketentuan     ›  │    │
│  │ ❓  Bantuan & Dukungan     ›  │    │
│  │ ⭐  Beri Penilaian         ›  │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🚪  Keluar                  │    │  ← destructive color
│  │ 🗑️  Hapus Akun              │    │  ← destructive color, konfirmasi
│  └─────────────────────────────┘    │
│                                     │
│  v1.0.0+build.a1b2c3d              │  ← versi app di footer
└─────────────────────────────────────┘
```

### 22.3 `edit_profile_screen.dart`
**UI Label (Bahasa Indonesia) → Field (nama variabel Bahasa Inggris):**
```
Nama Lengkap          → fullName          (TextFormField, required)
Tanggal Lahir         → birthDate         (DatePickerField)
Jenis Kelamin         → gender            (SegmentedButton: Laki-laki / Perempuan / Lainnya)
Nomor Telepon         → phoneNumber       (TextFormField, opsional)
Kondisi Kesehatan     → healthConditions  (MultiChip: Hipertensi, Diabetes, Kolesterol, dll)
Catatan               → notes            (TextArea, opsional)
```

Tombol: **Simpan Perubahan** → update ke Supabase `profiles` table.

### 22.4 `edit_avatar_screen.dart`
```
┌─────────────────────────────────────┐
│  ← Foto Profil                      │
├─────────────────────────────────────┤
│         Foto saat ini               │
│         ┌──────────┐                │
│         │   [👤]   │                │
│         └──────────┘                │
│                                     │
│  ┌──────────────────────────────┐   │
│  │  📷  Ambil Foto (Kamera)     │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │  🖼️  Pilih dari Galeri       │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │  🎨  Pilih Avatar Inisial    │   │  ← avatar warna + huruf
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │  🗑️  Hapus Foto              │   │  ← kembali ke avatar inisial
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```
- Foto di-crop ke rasio 1:1 (gunakan `image_cropper` package)
- Kompresi sebelum upload (max 500KB)
- Upload ke Supabase Storage bucket `avatars/{user_id}/avatar.jpg`

### 22.5 `change_password_screen.dart`
```
Form field (Bahasa Indonesia label, Bahasa Inggris variabel):
  Kata Sandi Lama      → currentPassword   (obscure, toggle visibility)
  Kata Sandi Baru      → newPassword       (obscure, toggle visibility)
  Konfirmasi Sandi     → confirmPassword   (obscure, toggle visibility)

Indikator kekuatan password:
  [████████░░] Kuat
  Syarat: min 8 karakter, ada huruf besar, ada angka

Tombol: Perbarui Kata Sandi
```
- Gunakan `supabase.auth.updateUser(password: newPassword)` setelah verifikasi `currentPassword`

### 22.6 `change_email_screen.dart`
```
Email Saat Ini         → currentEmail      (read-only)
Email Baru             → newEmail          (TextFormField, validasi format email)
Kata Sandi             → password          (untuk konfirmasi identitas)

Tombol: Kirim Tautan Verifikasi
Info: "Email verifikasi akan dikirim ke alamat email baru."
```
- Gunakan `supabase.auth.updateUser(email: newEmail)` — Supabase akan kirim konfirmasi ke kedua email
- Tampilkan instruksi tindak lanjut setelah submit

### 22.7 `notification_settings_screen.dart`
```
PENGINGAT OBAT
  🔔 Aktifkan Notifikasi Obat          [toggle]
  🔔 Aktifkan Pengingat Kedua          [toggle]
  ⏱️ Waktu Pengingat Kedua             [dropdown: 5, 10, 15, 30 menit]

PENGINGAT KESEHATAN
  🔔 Aktifkan Notifikasi Pengukuran    [toggle]
  🔔 Aktifkan Notifikasi Aktivitas     [toggle]

NOTIFIKASI LAIN
  🔥 Notifikasi Pencapaian Streak      [toggle]
  ⚠️ Peringatan Stok Obat              [toggle]
  📊 Ringkasan Harian                  [toggle]
  🕗 Jam Ringkasan Harian              [time picker, default: 21:00]

SUARA & GETAR
  🔊 Suara Notifikasi                  [toggle]
  📳 Getar                             [toggle]
```

### 22.8 `appearance_screen.dart`
```
TEMA
  🌙 Mode Tampilan:
     ○ Ikuti Sistem
     ○ Terang
     ● Gelap

UKURAN TEKS
  A  [━━━━●━━━━] A+
     Kecil | Normal | Besar

BAHASA
  🌐 Bahasa:  [Bahasa Indonesia ▾]   ← untuk sementara hanya ID
```

### 22.9 `data_management_screen.dart`
```
CADANGAN DATA
  📤 Ekspor Data (JSON)
     Unduh semua data jadwal & riwayat kesehatan
     [Ekspor Sekarang]

PULIHKAN DATA
  📥 Impor Data (JSON)
     Pulihkan dari file cadangan sebelumnya
     [Pilih File]

HAPUS DATA
  ⚠️ Hapus Semua Data Lokal
     Cache dan data sementara akan dihapus
     [Hapus Cache]

  🗑️ Hapus Semua Riwayat
     Hapus semua log task dan riwayat kesehatan
     Data jadwal tetap tersimpan
     [Hapus Riwayat]  ← butuh konfirmasi dialog

HAPUS AKUN
  ❌ Hapus Akun Permanen
     Semua data akan dihapus dan tidak dapat dikembalikan
     [Hapus Akun]  ← butuh konfirmasi 2 langkah + input ulang password
```

### 22.10 Package Tambahan untuk Profile
```yaml
image_cropper: ^5.x.x      # crop foto profil ke 1:1
```

---

## 23. HALAMAN PENDUKUNG (STATIC PAGES)

### 23.1 Struktur Screen
```
lib/features/static_pages/
├── about_screen.dart               ← Tentang MedSync
├── privacy_policy_screen.dart      ← Kebijakan Privasi
├── terms_screen.dart               ← Syarat & Ketentuan
├── help_support_screen.dart        ← Bantuan & Dukungan
├── faq_screen.dart                 ← Pertanyaan yang Sering Diajukan
├── open_source_licenses_screen.dart ← Lisensi Open Source
└── widgets/
    ├── static_page_scaffold.dart   ← layout wrapper seragam
    └── faq_item_tile.dart          ← expandable FAQ item
```

### 23.2 `about_screen.dart` — Tentang MedSync
```
┌─────────────────────────────────────┐
│  ← Tentang MedSync                  │
├─────────────────────────────────────┤
│         [Logo MedSync]              │
│         MedSync                     │
│         Versi 1.0.0 (build a1b2c3d) │ ← versi dari BuildConfig/package_info
│                                     │
│  Deskripsi Aplikasi                 │
│  ─────────────────────────────────  │
│  MedSync adalah aplikasi pendamping │
│  kesehatan pribadi yang membantu    │
│  Anda mengelola jadwal obat,        │
│  memantau kesehatan, dan menjaga    │
│  gaya hidup aktif...                │
│                                     │
│  INFORMASI TEKNIS                   │
│  ─────────────────────────────────  │
│  Platform      Android 8.0+         │
│  Framework     Flutter              │
│  Backend       Supabase             │
│  Versi         1.0.0                │
│  Build         a1b2c3d              │
│  Rilis         17 Maret 2025        │
│                                     │
│  SOSIAL & KONTAK                    │
│  ─────────────────────────────────  │
│  🌐 Website                     ›   │
│  📧 Hubungi Kami                ›   │
│  📱 Instagram                   ›   │
│                                     │
│  HUKUM                              │
│  ─────────────────────────────────  │
│  🔏 Kebijakan Privasi           ›   │
│  📋 Syarat & Ketentuan          ›   │
│  📄 Lisensi Open Source         ›   │
│                                     │
│  © 2025 MedSync. Hak cipta         │
│  dilindungi undang-undang.          │
└─────────────────────────────────────┘
```

### 23.3 `privacy_policy_screen.dart` — Kebijakan Privasi
Tampilkan konten kebijakan privasi dalam format scrollable. Gunakan `static_page_scaffold.dart` sebagai wrapper.

**Seksi Wajib Kebijakan Privasi:**
1. **Data yang Kami Kumpulkan** — email, nama, data kesehatan yang diinput user
2. **Cara Kami Menggunakan Data** — untuk fitur aplikasi, tidak dijual ke pihak ketiga
3. **Penyimpanan Data** — disimpan di Supabase (server aman), data lokal di perangkat
4. **Hak Anda** — akses, edit, hapus data kapan saja
5. **Keamanan Data** — enkripsi in-transit (HTTPS) dan at-rest
6. **Data Anak-Anak** — tidak diperuntukkan bagi anak di bawah 13 tahun
7. **Perubahan Kebijakan** — notifikasi melalui email jika ada perubahan signifikan
8. **Hubungi Kami** — kontak email untuk pertanyaan privasi

```dart
// privacy_policy_screen.dart
// Konten bisa di-hardcode sebagai string konstanta, atau
// di-fetch dari Supabase Storage sebagai file HTML/Markdown
// agar bisa diupdate tanpa update app
```

### 23.4 `terms_screen.dart` — Syarat & Ketentuan
Serupa dengan Privacy Policy. Seksi wajib:
1. Penerimaan Syarat
2. Penggunaan yang Diizinkan
3. Larangan Penggunaan
4. Disclaimer Medis ⚠️ — **PENTING**: sertakan disclaimer bahwa MedSync **bukan pengganti saran medis profesional**
5. Pembatasan Tanggung Jawab
6. Penghentian Layanan
7. Hukum yang Berlaku (Hukum Indonesia)

### 23.5 `help_support_screen.dart` — Bantuan & Dukungan
```
┌─────────────────────────────────────┐
│  ← Bantuan & Dukungan               │
├─────────────────────────────────────┤
│  Hai! Bagaimana kami bisa membantu? │
│  ┌─────────────────────────────┐    │
│  │ 🔍  Cari pertanyaan...      │    │  ← search bar FAQ
│  └─────────────────────────────┘    │
│                                     │
│  TOPIK POPULER                      │
│  ┌──────────┐ ┌──────────┐         │
│  │ 💊 Jadwal│ │🔔 Notif  │         │  ← grid chips topik
│  │  Obat    │ │          │         │
│  └──────────┘ └──────────┘         │
│  ┌──────────┐ ┌──────────┐         │
│  │ 📊 Lapor │ │🏥 Health │         │
│  │  an      │ │ Connect  │         │
│  └──────────┘ └──────────┘         │
│                                     │
│  PERTANYAAN UMUM                    │
│  ▶ Bagaimana cara menambah jadwal?  │  ← expandable FAQ
│  ▶ Notifikasi tidak muncul          │
│  ▶ Cara ekspor laporan PDF          │
│  ▶ Cara menambahkan anggota         │
│  ▶ Lupa kata sandi                  │
│                                     │
│  MASIH BUTUH BANTUAN?               │
│  ┌─────────────────────────────┐    │
│  │ 📧  Kirim Email             │    │  ← buka email client
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 💬  WhatsApp Support        │    │  ← buka WhatsApp (opsional)
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 🐛  Laporkan Bug            │    │  ← form laporan bug
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

### 23.6 `faq_screen.dart` — FAQ Lengkap
Daftar FAQ yang lebih lengkap dari yang ada di `help_support_screen.dart`. Dikelompokkan per kategori dengan `ExpansionTile`:

**Kategori:**
- Akun & Profil
- Jadwal & Obat
- Notifikasi & Alarm
- Laporan & Ekspor
- Health Connect
- Privasi & Data
- Teknis & Troubleshooting

### 23.7 `open_source_licenses_screen.dart`
```dart
// Gunakan Flutter bawaan untuk menampilkan lisensi
LicensePage(
  applicationName: 'MedSync',
  applicationVersion: appVersion,
  applicationIcon: Image.asset('assets/images/logo.png', width: 64),
  applicationLegalese: '© 2025 MedSync. Hak cipta dilindungi.',
)
// Atau gunakan showLicensePage() dari settings
```

### 23.8 Navigasi ke Static Pages
```dart
// Di app_routes.dart — tambahkan routes
static const String about = '/about';
static const String privacyPolicy = '/privacy-policy';
static const String terms = '/terms';
static const String helpSupport = '/help-support';
static const String faq = '/faq';
static const String openSourceLicenses = '/licenses';

// Semua halaman ini bisa diakses dari:
// 1. ProfileScreen (section Informasi)
// 2. Onboarding (link ke Privacy Policy & Terms sebelum register)
// 3. RegisterScreen (checkbox "Saya menyetujui Syarat & Kebijakan Privasi")
```

### 23.9 `static_page_scaffold.dart` — Widget Wrapper Seragam
```dart
// Widget wrapper untuk semua static pages agar konsisten
class StaticPageScaffold extends StatelessWidget {
  final String title;           // judul AppBar
  final Widget child;           // konten halaman
  final String? lastUpdated;    // "Terakhir diperbarui: 1 Jan 2025"
  final List<Widget>? actions;  // action AppBar tambahan (share, dll)

  // Menampilkan:
  // - AppBar dengan tombol back
  // - Timestamp "Terakhir diperbarui" di bagian atas
  // - Konten scrollable
  // - Footer copyright di bawah
}
```

---

## 24. KONVENSI BAHASA — ATURAN WAJIB

### 24.1 Bahasa Indonesia — Semua yang Terlihat User
```dart
// ✅ BENAR — UI text selalu Bahasa Indonesia
Text('Tambah Jadwal Obat')
Text('Simpan Perubahan')
Text('Berhasil menyimpan data')
SnackBar(content: Text('Jadwal berhasil dihapus'))
AppBar(title: Text('Pengaturan Notifikasi'))
hintText: 'Masukkan nama obat'
labelText: 'Tanggal Lahir'
ElevatedButton(child: Text('Keluar'))
AlertDialog(title: Text('Hapus Data?'),
            content: Text('Tindakan ini tidak dapat dibatalkan.'))
```

### 24.2 Bahasa Inggris — Semua yang Tidak Terlihat User
```dart
// ✅ BENAR — kode, variabel, fungsi, komentar dalam Bahasa Inggris
class MedicineScheduleController extends StateNotifier<AsyncValue<List<MedicineSchedule>>> {
  Future<void> addTimeSlot(TimeSlot timeSlot) async { ... }
  Future<void> deleteSchedule(String scheduleId) async { ... }
}

// Nama file & folder → Bahasa Inggris, snake_case
medicine_schedule_screen.dart     ✅
jadwal_minum_obat_screen.dart     ❌

// Nama variabel & fungsi → Bahasa Inggris, camelCase
String fullName = '';             ✅
String namaLengkap = '';          ❌

Future<void> fetchTodayTasks()    ✅
Future<void> ambilTaskHariIni()   ❌

// Nama class → Bahasa Inggris, PascalCase
class MedicineCard extends StatelessWidget   ✅
class KartuObat extends StatelessWidget      ❌

// Komentar kode → Bahasa Inggris
// Fetch today's scheduled tasks for the active profile
// Filter by care_person_id if caregiver mode is active
```

### 24.3 Pesan Error & Validasi (Bahasa Indonesia)
```dart
// Semua pesan yang muncul ke user → Bahasa Indonesia
validator: (value) {
  if (value == null || value.isEmpty) return 'Nama obat tidak boleh kosong';
  if (value.length < 2) return 'Nama terlalu pendek';
  return null;
}

// Exception messages internal → Bahasa Inggris (tidak ditampilkan ke user)
throw AppException('Failed to fetch schedules: ${e.toString()}');

// Tapi pesan yang ditampilkan ke user setelah catch → Bahasa Indonesia
showSnackBar('Gagal memuat jadwal. Coba lagi.');
```

### 24.4 Database & API (Bahasa Inggris)
```sql
-- Nama kolom, tabel, fungsi database → Bahasa Inggris
SELECT full_name, birth_date FROM profiles WHERE owner_id = $1;
CREATE FUNCTION calculate_streak(user_id UUID) RETURNS INTEGER AS ...;

-- Nilai enum yang disimpan di DB → Bahasa Inggris (snake_case)
medicine_type: 'tablet' | 'capsule' | 'syrup' | 'injection'
task_status: 'pending' | 'done' | 'skipped' | 'missed'
repeat_type: 'daily' | 'specific_days' | 'interval_days' | 'one_time'
```

### 24.5 Konstanta String UI — Gunakan AppStrings
```dart
// lib/core/constants/app_strings.dart
// Semua string UI dikumpulkan di satu tempat → Bahasa Indonesia
class AppStrings {
  // Auth
  static const String loginTitle = 'Selamat Datang';
  static const String loginSubtitle = 'Masuk ke akun MedSync Anda';
  static const String emailLabel = 'Alamat Email';
  static const String passwordLabel = 'Kata Sandi';
  static const String loginButton = 'Masuk';
  static const String forgotPassword = 'Lupa kata sandi?';
  static const String noAccount = 'Belum punya akun? ';
  static const String registerLink = 'Daftar';

  // Home
  static const String homeGreetingMorning = 'Selamat Pagi';
  static const String homeGreetingAfternoon = 'Selamat Siang';
  static const String homeGreetingEvening = 'Selamat Malam';
  static const String todayTasks = 'Tugas Hari Ini';
  static const String streakDays = 'hari berturut-turut';
  static const String allTasksDone = 'Semua tugas selesai! 🎉';

  // Medicine
  static const String addMedicine = 'Tambah Obat';
  static const String editMedicine = 'Edit Obat';
  static const String medicineName = 'Nama Obat';
  static const String medicineStock = 'Stok Saat Ini';
  static const String scheduleTitle = 'Jadwal Minum';
  static const String addTimeSlot = 'Tambah Waktu Minum';
  static const String deleteScheduleConfirm = 'Hapus jadwal ini?';

  // General
  static const String save = 'Simpan';
  static const String cancel = 'Batal';
  static const String delete = 'Hapus';
  static const String edit = 'Edit';
  static const String close = 'Tutup';
  static const String next = 'Lanjut';
  static const String back = 'Kembali';
  static const String skip = 'Lewati';
  static const String done = 'Selesai';
  static const String loading = 'Memuat...';
  static const String emptyData = 'Belum ada data';
  static const String errorGeneral = 'Terjadi kesalahan. Coba lagi.';
  static const String noInternet = 'Tidak ada koneksi internet';
}
```

---

## 25. RINGKASAN UPDATE AKHIR (VERSI 1.2)

### Penambahan File
```
.github/
  workflows/build-android.yml         ← CI/CD utama
  workflows/pull-request-check.yml    ← CI/CD untuk PR
Dockerfile                            ← packaging APK ke Docker image
android/app/build.gradle              ← update signing config

lib/features/profile/                 ← semua sub-screen profil baru
lib/features/static_pages/           ← 6 halaman pendukung baru
lib/core/constants/app_strings.dart  ← konstanta string UI
```

### Penambahan Package
```yaml
image_cropper: ^5.x.x    # crop foto profil
package_info_plus: ^6.x.x # baca versi app dari pubspec.yaml
url_launcher: ^6.x.x      # buka link eksternal (website, email, WhatsApp)
```

### GitHub Secrets yang Harus Dikonfigurasi
```
SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_URL_STAGING,
SUPABASE_ANON_KEY_STAGING, KEYSTORE_BASE64,
KEYSTORE_PASSWORD, KEY_PASSWORD, KEY_ALIAS
```

### Phase Pengembangan (Final)
```
Phase 1 — Core
  Auth, Onboarding, Home, Jadwal Obat, Notifikasi dasar

Phase 2 — Extended
  Pengukuran, Aktivitas Fisik, Streak, Caregiver Mode,
  Halaman Notifikasi, Foto Obat & Resep, Catatan Gejala,
  Follow-up Notification, Profil Lengkap, Static Pages

Phase 3 — Advanced
  Laporan + Chart, PDF Export, Health Connect,
  Offline Support, Native Permission Warnings,
  Riwayat Per Obat, Home Widget Android,
  Shared View Keluarga, CI/CD Pipeline
```

---

---

## 26. PANDUAN CODING — BEST PRACTICE WAJIB UNTUK AI AGENT

> ⚠️ Bagian ini adalah **aturan keras (hard rules)**. AI agent WAJIB membaca dan mengikuti seluruh panduan ini sebelum menulis kode apapun. Jika ada konflik antara panduan ini dengan instruksi lain, panduan ini yang diutamakan.

---

### 26.1 ATURAN UMUM ARSITEKTUR

**A. Satu File = Satu Tanggung Jawab (Single Responsibility)**

Setiap file hanya boleh memiliki **satu tanggung jawab utama**. Jika sebuah file mulai mengurus lebih dari satu hal, pecah menjadi beberapa file.

```
✅ BENAR:
  medicine_card.dart          → hanya widget kartu obat
  medicine_controller.dart    → hanya state management obat
  medicine_repository.dart    → hanya akses data obat

❌ SALAH:
  medicine_screen.dart        → screen + controller + repository + widget semua jadi satu
```

**B. Batas Panjang File — WAJIB DIPATUHI**

| Tipe File | Maksimal Baris | Tindakan jika Melebihi |
|-----------|---------------|------------------------|
| Screen (`*_screen.dart`) | 300 baris | Pecah widget ke file terpisah |
| Controller (`*_controller.dart`) | 200 baris | Pecah ke sub-controller atau helper |
| Widget (`*_widget.dart`, `*_card.dart`) | 150 baris | Pecah ke child widget |
| Repository (`*_repository.dart`) | 250 baris | Pecah ke datasource terpisah |
| Model (`*_model.dart`) | 100 baris | Satu model per file |
| Utils/Helper | 150 baris | Pecah per domain |

```dart
// ✅ BENAR — screen yang clean, delegasikan ke widget
class MedicineListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicines = ref.watch(medicinesProvider);
    return Scaffold(
      appBar: _buildAppBar(context),
      body: medicines.when(
        data: (data) => MedicineListBody(medicines: data),   // widget terpisah
        loading: () => const MedicineListSkeleton(),          // widget terpisah
        error: (e, _) => AppErrorWidget(onRetry: () => ref.invalidate(medicinesProvider)),
      ),
      floatingActionButton: const AddMedicineFab(),           // widget terpisah
    );
  }
}

// ❌ SALAH — semua dijejalkan ke satu build method
class MedicineListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 400+ baris berisi list, shimmer, error state, FAB, dialog, form inline... ← FAT FILE
  }
}
```

**C. Layer Separation — Tidak Boleh Dilanggar**

```
Widget Layer    → hanya UI, tidak boleh akses Supabase langsung
Controller Layer → hanya state management, tidak boleh build widget
Repository Layer → hanya akses data, tidak boleh ada logika bisnis kompleks
Service Layer   → hanya wrapper platform (notifikasi, alarm, health connect)
Model Layer     → hanya data class + fromJson/toJson, tidak boleh ada logika bisnis

Alur data yang benar:
Widget → (watch/read) → Controller → (call) → Repository → (call) → Datasource → Supabase/Drift
```

---

### 26.2 ATURAN WIDGET — ANTI FAT WIDGET

**A. Pecah Widget Secara Agresif**

Jika sebuah widget memiliki lebih dari **3 level nesting** atau lebih dari **50 baris** di `build()`, pecah menjadi widget terpisah.

```dart
// ❌ SALAH — nested dalam 1 file
class HomeScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(  // streak card — harusnya widget sendiri
            child: Row(
              children: [
                Icon(...),
                Column(
                  children: [
                    Text(...),
                    Text(...),
                  ],
                ),
              ],
            ),
          ),
          ListView.builder(  // task list — harusnya widget sendiri
            itemBuilder: (ctx, i) => Container(  // task item — harusnya widget sendiri
              child: Row(...),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ BENAR — dipecah ke widget mandiri
// home_screen.dart
class HomeScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: StreakCard()),        // file: streak_card.dart
          SliverToBoxAdapter(child: QuickStatsRow()),     // file: quick_stats_row.dart
          SliverToBoxAdapter(child: UpcomingReminder()),  // file: upcoming_reminder_card.dart
          TodayTaskSliver(),                              // file: today_task_sliver.dart
        ],
      ),
    );
  }
}
```

**B. Widget Harus Menerima Data via Constructor, Bukan Akses Provider Sendiri**

Widget "presentational" (tampilan murni) tidak boleh akses Riverpod. Data masuk via constructor. Hanya widget "container" level atas yang boleh `watch` provider.

```dart
// ✅ BENAR — presentational widget, mudah di-reuse dan di-test
class MedicineCard extends StatelessWidget {
  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onTap,
    required this.onLongPress,
  });

  final Medicine medicine;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) { ... }
}

// ✅ BENAR — container widget yang menyambungkan data ke presentational
class MedicineCardContainer extends ConsumerWidget {
  const MedicineCardContainer({super.key, required this.medicineId});
  final String medicineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicine = ref.watch(medicineByIdProvider(medicineId));
    return medicine.when(
      data: (m) => MedicineCard(
        medicine: m,
        onTap: () => context.push(AppRoutes.medicineDetail(m.id)),
        onLongPress: () => _showOptions(context, ref, m),
      ),
      loading: () => const MedicineCardSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

**C. Gunakan `const` Constructor Secara Konsisten**

```dart
// ✅ Semua widget yang tidak bergantung pada runtime data harus const
const AppButton(label: 'Simpan', onPressed: _handleSave)
const SizedBox(height: 16)
const Divider()
const AppEmptyState(message: 'Belum ada obat')

// Gunakan dart analyze dan flutter analyze untuk catch non-const yang seharusnya const
```

---

### 26.3 ATURAN STATE MANAGEMENT — RIVERPOD

**A. Granularitas Provider**

Satu provider = satu slice of state. Jangan gabungkan state yang tidak berkaitan.

```dart
// ❌ SALAH — terlalu banyak state dalam satu provider
class HomeController extends StateNotifier<HomeState> {
  // medicines, schedules, tasks, streak, notifications, settings... semua di sini
}

// ✅ BENAR — pisah per domain, compose di UI level
final medicinesProvider = StreamProvider<List<Medicine>>(...);
final todayTasksProvider = FutureProvider<List<TaskItem>>(...);
final streakProvider = StreamProvider<UserStreak>(...);
final unreadCountProvider = StreamProvider<int>(...);

// Di screen, compose beberapa provider
class HomeScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final tasks = ref.watch(todayTasksProvider);
    // masing-masing rebuild hanya bagiannya saja
  }
}
```

**B. Gunakan `.select()` untuk Mencegah Rebuild Tidak Perlu**

```dart
// ❌ SALAH — rebuild seluruh widget hanya karena satu field berubah
final profile = ref.watch(profileProvider);
Text(profile.value?.fullName ?? '')

// ✅ BENAR — hanya rebuild jika fullName berubah
final name = ref.watch(profileProvider.select((p) => p.value?.fullName));
Text(name ?? '')
```

**C. Naming Convention Provider**

```dart
// Format: <domain><Deskripsi>Provider
final medicinesProvider              // list semua obat
final medicineByIdProvider           // single obat by ID (family)
final todayTasksProvider             // task hari ini
final medicineSchedulesProvider      // semua jadwal
final scheduleByMedicineProvider     // jadwal by medicine ID (family)
final unreadNotifCountProvider       // count notif belum dibaca
final streakProvider                 // data streak user
final currentProfileProvider         // profil aktif (diri sendiri atau care person)
final selectedCarePersonIdProvider   // care person yang sedang dipilih (StateProvider)
```

**D. Selalu Handle Semua State: loading, data, error**

```dart
// ✅ WAJIB — tidak boleh ada AsyncValue yang tidak dihandle lengkap
ref.watch(medicinesProvider).when(
  data: (medicines) => MedicineListBody(medicines: medicines),
  loading: () => const MedicineListSkeleton(),   // skeleton, bukan CircularProgressIndicator polos
  error: (error, stack) => AppErrorWidget(
    message: 'Gagal memuat data obat',
    onRetry: () => ref.invalidate(medicinesProvider),
  ),
);

// ❌ SALAH — ignore loading dan error state
final medicines = ref.watch(medicinesProvider).value ?? [];
```

---

### 26.4 ATURAN REUSABILITY — KOMPONEN WAJIB

**A. Daftar Shared Widget yang WAJIB Dibuat di `lib/core/widgets/`**

Semua widget berikut harus dibuat sebagai komponen reusable sejak awal. Jangan buat inline di screen manapun.

```dart
// lib/core/widgets/

// 1. AppButton — tombol utama yang konsisten di seluruh app
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,         // tampilkan spinner di dalam tombol
    this.isDestructive = false,     // warna merah untuk aksi hapus
    this.icon,                      // icon opsional di kiri label
    this.type = AppButtonType.filled, // filled | outlined | text
    this.isFullWidth = true,
  });
  // ...
}

// 2. AppTextField — text field konsisten
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.isObscure = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.onChanged,
  });
}

// 3. AppCard — card container konsisten
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderRadius,
  });
}

// 4. AppEmptyState — empty state konsisten
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.animationAsset,  // path Lottie
    this.actionLabel,
    this.onAction,
  });
}

// 5. AppErrorWidget — error state konsisten
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    this.message = AppStrings.errorGeneral,
    this.onRetry,
  });
}

// 6. AppLoadingSkeleton — shimmer loading konsisten
class AppLoadingSkeleton extends StatelessWidget {
  const AppLoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });
}

// 7. AppBottomSheet — bottom sheet dengan style konsisten
class AppBottomSheet extends StatelessWidget {
  static Future<T?> show<T>(BuildContext context, {
    required String title,
    required Widget child,
    bool isDismissible = true,
  }) => showModalBottomSheet<T>(...);
}

// 8. AppDialog — dialog konfirmasi konsisten
class AppDialog {
  static Future<bool?> showConfirm(BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = AppStrings.delete,
    bool isDestructive = false,
  }) => showDialog<bool>(...);
}

// 9. WarningBanner — banner peringatan native permission
class WarningBanner extends StatelessWidget {
  const WarningBanner({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.type = WarningType.warning,  // warning | error | info
  });
}

// 10. AppAvatar — avatar user/care person konsisten
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,             // untuk inisial jika tidak ada foto
    this.color,            // warna background avatar inisial
    required this.size,
  });
}

// 11. StatusChip — chip status task
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status}); // TaskStatus enum
}

// 12. SectionHeader — header section konsisten di dalam screen
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });
}
```

**B. Shared Helper & Extension — Wajib Dibuat, Dipakai di Semua Fitur**

```dart
// lib/core/extensions/datetime_ext.dart
extension DateTimeExt on DateTime {
  String toIndonesianDate() => ...;    // "17 Maret 2025"
  String toShortDate() => ...;         // "17 Mar"
  String toTimeString() => ...;        // "08:00"
  bool get isToday => ...;
  bool get isYesterday => ...;
  String get greetingTime => ...;      // "Pagi" | "Siang" | "Sore" | "Malam"
  bool isSameDay(DateTime other) => ...;
}

// lib/core/extensions/string_ext.dart
extension StringExt on String {
  String get initials => ...;          // "Budi Santoso" → "BS"
  bool get isValidEmail => ...;
  String get capitalizeFirst => ...;
  String toTitleCase() => ...;
}

// lib/core/extensions/context_ext.dart
extension BuildContextExt on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  void showSnackBar(String message, {bool isError = false}) => ...;
  void pop<T>([T? result]) => GoRouter.of(this).pop(result);
  void push(String path) => GoRouter.of(this).push(path);
}

// lib/core/utils/date_utils.dart
class AppDateUtils {
  static List<DateTime> getDaysInRange(DateTime start, DateTime end) => ...;
  static bool isScheduledOnDay(MedicineSchedule schedule, DateTime date) => ...;
  static String formatDuration(int minutes) => ...;  // "1 jam 30 menit"
  static DateTime startOfDay(DateTime date) => ...;
  static DateTime endOfDay(DateTime date) => ...;
}
```

**C. Shared Mixin untuk Behavior Berulang**

```dart
// lib/core/mixins/

// Mixin untuk screen yang butuh konfirmasi sebelum keluar
mixin ConfirmExitMixin<T extends StatefulWidget> on State<T> {
  bool hasUnsavedChanges = false;
  Future<bool> onWillPop() async {
    if (!hasUnsavedChanges) return true;
    return await AppDialog.showConfirm(context,
      title: 'Keluar tanpa menyimpan?',
      message: 'Perubahan yang belum disimpan akan hilang.',
      confirmLabel: 'Keluar',
      isDestructive: true,
    ) ?? false;
  }
}

// Mixin untuk scroll-based AppBar behavior
mixin ScrollAwareAppBarMixin<T extends StatefulWidget> on State<T> {
  final ScrollController scrollController = ScrollController();
  bool isScrolled = false;
  // ... lifecycle + listener
}
```

---

### 26.5 ATURAN REPOSITORY & DATA LAYER

**A. Repository Interface + Implementation**

Selalu buat interface (abstract class) untuk setiap repository. Ini memudahkan penggantian implementasi dan testing.

```dart
// lib/domain/repositories/medicine_repository.dart  ← INTERFACE
abstract class MedicineRepository {
  Stream<List<Medicine>> watchMedicines({String? carePersonId});
  Future<Medicine?> getMedicineById(String id);
  Future<void> addMedicine(Medicine medicine);
  Future<void> updateMedicine(Medicine medicine);
  Future<void> deleteMedicine(String id);
  Future<void> updateStock(String medicineId, int newStock);
}

// lib/data/repositories/medicine_repository_impl.dart  ← IMPLEMENTASI
class MedicineRepositoryImpl implements MedicineRepository {
  const MedicineRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectivityService,
  });

  final MedicineRemoteDataSource remoteDataSource;
  final MedicineLocalDataSource localDataSource;
  final ConnectivityService connectivityService;

  @override
  Stream<List<Medicine>> watchMedicines({String? carePersonId}) async* {
    // Emit dari local cache dulu, lalu sync dari remote
    yield* localDataSource.watchMedicines(carePersonId: carePersonId);
    // Trigger background sync jika online
    if (await connectivityService.isOnline) {
      await _syncFromRemote(carePersonId: carePersonId);
    }
  }
  // ...
}
```

**B. Error Handling di Repository — Tidak Boleh Throw Raw Exception**

```dart
// lib/core/errors/app_exception.dart
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Tidak ada koneksi internet']);
}

class AuthException extends AppException {
  const AuthException([super.message = 'Sesi login telah berakhir']);
}

class DatabaseException extends AppException {
  const DatabaseException([super.message = 'Gagal menyimpan data']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Data tidak ditemukan']);
}

// lib/core/errors/result.dart
// Gunakan Result type untuk operasi yang bisa gagal
typedef Result<T> = AsyncValue<T>; // manfaatkan Riverpod AsyncValue
// Atau gunakan Either dari fpdart jika project membutuhkan functional approach

// Di repository:
@override
Future<void> addMedicine(Medicine medicine) async {
  try {
    await remoteDataSource.insertMedicine(medicine.toJson());
    await localDataSource.insertMedicine(medicine);
  } on PostgrestException catch (e) {
    throw DatabaseException('Gagal menyimpan obat: ${e.message}');
  } on SocketException {
    throw const NetworkException();
  } catch (e) {
    throw DatabaseException(e.toString());
  }
}
```

**C. Model — Selalu Immutable + copyWith + fromJson/toJson**

```dart
// lib/domain/models/medicine.dart
@immutable
class Medicine {
  const Medicine({
    required this.id,
    required this.ownerId,
    this.carePersonId,
    required this.name,
    required this.dosage,
    this.medicineType = MedicineType.tablet,
    this.stockCurrent = 0,
    this.stockUnit = 'tablet',
    this.stockLowThreshold = 5,
    this.stockReminderAt = 3,
    this.notes,
    this.color,
    this.photoUrl,
    this.prescriptionUrl,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String? carePersonId;
  final String name;
  final String dosage;
  final MedicineType medicineType;
  final int stockCurrent;
  final String stockUnit;
  final int stockLowThreshold;
  final int stockReminderAt;
  final String? notes;
  final String? color;
  final String? photoUrl;
  final String? prescriptionUrl;
  final bool isActive;
  final DateTime createdAt;

  // Computed property
  bool get isStockLow => stockCurrent <= stockLowThreshold;
  bool get needsStockReminder => stockCurrent <= stockReminderAt;

  Medicine copyWith({
    String? name,
    String? dosage,
    int? stockCurrent,
    bool? isActive,
    // ... semua field
  }) => Medicine(
    id: id,
    ownerId: ownerId,
    name: name ?? this.name,
    // ...
  );

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
    id: json['id'] as String,
    ownerId: json['owner_id'] as String,
    name: json['name'] as String,
    // ...
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'name': name,
    // ...
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Medicine && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
```

---

### 26.6 ATURAN NAVIGASI — GO_ROUTER

**A. Semua Route Didefinisikan di Satu Tempat**

```dart
// lib/core/router/app_routes.dart  ← konstanta nama route
abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String medicineList = '/medicines';
  static const String medicineForm = '/medicines/form';
  static const String medicineDetail = '/medicines/:id';
  static const String scheduleForm = '/medicines/:id/schedule/form';
  // ... dst

  // Helper untuk generate path dengan parameter
  static String medicineDetailPath(String id) => '/medicines/$id';
  static String scheduleFormPath(String medicineId) => '/medicines/$medicineId/schedule/form';
}

// lib/core/router/app_router.dart  ← GoRouter instance
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isOnAuthPage = state.matchedLocation.startsWith('/login') ||
                           state.matchedLocation.startsWith('/register') ||
                           state.matchedLocation == AppRoutes.onboarding;
      if (!isLoggedIn && !isOnAuthPage) return AppRoutes.login;
      if (isLoggedIn && isOnAuthPage) return AppRoutes.home;
      return null;
    },
    routes: [ ... ],
  );
});
```

**B. Tidak Boleh Gunakan Navigator.push/pop Langsung**

```dart
// ❌ SALAH
Navigator.push(context, MaterialPageRoute(builder: (_) => MedicineFormScreen()));
Navigator.pop(context);

// ✅ BENAR
context.push(AppRoutes.medicineForm);
context.pop();
context.pushReplacement(AppRoutes.home);
```

---

### 26.7 ATURAN SUPABASE & KEAMANAN

**A. Tidak Boleh Akses Supabase Langsung dari Widget atau Controller**

```dart
// ❌ SALAH — akses Supabase dari controller langsung
class MedicineController extends StateNotifier<...> {
  Future<void> addMedicine(Medicine m) async {
    await Supabase.instance.client.from('medicines').insert(m.toJson()); // ❌
  }
}

// ✅ BENAR — lewat repository
class MedicineController extends StateNotifier<...> {
  Future<void> addMedicine(Medicine m) async {
    await _medicineRepository.addMedicine(m); // ✅
  }
}
```

**B. Selalu Validasi Data Sebelum Kirim ke Supabase**

```dart
// Di repository atau sebelum insert, pastikan required fields terisi
// Jangan bergantung hanya pada constraint database
void _validateMedicine(Medicine medicine) {
  if (medicine.name.trim().isEmpty) throw const DatabaseException('Nama obat tidak boleh kosong');
  if (medicine.stockCurrent < 0) throw const DatabaseException('Stok tidak boleh negatif');
}
```

**C. Realtime Subscription — Selalu Cancel**

```dart
// Di controller yang pakai Supabase Realtime:
class NotificationController extends StateNotifier<...> {
  RealtimeChannel? _channel;

  void _subscribeToNotifications() {
    _channel = Supabase.instance.client
      .channel('notification_logs')
      .onPostgresChanges(...)
      .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe(); // ← WAJIB cancel subscription
    super.dispose();
  }
}
```

---

### 26.8 ATURAN PERFORMA

**A. Gunakan `ListView.builder`, Bukan `ListView` dengan children**

```dart
// ❌ SALAH — semua item dirender sekaligus
ListView(children: medicines.map((m) => MedicineCard(medicine: m)).toList())

// ✅ BENAR — lazy rendering
ListView.builder(
  itemCount: medicines.length,
  itemBuilder: (context, index) => MedicineCard(medicine: medicines[index]),
)
```

**B. Hindari `setState` / `ref.watch` di dalam Loop atau `initState`**

```dart
// ❌ SALAH
@override
void initState() {
  super.initState();
  ref.read(medicinesProvider); // bukan tempat yang tepat untuk watch
}

// ✅ BENAR — gunakan ref.listen di ConsumerStatefulWidget atau efek di ConsumerWidget
@override
Widget build(BuildContext context, WidgetRef ref) {
  ref.listen(medicinesProvider, (prev, next) {
    // react to changes
  });
}
```

**C. Image Caching — Selalu Gunakan `CachedNetworkImage`**

```dart
// ❌ SALAH
Image.network(avatarUrl)

// ✅ BENAR
CachedNetworkImage(
  imageUrl: avatarUrl,
  placeholder: (context, url) => const AppLoadingSkeleton(width: 40, height: 40),
  errorWidget: (context, url, error) => AppAvatar(name: userName, size: 40),
)
```

**D. Hindari Rebuild yang Tidak Perlu dengan `RepaintBoundary`**

```dart
// Wrap widget yang sering rebuild atau berat secara visual
RepaintBoundary(
  child: MedicineAdherenceChart(...),  // chart tidak perlu ikut rebuild parent
)
```

---

### 26.9 ATURAN ASYNC & LIFECYCLE

**A. Selalu Handle `mounted` Check Setelah `await`**

```dart
// ❌ SALAH — bisa crash jika widget sudah unmount saat await selesai
Future<void> _handleSave() async {
  await repository.saveMedicine(medicine);
  ScaffoldMessenger.of(context).showSnackBar(...); // context mungkin sudah tidak valid
}

// ✅ BENAR — cek mounted sebelum gunakan context setelah await
Future<void> _handleSave() async {
  await repository.saveMedicine(medicine);
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

**B. Dispose Semua Controller, Subscription, dan AnimationController**

```dart
class _MedicineFormScreenState extends State<MedicineFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final AnimationController _animationController;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _dosageController = TextEditingController();
    _animationController = AnimationController(vsync: this, duration: ...);
  }

  @override
  void dispose() {
    _nameController.dispose();       // ← wajib
    _dosageController.dispose();     // ← wajib
    _animationController.dispose();  // ← wajib
    _subscription?.cancel();         // ← wajib
    super.dispose();
  }
}
```

---

### 26.10 CHECKLIST SEBELUM COMMIT — AI AGENT WAJIB VERIFIKASI

Sebelum menganggap sebuah fitur selesai, AI agent WAJIB memverifikasi checklist berikut:

```
STRUKTUR & ARSITEKTUR
  □ Tidak ada file yang melebihi batas baris maksimum (Section 26.1B)
  □ Setiap file memiliki satu tanggung jawab
  □ Widget dipecah dengan benar, tidak ada fat widget
  □ Layer separation terjaga (widget → controller → repository → datasource)
  □ Tidak ada akses Supabase langsung dari widget atau controller

REUSABILITY
  □ Tidak ada komponen UI yang diduplikasi — gunakan shared widgets
  □ Semua string UI menggunakan AppStrings (bukan hardcode di widget)
  □ Warna menggunakan Theme.of(context).colorScheme (bukan hardcode)
  □ Spacing menggunakan AppSizes konstanta (bukan hardcode angka)
  □ Semua TextStyle menggunakan Theme.of(context).textTheme

STATE MANAGEMENT
  □ Semua AsyncValue dihandle: loading, data, error
  □ Provider diberi nama sesuai konvensi
  □ Tidak ada setState yang seharusnya pakai Riverpod
  □ Subscription dan controller di-dispose dengan benar

BAHASA & TEKS
  □ Semua teks yang terlihat user dalam Bahasa Indonesia
  □ Semua nama variabel, fungsi, class, file dalam Bahasa Inggris
  □ Pesan error user-facing dalam Bahasa Indonesia
  □ Komentar kode dalam Bahasa Inggris

KEAMANAN & DATA
  □ Semua tabel Supabase memiliki RLS aktif
  □ Semua operasi async memiliki try/catch
  □ BuildContext tidak digunakan setelah await tanpa mounted check
  □ Tidak ada secret/key yang di-hardcode di kode

PERFORMA
  □ List menggunakan ListView.builder, bukan ListView dengan children
  □ Widget yang tidak berubah menggunakan const constructor
  □ Image network menggunakan CachedNetworkImage
  □ Tidak ada operasi berat di build() method

UI/UX
  □ Setiap screen memiliki loading state (skeleton, bukan spinner polos)
  □ Setiap screen memiliki empty state (dengan ilustrasi/animasi)
  □ Setiap screen memiliki error state (dengan tombol retry)
  □ Mendukung light mode DAN dark mode
  □ Semua teks dapat dibaca di kedua mode tema
```

---

*Dokumen ini dibuat untuk keperluan pengembangan aplikasi MedSync.*
*Versi: 1.3 | Diperbarui: Maret 2025*
*Perubahan: Panduan Best Practice AI Agent — Anti Fat File, Reusability, Architecture Rules, Coding Checklist*
