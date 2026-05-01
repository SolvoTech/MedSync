# Alarm Ringtone Sources

Tanggal pembaruan: 2026-05-01

Dokumen ini mencatat sumber nada dering alarm yang digunakan aplikasi Android.
Nada aktif dibuat dari kombinasi sintetis lokal dan satu sumber public domain
dari internet. Semua nada dibuat panjang dan berkarakter alarm agar pengingat
obat, pengukuran, dan aktivitas lebih mudah terdengar.

## Daftar Nada Aktif

1. Wake Pulse
- ID preferensi: `medsync_alarm_pulse`
- Resource Android: `medsync_alarm_pulse_pcm`
- Durasi: 30 detik
- Pola: pulsa cepat 880 Hz dengan harmonic 1760 Hz.

2. Warning Beep
- ID preferensi: `medsync_alarm_siren`
- Resource Android: `medsync_alarm_siren_pcm`
- Durasi: 30 detik
- Sumber: Wikimedia Commons, `Alarm_or_siren.ogg`
  <https://commons.wikimedia.org/wiki/File:Alarm_or_siren.ogg>
- Lisensi: public domain, sumber asli PDSounds oleh stephan.
- Proses: file OGG 10 detik di-loop dan dikonversi ke WAV PCM mono 44.1 kHz.

3. Rapid Bell
- ID preferensi: `medsync_alarm_bell`
- Resource Android: `medsync_alarm_bell_pcm`
- Durasi: 30 detik
- Pola: bel tiga ketukan berulang 1046 Hz dengan harmonic 2093 Hz.

## Catatan Teknis

- File audio disimpan di `android/app/src/main/res/raw`.
- Format tiap nada aktif: WAV PCM mono 44.1 kHz, 16-bit.
- ID preferensi lama (`cc0_chime_notification`, `cc0_phone_chime`,
  `cc0_soft_bell`, `medsync_classic`) dimapping otomatis ke `Wake Pulse`.
- File raw lama yang duplikat sudah dihapus. Kompatibilitas preferensi lama
  tetap dijaga lewat mapping ID ke `Wake Pulse` dan cleanup channel lama.
- UI pengaturan menampilkan tiga nada aktif di atas dan `System Default`.
