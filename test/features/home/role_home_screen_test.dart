import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_syn/core/constants/app_strings.dart';
import 'package:med_syn/core/widgets/app_error_widget.dart';
import 'package:med_syn/features/home/role_home_screen.dart';

void main() {
  Future<void> pumpRoleHome(
    WidgetTester tester, {
    required bool? initialIsAdmin,
    required Override roleOverride,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [roleOverride],
        child: MaterialApp(
          home: RoleHomeScreen(
            initialIsAdmin: initialIsAdmin,
            adminView: const Text('ADMIN_VIEW'),
            userView: const Text('USER_VIEW'),
          ),
        ),
      ),
    );
  }

  group('RoleHomeScreen', () {
    testWidgets('admin login stays on admin home when role fetch fails', (
      tester,
    ) async {
      await pumpRoleHome(
        tester,
        initialIsAdmin: true,
        roleOverride: homeRoleProvider.overrideWith((ref) async {
          throw Exception('role fetch failed');
        }),
      );

      expect(find.text('ADMIN_VIEW'), findsOneWidget);
    });

    testWidgets('user login stays on user home while role verification fails', (
      tester,
    ) async {
      await pumpRoleHome(
        tester,
        initialIsAdmin: false,
        roleOverride: homeRoleProvider.overrideWith((ref) async {
          throw Exception('role fetch failed');
        }),
      );

      expect(find.text('USER_VIEW'), findsOneWidget);
    });

    testWidgets('shows loading indicator without bootstrap role', (
      tester,
    ) async {
      final pendingRole = Completer<bool>();

      await pumpRoleHome(
        tester,
        initialIsAdmin: null,
        roleOverride: homeRoleProvider.overrideWith((ref) async {
          return pendingRole.future;
        }),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows user home when role resolves as non-admin', (
      tester,
    ) async {
      await pumpRoleHome(
        tester,
        initialIsAdmin: null,
        roleOverride: homeRoleProvider.overrideWith((ref) async => false),
      );
      await tester.pumpAndSettle();

      expect(find.text('USER_VIEW'), findsOneWidget);
    });

    testWidgets('shows admin home when role resolves as admin', (tester) async {
      await pumpRoleHome(
        tester,
        initialIsAdmin: null,
        roleOverride: homeRoleProvider.overrideWith((ref) async => true),
      );
      await tester.pumpAndSettle();

      expect(find.text('ADMIN_VIEW'), findsOneWidget);
    });

    testWidgets('shows retryable error and can recover on retry', (
      tester,
    ) async {
      var callCount = 0;

      await pumpRoleHome(
        tester,
        initialIsAdmin: null,
        roleOverride: homeRoleProvider.overrideWith((ref) async {
          callCount += 1;
          if (callCount == 1) {
            throw Exception('temporary role fetch error');
          }
          return false;
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorWidget), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);

      await tester.tap(find.text(AppStrings.retry));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(callCount, 2);
      expect(find.text('USER_VIEW'), findsOneWidget);
    });
  });
}
