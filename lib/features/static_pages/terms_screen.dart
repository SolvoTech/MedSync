import 'package:flutter/material.dart';

import 'widgets/static_page_scaffold.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      height: 1.6,
    );

    return StaticPageScaffold(
      title: 'Syarat & Ketentuan',
      lastUpdated: '17 Maret 2025',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(context, '1. Penerimaan Syarat'),
          Text(
            'Dengan menggunakan aplikasi MEDISNA, Anda menyetujui untuk '
            'terikat oleh syarat dan ketentuan ini. Jika Anda tidak setuju, '
            'harap tidak menggunakan aplikasi ini.',
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          _heading(context, '2. Penggunaan yang Diizinkan'),
          Text(
            'MEDISNA dirancang untuk penggunaan pribadi dalam mengelola '
            'jadwal obat, pengukuran kesehatan, dan aktivitas fisik. '
            'Anda bertanggung jawab atas keakuratan data yang dimasukkan.',
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          _heading(context, '3. Larangan Penggunaan'),
          Text(
            'Anda tidak diperkenankan untuk:\n'
            '• Menggunakan aplikasi untuk tujuan ilegal\n'
            '• Mencoba mengakses data pengguna lain\n'
            '• Memodifikasi, mendekompilasi, atau merekayasa balik aplikasi\n'
            '• Mendistribusikan ulang aplikasi tanpa izin',
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          _heading(context, '⚠️ 4. Disclaimer Medis'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'MEDISNA adalah alat bantu pengingat dan pencatatan kesehatan. '
              'Aplikasi ini BUKAN pengganti saran, diagnosis, atau perawatan '
              'medis profesional. Selalu konsultasikan dengan tenaga medis '
              'profesional untuk keputusan kesehatan Anda.',
              style: bodyStyle?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _heading(context, '5. Pembatasan Tanggung Jawab'),
          Text(
            'MEDISNA tidak bertanggung jawab atas kerugian yang timbul '
            'dari ketidakakuratan data, kegagalan pengingat, atau '
            'keputusan kesehatan yang diambil berdasarkan informasi '
            'dalam aplikasi.',
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          _heading(context, '6. Penghentian Layanan'),
          Text(
            'Kami berhak untuk menghentikan atau membatasi akses Anda '
            'ke layanan jika terjadi pelanggaran terhadap syarat ini.',
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          _heading(context, '7. Hukum yang Berlaku'),
          Text(
            'Syarat dan ketentuan ini tunduk pada dan ditafsirkan '
            'sesuai dengan hukum Republik Indonesia.',
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
