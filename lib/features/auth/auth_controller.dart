import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/observability/app_monitoring.dart';

final authControllerProvider =
    AutoDisposeNotifierProvider<AuthController, AsyncValue<void>>(
      AuthController.new,
    );

class AuthController extends AutoDisposeNotifier<AsyncValue<void>> {
  static const String _internalEmailDomain = 'users.medsync.local';
  static final RegExp _usernameRegex = RegExp(r'^[a-z0-9_]{3,24}$');

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final email = _resolveLoginEmail(username);
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await _enforceAccountStatus();
    });
  }

  Future<void> signUp({
    required String fullName,
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final normalizedUsername = _normalizeUsername(username);
      if (!_usernameRegex.hasMatch(normalizedUsername)) {
        throw Exception('Username tidak valid.');
      }

      final response = await Supabase.instance.client.auth.signUp(
        data: {'full_name': fullName.trim(), 'username': normalizedUsername},
        email: _internalEmailFromUsername(normalizedUsername),
        password: password,
        emailRedirectTo: 'io.supabase.medsync://login-callback/',
      );

      // Keep registration flow explicit: users must log in manually after sign up.
      if (response.session != null ||
          Supabase.instance.client.auth.currentSession != null) {
        await Supabase.instance.client.auth.signOut();
      }
    });
  }

  Future<void> resetPassword({required String username}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final email = _resolveLoginEmail(username);
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.medsync://login-callback/',
      );
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client.auth.signOut();
    });
  }

  String _normalizeUsername(String username) => username.trim().toLowerCase();

  String _resolveLoginEmail(String usernameOrEmail) {
    final raw = usernameOrEmail.trim().toLowerCase();
    if (raw.contains('@')) {
      // Backward compatibility for legacy accounts that still authenticate by email.
      return raw;
    }
    if (!_usernameRegex.hasMatch(raw)) {
      throw Exception('Username tidak valid.');
    }
    return _internalEmailFromUsername(raw);
  }

  String _internalEmailFromUsername(String username) =>
      '$username@$_internalEmailDomain';

  Future<void> _enforceAccountStatus() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      final profile = await client
          .from('profiles')
          .select('account_status')
          .eq('id', user.id)
          .maybeSingle();
      final status = (profile?['account_status'] as String?) ?? 'active';

      if (status == 'suspended') {
        await client.auth.signOut();
        throw Exception('Akun Anda sedang dinonaktifkan oleh admin.');
      }
    } catch (error, stackTrace) {
      unawaited(
        AppMonitoring.logQueryFailure(
          source: 'auth_controller',
          event: 'enforce_account_status_failed',
          error: error,
          stackTrace: stackTrace,
          metadata: {'user_id': user.id},
        ),
      );
      rethrow;
    }
  }
}
