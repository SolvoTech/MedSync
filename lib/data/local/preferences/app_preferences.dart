import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/alarm_ringtones.dart';

/// SharedPreferences wrapper per spec §2 for local settings.
class AppPreferences {
  AppPreferences._();

  static late SharedPreferences _prefs;
  static const _guestScope = 'guest';

  /// Must call init() in main.dart before using.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _migrateLegacyThemeMode();
  }

  static Future<void> _migrateLegacyThemeMode() async {
    final raw = _prefs.getString(_keyThemeMode);
    if (raw == 'system') {
      await _prefs.setString(_keyThemeMode, 'light');
    }
  }

  static String _activeUserScope() {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null && userId.isNotEmpty) {
        return userId;
      }
    } catch (_) {}
    return _guestScope;
  }

  static String _scopedKey(String baseKey, {String? scope}) {
    return '${baseKey}__${scope ?? _activeUserScope()}';
  }

  static bool _getScopedBool(String baseKey, {required bool defaultValue}) {
    return _prefs.getBool(_scopedKey(baseKey)) ?? defaultValue;
  }

  static Future<void> _setScopedBool(String baseKey, bool value) {
    return _prefs.setBool(_scopedKey(baseKey), value);
  }

  static String? _getScopedString(String baseKey) {
    return _prefs.getString(_scopedKey(baseKey));
  }

  static Future<void> _setScopedString(String baseKey, String value) {
    return _prefs.setString(_scopedKey(baseKey), value);
  }

  // ─── Theme ───────────────────────────────────────
  static const _keyThemeMode = 'theme_mode';
  static String get themeMode => _prefs.getString(_keyThemeMode) ?? 'light';
  static Future<void> setThemeMode(String value) =>
      _prefs.setString(_keyThemeMode, value);

  // ─── Language ───────────────────────────────────
  static const _keyLanguageCode = 'language_code';
  static String get languageCode => _prefs.getString(_keyLanguageCode) ?? 'id';
  static Future<void> setLanguageCode(String value) =>
      _prefs.setString(_keyLanguageCode, value);

  // ─── Onboarding ──────────────────────────────────
  static const _keyOnboardingDone = 'onboarding_done';
  static bool get isOnboardingDone =>
      _prefs.getBool(_keyOnboardingDone) ?? false;
  static Future<void> setOnboardingDone(bool value) =>
      _prefs.setBool(_keyOnboardingDone, value);

  // ─── Notification Settings ───────────────────────
  static const _keyNotifMedicine = 'notif_medicine';
  static const _keyNotifMeasurement = 'notif_measurement';
  static const _keyNotifActivity = 'notif_activity';
  static const _keyNotifStock = 'notif_stock';
  static const _keyNotifStreak = 'notif_streak';
  static const _keyNotifDailySummary = 'notif_daily_summary';
  static const _keyNotifMedicineRingtone = 'notif_medicine_ringtone';
  static const _keyNotifMeasurementRingtone = 'notif_measurement_ringtone';
  static const _keyNotifActivityRingtone = 'notif_activity_ringtone';

  static bool get notifMedicine =>
      _getScopedBool(_keyNotifMedicine, defaultValue: true);
  static Future<void> setNotifMedicine(bool v) =>
      _setScopedBool(_keyNotifMedicine, v);

  static bool get notifMeasurement =>
      _getScopedBool(_keyNotifMeasurement, defaultValue: true);
  static Future<void> setNotifMeasurement(bool v) =>
      _setScopedBool(_keyNotifMeasurement, v);

  static bool get notifActivity =>
      _getScopedBool(_keyNotifActivity, defaultValue: true);
  static Future<void> setNotifActivity(bool v) =>
      _setScopedBool(_keyNotifActivity, v);

  static bool get notifStock =>
      _getScopedBool(_keyNotifStock, defaultValue: true);
  static Future<void> setNotifStock(bool v) =>
      _setScopedBool(_keyNotifStock, v);

  static bool get notifStreak =>
      _getScopedBool(_keyNotifStreak, defaultValue: true);
  static Future<void> setNotifStreak(bool v) =>
      _setScopedBool(_keyNotifStreak, v);

  static bool get notifDailySummary =>
      _getScopedBool(_keyNotifDailySummary, defaultValue: true);
  static Future<void> setNotifDailySummary(bool v) =>
      _setScopedBool(_keyNotifDailySummary, v);

  static String get notifMedicineRingtoneId =>
      AlarmRingtones.normalizeId(_getScopedString(_keyNotifMedicineRingtone));
  static Future<void> setNotifMedicineRingtoneId(String value) =>
      _setScopedString(
        _keyNotifMedicineRingtone,
        AlarmRingtones.normalizeId(value),
      );

  static String get notifMeasurementRingtoneId => AlarmRingtones.normalizeId(
    _getScopedString(_keyNotifMeasurementRingtone),
  );
  static Future<void> setNotifMeasurementRingtoneId(String value) =>
      _setScopedString(
        _keyNotifMeasurementRingtone,
        AlarmRingtones.normalizeId(value),
      );

  static String get notifActivityRingtoneId =>
      AlarmRingtones.normalizeId(_getScopedString(_keyNotifActivityRingtone));
  static Future<void> setNotifActivityRingtoneId(String value) =>
      _setScopedString(
        _keyNotifActivityRingtone,
        AlarmRingtones.normalizeId(value),
      );

  // ─── Last Sync ───────────────────────────────────
  static const _keyLastSync = 'last_sync';
  static DateTime? get lastSync {
    final raw = _getScopedString(_keyLastSync);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  static Future<void> setLastSync(DateTime value) =>
      _setScopedString(_keyLastSync, value.toIso8601String());

  // ─── General helpers ─────────────────────────────
  static bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;

  static Future<void> setBool(String key, bool value) =>
      _prefs.setBool(key, value);

  static Future<void> clear() => _prefs.clear();
}
