import 'package:flutter/material.dart';

import 'widgets/static_page_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return StaticPageScaffold(
      title: 'Tentang MedSync',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Icon(
            Icons.medication_rounded,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text('MedSync', style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 4),
          Text(
            'Versi 1.0.0',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Deskripsi Aplikasi',
            content:
                'MedSync adalah aplikasi pendamping kesehatan pribadi yang '
                'membantu Anda mengelola jadwal obat, memantau kesehatan, dan '
                'menjaga gaya hidup aktif. Dengan fitur pengingat cerdas, '
                'pelacakan kepatuhan, dan mode caregiver, MedSync membantu '
                'Anda dan keluarga tetap sehat setiap hari.',
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Informasi Teknis',
            content: '',
            child: Column(
              children: [
                _InfoRow(label: 'Platform', value: 'Android 8.0+'),
                _InfoRow(label: 'Framework', value: 'Flutter'),
                _InfoRow(label: 'Backend', value: 'Supabase'),
                _InfoRow(label: 'Versi', value: '1.0.0'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Sosial & Kontak',
            content: '',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language),
                  title: const Text('Website'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Hubungi Kami'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.content, this.child});
  final String title, content;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  height: 1.5,
                ),
          ),
        ],
        if (child != null) child!,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    )),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
