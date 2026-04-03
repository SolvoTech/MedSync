import '../../../domain/models/user_profile.dart';
import '../supabase_client.dart';

class ProfileRemoteDataSource {
  Future<UserProfile?> getCurrentProfile() async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum diinisialisasi. Periksa konfigurasi .env.',
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final row = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return UserProfile.fromMap(row);
  }

  Future<void> upsertCurrentProfile({
    required String fullName,
    DateTime? birthDate,
  }) async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum diinisialisasi. Periksa konfigurasi .env.',
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    final metadataUsername = (user.userMetadata?['username'] as String?)
        ?.trim()
        .toLowerCase();
    final fallbackUsername = _usernameFromInternalEmail(user.email);
    final payload = <String, dynamic>{
      'id': user.id,
      'full_name': fullName,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final resolvedUsername = metadataUsername ?? fallbackUsername;
    if (resolvedUsername != null && resolvedUsername.isNotEmpty) {
      payload['username'] = resolvedUsername;
      payload['internal_email'] = user.email;
    }

    await client.from('profiles').upsert(payload);
  }

  /// Generic partial update for profile fields (theme_mode, etc.)
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception(
        'Supabase belum diinisialisasi. Periksa konfigurasi .env.',
      );
    }

    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    data['updated_at'] = DateTime.now().toIso8601String();
    await client.from('profiles').update(data).eq('id', user.id);
  }

  String? _usernameFromInternalEmail(String? email) {
    if (email == null) {
      return null;
    }

    final normalized = email.trim().toLowerCase();
    const suffix = '@users.medsync.local';
    if (!normalized.endsWith(suffix)) {
      return null;
    }

    return normalized.substring(0, normalized.length - suffix.length);
  }
}
