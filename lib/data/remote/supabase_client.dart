import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientRef {
  const SupabaseClientRef._();

  static SupabaseClient? get maybeClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
