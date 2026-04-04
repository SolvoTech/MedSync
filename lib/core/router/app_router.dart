import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/admin/admin_control_screen.dart';
import '../../features/admin/admin_education_screen.dart';
import '../../features/auth/forgot_password/forgot_password_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/onboarding_profile/onboarding_profile_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/education/education_detail_screen.dart';
import '../../features/education/education_feed_screen.dart';
import '../../features/home/role_home_screen.dart';
import '../../features/medicine/schedule/schedule_list_screen.dart';
import '../../features/notifications/notification_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/reports/report_screen.dart';
import '../../features/splash/onboarding/onboarding_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../observability/app_monitoring.dart';
import 'app_routes.dart';
import 'app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = GoRouterAuthNotifier();
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      return resolveAppRedirect(
        matchedLocation: state.matchedLocation,
        isAuthenticated: authNotifier.session != null,
        isAdmin: authNotifier.isAdmin,
      );
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
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.education}/:articleId',
        builder: (_, state) {
          final articleId = state.pathParameters['articleId'] ?? '';
          return EducationDetailScreen(articleId: articleId);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(
          navigationShell: shell,
          roleListenable: authNotifier,
          readIsAdmin: () => authNotifier.isAdmin,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) =>
                    RoleHomeScreen(initialIsAdmin: authNotifier.isAdmin),
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
                path: AppRoutes.education,
                builder: (_, _) => const EducationFeedScreen(),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminControl,
                builder: (_, _) => const AdminControlScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminEducation,
                builder: (_, _) => const AdminEducationScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

@visibleForTesting
String? resolveAppRedirect({
  required String matchedLocation,
  required bool isAuthenticated,
  required bool? isAdmin,
}) {
  final isAuthRoute =
      matchedLocation == AppRoutes.login ||
      matchedLocation == AppRoutes.register ||
      matchedLocation == AppRoutes.forgotPassword;
  final isAdminRoute =
      matchedLocation == AppRoutes.adminControl ||
      matchedLocation == AppRoutes.adminEducation;
  final isUserFeatureRoute =
      matchedLocation == AppRoutes.schedule ||
      matchedLocation == AppRoutes.report ||
      matchedLocation == AppRoutes.education ||
      matchedLocation.startsWith('${AppRoutes.education}/');
  final isPublicRoute =
      matchedLocation == AppRoutes.splash ||
      matchedLocation == AppRoutes.onboarding;

  if (!isAuthenticated && !isAuthRoute && !isPublicRoute) {
    return AppRoutes.login;
  }

  if (isAuthenticated && isAuthRoute) {
    return AppRoutes.home;
  }

  if (isAuthenticated && isAdminRoute) {
    if (isAdmin == null) {
      // Wait until role is loaded before deciding redirect.
      return null;
    }

    if (isAdmin != true) {
      return AppRoutes.home;
    }
  }

  if (isAuthenticated && isUserFeatureRoute) {
    if (isAdmin == null) {
      // Wait until role is loaded before deciding redirect.
      return null;
    }

    if (isAdmin == true) {
      return AppRoutes.home;
    }
  }

  return null;
}

class GoRouterAuthNotifier extends ChangeNotifier {
  GoRouterAuthNotifier() {
    _tryReadSession();
    _syncAdminRole();

    try {
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        session = data.session;
        isAdmin = null;
        notifyListeners();
        _syncAdminRole();
      });
    } catch (_) {
      _sub = null;
    }
  }

  StreamSubscription<AuthState>? _sub;
  Session? session;
  bool? isAdmin;

  void _tryReadSession() {
    try {
      session = Supabase.instance.client.auth.currentSession;
    } catch (_) {
      session = null;
    }
  }

  Future<void> _syncAdminRole() async {
    final activeSession = session;
    if (activeSession == null) {
      isAdmin = null;
      notifyListeners();
      return;
    }

    final expectedUserId = activeSession.user.id;

    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', expectedUserId)
          .maybeSingle();
      final role = (row?['role'] as String?) ?? 'user';

      final currentUserId = session?.user.id;
      if (currentUserId != expectedUserId) {
        return;
      }

      isAdmin = role == 'admin';
      notifyListeners();
    } catch (error, stackTrace) {
      final currentUserId = session?.user.id;
      if (currentUserId != expectedUserId) {
        return;
      }

      unawaited(
        AppMonitoring.logQueryFailure(
          source: 'router_auth_notifier',
          event: 'sync_admin_role_failed',
          error: error,
          stackTrace: stackTrace,
          metadata: {'user_id': expectedUserId},
        ),
      );

      isAdmin = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
