import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authControllerProvider =
    AutoDisposeNotifierProvider<AuthController, AsyncValue<void>>(
      AuthController.new,
    );

class AuthController extends AutoDisposeNotifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client.auth.signUp(
        data: {'full_name': fullName.trim()},
        email: email.trim(),
        password: password,
        emailRedirectTo: 'io.supabase.medsync://login-callback/',
      );
    });
  }

  Future<void> resetPassword({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email.trim(),
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
}
