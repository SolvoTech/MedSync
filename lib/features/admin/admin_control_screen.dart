import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_strings.dart';
import '../../core/errors/user_error_message.dart';
import '../../core/extensions/context_ext.dart';
import '../../core/observability/app_monitoring.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_widget.dart';
import '../../core/widgets/app_loading_skeleton.dart';
import '../../data/remote/supabase_client.dart';
import 'widgets/admin_ui.dart';

final adminRoleProvider = FutureProvider.autoDispose<bool>((ref) async {
  final client = SupabaseClientRef.maybeClient;
  if (client == null) {
    throw Exception('Supabase belum diinisialisasi.');
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
        source: 'admin_control_screen',
        event: 'admin_role_lookup_failed',
        error: error,
        stackTrace: stackTrace,
        metadata: {'user_id': user.id},
      ),
    );
    rethrow;
  }
});

final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardData>((
  ref,
) async {
  final client = SupabaseClientRef.maybeClient;
  if (client == null) {
    throw Exception('Supabase belum diinisialisasi.');
  }

  final currentUserId = client.auth.currentUser?.id;

  try {
    final profilesRows =
        await client.from('profiles').select('id, role, account_status')
            as List<dynamic>;

    final profiles = profilesRows.cast<Map<String, dynamic>>();
    final totalUsers = profiles.length;
    final activeUsers = profiles
        .where((row) => (row['account_status'] as String?) != 'suspended')
        .length;
    final suspendedUsers = profiles
        .where((row) => (row['account_status'] as String?) == 'suspended')
        .length;
    final adminUsers = profiles
        .where((row) => (row['role'] as String?) == 'admin')
        .length;

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final tasksRows =
        await client
                .from('task_logs')
                .select('status')
                .gte('scheduled_at', start.toIso8601String())
                .lt('scheduled_at', end.toIso8601String())
            as List<dynamic>;

    final tasks = tasksRows.cast<Map<String, dynamic>>();
    final todayTasks = tasks.length;
    final todayCompleted = tasks
        .where((row) => row['status'] == 'done' || row['status'] == 'skipped')
        .length;
    final adherence = todayTasks == 0
        ? 0
        : ((todayCompleted / todayTasks) * 100).round();

    return AdminDashboardData(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      suspendedUsers: suspendedUsers,
      adminUsers: adminUsers,
      todayTasks: todayTasks,
      todayCompleted: todayCompleted,
      adherencePercent: adherence,
      fetchedAt: DateTime.now(),
    );
  } catch (error, stackTrace) {
    unawaited(
      AppMonitoring.logQueryFailure(
        source: 'admin_control_screen',
        event: 'admin_dashboard_query_failed',
        error: error,
        stackTrace: stackTrace,
        metadata: {'user_id': currentUserId},
      ),
    );
    rethrow;
  }
});

final adminUsersProvider = FutureProvider.autoDispose<List<AdminManagedUser>>((
  ref,
) async {
  final client = SupabaseClientRef.maybeClient;
  if (client == null) {
    throw Exception('Supabase belum diinisialisasi.');
  }

  final currentUserId = client.auth.currentUser?.id;

  try {
    final rows =
        await client
                .from('profiles')
                .select(
                  'id, full_name, username, role, account_status, internal_email, created_at',
                )
                .order('created_at', ascending: false)
            as List<dynamic>;

    return rows
        .cast<Map<String, dynamic>>()
        .map(AdminManagedUser.fromMap)
        .toList();
  } catch (error, stackTrace) {
    unawaited(
      AppMonitoring.logQueryFailure(
        source: 'admin_control_screen',
        event: 'admin_users_query_failed',
        error: error,
        stackTrace: stackTrace,
        metadata: {'user_id': currentUserId},
      ),
    );
    rethrow;
  }
});

enum AdminAccountFilter { all, active, suspended }

enum AdminRoleFilter { all, admin, user }

final adminUserSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

final adminUserAccountFilterProvider =
    StateProvider.autoDispose<AdminAccountFilter>(
      (ref) => AdminAccountFilter.all,
    );

