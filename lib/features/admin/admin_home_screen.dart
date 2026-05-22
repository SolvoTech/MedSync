import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/errors/user_error_message.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_error_widget.dart';
import '../../core/widgets/app_loading_skeleton.dart';
import 'admin_control_screen.dart';
import 'widgets/admin_ui.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 390 || media.textScaler.scale(1) > 1.1;
    final pagePadding = EdgeInsets.fromLTRB(
      isCompact ? 12 : 16,
      isCompact ? 10 : 12,
      isCompact ? 12 : 16,
      isCompact ? 20 : 24,
    );

    final dashboardState = ref.watch(adminDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.adminHomeTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.adminRefreshTooltip,
            onPressed: () => ref.invalidate(adminDashboardProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardProvider);
          await ref.read(adminDashboardProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding,
          children: [
            AdminIntroCard(
              icon: Icons.admin_panel_settings_outlined,
              title: AppStrings.adminControlHubTitle,
              subtitle: AppStrings.adminControlHubSubtitle,
              badge: AppStrings.adminBadge,
            ),
            const SizedBox(height: 14),
            AdminSectionTitle(
              title: AppStrings.adminQuickAccessTitle,
              subtitle: AppStrings.adminQuickAccessSubtitle,
              icon: Icons.flash_on_outlined,
            ),
            const SizedBox(height: 8),
            _QuickActionCard(
              icon: Icons.manage_accounts_outlined,
              title: AppStrings.adminUserManagementTitle,
              subtitle: AppStrings.adminUserManagementHint,
              onTap: () => context.go(AppRoutes.adminControl),
            ),
            const SizedBox(height: 10),
            _QuickActionCard(
              icon: Icons.edit_note_outlined,
              title: AppStrings.adminContentManagementTitle,
              subtitle: AppStrings.adminContentManagementHint,
              onTap: () => context.go(AppRoutes.adminEducation),
            ),
            const SizedBox(height: 20),
            AdminSectionTitle(
              title: AppStrings.adminSystemSnapshotTitle,
              subtitle: AppStrings.adminSystemOverviewSubtitle,
              icon: Icons.query_stats_outlined,
            ),
            const SizedBox(height: 8),
            dashboardState.when(
              loading: () => const _OverviewLoading(),
              error: (error, _) => AppErrorWidget(
                message: toUserErrorMessage(error),
                onRetry: () => ref.invalidate(adminDashboardProvider),
              ),
              data: (dashboard) {
                final singleColumnMetrics =
                    media.size.width < 430 || media.textScaler.scale(1) > 1.05;
                final firstRow = [
                  AdminMetricTile(
                    title: AppStrings.adminMetricTotalUsers,
                    value: '${dashboard.totalUsers}',
                    icon: Icons.groups_2_outlined,
                    color: const Color(0xFF2B6CB0),
                  ),
                  AdminMetricTile(
                    title: AppStrings.adminMetricActiveUsers,
                    value: '${dashboard.activeUsers}',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF2F855A),
                  ),
                ];
                final secondRow = [
                  AdminMetricTile(
                    title: AppStrings.adminMetricSuspendedUsers,
                    value: '${dashboard.suspendedUsers}',
                    icon: Icons.block_outlined,
                    color: const Color(0xFFC53030),
                  ),
                  AdminMetricTile(
                    title: AppStrings.adminMetricAdherenceToday,
                    value: '${dashboard.adherencePercent}%',
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFF805AD5),
                    subtitle: AppStrings.adminTodayAdherenceSummary(
                      completed: dashboard.todayCompleted,
                      total: dashboard.todayTasks,
                      percent: dashboard.adherencePercent,
                    ),
                  ),
                ];

                if (singleColumnMetrics) {
                  return Column(
                    children: [
                      for (final metric in [...firstRow, ...secondRow]) ...[
                        metric,
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: firstRow[0]),
                        const SizedBox(width: 10),
                        Expanded(child: firstRow[1]),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: secondRow[0]),
                        const SizedBox(width: 10),
                        Expanded(child: secondRow[1]),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 390 || media.textScaler.scale(1) > 1.1;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: isCompact ? 36 : 40,
            height: isCompact ? 36 : 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: isCompact ? 18 : 20,
            ),
          ),
          SizedBox(width: isCompact ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: isCompact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}

class _OverviewLoading extends StatelessWidget {
  const _OverviewLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppLoadingSkeleton(
          width: double.infinity,
          height: 110,
          borderRadius: 22,
        ),
        SizedBox(height: 10),
        AppLoadingSkeleton(
          width: double.infinity,
          height: 110,
          borderRadius: 22,
        ),
      ],
    );
  }
}
