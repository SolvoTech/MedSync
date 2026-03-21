import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/user_error_message.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/l10n/language_provider.dart';
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
  String _languageCode = 'en';
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
    _languageCode = ref.read(appLanguageProvider).languageCode;
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
        context.showErrorSnackBar(
          toUserErrorMessage(e, fallback: AppStrings.settingsSaveFailed),
        );
      }
    }
  }

  Future<void> _saveLanguage(String code) async {
    final previous = _languageCode;
    setState(() => _languageCode = code);

    try {
      await ref.read(appLanguageProvider.notifier).setLanguageCode(code);
      if (mounted) {
        context.showSuccessSnackBar(
          code == 'id'
              ? AppStrings.languageChangedToIndonesian
              : AppStrings.languageChangedToEnglish,
        );
      }
    } catch (e) {
      setState(() => _languageCode = previous);
      if (mounted) {
        context.showErrorSnackBar(
          toUserErrorMessage(e, fallback: AppStrings.errorGeneral),
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
      appBar: AppBar(title: Text(AppStrings.appearance)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme mode section
          Text(
            AppStrings.themeSectionTitle,
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
                    title: Text(AppStrings.followSystem),
                    subtitle: Text(AppStrings.followSystemSubtitle),
                    secondary: const Icon(Icons.settings_brightness),
                    value: 'system',
                  ),
                  const Divider(height: 1, indent: 56),
                  RadioListTile<String>(
                    title: Text(AppStrings.lightMode),
                    secondary: const Icon(Icons.light_mode),
                    value: 'light',
                  ),
                  const Divider(height: 1, indent: 56),
                  RadioListTile<String>(
                    title: Text(AppStrings.darkMode),
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
            AppStrings.languageSectionTitle,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: RadioGroup<String>(
              groupValue: _languageCode,
              onChanged: (value) {
                if (value == null) return;
                _saveLanguage(value);
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    secondary: const Icon(Icons.language),
                    title: Text(AppStrings.tr('English', 'English')),
                    subtitle: Text(AppStrings.defaultLabel),
                    value: 'en',
                  ),
                  const Divider(height: 1, indent: 56),
                  RadioListTile<String>(
                    secondary: const Icon(Icons.translate),
                    title: Text(AppStrings.indonesianLanguage),
                    subtitle: Text(AppStrings.indonesianLabel),
                    value: 'id',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
