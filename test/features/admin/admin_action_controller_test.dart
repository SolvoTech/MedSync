import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_syn/features/admin/admin_control_screen.dart';

void main() {
  ProviderContainer createContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen<AsyncValue<void>>(
      adminActionControllerProvider,
      (previous, next) {},
    );
    return container;
  }

  const targetUser = AdminManagedUser(
    id: 'user-1',
    fullName: 'Target User',
    username: 'target_user',
    role: 'user',
    accountStatus: 'active',
    createdAt: null,
    internalEmail: 'target_user@users.medsync.local',
  );

  group('AdminActionController', () {
    test('setUserStatus stores error when Supabase is unavailable', () async {
      final container = createContainer();
      final controller = container.read(adminActionControllerProvider.notifier);

      await controller.setUserStatus(target: targetUser, suspend: true);

      final state = container.read(adminActionControllerProvider);
      expect(state.hasError, isTrue);
      expect(
        state.error.toString(),
        contains('Supabase belum diinisialisasi.'),
      );
    });

    test('resetUserAccess stores error when Supabase is unavailable', () async {
      final container = createContainer();
      final controller = container.read(adminActionControllerProvider.notifier);

      await controller.resetUserAccess(target: targetUser);

      final state = container.read(adminActionControllerProvider);
      expect(state.hasError, isTrue);
      expect(
        state.error.toString(),
        contains('Supabase belum diinisialisasi.'),
      );
    });
  });
}
