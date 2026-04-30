# Alarm Ringtone Sources (CC0)

Tanggal pembaruan: 2026-04-30

Dokumen ini mencatat sumber nada dering alarm yang digunakan aplikasi.
Semua item di bawah menggunakan lisensi Creative Commons 0 (CC0) dari Freesound.

## Daftar Nada

1. Default reminder tone
- Nama internal: fs_cc0_chime_notification_pcm
- Sumber: Notification.wav
- URL: https://freesound.org/people/finn.appleton/sounds/560880/
- Lisensi: Creative Commons 0
- Durasi: 15.253 detik

2. Alternatif reminder tone
- Nama internal: fs_cc0_phone_chime_pcm
- Sumber: Phone chime.wav
- URL: https://freesound.org/people/ChristopherJngs/sounds/666296/
- Lisensi: Creative Commons 0

3. Alternatif reminder tone
- Nama internal: fs_cc0_soft_bell_pcm
- Sumber: Soft-Notifications - Bell - Ding-Dong.mp3
- URL: https://freesound.org/people/LegitCheese/sounds/571513/
- Lisensi: Creative Commons 0

## Catatan Teknis

- File audio disimpan di android/app/src/main/res/raw.
- Ringtone default Android dibundel ulang sebagai WAV PCM mono 44.1 kHz dengan durasi 15.253 detik.
- Dua ringtone alternatif CC0 Android dibundel ulang sebagai WAV PCM mono 44.1 kHz dengan durasi minimum 1.25 detik untuk meningkatkan kompatibilitas channel notifikasi Android.
- Saat ini aplikasi menggunakan versi preview publik Freesound agar unduhan otomatis dapat dilakukan tanpa sesi login.
- Jika diperlukan kualitas audio lebih tinggi, unduh file original dari halaman sumber di atas (memerlukan login Freesound), lalu ganti file resource dengan nama internal yang sama.
