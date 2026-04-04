import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/local/preferences/app_preferences.dart';

final appLanguageProvider = NotifierProvider<AppLanguageNotifier, Locale>(
  AppLanguageNotifier.new,
);

class AppLanguageNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    return _localeFromCode(AppPreferences.languageCode);
  }

  Future<void> setLanguageCode(String code) async {
    final locale = _localeFromCode(code);
    state = locale;
    Intl.defaultLocale = _intlLocale(locale.languageCode);
    await AppPreferences.setLanguageCode(locale.languageCode);
  }

  static Locale _localeFromCode(String code) {
    switch (code) {
      case 'id':
        return const Locale('id');
      case 'en':
        return const Locale('en');
      default:
        return const Locale('id');
    }
  }

  static String _intlLocale(String code) {
    return code == 'id' ? 'id_ID' : 'en_US';
  }
}
