# Audit Fase 1: RLS dan Privilege Escalation

Tanggal audit: 2026-04-03
Ruang lingkup: validasi kebijakan akses tabel setelah migration auth/admin/education.

## Referensi Teknis
- [supabase/migrations/202603170001_init_medsync.sql](../../supabase/migrations/202603170001_init_medsync.sql)
- [supabase/migrations/202603170002_rls_policy_performance_optimizations.sql](../../supabase/migrations/202603170002_rls_policy_performance_optimizations.sql)
- [supabase/migrations/202605220002_live_cleanup_storage_rpc_hardening.sql](../../supabase/migrations/202605220002_live_cleanup_storage_rpc_hardening.sql)

## Checklist Hasil
- PASS: tabel profiles memiliki trigger guard untuk mencegah user non-admin mengubah role, account_status, dan internal_email.
- PASS: helper admin untuk RLS dipindahkan ke schema `private` agar tidak terekspos sebagai RPC publik.
- PASS: policy profiles memisahkan operasi select/insert/update/delete dengan syarat owner atau admin.
- PASS: policy admin-only read diterapkan pada medicines, medicine_schedules, schedule_time_slots, task_logs, measurement_reminders, measurement_logs, physical_activity_reminders, physical_activity_logs, notification_logs, dan user_streaks.
- PASS: tabel admin_audit_logs hanya bisa diinsert oleh admin dengan actor_id sama dengan auth.uid().
- PASS: tabel education_articles hanya bisa dimanage admin, user biasa hanya dapat membaca status published.

## Risiko Residual
- Risiko rendah: helper admin untuk policy tetap bertipe security definer di schema non-exposed. Tetap perlu audit berkala hak schema/database di environment produksi.
- Risiko rendah: perubahan policy di migration masa depan dapat membuka celah jika tidak melalui review lintas tim.

## Rekomendasi Operasional
1. Wajib code review untuk setiap perubahan migration yang menyentuh policy RLS.
2. Tambahkan smoke test SQL policy di pipeline CI environment staging sebelum deploy produksi.
3. Lakukan review privilege database triwulanan (roles, grants, dan function security definer).

## Kesimpulan
Audit fase 1 untuk potensi privilege escalation dinyatakan selesai pada level kode/migration.
