# Panduan Setup Repository GitHub (CI/CD)

Repositori ini telah dikonfigurasi dengan **GitHub Actions** untuk menjalankan pengujian otomatis (PR) dan _build_ rilis Android (.apk) serta *Docker image*. 

Agar *pipeline* CI/CD ini dapat berjalan dengan sukses tanpa *error*, Anda perlu mengatur beberapa **Repository Secrets** di pengaturan GitHub Anda.

## Cara Menambahkan Secrets & Variables
1. Buka Repositori GitHub Anda.
2. Pindah ke tab **Settings**.
3. Scroll ke bawah di *sidebar* kiri, pilih **Secrets and variables** -> **Actions**.
4. Klik tombol **New repository secret** untuk menambahkan masing-masing _secret_ di bawah ini.

---

## Daftar Repository Secrets

### 1. Kredensial Supabase (Wajib)
Aplikasi ini membutuhkan koneksi ke backend Supabase untuk dapat dikompilasi (di-*build*) dengan sukses karena *environment variables* ini akan di-_inject_ ke dalam aplikasi.

| Nama Secret | Status | Deskripsi |
|-------------|--------|-------------|
| `SUPABASE_URL` | **Wajib** | URL unik _Project_ Supabase Anda (contoh: `https://xxxxxx.supabase.co`). |
| `SUPABASE_ANON_KEY` | **Wajib** | Kunci _anon/public_ dari _Project_ Supabase Anda. |

### 2. Kredensial Android Keystore (Wajib untuk Rilis .APK)
Agar GitHub Actions dapat men-_generate_ APK Android bertanda tangan (Signed APK) yang siap didistribusikan atau di-*upload* ke Play Store, Anda perlu mengunggah *Keystore* Anda.

| Nama Secret | Status | Deskripsi |
|-------------|--------|-------------|
| `KEY_ALIAS` | **Wajib** | Alias dari kunci yang dibuat di Keystore (umumnya `upload` atau `key`). |
| `KEY_PASSWORD` | **Wajib** | Kata sandi untuk kunci (Key alias) tersebut. |
| `KEYSTORE_PASSWORD` | **Wajib** | Kata sandi utama untuk *file* Keystore (`.jks` / `.keystore`). |
| `KEYSTORE_BASE64` | **Wajib** | Isi *file* Keystore yang telah di-_encode_ dalam format Base64. |

> **Cara membuat `KEYSTORE_BASE64`:**
> Dari terminal Linux/Mac Anda, jalankan perintah ini terhadap file `.jks` Anda:
> ```bash
> base64 -i path/to/your/upload-keystore.jks | tr -d '\n' | pbcopy
> ```
> *(Teks Base64 akan disalin ke clipboard Anda dan siap di-*paste* ke GitHub Secrets)*.

### 3. Otentikasi GitHub (Otomatis)
- `GITHUB_TOKEN`: Digunakan untuk mempublikasikan *Docker image* ke GitHub Container Registry (`ghcr.io`). Token ini **otomatis disediakan oleh GitHub**, jadi Anda **TIDAK PERLU** menambahkannya ke *Secrets* manual.
> *Catatan: Pastikan pada menu **Settings > Actions > General > Workflow permissions**, opsi **Read and write permissions** tercentang.*

---

## Daftar Workflow CI/CD

Repository ini memiliki dua *workflow* (berada di `.github/workflows/`):

1. **`pull-request-check.yml`**
   - **Trigger:** Setiap pembuatan atau pembaruan *Pull Request* ke _branch_ `main`.
   - **Tugas:** Menjalankan `flutter analyze` dan `flutter test` (jika ada) untuk memastikan kode yang akan di-_merge_ tidak rusak.

2. **`build-android.yml`**
   - **Trigger:** Saat membuat GitHub Release baru (Tag `v*`, contoh: `v1.0.0`).
   - **Tugas:** 
     1. Men-_setup_ Flutter dan Java.
     2. Mendekode Keystore dari *Secret Base64*.
     3. Membuat `assets/.env` secara *on-the-fly* dari Supabase *secrets*.
     4. Mem-*build* aplikasi ke dalam format `app-release.apk`.
     5. Mengunggah `.apk` tersebut ke lampiran GitHub Release.
     6. Membungkus `.apk` ke dalam Docker image dan mengunggahnya ke GitHub Container Registry (`ghcr.io`).
