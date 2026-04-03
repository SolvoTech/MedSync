import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_syn/features/auth/auth_controller.dart';

void main() {
  ProviderContainer createContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen<AsyncValue<void>>(authControllerProvider, (_, __) {});
    return container;
  }

  group('AuthController username flow validation', () {
    test('signIn marks state as error for invalid username', () async {
      final container = createContainer();
      final controller = container.read(authControllerProvider.notifier);

      await controller.signIn(
        username: 'Invalid Username!',
        password: 'Password123',
      );

      final state = container.read(authControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('Username tidak valid.'));
    });

    test('signUp marks state as error for invalid username', () async {
      final container = createContainer();
      final controller = container.read(authControllerProvider.notifier);

      await controller.signUp(
        fullName: 'Demo User',
        username: 'x',
        password: 'Password123',
      );

      final state = container.read(authControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('Username tidak valid.'));
    });

    test('resetPassword marks state as error for invalid username', () async {
      final container = createContainer();
      final controller = container.read(authControllerProvider.notifier);

      await controller.resetPassword(username: 'a b');

      final state = container.read(authControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('Username tidak valid.'));
    });

    test(
      'signIn accepts legacy email format (no username validation error)',
      () async {
        final container = createContainer();
        final controller = container.read(authControllerProvider.notifier);

        await controller.signIn(
          username: 'legacy.user@example.com',
          password: 'Password123',
        );

        final state = container.read(authControllerProvider);
        expect(state.hasError, isTrue);
        expect(
          state.error.toString(),
          isNot(contains('Username tidak valid.')),
        );
      },
    );

    test(
      'resetPassword accepts legacy email format (no username validation error)',
      () async {
        final container = createContainer();
        final controller = container.read(authControllerProvider.notifier);

        await controller.resetPassword(username: 'legacy.user@example.com');

        final state = container.read(authControllerProvider);
        expect(state.hasError, isTrue);
        expect(
          state.error.toString(),
          isNot(contains('Username tidak valid.')),
        );
      },
    );
  });
}
