import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.roleListenable,
    required this.readIsAdmin,
  });

  final StatefulNavigationShell navigationShell;
  final Listenable roleListenable;
  final bool? Function() readIsAdmin;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: roleListenable,
      builder: (context, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        // Keep navigation visible even while role is loading to avoid empty shell state.
        final navItems = _buildNavItems(readIsAdmin() == true);
        final visibleIndex = navItems.indexWhere(
          (item) => item.branchIndex == navigationShell.currentIndex,
        );
        final selectedIndex = visibleIndex >= 0 ? visibleIndex : 0;

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? colorScheme.outlineVariant.withValues(alpha: 0.34)
                        : Colors.white.withValues(alpha: 0.86),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.softShadow.withValues(alpha: 0.12),
                            blurRadius: 26,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          for (var i = 0; i < navItems.length; i++)
                            Expanded(
                              child: _ShellNavButton(
                                item: navItems[i],
                                selected: i == selectedIndex,
                                onTap: () => navigationShell.goBranch(
                                  navItems[i].branchIndex,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<_ShellNavItem> _buildNavItems(bool adminMode) {
    if (adminMode) {
      return [
        _ShellNavItem(
          branchIndex: 0,
          icon: Icons.space_dashboard_outlined,
          selectedIcon: Icons.space_dashboard_rounded,
          label: AppStrings.adminDashboardNavLabel,
        ),
        _ShellNavItem(
          branchIndex: 5,
          icon: Icons.manage_accounts_outlined,
          selectedIcon: Icons.manage_accounts_rounded,
          label: AppStrings.adminUsersTitle,
        ),
        _ShellNavItem(
          branchIndex: 6,
          icon: Icons.edit_note_outlined,
          selectedIcon: Icons.edit_note_rounded,
          label: AppStrings.adminContentTitle,
        ),
        _ShellNavItem(
          branchIndex: 4,
          icon: Icons.person_outline,
          selectedIcon: Icons.person_rounded,
          label: AppStrings.profileTitle,
        ),
      ];
    }

    return [
      _ShellNavItem(
        branchIndex: 0,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: AppStrings.homeTitle,
      ),
      _ShellNavItem(
        branchIndex: 1,
        icon: Icons.medication_outlined,
        selectedIcon: Icons.medication_rounded,
        label: AppStrings.scheduleTitle,
      ),
      _ShellNavItem(
        branchIndex: 2,
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart_rounded,
        label: AppStrings.reportTitle,
      ),
      _ShellNavItem(
        branchIndex: 3,
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book_rounded,
        label: AppStrings.articleTitle,
      ),
      _ShellNavItem(
        branchIndex: 4,
        icon: Icons.person_outline,
        selectedIcon: Icons.person_rounded,
        label: AppStrings.profileTitle,
      ),
    ];
  }
}

class _ShellNavItem {
  const _ShellNavItem({
    required this.branchIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final int branchIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _ShellNavButton extends StatelessWidget {
  const _ShellNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _ShellNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final idleColor = isDark
        ? AppColors.darkTextTertiary
        : AppColors.textTertiary;
    final indicatorColor = selectedColor.withValues(
      alpha: isDark ? 0.18 : 0.12,
    );

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: selected ? 46 : 44,
                height: 34,
                decoration: BoxDecoration(
                  color: selected ? indicatorColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: selected ? selectedColor : idleColor,
                  size: selected ? 24 : 23,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? selectedColor : idleColor,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  fontSize: 11,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
