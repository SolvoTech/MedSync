import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'data/local/preferences/app_preferences.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('id_ID', null);

  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  await AppPreferences.init();
  Intl.defaultLocale = AppPreferences.languageCode == 'id' ? 'id_ID' : 'en_US';

  runApp(const ProviderScope(child: MedisnaApp()));

  // Keep first frame fast: notification bootstrap runs after app is rendered.
  unawaited(_initializeNotificationsSafely());
}

Future<void> _initializeNotificationsSafely() async {
  final notificationService = NotificationService();
  var initialized = false;

  try {
    await notificationService.initialize().timeout(const Duration(seconds: 12));
    initialized = true;
  } catch (error) {
    debugPrint('[main] Notification initialization skipped: $error');
  }

  try {
    await notificationService
        .cancelStaleTaskNotificationsForActiveSession()
        .timeout(const Duration(seconds: 8));
  } catch (error) {
    debugPrint('[main] Notification stale cleanup skipped: $error');
  }

  if (!initialized) {
    return;
  }

  try {
    await notificationService.requestPermission().timeout(
      const Duration(seconds: 8),
    );
  } catch (error) {
    debugPrint('[main] Notification permission request skipped: $error');
  }

  try {
    await notificationService
        .syncTaskNotificationsWithCurrentPreferences()
        .timeout(const Duration(seconds: 20));
  } catch (error) {
    debugPrint('[main] Notification startup resync skipped: $error');
  }
}
