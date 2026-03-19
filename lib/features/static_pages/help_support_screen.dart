import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/static_page_scaffold.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const _supportEmail = 'support@medsync.app';
  final _bugFormKey = GlobalKey<FormState>();
  final _bugController = TextEditingController();

  @override
  void dispose() {
    _bugController.dispose();
    super.dispose();
  }

  String _platformName() {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }

  Future<String> _buildBugReportBody(String userDetail) async {
    String appVersion = 'Unknown';
    String buildNumber = 'Unknown';

    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
      buildNumber = info.buildNumber;
    } catch (_) {
      // Keep fallback values when package info cannot be read.
    }

    final timestamp = DateTime.now().toIso8601String();

    return [
      'Deskripsi masalah:',
      userDetail,
      '',
      '---',
      'Metadata debugging (otomatis):',
      'App version: $appVersion+$buildNumber',
      'Platform: ${_platformName()}',
      'Waktu laporan: $timestamp',
    ].join('\n');
  }

  static const _faqs = [
    (
      q: 'Bagaimana cara menambah jadwal obat?',
      a:
          'Buka tab Jadwal → Tab Obat → Ketuk tombol "Tambah Obat" → Isi form → '
          'Lal tap obat yang ditambahkan → Tap "Tambah Jadwal Minum".',
    ),
    (
      q: 'Notifikasi tidak muncul, bagaimana cara memperbaikinya?',
      a:
          'Pastikan izin notifikasi dan alarm tepat waktu sudah diaktifkan. '
          'Buka Pengaturan → Aplikasi → MedSync → Izin. Nonaktifkan juga '
          'optimasi baterai untuk MedSync.',
    ),
    (
      q: 'Cara mengekspor laporan PDF?',
      a:
          'Buka tab Laporan → Pilih periode yang diinginkan → Ketuk tombol '
          '"Ekspor PDF" di bagian bawah layar.',
    ),
    (
      q: 'Cara menambahkan anggota keluarga?',
      a:
          'Buka Profil → Kelola Anggota → Daftar Anggota → Ketuk "Tambah Anggota" '
          '→ Isi nama, hubungan, dan catatan.',
    ),
    (
      q: 'Lupa kata sandi?',
      a:
          'Di halaman login, ketuk "Lupa kata sandi?" → Masukkan email Anda → '
          'Cek email untuk tautan reset kata sandi.',
    ),
  ];

  Future<void> _openSupportEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': 'Bantuan MedSync'},
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka aplikasi email.')),
      );
    }
  }

  Future<void> _reportBug() async {
    _bugController.clear();
    var hasAttemptedSubmit = false;

    final shouldSend = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Form(
                key: _bugFormKey,
                autovalidateMode: hasAttemptedSubmit
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Laporkan Bug',
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bugController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Detail bug',
                        hintText:
                            'Contoh: Saat menekan tombol Simpan di Jadwal, aplikasi tertutup sendiri.',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        final bugDetail = value?.trim() ?? '';
                        if (bugDetail.isEmpty) {
                          return 'Detail bug wajib diisi';
                        }
                        if (bugDetail.length < 10) {
                          return 'Detail bug terlalu singkat';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        if (!_bugFormKey.currentState!.validate()) {
                          setSheetState(() => hasAttemptedSubmit = true);
                          return;
                        }
                        Navigator.pop(sheetContext, true);
                      },
                      child: const Text('Kirim Laporan'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (shouldSend != true) {
      return;
    }

    final bugDetail = _bugController.text.trim();

    final bugBody = await _buildBugReportBody(bugDetail);
    if (!mounted) return;

    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': 'Laporan Bug MedSync', 'body': bugBody},
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka aplikasi email.')),
      );
    }
  }

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
          Text(
            'TOPIK POPULER',
            style: textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
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
          Text(
            'PERTANYAAN UMUM',
            style: textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
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
          Text(
            'MASIH BUTUH BANTUAN?',
            style: textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.email_outlined,
            label: 'Kirim Email',
            subtitle: _supportEmail,
            onTap: _openSupportEmail,
          ),
          const SizedBox(height: 8),
          _ContactTile(
            icon: Icons.bug_report_outlined,
            label: 'Laporkan Bug',
            subtitle: 'Bantu kami memperbaiki masalah',
            onTap: _reportBug,
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
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
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
