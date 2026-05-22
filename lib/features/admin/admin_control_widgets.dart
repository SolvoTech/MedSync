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
      AdminMetricTile(
        title: AppStrings.adminMetricTotalUsers,
        value: data.totalUsers.toString(),
        icon: Icons.groups_2_outlined,
        color: const Color(0xFF2B6CB0),
      ),
      AdminMetricTile(
        title: AppStrings.adminMetricActiveUsers,
        value: data.activeUsers.toString(),
        icon: Icons.check_circle_outline,
        color: const Color(0xFF2F855A),
      ),
      AdminMetricTile(
        title: AppStrings.adminMetricSuspendedUsers,
        value: data.suspendedUsers.toString(),
        icon: Icons.block_outlined,
        color: const Color(0xFFC53030),
      ),
      AdminMetricTile(
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
        AdminCollapsibleSection(
          title: AppStrings.tr('Operational details', 'Detail operasional'),
          subtitle: AppStrings.tr(
            'Daily adherence and last sync info.',
            'Kepatuhan harian dan info sinkron terakhir.',
          ),
          icon: Icons.analytics_outlined,
          child: Column(
            children: [
              _CompactInfoRow(
                icon: Icons.analytics_outlined,
                text: AppStrings.adminTodayAdherenceSummary(
                  completed: data.todayCompleted,
                  total: data.todayTasks,
                  percent: data.adherencePercent,
                ),
              ),
              const SizedBox(height: 8),
              _CompactInfoRow(
                icon: Icons.sync_rounded,
                text: AppStrings.adminLastSyncLabel(
                  _formatFetchedAt(data.fetchedAt),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  const _CompactInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _SelectionModePanel extends StatelessWidget {
  const _SelectionModePanel({
    required this.enabled,
    required this.selectedCount,
    required this.onChanged,
  });

  final bool enabled;
  final int selectedCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AdminToolbarCard(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.checklist_rounded,
              color: colorScheme.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.tr('Selection mode', 'Mode pilih'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  selectedCount == 0
                      ? AppStrings.tr(
                          'Enable only when bulk actions are needed.',
                          'Aktifkan hanya saat perlu aksi massal.',
                        )
                      : AppStrings.tr(
                          '$selectedCount users selected.',
                          '$selectedCount pengguna dipilih.',
                        ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: onChanged),
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

    return Column(
      children: [
        AdminToolbarCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
        ),
        const SizedBox(height: 10),
        AdminCollapsibleSection(
          title: AppStrings.tr('Advanced filters', 'Filter lanjutan'),
          subtitle: AppStrings.tr(
            'Filter by account status and role.',
            'Saring berdasarkan status akun dan peran.',
          ),
          icon: Icons.tune_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.adminUserFilterStatusLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w700,
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
                    label: _FilterChipLabel(
                      AppStrings.adminUserFilterActiveLabel,
                    ),
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
                  fontWeight: FontWeight.w700,
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
                    label: _FilterChipLabel(
                      AppStrings.adminUserFilterUserLabel,
                    ),
                    selected: roleFilter == AdminRoleFilter.user,
                    onSelected: (_) => onSelectRoleFilter(AdminRoleFilter.user),
                  ),
                  ChoiceChip(
                    label: _FilterChipLabel(
                      AppStrings.adminUserFilterAdminLabel,
                    ),
                    selected: roleFilter == AdminRoleFilter.admin,
                    onSelected: (_) =>
                        onSelectRoleFilter(AdminRoleFilter.admin),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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

    return AdminToolbarCard(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
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

enum _UserCardAction { resetAccess, toggleStatus }

class _UserItem extends StatelessWidget {
  const _UserItem({
    required this.user,
    required this.isBusy,
    required this.isSelf,
    required this.isSelected,
    required this.showSelectionControls,
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
  final bool showSelectionControls;
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isCompact ? 96 : 118,
                        ),
                        child: AdminStatusPill(
                          label: statusLabel,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      PopupMenuButton<_UserCardAction>(
                        tooltip: AppStrings.tr('More actions', 'Aksi lainnya'),
                        onSelected: (action) {
                          if (action == _UserCardAction.resetAccess) {
                            onResetAccess();
                          } else {
                            onToggleStatus();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: _UserCardAction.resetAccess,
                            enabled: !isBusy && canManage && canResetAccess,
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.key_outlined),
                              title: Text(AppStrings.adminResetAccessButton),
                            ),
                          ),
                          PopupMenuItem(
                            value: _UserCardAction.toggleStatus,
                            enabled: !isBusy && canManage,
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                user.accountStatus == 'suspended'
                                    ? Icons.check_circle_outline
                                    : Icons.block,
                              ),
                              title: Text(
                                user.accountStatus == 'suspended'
                                    ? AppStrings.adminActivateAction
                                    : AppStrings.adminSuspendAction,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (showSelectionControls)
                    Checkbox(
                      value: isSelected,
                      onChanged: canSelect ? onSelectionChanged : null,
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: isCompact ? 8 : 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onViewActivity,
              icon: const Icon(Icons.timeline_outlined, size: 18),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
              label: Text(
                AppStrings.adminViewActivityButton,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
