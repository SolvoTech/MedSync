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

    await client.from('profiles').upsert({
      'id': user.id,
      'full_name': fullName,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'updated_at': DateTime.now().toIso8601String(),
    });
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
}