final adminUserRoleFilterProvider = StateProvider.autoDispose<AdminRoleFilter>(
  (ref) => AdminRoleFilter.all,
);

final adminSelectedUserIdsProvider = StateProvider.autoDispose<Set<String>>(
  (ref) => <String>{},
);

final adminActionControllerProvider =
    AutoDisposeNotifierProvider<AdminActionController, AsyncValue<void>>(
      AdminActionController.new,
    );

class AdminActionController extends AutoDisposeNotifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> setUserStatus({
    required AdminManagedUser target,
    required bool suspend,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = _requireClient();
      final targetStatus = suspend ? 'suspended' : 'active';

      await client.rpc(
        'admin_set_user_account_status',
        params: {
          'target_user_id': target.id,
          'target_status': targetStatus,
          'target_username': target.username,
        },
      );
    });
  }

  Future<void> resetUserAccess({required AdminManagedUser target}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = _requireClient();

      if (target.internalEmail == null || target.internalEmail!.isEmpty) {
        throw Exception('Email internal user tidak ditemukan.');
      }

      await client.auth.resetPasswordForEmail(
        target.internalEmail!,
        redirectTo: 'io.supabase.medsync://login-callback/',
      );

      await client.rpc(
        'admin_insert_audit_log',
        params: {
          'action_name': 'reset_user_access',
          'target_user_id': target.id,
          'metadata': {
            'target_username': target.username,
            'target_internal_email': target.internalEmail,
          },
        },
      );
    });
  }

  SupabaseClient _requireClient() {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception('Supabase belum diinisialisasi.');
    }
    return client;
  }
}

class AdminControlScreen extends ConsumerWidget {
  const AdminControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleState = ref.watch(adminRoleProvider);

