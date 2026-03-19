import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences wrapper per spec §2 for local settings.
class AppPreferences {
  AppPreferences._();

  static late SharedPreferences _prefs;

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

  // ─── Theme ───────────────────────────────────────
  static const _keyThemeMode = 'theme_mode';
  static String get themeMode => _prefs.getString(_keyThemeMode) ?? 'light';
  static Future<void> setThemeMode(String value) =>
      _prefs.setString(_keyThemeMode, value);

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

  static bool get notifMedicine => _prefs.getBool(_keyNotifMedicine) ?? true;
  static Future<void> setNotifMedicine(bool v) =>
      _prefs.setBool(_keyNotifMedicine, v);

  static bool get notifMeasurement =>
      _prefs.getBool(_keyNotifMeasurement) ?? true;
  static Future<void> setNotifMeasurement(bool v) =>
      _prefs.setBool(_keyNotifMeasurement, v);

  static bool get notifActivity => _prefs.getBool(_keyNotifActivity) ?? true;
  static Future<void> setNotifActivity(bool v) =>
      _prefs.setBool(_keyNotifActivity, v);

  static bool get notifStock => _prefs.getBool(_keyNotifStock) ?? true;
  static Future<void> setNotifStock(bool v) =>
      _prefs.setBool(_keyNotifStock, v);

  static bool get notifStreak => _prefs.getBool(_keyNotifStreak) ?? true;
  static Future<void> setNotifStreak(bool v) =>
      _prefs.setBool(_keyNotifStreak, v);

  static bool get notifDailySummary =>
      _prefs.getBool(_keyNotifDailySummary) ?? true;
  static Future<void> setNotifDailySummary(bool v) =>
      _prefs.setBool(_keyNotifDailySummary, v);

  // ─── Last Sync ───────────────────────────────────
  static const _keyLastSync = 'last_sync';
  static DateTime? get lastSync {
    final raw = _prefs.getString(_keyLastSync);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  static Future<void> setLastSync(DateTime value) =>
      _prefs.setString(_keyLastSync, value.toIso8601String());

  // ─── General helpers ─────────────────────────────
  static Future<void> clear() => _prefs.clear();
}
