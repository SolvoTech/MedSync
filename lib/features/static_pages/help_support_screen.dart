import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_strings.dart';
import '../../core/extensions/context_ext.dart';
import '../../core/widgets/app_form_container.dart';
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
      AppStrings.tr('Issue description:', 'Deskripsi masalah:'),
      userDetail,
      '',
      '---',
      AppStrings.tr(
        'Debug metadata (automatic):',
        'Metadata debugging (otomatis):',
      ),
      'App version: $appVersion+$buildNumber',
      'Platform: ${_platformName()}',
      '${AppStrings.tr('Report time', 'Waktu laporan')}: $timestamp',
    ].join('\n');
  }

  List<({String q, String a})> get _faqs => [
    (
      q: AppStrings.tr(
        'How do I add a medication schedule?',
        'Bagaimana cara menambah jadwal obat?',
      ),
      a: AppStrings.tr(
        'Open the Schedule tab -> Medication tab -> tap Add Medication -> fill the form -> tap the medication you added -> tap Add Intake Schedule.',
        'Buka tab Jadwal -> Tab Obat -> Ketuk tombol Tambah Obat -> Isi form -> Tap obat yang ditambahkan -> Tap Tambah Jadwal Minum.',
      ),
    ),
    (
      q: AppStrings.tr(
        'Notifications are not showing. How do I fix it?',
        'Notifikasi tidak muncul, bagaimana cara memperbaikinya?',
      ),
      a: AppStrings.tr(
        'Make sure notification and exact alarm permissions are enabled. Open Settings -> Apps -> MedSync -> Permissions. Also disable battery optimization for MedSync.',
        'Pastikan izin notifikasi dan alarm tepat waktu sudah diaktifkan. Buka Pengaturan -> Aplikasi -> MedSync -> Izin. Nonaktifkan juga optimasi baterai untuk MedSync.',
      ),
    ),
    (
      q: AppStrings.tr(
        'How to export a PDF report?',
        'Cara mengekspor laporan PDF?',
      ),
      a: AppStrings.tr(
        'Open the Report tab -> choose your desired period -> tap Export PDF at the bottom of the screen.',
        'Buka tab Laporan -> Pilih periode yang diinginkan -> Ketuk tombol Ekspor PDF di bagian bawah layar.',
      ),
    ),
    (
      q: AppStrings.tr(
        'How to add a family member?',
        'Cara menambahkan anggota keluarga?',
      ),
      a: AppStrings.tr(
        'Open Profile -> Manage Members -> Member List -> tap Add Member -> fill in name, relationship, and notes.',
        'Buka Profil -> Kelola Anggota -> Daftar Anggota -> Ketuk Tambah Anggota -> Isi nama, hubungan, dan catatan.',
      ),
    ),
    (
      q: AppStrings.tr('Forgot password?', 'Lupa kata sandi?'),
      a: AppStrings.tr(
        'On the login screen, tap Forgot password? -> enter your email -> check your email for a reset link.',
        'Di halaman login, ketuk Lupa kata sandi? -> Masukkan email Anda -> Cek email untuk tautan reset kata sandi.',
      ),
    ),
  ];

  Future<void> _openSupportEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': AppStrings.tr('MedSync Support', 'Bantuan MedSync'),
      },
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      context.showErrorSnackBar(
        AppStrings.tr(
          'Failed to open email app. Please try again.',
          'Gagal membuka aplikasi email. Silakan coba lagi.',
        ),
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
            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: AppFormContainer(
                    title: AppStrings.tr('Report Bug', 'Laporkan Bug'),
                    subtitle: AppStrings.tr(
                      'Describe the issue briefly so our team can follow up faster.',
                      'Ceritakan masalah secara ringkas agar tim kami bisa menindaklanjuti lebih cepat.',
                    ),
                    icon: Icons.bug_report_outlined,
                    child: Form(
                      key: _bugFormKey,
                      autovalidateMode: hasAttemptedSubmit
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _bugController,
                            minLines: 4,
                            maxLines: 6,
                            decoration: InputDecoration(
                              labelText: AppStrings.tr(
                                'Bug details',
                                'Detail bug',
                              ),
                              hintText: AppStrings.tr(
                                'Example: When tapping Save in Schedule, the app closes unexpectedly.',
                                'Contoh: Saat menekan tombol Simpan di Jadwal, aplikasi tertutup sendiri.',
                              ),
                              alignLabelWithHint: true,
                            ),
                            validator: (value) {
                              final bugDetail = value?.trim() ?? '';
                              if (bugDetail.isEmpty) {
                                return AppStrings.tr(
                                  'Bug details are required.',
                                  'Detail bug wajib diisi',
                                );
                              }
                              if (bugDetail.length < 10) {
                                return AppStrings.tr(
                                  'Bug details are too short.',
                                  'Detail bug terlalu singkat',
                                );
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
                            child: Text(
                              AppStrings.tr('Send Report', 'Kirim Laporan'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
      queryParameters: {
        'subject': AppStrings.tr('MedSync Bug Report', 'Laporan Bug MedSync'),
        'body': bugBody,
      },
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      context.showErrorSnackBar(
        AppStrings.tr(
          'Failed to open email app. Please try again.',
          'Gagal membuka aplikasi email. Silakan coba lagi.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StaticPageScaffold(
      title: AppStrings.helpSupport,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.helpIntro, style: textTheme.titleMedium),
          const SizedBox(height: 20),

          // Topic chips
          Text(
            AppStrings.popularTopics,
            style: textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TopicChip(
                icon: Icons.medication,
                label: AppStrings.tr('Medication Schedule', 'Jadwal Obat'),
              ),
              _TopicChip(
                icon: Icons.notifications,
                label: AppStrings.notificationTitle,
              ),
              _TopicChip(icon: Icons.bar_chart, label: AppStrings.reportTitle),
              _TopicChip(
                icon: Icons.favorite,
                label: AppStrings.tr('Health Connect', 'Health Connect'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // FAQ
          Text(
            AppStrings.faqTitle,
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
            AppStrings.stillNeedHelp,
            style: textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.email_outlined,
            label: AppStrings.sendEmail,
            subtitle: _supportEmail,
            onTap: _openSupportEmail,
          ),
          const SizedBox(height: 8),
          _ContactTile(
            icon: Icons.bug_report_outlined,
            label: AppStrings.tr('Report Bug', 'Laporkan Bug'),
            subtitle: AppStrings.tr(
              'Help us fix issues',
              'Bantu kami memperbaiki masalah',
            ),
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