    return roleState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(AppStrings.adminControlCenterTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(AppStrings.adminControlCenterTitle)),
        body: AppErrorWidget(
          message: toUserErrorMessage(error),
          onRetry: () => ref.invalidate(adminRoleProvider),
        ),
      ),
      data: (isAdmin) {
        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(title: Text(AppStrings.adminControlCenterTitle)),
            body: AppEmptyState(
              message: AppStrings.adminNoAccessMessage,
              subtitle: AppStrings.adminNoAccessSubtitle,
              icon: Icons.lock_outline,
            ),
          );
        }

        final media = MediaQuery.of(context);
        final isCompact =
            media.size.width < 390 || media.textScaler.scale(1) > 1.1;
        final pagePadding = EdgeInsets.fromLTRB(
          isCompact ? 12 : 16,
          isCompact ? 10 : 12,
          isCompact ? 12 : 16,
          isCompact ? 20 : 24,
        );

        final dashboardState = ref.watch(adminDashboardProvider);
        final usersState = ref.watch(adminUsersProvider);
        final actionState = ref.watch(adminActionControllerProvider);
        final searchQuery = ref.watch(adminUserSearchQueryProvider);
        final accountFilter = ref.watch(adminUserAccountFilterProvider);
        final roleFilter = ref.watch(adminUserRoleFilterProvider);
        final selectedUserIds = ref.watch(adminSelectedUserIdsProvider);

        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.adminControlCenterTitle),
            actions: [
              IconButton(
                tooltip: AppStrings.adminRefreshTooltip,
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(adminDashboardProvider);
                  ref.invalidate(adminUsersProvider);
                  ref.read(adminSelectedUserIdsProvider.notifier).state =
                      <String>{};
                },
              ),
            ],
            bottom: actionState.isLoading
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(2),
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                : null,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminDashboardProvider);
              ref.invalidate(adminUsersProvider);
              ref.read(adminSelectedUserIdsProvider.notifier).state =
                  <String>{};
              await ref.read(adminDashboardProvider.future);
              await ref.read(adminUsersProvider.future);
            },
            child: ListView(
              padding: pagePadding,
              children: [
                AdminIntroCard(
                  icon: Icons.admin_panel_settings_outlined,
                  title: AppStrings.adminControlCenterTitle,
                  subtitle: AppStrings.adminControlCenterIntroSubtitle,
                  badge: AppStrings.adminBadge,
                ),
                const SizedBox(height: 14),
                AppCard(
                  padding: EdgeInsets.all(isCompact ? 12 : 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compactCard =
                          isCompact || constraints.maxWidth < 360;

                      if (compactCard) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.school_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppStrings.adminManageEducationHint,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonalIcon(
                                onPressed: () =>
                                    context.go(AppRoutes.adminEducation),
                                icon: const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                ),
                                label: Text(AppStrings.adminManageLabel),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.school_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(AppStrings.adminManageEducationHint),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                context.go(AppRoutes.adminEducation),
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                            ),
                            label: Text(AppStrings.adminManageLabel),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                AdminSectionTitle(
                  title: AppStrings.adminSystemSnapshotTitle,
                  subtitle: AppStrings.adminSystemSnapshotSubtitle,
                  icon: Icons.query_stats_rounded,
                ),
                const SizedBox(height: 8),
                dashboardState.when(
                  loading: () => const _DashboardLoading(),
                  error: (error, _) => AppErrorWidget(
                    message: toUserErrorMessage(error),
                    onRetry: () => ref.invalidate(adminDashboardProvider),
                  ),
                  data: (dashboard) => _DashboardSummary(data: dashboard),
                ),
                const SizedBox(height: 20),
                AdminSectionTitle(
                  title: AppStrings.adminUserManagementTitle,
                  subtitle: AppStrings.adminUserManagementSubtitle,
                  icon: Icons.groups_rounded,
                ),
                const SizedBox(height: 8),
                usersState.when(
                  loading: () => const _UsersLoading(),
                  error: (error, _) => AppErrorWidget(
                    message: toUserErrorMessage(error),
                    onRetry: () => ref.invalidate(adminUsersProvider),
                  ),
                  data: (users) {
                    if (users.isEmpty) {
                      return AppEmptyState(
                        message: AppStrings.adminNoUserDataMessage,
                        subtitle: AppStrings.adminNoUserDataSubtitle,
                        icon: Icons.group_outlined,
                      );
                    }

                    final filteredUsers = _applyUserFilters(
                      users: users,
                      searchQuery: searchQuery,
                      accountFilter: accountFilter,
                      roleFilter: roleFilter,
                    );

                    final currentUserId =
                        SupabaseClientRef.maybeClient?.auth.currentUser?.id;

                    final manageableFilteredUsers = filteredUsers
                        .where(
                          (user) => _canManageUser(
                            user: user,
                            currentUserId: currentUserId,
                          ),
                        )
                        .toList();
                    final selectedFilteredUsers = manageableFilteredUsers
                        .where((user) => selectedUserIds.contains(user.id))
                        .toList();
                    final selectedSuspendCandidates = selectedFilteredUsers
                        .where((user) => user.accountStatus != 'suspended')
                        .toList();
                    final selectedActivateCandidates = selectedFilteredUsers
                        .where((user) => user.accountStatus == 'suspended')
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AdminUserFilterPanel(
                          accountFilter: accountFilter,
                          roleFilter: roleFilter,
                          shownCount: filteredUsers.length,
                          totalCount: users.length,
                          onSearchChanged: (value) {
                            ref
                                    .read(adminUserSearchQueryProvider.notifier)
                                    .state =
                                value;
                          },
                          onSelectAccountFilter: (value) {
                            ref
                                    .read(
                                      adminUserAccountFilterProvider.notifier,
                                    )
                                    .state =
                                value;
                          },
                          onSelectRoleFilter: (value) {
                            ref
                                    .read(adminUserRoleFilterProvider.notifier)
                                    .state =
                                value;
                          },
                        ),
                        const SizedBox(height: 12),
                        _AdminBulkActionPanel(
                          selectedCount: selectedFilteredUsers.length,
                          suspendCandidateCount:
                              selectedSuspendCandidates.length,
                          activateCandidateCount:
                              selectedActivateCandidates.length,
                          isBusy: actionState.isLoading,
                          onSelectAll: () {
                            final ids = manageableFilteredUsers
                                .map((user) => user.id)
                                .toSet();
                            ref
                                    .read(adminSelectedUserIdsProvider.notifier)
                                    .state =
                                ids;
                          },
                          onClearSelection: () {
                            ref
                                    .read(adminSelectedUserIdsProvider.notifier)
                                    .state =
                                <String>{};
                          },
                          onBulkSuspend: () => _onBulkSetStatus(
                            context,
                            ref,
                            targets: selectedFilteredUsers,
                            suspend: true,
                          ),
                          onBulkActivate: () => _onBulkSetStatus(
                            context,
                            ref,
                            targets: selectedFilteredUsers,
                            suspend: false,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (filteredUsers.isEmpty)
                          AppEmptyState(
                            message: AppStrings.adminNoFilteredUserMessage,
                            subtitle: AppStrings.adminNoFilteredUserSubtitle,
                            icon: Icons.filter_alt_off_outlined,
                          )
                        else
                          Column(
                            children: filteredUsers
                                .map(
                                  (user) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _UserItem(
                                      user: user,
                                      isBusy: actionState.isLoading,
                                      isSelf: currentUserId == user.id,
                                      isSelected: selectedUserIds.contains(
                                        user.id,
                                      ),
                                      onSelectionChanged: (value) {
                                        _toggleUserSelection(
                                          ref,
                                          userId: user.id,
                                          selected: value ?? false,
                                        );
                                      },
                                      onToggleStatus: () =>
                                          _onToggleStatus(context, ref, user),
                                      onResetAccess: () =>
                                          _onResetAccess(context, ref, user),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<AdminManagedUser> _applyUserFilters({
    required List<AdminManagedUser> users,
    required String searchQuery,
    required AdminAccountFilter accountFilter,
    required AdminRoleFilter roleFilter,
  }) {
    final normalizedQuery = searchQuery.trim().toLowerCase();

    return users.where((user) {
      final isAccountMatch = switch (accountFilter) {
        AdminAccountFilter.all => true,
        AdminAccountFilter.active => user.accountStatus == 'active',
        AdminAccountFilter.suspended => user.accountStatus == 'suspended',
      };

      if (!isAccountMatch) {
        return false;
      }

      final isRoleMatch = switch (roleFilter) {
        AdminRoleFilter.all => true,
        AdminRoleFilter.admin => user.role == 'admin',
        AdminRoleFilter.user => user.role == 'user',
      };

      if (!isRoleMatch) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      final searchTarget = [
        user.fullName,
        user.username,
        user.internalEmail ?? '',
        user.role,
        user.accountStatus,
      ].join(' ').toLowerCase();

      return searchTarget.contains(normalizedQuery);
    }).toList();
  }

  bool _canManageUser({
    required AdminManagedUser user,
    required String? currentUserId,
  }) {
    return currentUserId != user.id && user.role != 'admin';
  }

  void _toggleUserSelection(
    WidgetRef ref, {
    required String userId,
    required bool selected,
  }) {
    final current = ref.read(adminSelectedUserIdsProvider);
    final next = <String>{...current};

    if (selected) {
      next.add(userId);
    } else {
      next.remove(userId);
    }

    ref.read(adminSelectedUserIdsProvider.notifier).state = next;
  }

  Future<void> _onBulkSetStatus(
    BuildContext context,
    WidgetRef ref, {
    required List<AdminManagedUser> targets,
    required bool suspend,
  }) async {
    final actionableTargets = targets
        .where(
          (user) => suspend
              ? user.accountStatus != 'suspended'
              : user.accountStatus == 'suspended',
        )
        .toList();

    if (actionableTargets.isEmpty) {
      context.showErrorSnackBar(AppStrings.adminBulkNoEligibleSelection);
      return;
    }

    final confirmed = await AppDialog.showConfirm(
      context,
      title: suspend
          ? AppStrings.adminBulkSuspendTitle(actionableTargets.length)
          : AppStrings.adminBulkActivateTitle(actionableTargets.length),
      message: suspend
          ? AppStrings.adminBulkSuspendMessage(actionableTargets.length)
          : AppStrings.adminBulkActivateMessage(actionableTargets.length),
      confirmLabel: suspend
          ? AppStrings.adminBulkSuspendAction
          : AppStrings.adminBulkActivateAction,
      cancelLabel: AppStrings.cancel,
      isDestructive: suspend,
      icon: suspend ? Icons.block : Icons.check_circle_outline,
    );

    if (confirmed != true) {
      return;
    }

    var successCount = 0;
    var failedCount = 0;

    for (final user in actionableTargets) {
      await ref
          .read(adminActionControllerProvider.notifier)
          .setUserStatus(target: user, suspend: suspend);

      final actionState = ref.read(adminActionControllerProvider);
      if (actionState.hasError) {
        failedCount += 1;
        continue;
      }

      successCount += 1;
    }

    if (!context.mounted) {
      return;
    }

    if (successCount > 0) {
      context.showSuccessSnackBar(
        AppStrings.adminBulkStatusResult(
          successCount: successCount,
          failedCount: failedCount,
        ),
      );
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(adminUsersProvider);
    }

    if (successCount == 0 && failedCount > 0) {
      context.showErrorSnackBar(AppStrings.adminBulkActionFailed);
    }

    ref.read(adminSelectedUserIdsProvider.notifier).state = <String>{};
  }

  Future<void> _onToggleStatus(
    BuildContext context,
    WidgetRef ref,
    AdminManagedUser user,
  ) async {
    final suspend = user.accountStatus != 'suspended';
    final confirmed = await AppDialog.showConfirm(
      context,
      title: suspend
          ? AppStrings.adminSuspendAccountTitle
          : AppStrings.adminActivateAccountTitle,
      message: suspend
          ? AppStrings.adminSuspendAccountMessage
          : AppStrings.adminActivateAccountMessage,
      confirmLabel: suspend
          ? AppStrings.adminSuspendAction
          : AppStrings.adminActivateAction,
      cancelLabel: AppStrings.cancel,
      isDestructive: suspend,
      icon: suspend ? Icons.block : Icons.check_circle_outline,
    );

    if (confirmed != true) {
      return;
    }

    await ref
        .read(adminActionControllerProvider.notifier)
        .setUserStatus(target: user, suspend: suspend);

    final actionState = ref.read(adminActionControllerProvider);
    if (!context.mounted) {
      return;
    }

    if (actionState.hasError) {
      context.showErrorSnackBar(toUserErrorMessage(actionState.error!));
      return;
    }

    context.showSuccessSnackBar(
      suspend
          ? AppStrings.adminUserSuspendedSuccess
          : AppStrings.adminUserActivatedSuccess,
    );

    final nextSelected = <String>{...ref.read(adminSelectedUserIdsProvider)}
      ..remove(user.id);
    ref.read(adminSelectedUserIdsProvider.notifier).state = nextSelected;

    ref.invalidate(adminDashboardProvider);
    ref.invalidate(adminUsersProvider);
  }

  Future<void> _onResetAccess(
    BuildContext context,
    WidgetRef ref,
    AdminManagedUser user,
  ) async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: AppStrings.adminResetUserAccessTitle,
      message: AppStrings.adminResetUserAccessMessage,
      confirmLabel: AppStrings.adminSendResetAction,
      cancelLabel: AppStrings.cancel,
      icon: Icons.key_outlined,
    );

    if (confirmed != true) {
      return;
    }

    await ref
        .read(adminActionControllerProvider.notifier)
        .resetUserAccess(target: user);

    final actionState = ref.read(adminActionControllerProvider);
    if (!context.mounted) {
      return;
    }

    if (actionState.hasError) {
      context.showErrorSnackBar(toUserErrorMessage(actionState.error!));
      return;
    }

    context.showSuccessSnackBar(AppStrings.adminResetAccessSuccess);
    ref.invalidate(adminUsersProvider);
  }
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.totalUsers,
    required this.activeUsers,
    required this.suspendedUsers,
    required this.adminUsers,
    required this.todayTasks,
    required this.todayCompleted,
    required this.adherencePercent,
    required this.fetchedAt,
  });

  final int totalUsers;
  final int activeUsers;
  final int suspendedUsers;
  final int adminUsers;
  final int todayTasks;
  final int todayCompleted;
  final int adherencePercent;
  final DateTime fetchedAt;
}

class AdminManagedUser {
  const AdminManagedUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    required this.accountStatus,
    required this.createdAt,
    this.internalEmail,
  });

  final String id;
  final String fullName;
  final String username;
  final String role;
  final String accountStatus;
  final DateTime? createdAt;
  final String? internalEmail;

  factory AdminManagedUser.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map['created_at'];

    return AdminManagedUser(
      id: map['id'] as String,
      fullName: (map['full_name'] as String?) ?? AppStrings.adminUnknownName,
      username: (map['username'] as String?) ?? '-',
      role: (map['role'] as String?) ?? 'user',
      accountStatus: (map['account_status'] as String?) ?? 'active',
      createdAt: rawCreatedAt is DateTime
          ? rawCreatedAt
          : rawCreatedAt is String
          ? DateTime.tryParse(rawCreatedAt)
          : null,
      internalEmail: map['internal_email'] as String?,
    );
  }
}

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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: AppStrings.adminMetricTotalUsers,
                value: data.totalUsers.toString(),
                icon: Icons.groups_2_outlined,
                color: const Color(0xFF2B6CB0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: AppStrings.adminMetricActiveUsers,
                value: data.activeUsers.toString(),
                icon: Icons.check_circle_outline,
                color: const Color(0xFF2F855A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: AppStrings.adminMetricSuspendedUsers,
                value: data.suspendedUsers.toString(),
                icon: Icons.block_outlined,
                color: const Color(0xFFC53030),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: AppStrings.adminMetricAdminAccounts,
                value: data.adminUsers.toString(),
                icon: Icons.admin_panel_settings_outlined,
                color: const Color(0xFF805AD5),
              ),
            ),
          ],
        ),
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            title,
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
                borderRadius: BorderRadius.circular(12),
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
                label: Text(AppStrings.adminUserFilterAllLabel),
                selected: accountFilter == AdminAccountFilter.all,
                onSelected: (_) =>
                    onSelectAccountFilter(AdminAccountFilter.all),
              ),
              ChoiceChip(
                label: Text(AppStrings.adminUserFilterActiveLabel),
                selected: accountFilter == AdminAccountFilter.active,
                onSelected: (_) =>
                    onSelectAccountFilter(AdminAccountFilter.active),
              ),
              ChoiceChip(
                label: Text(AppStrings.adminUserFilterSuspendedLabel),
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
                label: Text(AppStrings.adminUserFilterAllLabel),
                selected: roleFilter == AdminRoleFilter.all,
                onSelected: (_) => onSelectRoleFilter(AdminRoleFilter.all),
              ),
              ChoiceChip(
                label: Text(AppStrings.adminUserFilterUserLabel),
                selected: roleFilter == AdminRoleFilter.user,
                onSelected: (_) => onSelectRoleFilter(AdminRoleFilter.user),
              ),
              ChoiceChip(
                label: Text(AppStrings.adminUserFilterAdminLabel),
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
    required this.onSelectionChanged,
    required this.onToggleStatus,
    required this.onResetAccess,
  });

  final AdminManagedUser user;
  final bool isBusy;
  final bool isSelf;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
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
                  borderRadius: BorderRadius.circular(12),
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
                  Container(
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
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
                        onPressed: isBusy || !canManage ? null : onResetAccess,
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
                      onPressed: isBusy || !canManage ? null : onResetAccess,
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
    return Container(
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
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
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
                borderRadius: 20,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: AppLoadingSkeleton(
                width: double.infinity,
                height: 120,
                borderRadius: 20,
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
                borderRadius: 20,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: AppLoadingSkeleton(
                width: double.infinity,
                height: 120,
                borderRadius: 20,
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
          borderRadius: 20,
        ),
        SizedBox(height: 10),
        AppLoadingSkeleton(
          width: double.infinity,
          height: 120,
          borderRadius: 20,
        ),
        SizedBox(height: 10),
        AppLoadingSkeleton(
          width: double.infinity,
          height: 120,
          borderRadius: 20,
        ),
      ],
    );
  }
}
