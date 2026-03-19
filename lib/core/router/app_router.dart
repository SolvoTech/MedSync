import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/forgot_password/forgot_password_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/onboarding_profile/onboarding_profile_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/medicine/schedule/schedule_list_screen.dart';
import '../../features/notifications/notification_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/reports/report_screen.dart';
import '../../features/splash/onboarding/onboarding_screen.dart';
import '../../features/splash/splash_screen.dart';
import 'app_routes.dart';
import 'app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = GoRouterAuthNotifier();
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthenticated = authNotifier.session != null;
      final isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword;
      final isPublicRoute =
          state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.onboarding;

      if (!isAuthenticated && !isAuthRoute && !isPublicRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingProfile,
        builder: (_, _) => const OnboardingProfileScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.schedule,
                builder: (_, _) => const ScheduleListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.report,
                builder: (_, _) => const ReportScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.notifications,
                builder: (_, _) => const NotificationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class GoRouterAuthNotifier extends ChangeNotifier {
  GoRouterAuthNotifier() {
    _tryReadSession();

    try {
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        session = data.session;
        notifyListeners();
      });
    } catch (_) {
      _sub = null;
    }
  }

  StreamSubscription<AuthState>? _sub;
  Session? session;

  void _tryReadSession() {
    try {
      session = Supabase.instance.client.auth.currentSession;
    } catch (_) {
      session = null;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
