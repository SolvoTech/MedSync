import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_strings.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.isAdmin,
  });

  final StatefulNavigationShell navigationShell;
  final bool? isAdmin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Keep navigation visible even while role is loading to avoid empty shell state.
    final navItems = _buildNavItems(isAdmin == true);
    final visibleIndex = navItems.indexWhere(
      (item) => item.branchIndex == navigationShell.currentIndex,
    );
    final selectedIndex = visibleIndex >= 0 ? visibleIndex : 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(navItems[index].branchIndex);
          },
          destinations: [for (final item in navItems) item.destination],
        ),
      ),
    );
  }

  List<_ShellNavItem> _buildNavItems(bool adminMode) {
    if (adminMode) {
      return [
        _ShellNavItem(
          branchIndex: 0,
          destination: NavigationDestination(
            icon: const Icon(Icons.space_dashboard_outlined),
            selectedIcon: const Icon(Icons.space_dashboard_rounded),
            label: AppStrings.adminHomeTitle,
          ),
        ),
        _ShellNavItem(
          branchIndex: 5,
          destination: NavigationDestination(
            icon: const Icon(Icons.manage_accounts_outlined),
            selectedIcon: const Icon(Icons.manage_accounts_rounded),
            label: AppStrings.adminUsersTitle,
          ),
        ),
        _ShellNavItem(
          branchIndex: 6,
          destination: NavigationDestination(
            icon: const Icon(Icons.edit_note_outlined),
            selectedIcon: const Icon(Icons.edit_note_rounded),
            label: AppStrings.adminContentTitle,
          ),
        ),
        _ShellNavItem(
          branchIndex: 4,
          destination: NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person_rounded),
            label: AppStrings.profileTitle,
          ),
        ),
      ];
    }

    return [
      _ShellNavItem(
        branchIndex: 0,
        destination: NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: AppStrings.homeTitle,
        ),
      ),
      _ShellNavItem(
        branchIndex: 1,
        destination: NavigationDestination(
          icon: const Icon(Icons.medication_outlined),
          selectedIcon: const Icon(Icons.medication_rounded),
          label: AppStrings.scheduleTitle,
        ),
      ),
      _ShellNavItem(
        branchIndex: 2,
        destination: NavigationDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          selectedIcon: const Icon(Icons.bar_chart_rounded),
          label: AppStrings.reportTitle,
        ),
      ),
      _ShellNavItem(
        branchIndex: 3,
        destination: NavigationDestination(
          icon: const Icon(Icons.menu_book_outlined),
          selectedIcon: const Icon(Icons.menu_book_rounded),
          label: AppStrings.articleTitle,
        ),
      ),
      _ShellNavItem(
        branchIndex: 4,
        destination: NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person_rounded),
          label: AppStrings.profileTitle,
        ),
      ),
    ];
  }
}

class _ShellNavItem {
  const _ShellNavItem({required this.branchIndex, required this.destination});

  final int branchIndex;
  final NavigationDestination destination;
}
