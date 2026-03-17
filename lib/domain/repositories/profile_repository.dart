import '../models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> getCurrentProfile();

  Future<void> upsertCurrentProfile({
    required String fullName,
    DateTime? birthDate,
  });
}
