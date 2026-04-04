import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/observability/app_monitoring.dart';
import '../../core/errors/user_error_message.dart';
import '../../core/widgets/app_error_widget.dart';
import '../../data/remote/supabase_client.dart';
import '../admin/admin_home_screen.dart';
import 'home_screen.dart';

final homeRoleProvider = FutureProvider.autoDispose<bool>((ref) async {
  final link = ref.keepAlive();
  Timer? disposeTimer;

  ref
    ..onCancel(() {
      disposeTimer = Timer(const Duration(minutes: 2), link.close);
    })
    ..onResume(() {
      disposeTimer?.cancel();
    })
    ..onDispose(() {
      disposeTimer?.cancel();
    });

  final client = SupabaseClientRef.maybeClient;
  if (client == null) {
    throw Exception(
      AppStrings.tr(
        'Supabase is not initialized.',
        'Supabase belum diinisialisasi.',
      ),
    );
  }

  final user = client.auth.currentUser;
  if (user == null) {
    return false;
  }

  try {
    final row = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return (row?['role'] as String?) == 'admin';
  } catch (error, stackTrace) {
    unawaited(
      AppMonitoring.logQueryFailure(
        source: 'role_home_screen',
        event: 'home_role_lookup_failed',
        error: error,
        stackTrace: stackTrace,
        metadata: {'user_id': user.id},
      ),
    );
    Error.throwWithStackTrace(error, stackTrace);
  }
});

class RoleHomeScreen extends ConsumerWidget {
  const RoleHomeScreen({
    super.key,
    this.initialIsAdmin,
    this.adminView,
    this.userView,
  });

  final bool? initialIsAdmin;
  final Widget? adminView;
  final Widget? userView;

  Widget _adminHome() => adminView ?? const AdminHomeScreen();
  Widget _userHome() => userView ?? const HomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialIsAdmin == true) {
      return _adminHome();
    }

    final roleState = ref.watch(homeRoleProvider);

    return roleState.when(
      loading: () {
        if (initialIsAdmin == false) {
          return _userHome();
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error: (error, _) {
        if (initialIsAdmin == false) {
          return _userHome();
        }

        return Scaffold(
          body: AppErrorWidget(
            message: toUserErrorMessage(
              error,
              fallback: AppStrings.errorGeneral,
            ),
            onRetry: () => ref.invalidate(homeRoleProvider),
          ),
        );
      },
      data: (isAdmin) => isAdmin ? _adminHome() : _userHome(),
    );
  }
}
