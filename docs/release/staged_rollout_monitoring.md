# Runbook Rilis Bertahap dan Monitoring

Tanggal: 2026-04-03

## Gate Sebelum Rilis
1. Jalankan `make release-gate` untuk validasi analyze + test kritikal.
2. Jalankan `flutter test` untuk regresi menyeluruh.
3. Pastikan migration sudah ter-apply di environment target.

## Tahap Rollout
1. Canary internal (5% pengguna) selama 24 jam.
2. Beta terbatas (20% pengguna) selama 48 jam.
3. Rollout penuh (100%) jika metrik stabil.

## Metrik Monitoring Utama
- Error autentikasi username (`invalid_login_credentials`, `validation_failed`).
- Error aksi admin (suspend/reset/publish/unpublish/delete artikel).
- Latensi dan error load artikel edukasi (feed + detail).
- Jumlah notifikasi artikel publish yang berhasil tercatat.

## Ambang Batas Rollback
- Kegagalan login meningkat > 30% dari baseline 7 hari.
- Error rate endpoint admin atau edukasi > 5% dalam 15 menit.
- Crash rate aplikasi > 2% sesi aktif.

## Prosedur Rollback
1. Hentikan rollout pada channel aktif.
2. Kembalikan build aplikasi ke versi stabil sebelumnya.
3. Jika perlu, nonaktifkan fitur baru via konfigurasi backend.
4. Dokumentasikan akar masalah dan rencana perbaikan.

## Checklist Pasca Rilis
- Verifikasi dashboard metrik setelah 1 jam, 6 jam, dan 24 jam.
- Konfirmasi tidak ada lonjakan tiket user terkait login/admin/edukasi.
- Jadwalkan penutupan fallback email legacy saat metrik auth sudah stabil.
