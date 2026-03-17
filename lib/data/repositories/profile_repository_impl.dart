import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../remote/datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<UserProfile?> getCurrentProfile() {
    return _remote.getCurrentProfile();
  }

  @override
  Future<void> upsertCurrentProfile({
    required String fullName,
    DateTime? birthDate,
  }) {
    return _remote.upsertCurrentProfile(
      fullName: fullName,
      birthDate: birthDate,
    );
  }
}
