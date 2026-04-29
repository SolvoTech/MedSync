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

part 'admin_control_widgets.dart';

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
  static const String _internalEmailDomain = 'users.medsync.local';
  static final RegExp _usernameRegex = RegExp(r'^[a-z0-9_]{3,24}$');

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
      final usedRpc = await _trySetUserStatusViaRpc(
        client,
        target: target,
        targetStatus: targetStatus,
      );

      if (!usedRpc) {
        await client
            .from('profiles')
            .update({'account_status': targetStatus})
            .eq('id', target.id)
            .select('id')
            .single();

        await _insertAuditLogBestEffort(
          client,
          action: suspend ? 'suspend_user' : 'unsuspend_user',
          targetUserId: target.id,
          metadata: {
            'target_status': targetStatus,
            'target_username': target.username,
          },
        );
      }
    });
  }

  Future<void> resetUserAccess({required AdminManagedUser target}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = _requireClient();
      final resetEmail = _resolveResetEmail(target);
      if (resetEmail == null) {
        throw Exception('Email internal user tidak ditemukan.');
      }

      await client.auth.resetPasswordForEmail(
        resetEmail,
        redirectTo: 'io.supabase.medsync://login-callback/',
      );

      await _insertAuditLogBestEffort(
        client,
        action: 'reset_user_access',
        targetUserId: target.id,
        metadata: {
          'target_username': target.username,
          'target_internal_email': resetEmail,
        },
      );
    });
  }

  Future<bool> _trySetUserStatusViaRpc(
    SupabaseClient client, {
    required AdminManagedUser target,
    required String targetStatus,
  }) async {
    try {
      await client.rpc(
        'admin_set_user_account_status',
        params: {
          'target_user_id': target.id,
          'target_status': targetStatus,
          'target_username': target.username,
        },
      );
      return true;
    } catch (error) {
      if (_isMissingRpcFunction(
        error,
        functionName: 'admin_set_user_account_status',
      )) {
        return false;
      }
      rethrow;
    }
  }

  Future<void> _insertAuditLogBestEffort(
    SupabaseClient client, {
    required String action,
    required String? targetUserId,
    required Map<String, dynamic> metadata,
  }) async {
    final actorId = client.auth.currentUser?.id;

    try {
      await client.rpc(
        'admin_insert_audit_log',
        params: {
          'action_name': action,
          'target_user_id': targetUserId,
          'metadata': metadata,
        },
      );
      return;
    } catch (_) {
      // Best-effort: never block primary action due to audit sink availability.
    }

    if (actorId == null) {
      return;
    }

    try {
      await client.from('admin_audit_logs').insert({
        'actor_id': actorId,
        'target_user_id': targetUserId,
        'action': action,
        'metadata': metadata,
      });
    } catch (_) {
      // Ignore audit sink failures.
    }
  }

  String? _resolveResetEmail(AdminManagedUser target) {
    final internalEmail = target.internalEmail?.trim().toLowerCase();
    if (internalEmail != null && internalEmail.contains('@')) {
      return internalEmail;
    }

    final username = target.username.trim().toLowerCase();
    if (_usernameRegex.hasMatch(username)) {
      return '$username@$_internalEmailDomain';
    }

    return null;
  }

  bool _isMissingRpcFunction(Object error, {required String functionName}) {
    if (error is! PostgrestException) {
      return false;
    }

    final message = error.message.toLowerCase();
    return message.contains('could not find the function') &&
        message.contains(functionName.toLowerCase());
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

  static final RegExp _usernameRegex = RegExp(r'^[a-z0-9_]{3,24}$');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleState = ref.watch(adminRoleProvider);

    return roleState.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(
            AppStrings.adminControlCenterTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            AppStrings.adminControlCenterTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: AppErrorWidget(
          message: toUserErrorMessage(error),
          onRetry: () => ref.invalidate(adminRoleProvider),
        ),
      ),
      data: (isAdmin) {
        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                AppStrings.adminControlCenterTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
            title: Text(
              AppStrings.adminControlCenterTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
                                    borderRadius: BorderRadius.circular(8),
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
                              borderRadius: BorderRadius.circular(8),
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
                                      canResetAccess: _canResetAccess(user),
                                      onSelectionChanged: (value) {
                                        _toggleUserSelection(
                                          ref,
                                          userId: user.id,
                                          selected: value ?? false,
                                        );
                                      },
                                      onViewActivity: () => context.push(
                                        AppRoutes.adminUserActivity(user.id),
                                      ),
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

  bool _canResetAccess(AdminManagedUser user) {
    final internalEmail = user.internalEmail?.trim().toLowerCase();
    if (internalEmail != null && internalEmail.contains('@')) {
      return true;
    }

    return _usernameRegex.hasMatch(user.username.trim().toLowerCase());
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
