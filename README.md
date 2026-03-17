# MedSync

MedSync adalah aplikasi Flutter untuk manajemen pengobatan, pengukuran kesehatan, dan aktivitas fisik dengan dukungan Supabase.

## Menjalankan Proyek

1. Pastikan Flutter SDK terpasang.
2. Siapkan file `assets/.env` berisi:

```env
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

3. Install dependency:

```bash
flutter pub get
```

4. Jalankan aplikasi:

```bash
flutter run
```

## Struktur Ringkas

- `lib/features/` untuk layer UI + state per fitur.
- `lib/data/remote/` untuk datasource Supabase.
- `lib/domain/models/` untuk model data.
- `lib/services/` untuk notifikasi, alarm, dan permission.
- `lib/core/` untuk router, theme, konstanta, dan utilitas global.

## Standar Ukuran File

Codebase menerapkan batas ukuran file Dart maksimum **500 LOC per file** di dalam `lib/`.

- Script validasi lokal: `tooling/check_dart_file_size.sh`
- Workflow PR dan build Android akan gagal jika ada file melewati batas.

Cek manual:

```bash
bash tooling/check_dart_file_size.sh 500 lib
```

Opsional exclude regex (misalnya untuk generated folder):

```bash
bash tooling/check_dart_file_size.sh 500 lib 'generated|\.g\.dart$'
```

## Workflow Lokal

Gunakan perintah ringkas via Makefile:

```bash
make size
make analyze
make test
make check
```

## Pre-Commit Hook (Opsional)

Template hook tersedia di `tooling/pre-commit.sample`.

Aktifkan:

```bash
cp tooling/pre-commit.sample .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```
