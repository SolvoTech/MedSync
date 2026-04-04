# Plan Implementasi: Username Auth, Admin Control, dan Edukasi

## Legenda Status
- [ ] Belum dikerjakan
- [x] Selesai dikerjakan
- [~] Butuh audit

## Tujuan Implementasi
- Menyediakan alur autentikasi berbasis username yang konsisten dan aman.
- Memisahkan pengalaman pengguna admin dan user agar tidak saling tercampur.
- Menstabilkan fitur admin control dan manajemen edukasi.
- Menjaga kualitas kode tetap bersih (test hijau dan analyzer bersih).

## Ringkasan Kondisi Saat Ini

### 1) Auth dan Registrasi
- [x] Login berbasis username (mapping ke internal email).
- [x] Registrasi sukses diarahkan ke halaman login (bukan auto-masuk dashboard).
- [x] Validasi username dan account status saat login.
- [~] Audit messaging error auth agar benar-benar seragam pada semua edge case.

### 2) Router dan Role Guard
- [x] Route guard memisahkan akses admin route vs user route.
- [x] Home route dipusatkan lewat role resolver screen.
- [x] Bottom nav admin dan user dipisah sesuai role.
- [~] Audit ulang skenario race condition auth/role saat koneksi tidak stabil.

### 3) Admin Control
- [x] Dashboard ringkasan sistem (user aktif, suspend, adherence harian).
- [x] Kelola status user (suspend/unsuspend).
- [x] Reset akses user dan audit log tindakan admin.
- [~] Audit policy RLS Supabase untuk tabel admin (wajib sebelum release production).

### 4) Edukasi
- [x] Feed dan detail artikel berjalan.
- [x] Admin education management tersedia.
- [~] Audit konsistensi label dan empty state pada semua kondisi data kosong/gagal.

### 5) Quality Gate
- [x] Analyzer bersih (no issues).
- [x] Test suite lulus penuh.
- [x] Lint info yang sempat muncul sudah dibereskan.

## Perbaikan yang Diterapkan Sekarang
- [x] Home role resolver kini menerima bootstrap role dari router agar transisi ke dashboard admin lebih cepat saat role sudah diketahui.
- [x] Provider role di home diberi cache singkat (keep-alive 2 menit) untuk menekan query berulang yang tidak perlu.
- [x] Error state pada role resolver ditampilkan dengan komponen error + tombol retry, tidak lagi diam-diam fallback di semua kasus.
- [x] Untuk sesi yang sudah teridentifikasi user (non-admin), UI tetap responsif sambil verifikasi role berjalan di background.
- [x] Hardening backend ditambahkan lewat migration baru: FORCE RLS pada tabel kritikal, RPC guard untuk aksi admin, dan sink monitoring log query failure.
- [x] Alur admin action di Flutter dialihkan dari mutasi tabel langsung ke RPC server-side agar otorisasi final divalidasi di database.
- [x] Monitoring kegagalan query role/account status ditambahkan pada beberapa flow utama (router auth sync, role resolver home, auth account-status, dan admin control queries).

## Roadmap Lanjutan (Prioritas)

### P0 - Stabilitas Produksi (1-2 hari)
- [x] Tambah test untuk skenario role fetch gagal saat login admin/user.
- [x] Tambah test widget untuk role resolver (loading, error, retry, success).
- [x] Verifikasi semua redirect route sensitif role pada deep link.

### P1 - Keamanan dan Data (2-3 hari)
- [x] Audit dan hardening RLS policy untuk `profiles`, `admin_audit_logs`, dan konten edukasi.
- [x] Tambah guard server-side untuk aksi admin (bukan hanya guard di client).
- [x] Tambah monitoring log untuk kegagalan query role/account status.

### P2 - UX dan Operasional (2-4 hari)
- [ ] Tambah indikator sinkronisasi terakhir di dashboard admin.
- [ ] Tambah filter user management (status role/account + pencarian cepat).
- [ ] Tambah bulk action aman (mis. bulk suspend dengan konfirmasi bertingkat).

### P3 - Performa dan Maintainability (berjalan)
- [ ] Refactor query profil/role ke satu service/provider bersama agar tidak duplikasi lintas layar.
- [ ] Tambah caching terukur untuk data dashboard admin.
- [ ] Dokumentasi arsitektur role-based routing di README internal.

## Checklist Verifikasi Setiap Perubahan
- [x] `flutter test` lulus.
- [x] `flutter analyze` tanpa issue.
- [ ] Skenario manual: login user normal.
- [ ] Skenario manual: login admin dan akses menu admin.
- [ ] Skenario manual: non-admin tidak bisa akses route admin.
- [ ] Skenario manual: admin tidak melihat fitur harian user.

## Progress Plan
- [x] Alur auth username + register redirect ke login.
- [x] Pemisahan dashboard dan bottom nav admin/user.
- [x] Perapihan string admin ke AppStrings.
- [x] Perbaikan bug admin dashboard menampilkan konten user.
- [x] Pembersihan lint dan verifikasi test/analyzer.
- [x] Perbaikan role resolver (bootstrap role, cache singkat, retry error state).
- [x] Penambahan test spesifik role resolver.
- [x] Audit RLS dan hardening akses admin sisi backend.

