import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

Future<bool> openDashboardFromRootNavigator({
  Duration retryDelay = const Duration(milliseconds: 100),
  int maxAttempts = 10,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      context.go(AppRoutes.home);
      return true;
    }

    if (attempt < maxAttempts - 1) {
      await Future<void>.delayed(retryDelay);
    }
  }

  return false;
}
