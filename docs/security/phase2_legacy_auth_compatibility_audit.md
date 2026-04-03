# Audit Fase 2: Kompatibilitas Legacy Email Auth

Tanggal audit: 2026-04-03
Ruang lingkup: verifikasi fallback login/reset password berbasis email lama saat transisi ke username.

## Referensi Teknis
- [lib/features/auth/auth_controller.dart](../../lib/features/auth/auth_controller.dart)
- [test/features/auth/auth_controller_test.dart](../../test/features/auth/auth_controller_test.dart)

## Hasil Audit
- PASS: input username dinormalisasi ke lowercase.
- PASS: regex username memblokir format tidak valid.
- PASS: fallback legacy email tetap diizinkan saat input berisi karakter `@`.
- PASS: test otomatis memastikan input email legacy tidak gagal di tahap validasi username.

## Bukti Test
- `signIn accepts legacy email format (no username validation error)`
- `resetPassword accepts legacy email format (no username validation error)`

## Risiko Residual
- Risiko sedang: fallback email memperluas permukaan kredensial selama masa transisi.
- Risiko rendah: kemungkinan kebingungan UX jika user campur input username/email.

## Rencana Sunset Fallback
1. Monitor metrik login selama 2-4 minggu setelah rilis.
2. Identifikasi akun yang masih login via email legacy.
3. Lakukan komunikasi migrasi username ke pengguna terdampak.
4. Nonaktifkan fallback email setelah angka penggunaan legacy mendekati nol.

## Kesimpulan
Audit kompatibilitas legacy auth dinyatakan selesai dengan fallback dipertahankan sementara dan rencana sunset terdefinisi.
