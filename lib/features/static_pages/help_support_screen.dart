import 'package:flutter/material.dart';

import 'widgets/static_page_scaffold.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      q: 'Bagaimana cara menambah jadwal obat?',
      a: 'Buka tab Jadwal → Tab Obat → Ketuk tombol "Tambah Obat" → Isi form → '
          'Lal tap obat yang ditambahkan → Tap "Tambah Jadwal Minum".'
    ),
    (
      q: 'Notifikasi tidak muncul, bagaimana cara memperbaikinya?',
      a: 'Pastikan izin notifikasi dan alarm tepat waktu sudah diaktifkan. '
          'Buka Pengaturan → Aplikasi → MedSync → Izin. Nonaktifkan juga '
          'optimasi baterai untuk MedSync.'
    ),
    (
      q: 'Cara mengekspor laporan PDF?',
      a: 'Buka tab Laporan → Pilih periode yang diinginkan → Ketuk tombol '
          '"Ekspor PDF" di bagian bawah layar.'
    ),
    (
      q: 'Cara menambahkan anggota keluarga?',
      a: 'Buka Profil → Kelola Anggota → Daftar Anggota → Ketuk "Tambah Anggota" '
          '→ Isi nama, hubungan, dan catatan.'
    ),
    (
      q: 'Lupa kata sandi?',
      a: 'Di halaman login, ketuk "Lupa kata sandi?" → Masukkan email Anda → '
          'Cek email untuk tautan reset kata sandi.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StaticPageScaffold(
      title: 'Bantuan & Dukungan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hai! Bagaimana kami bisa membantu?',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 20),

          // Topic chips
          Text('TOPIK POPULER',
              style: textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _TopicChip(icon: Icons.medication, label: 'Jadwal Obat'),
              _TopicChip(icon: Icons.notifications, label: 'Notifikasi'),
              _TopicChip(icon: Icons.bar_chart, label: 'Laporan'),
              _TopicChip(icon: Icons.favorite, label: 'Health Connect'),
            ],
          ),
          const SizedBox(height: 24),

          // FAQ
          Text('PERTANYAAN UMUM',
              style: textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              )),
          const SizedBox(height: 8),
          ..._faqs.map(
            (faq) => ExpansionTile(
              title: Text(faq.q, style: textTheme.bodyMedium),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 12),
              children: [
                Text(
                  faq.a,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact section
          Text('MASIH BUTUH BANTUAN?',
              style: textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              )),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.email_outlined,
            label: 'Kirim Email',
            subtitle: 'support@medsync.app',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _ContactTile(
            icon: Icons.bug_report_outlined,
            label: 'Laporkan Bug',
            subtitle: 'Bantu kami memperbaiki masalah',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {},
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
