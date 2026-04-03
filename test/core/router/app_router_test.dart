import 'package:flutter_test/flutter_test.dart';
import 'package:med_syn/core/router/app_router.dart';
import 'package:med_syn/core/router/app_routes.dart';

void main() {
  group('resolveAppRedirect', () {
    test('redirects unauthenticated user from protected route', () {
      final result = resolveAppRedirect(
        matchedLocation: AppRoutes.home,
        isAuthenticated: false,
        isAdmin: null,
      );

      expect(result, AppRoutes.login);
    });

    test('allows unauthenticated user on auth route', () {
      final result = resolveAppRedirect(
        matchedLocation: AppRoutes.login,
        isAuthenticated: false,
        isAdmin: null,
      );

      expect(result, isNull);
    });

    test('redirects authenticated user away from auth route', () {
      final result = resolveAppRedirect(
        matchedLocation: AppRoutes.register,
        isAuthenticated: true,
        isAdmin: false,
      );

      expect(result, AppRoutes.home);
    });

    test('redirects admin user away from user feature routes', () {
      final locations = [
        AppRoutes.schedule,
        AppRoutes.report,
        AppRoutes.education,
        '${AppRoutes.education}/:articleId',
      ];

      for (final location in locations) {
        final result = resolveAppRedirect(
          matchedLocation: location,
          isAuthenticated: true,
          isAdmin: true,
        );
        expect(result, AppRoutes.home);
      }
    });

    test('allows non-admin user on user feature route', () {
      final result = resolveAppRedirect(
        matchedLocation: AppRoutes.schedule,
        isAuthenticated: true,
        isAdmin: false,
      );

      expect(result, isNull);
    });

    test('defers decision while admin role is loading', () {
      final result = resolveAppRedirect(
        matchedLocation: AppRoutes.adminControl,
        isAuthenticated: true,
        isAdmin: null,
      );

      expect(result, isNull);
    });

    test('redirects non-admin user from admin route', () {
      final result = resolveAppRedirect(
        matchedLocation: AppRoutes.adminEducation,
        isAuthenticated: true,
        isAdmin: false,
      );

      expect(result, AppRoutes.home);
    });

    test('allows admin user on admin route', () {
      final result = resolveAppRedirect(
        matchedLocation: AppRoutes.adminEducation,
        isAuthenticated: true,
        isAdmin: true,
      );

      expect(result, isNull);
    });
  });
}
