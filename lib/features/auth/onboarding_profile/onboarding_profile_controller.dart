import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/datasources/profile_remote_datasource.dart';
import '../../../data/repositories/profile_repository_impl.dart';
import '../../../domain/repositories/profile_repository.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((
  ref,
) {
  return ProfileRemoteDataSource();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remote = ref.watch(profileRemoteDataSourceProvider);
  return ProfileRepositoryImpl(remote);
});

final currentUserHasProfileProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.read(profileRepositoryProvider).getCurrentProfile();
  return profile != null;
});

final onboardingProfileControllerProvider =
    AutoDisposeNotifierProvider<OnboardingProfileController, AsyncValue<void>>(
      OnboardingProfileController.new,
    );

class OnboardingProfileController
    extends AutoDisposeNotifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> saveProfile({
    required String fullName,
    DateTime? birthDate,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref
          .read(profileRepositoryProvider)
          .upsertCurrentProfile(
            fullName: fullName.trim(),
            birthDate: birthDate,
          );
    });
  }
}
