part of 'admin_control_screen.dart';

class _DashboardSummary extends StatelessWidget {
  const _DashboardSummary({required this.data});

  final AdminDashboardData data;

  String _formatFetchedAt(DateTime value) {
    final locale = _resolvedDateLocale();
    return DateFormat('dd MMM yyyy, HH:mm', locale).format(value.toLocal());
  }

  String _resolvedDateLocale() {
    final preferred = AppStrings.languageCode == 'id' ? 'id_ID' : 'en_US';
    try {
      return DateFormat.localeExists(preferred) ? preferred : 'en_US';
    } catch (_) {
      return 'en_US';
    }
  }

  @override
  Widget build(BuildContext context) {
    final xxs = MediaQuery.sizeOf(context).width < 340;
    final metricCards = [
      _MetricCard(
        title: AppStrings.adminMetricTotalUsers,
        value: data.totalUsers.toString(),
        icon: Icons.groups_2_outlined,
        color: const Color(0xFF2B6CB0),
      ),
      _MetricCard(
        title: AppStrings.adminMetricActiveUsers,
        value: data.activeUsers.toString(),
        icon: Icons.check_circle_outline,
        color: const Color(0xFF2F855A),
      ),
      _MetricCard(
        title: AppStrings.adminMetricSuspendedUsers,
        value: data.suspendedUsers.toString(),
        icon: Icons.block_outlined,
        color: const Color(0xFFC53030),
      ),
      _MetricCard(
        title: AppStrings.adminMetricAdminAccounts,
        value: data.adminUsers.toString(),
        icon: Icons.admin_panel_settings_outlined,
        color: const Color(0xFF805AD5),
      ),
    ];

    return Column(
      children: [
        if (xxs) ...[
          for (final metric in metricCards) ...[
            metric,
            const SizedBox(height: 10),
          ],
        ] else ...[
          Row(
            children: [
              Expanded(child: metricCards[0]),
              const SizedBox(width: 10),
              Expanded(child: metricCards[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: metricCards[2]),
              const SizedBox(width: 10),
              Expanded(child: metricCards[3]),
            ],
          ),
        ],
        const SizedBox(height: 10),
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.analytics_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.adminTodayAdherenceSummary(
                    completed: data.todayCompleted,
                    total: data.todayTasks,
                    percent: data.adherencePercent,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.sync_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.adminLastSyncLabel(
                    _formatFetchedAt(data.fetchedAt),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 390 || media.textScaler.scale(1) > 1.1;

    return AppCard(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminUserFilterPanel extends StatelessWidget {
  const _AdminUserFilterPanel({
    required this.accountFilter,
    required this.roleFilter,
    required this.shownCount,
    required this.totalCount,
    required this.onSearchChanged,
    required this.onSelectAccountFilter,
    required this.onSelectRoleFilter,
  });

  final AdminAccountFilter accountFilter;
  final AdminRoleFilter roleFilter;
  final int shownCount;
  final int totalCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<AdminAccountFilter> onSelectAccountFilter;
  final ValueChanged<AdminRoleFilter> onSelectRoleFilter;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 390 || media.textScaler.scale(1) > 1.1;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.adminUserFilterTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: isCompact ? 8 : 10),
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: AppStrings.adminUserSearchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: isCompact ? 10 : 12),
          Text(
            AppStrings.adminUserFilterStatusLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: _FilterChipLabel(AppStrings.adminUserFilterAllLabel),
                selected: accountFilter == AdminAccountFilter.all,
                onSelected: (_) =>
                    onSelectAccountFilter(AdminAccountFilter.all),
              ),
              ChoiceChip(
                label: _FilterChipLabel(AppStrings.adminUserFilterActiveLabel),
                selected: accountFilter == AdminAccountFilter.active,
                onSelected: (_) =>
                    onSelectAccountFilter(AdminAccountFilter.active),
              ),
              ChoiceChip(
                label: _FilterChipLabel(
                  AppStrings.adminUserFilterSuspendedLabel,
                ),
                selected: accountFilter == AdminAccountFilter.suspended,
                onSelected: (_) =>
                    onSelectAccountFilter(AdminAccountFilter.suspended),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 10 : 12),
          Text(
            AppStrings.adminUserFilterRoleLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: _FilterChipLabel(AppStrings.adminUserFilterAllLabel),
                selected: roleFilter == AdminRoleFilter.all,
                onSelected: (_) => onSelectRoleFilter(AdminRoleFilter.all),
              ),
              ChoiceChip(
                label: _FilterChipLabel(AppStrings.adminUserFilterUserLabel),
                selected: roleFilter == AdminRoleFilter.user,
                onSelected: (_) => onSelectRoleFilter(AdminRoleFilter.user),
              ),
              ChoiceChip(
                label: _FilterChipLabel(AppStrings.adminUserFilterAdminLabel),
                selected: roleFilter == AdminRoleFilter.admin,
                onSelected: (_) => onSelectRoleFilter(AdminRoleFilter.admin),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 10 : 12),
          Text(
            AppStrings.adminUserFilterResultSummary(
              shown: shownCount,
              total: totalCount,
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipLabel extends StatelessWidget {
  const _FilterChipLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.58,
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _AdminBulkActionPanel extends StatelessWidget {
  const _AdminBulkActionPanel({
    required this.selectedCount,
    required this.suspendCandidateCount,
    required this.activateCandidateCount,
    required this.isBusy,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onBulkSuspend,
    required this.onBulkActivate,
  });

  final int selectedCount;
  final int suspendCandidateCount;
  final int activateCandidateCount;
  final bool isBusy;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onBulkSuspend;
  final VoidCallback onBulkActivate;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 390 || media.textScaler.scale(1) > 1.1;

    return AppCard(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.adminBulkActionTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.adminBulkSelectionSummary(
              selectedCount: selectedCount,
              suspendCandidateCount: suspendCandidateCount,
              activateCandidateCount: activateCandidateCount,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: isCompact ? double.infinity : null,
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onSelectAll,
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: Text(
                    AppStrings.adminBulkSelectAllAction,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(
                width: isCompact ? double.infinity : null,
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onClearSelection,
                  icon: const Icon(Icons.deselect_rounded, size: 18),
                  label: Text(
                    AppStrings.adminBulkClearSelectionAction,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(
                width: isCompact ? double.infinity : null,
                child: FilledButton.icon(
                  onPressed: isBusy ? null : onBulkSuspend,
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: Text(
                    AppStrings.adminBulkSuspendAction,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(
                width: isCompact ? double.infinity : null,
                child: FilledButton.tonalIcon(
                  onPressed: isBusy ? null : onBulkActivate,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    AppStrings.adminBulkActivateAction,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserItem extends StatelessWidget {
  const _UserItem({
    required this.user,
    required this.isBusy,
    required this.isSelf,
    required this.isSelected,
    required this.canResetAccess,
    required this.onSelectionChanged,
    required this.onViewActivity,
    required this.onToggleStatus,
    required this.onResetAccess,
  });

  final AdminManagedUser user;
  final bool isBusy;
  final bool isSelf;
  final bool isSelected;
  final bool canResetAccess;
  final ValueChanged<bool?> onSelectionChanged;
  final VoidCallback onViewActivity;
  final VoidCallback onToggleStatus;
  final VoidCallback onResetAccess;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 390 || media.textScaler.scale(1) > 1.1;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = user.accountStatus == 'suspended'
        ? const Color(0xFFC53030)
        : const Color(0xFF2F855A);
    final statusLabel = user.accountStatus == 'suspended'
        ? AppStrings.adminStatusSuspended
        : AppStrings.adminStatusActive;
    final canManage = !isSelf && user.role != 'admin';
    final canSelect = canManage && !isBusy;
    final createdAtLabel = user.createdAt == null
        ? '-'
        : DateFormat('dd MMM yyyy').format(user.createdAt!.toLocal());
    final initials = _initials(user.fullName);

    return AppCard(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 14,
        isCompact ? 10 : 12,
        isCompact ? 12 : 14,
        isCompact ? 10 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isCompact ? 36 : 40,
                height: isCompact ? 36 : 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _InfoTag(
                          label: '@${user.username}',
                          icon: Icons.alternate_email_rounded,
                        ),
                        _InfoTag(
                          label: user.role.toUpperCase(),
                          icon: Icons.shield_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.adminCreatedAtLabel(createdAtLabel),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: canSelect ? onSelectionChanged : null,
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isCompact ? 82 : 96),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isCompact ? 8 : 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final compactActions = isCompact || constraints.maxWidth < 360;

              if (compactActions) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onViewActivity,
                        icon: const Icon(Icons.timeline_outlined, size: 18),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                        ),
                        label: Text(
                          AppStrings.adminViewActivityButton,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isBusy || !canManage || !canResetAccess
                            ? null
                            : onResetAccess,
                        icon: const Icon(Icons.key_outlined, size: 18),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                        ),
                        label: Text(
                          AppStrings.adminResetAccessButton,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isBusy || !canManage ? null : onToggleStatus,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                        ),
                        icon: Icon(
                          user.accountStatus == 'suspended'
                              ? Icons.check_circle_outline
                              : Icons.block,
                          size: 18,
                        ),
                        label: Text(
                          user.accountStatus == 'suspended'
                              ? AppStrings.adminActivateAction
                              : AppStrings.adminSuspendAction,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewActivity,
                      icon: const Icon(Icons.timeline_outlined, size: 18),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                      ),
                      label: Text(
                        AppStrings.adminViewActivityButton,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isBusy || !canManage || !canResetAccess
                          ? null
                          : onResetAccess,
                      icon: const Icon(Icons.key_outlined, size: 18),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                      ),
                      label: Text(
                        AppStrings.adminResetAccessButton,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isBusy || !canManage ? null : onToggleStatus,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 42),
                      ),
                      icon: Icon(
                        user.accountStatus == 'suspended'
                            ? Icons.check_circle_outline
                            : Icons.block,
                        size: 18,
                      ),
                      label: Text(
                        user.accountStatus == 'suspended'
                            ? AppStrings.adminActivateAction
                            : AppStrings.adminSuspendAction,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (!canManage) ...[
            const SizedBox(height: 8),
            Text(
              isSelf
                  ? AppStrings.adminSelfAccountHint
                  : AppStrings.adminOtherAdminHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ] else if (!canResetAccess) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.adminResetAccessUnavailableHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.62,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.62),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Row(
          children: [
            Expanded(
              child: AppLoadingSkeleton(
                width: double.infinity,
                height: 120,
                borderRadius: 12,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: AppLoadingSkeleton(
                width: double.infinity,
                height: 120,
                borderRadius: 12,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AppLoadingSkeleton(
                width: double.infinity,
                height: 120,
                borderRadius: 12,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: AppLoadingSkeleton(
                width: double.infinity,
                height: 120,
                borderRadius: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UsersLoading extends StatelessWidget {
  const _UsersLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        AppLoadingSkeleton(
          width: double.infinity,
          height: 120,
          borderRadius: 12,
        ),
        SizedBox(height: 10),
        AppLoadingSkeleton(
          width: double.infinity,
          height: 120,
          borderRadius: 12,
        ),
        SizedBox(height: 10),
        AppLoadingSkeleton(
          width: double.infinity,
          height: 120,
          borderRadius: 12,
        ),
      ],
    );
  }
}
