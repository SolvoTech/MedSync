# Plan Implementasi: Username Auth, Admin Control, dan Edukasi

## Legenda Status
- [ ] Belum dikerjakan
- [x] Selesai dikerjakan
- [~] Butuh audit

## Progress Plan

### Fase 1 - Fondasi Database dan Security
- [x] Tambah migration pondasi untuk `profiles.username`, `profiles.role`, `profiles.account_status`, dan `profiles.internal_email`.
- [x] Tambah helper fungsi SQL `public.is_admin()` untuk RBAC policy.
- [x] Tambah tabel `admin_audit_logs` untuk jejak aksi admin.
- [x] Tambah tabel `education_articles` untuk konten edukasi.
- [x] Tambah baseline RLS policy untuk akses admin (monitoring) dan akses artikel published untuk user.
- [x] Audit policy per tabel agar tidak ada celah privilege escalation.
	- Artefak: `docs/security/phase1_rls_privilege_escalation_audit.md`.

### Fase 2 - Migrasi Auth ke Username + Password
- [x] Refactor alur login agar menerima `username + password`.
- [x] Refactor alur registrasi agar menyimpan metadata username dan memakai email internal sintetis.
- [x] Refactor alur forgot password agar menerima username.
- [x] Refactor validator form ke validasi username.
- [x] Refactor string UX auth dari email ke username.
- [x] Audit kompatibilitas akun legacy berbasis email (fallback login email masih dipertahankan sementara).
	- Artefak: `docs/security/phase2_legacy_auth_compatibility_audit.md`.

### Fase 3 - Admin Control Center
- [x] Tambah route dan guard role admin di layer router.
- [x] Implement dashboard monitoring admin.
- [x] Implement manajemen user (suspend/unsuspend + reset akses).
- [x] Tulis audit log untuk setiap aksi admin dari aplikasi.

### Fase 4 - Fitur Edukasi
- [x] Buat model/domain/repository artikel di Flutter.
- [x] Bangun UI admin CRUD + publish/unpublish artikel.
- [x] Bangun UI user untuk feed + detail artikel (read-only).
- [x] Integrasikan notifikasi in-app saat artikel dipublish.

### Fase 5 - Verifikasi dan Rilis
- [x] Tambah unit test dan widget test untuk auth username, role guard, admin action, artikel.
- [x] Uji integrasi end-to-end skenario kritikal.
- [x] Audit keamanan final (RLS bypass, username enumeration, kebocoran internal email).
- [x] Rilis bertahap dengan monitoring error dan aktivitas admin.

### Artefak Fase 5
- [x] Test skenario kritikal: `test/integration/critical_scenarios_test.dart`.
- [x] Laporan audit keamanan: `docs/security/phase5_final_audit.md`.
- [x] Runbook rilis bertahap: `docs/release/staged_rollout_monitoring.md`.

## Catatan Implementasi Penting
- Username dinormalisasi ke lowercase.
- Domain email internal yang dipakai auth saat ini: `@users.medsync.local`.
- Untuk menghindari lockout saat transisi, fallback login email legacy masih diizinkan di controller.
