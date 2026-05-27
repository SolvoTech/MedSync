import 'package:flutter/material.dart';

import 'widgets/static_page_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      height: 1.6,
    );

    return StaticPageScaffold(
      title: 'Kebijakan Privasi',
      lastUpdated: '17 Maret 2025',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(context, '1. Data yang Kami Kumpulkan'),
          Text(
            'Kami mengumpulkan data berikut saat Anda menggunakan MEDISNA:\n'
            '• Alamat email untuk autentikasi\n'
            '• Nama dan tanggal lahir (opsional)\n'
            '• Data jadwal obat, pengukuran, dan aktivitas yang Anda input\n'
            '• Data penggunaan aplikasi untuk peningkatan layanan',
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          _heading(context, '2. Cara Kami Menggunakan Data'),
          Text(
            'Data Anda digunakan semata-mata untuk menjalankan fitur aplikasi — '
            'jadwal, pengingat, laporan, dan pelacakan kesehatan. Kami tidak '
            'menjual data Anda kepada pihak ketiga manapun.',
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          _heading(context, '3. Penyimpanan Data'),
          Text(
            'Data disimpan secara aman di server Supabase dengan enkripsi '
            'in-transit (HTTPS) dan at-rest. Data lokal disimpan di perangkat '
            'Anda menggunakan SQLite terenkripsi.',
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          _heading(context, '4. Hak Anda'),
          Text(
            'Anda berhak untuk:\n'
            '• Mengakses semua data Anda kapan saja\n'
            '• Mengedit atau memperbarui data Anda\n'
            '• Mengekspor data Anda dalam format JSON\n'
            '• Menghapus akun dan semua data terkait secara permanen',
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          _heading(context, '5. Keamanan Data'),
          Text(
            'Kami menggunakan Row Level Security (RLS) di database, '
            'enkripsi HTTPS untuk semua komunikasi, dan token autentikasi '
            'yang aman untuk melindungi data Anda.',
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          _heading(context, '6. Data Anak-Anak'),
          Text(
            'MEDISNA tidak diperuntukkan bagi anak di bawah 13 tahun. '
            'Aplikasi ini ditujukan untuk orang dewasa yang mengelola '
            'jadwal dan catatan kesehatannya sendiri.',
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          _heading(context, '7. Perubahan Kebijakan'),
          Text(
            'Jika ada perubahan signifikan terhadap kebijakan ini, kami akan '
            'menginformasikan melalui email dan notifikasi dalam aplikasi.',
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          _heading(context, '8. Hubungi Kami'),
          Text(
            'Untuk pertanyaan terkait privasi, hubungi kami melalui '
            'email di privacy@medsync.app',
            style: bodyStyle,
          ),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
