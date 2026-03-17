import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract auth repository interface per spec §26.5.
abstract class AuthRepository {
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  });

  Future<void> signOut();

  Future<void> resetPassword(String email);

  Future<void> updatePassword(String newPassword);

  User? get currentUser;

  Stream<AuthState> get authStateChanges;
}
