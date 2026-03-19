import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../profile_screen.dart';

class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});

  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen> {
  String _themeMode = 'light'; // 'light', 'dark', 'system'
  bool _loaded = false;

  static String _toRaw(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }

  void _initFromProfile() {
    if (_loaded) return;
    _loaded = true;
    _themeMode = _toRaw(ref.read(themeModeProvider));
  }

  Future<void> _saveTheme(String mode) async {
    final previous = _themeMode;
    setState(() => _themeMode = mode);

    try {
      await ref.read(themeModeProvider.notifier).setThemeMode(mode);
      await ref.read(profileDataSourceProvider).updateProfile({
        'theme_mode': mode,
      });
      ref.invalidate(currentProfileProvider);
    } catch (e) {
      await ref.read(themeModeProvider.notifier).setThemeMode(previous);
      if (mounted) {
        setState(() => _themeMode = previous);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan pengaturan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _initFromProfile();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appearance)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme mode section
          Text(
            'TEMA',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: RadioGroup<String>(
              groupValue: _themeMode,
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                _saveTheme(value);
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Ikuti Sistem'),
                    subtitle: const Text(
                      'Otomatis sesuai pengaturan perangkat',
                    ),
                    secondary: const Icon(Icons.settings_brightness),
                    value: 'system',
                  ),
                  const Divider(height: 1, indent: 56),
                  RadioListTile<String>(
                    title: const Text('Terang'),
                    secondary: const Icon(Icons.light_mode),
                    value: 'light',
                  ),
                  const Divider(height: 1, indent: 56),
                  RadioListTile<String>(
                    title: const Text('Gelap'),
                    secondary: const Icon(Icons.dark_mode),
                    value: 'dark',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Language section
          Text(
            'BAHASA',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Bahasa'),
              subtitle: const Text('Bahasa Indonesia'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Saat ini hanya tersedia Bahasa Indonesia.'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
