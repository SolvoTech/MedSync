import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_strings.dart';
import '../../core/errors/user_error_message.dart';
import '../../core/extensions/context_ext.dart';
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

  final row = await client
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();

  return (row?['role'] as String?) == 'admin';
});

final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardData>((
  ref,
) async {
  final client = SupabaseClientRef.maybeClient;
  if (client == null) {
    throw Exception('Supabase belum diinisialisasi.');
  }

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
  );
});

final adminUsersProvider = FutureProvider.autoDispose<List<AdminManagedUser>>((
  ref,
) async {
  final client = SupabaseClientRef.maybeClient;
  if (client == null) {
    throw Exception('Supabase belum diinisialisasi.');
  }

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
});

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
      final currentUser = _requireCurrentUser(client);
      final targetStatus = suspend ? 'suspended' : 'active';

      await client
          .from('profiles')
          .update({'account_status': targetStatus})
          .eq('id', target.id);

      await _insertAuditLog(
        client,
        actorId: currentUser.id,
        targetUserId: target.id,
        action: suspend ? 'suspend_user' : 'unsuspend_user',
        metadata: {
          'target_username': target.username,
          'target_status': targetStatus,
        },
      );
    });
  }

  Future<void> resetUserAccess({required AdminManagedUser target}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = _requireClient();
      final currentUser = _requireCurrentUser(client);

      if (target.internalEmail == null || target.internalEmail!.isEmpty) {
        throw Exception('Email internal user tidak ditemukan.');
      }

      await client.auth.resetPasswordForEmail(
        target.internalEmail!,
        redirectTo: 'io.supabase.medsync://login-callback/',
      );

      await _insertAuditLog(
        client,
        actorId: currentUser.id,
        targetUserId: target.id,
        action: 'reset_user_access',
        metadata: {
          'target_username': target.username,
          'target_internal_email': target.internalEmail,
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

  User _requireCurrentUser(SupabaseClient client) {
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }
    return user;
  }

  Future<void> _insertAuditLog(
    SupabaseClient client, {
    required String actorId,
    required String targetUserId,
    required String action,
    required Map<String, dynamic> metadata,
  }) async {
    await client.from('admin_audit_logs').insert({
      'actor_id': actorId,
      'target_user_id': targetUserId,
      'action': action,
      'metadata': metadata,
    });
  }
}

class AdminControlScreen extends ConsumerWidget {
  const AdminControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleState = ref.watch(adminRoleProvider);

    return roleState.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(
            AppStrings.tr('Admin Control Center', 'Pusat Kontrol Admin'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            AppStrings.tr('Admin Control Center', 'Pusat Kontrol Admin'),
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
                AppStrings.tr('Admin Control Center', 'Pusat Kontrol Admin'),
              ),
            ),
            body: AppEmptyState(
              message: AppStrings.tr(
                'You do not have access to this admin page.',
                'Anda tidak memiliki akses ke halaman admin.',
              ),
              subtitle: AppStrings.tr(
                'Contact your administrator if this is unexpected.',
                'Hubungi administrator jika ini tidak sesuai.',
              ),
              icon: Icons.lock_outline,
            ),
          );
        }

        final dashboardState = ref.watch(adminDashboardProvider);
        final usersState = ref.watch(adminUsersProvider);
        final actionState = ref.watch(adminActionControllerProvider);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppStrings.tr('Admin Control Center', 'Pusat Kontrol Admin'),
            ),
            actions: [
              IconButton(
                tooltip: AppStrings.tr('Refresh', 'Muat Ulang'),
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(adminDashboardProvider);
                  ref.invalidate(adminUsersProvider);
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
              await ref.read(adminDashboardProvider.future);
              await ref.read(adminUsersProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                AdminIntroCard(
                  icon: Icons.admin_panel_settings_outlined,
                  title: AppStrings.tr(
                    'Admin Control Center',
                    'Pusat Kontrol Admin',
                  ),
                  subtitle: AppStrings.tr(
                    'Monitor account access, user status, and today\'s adherence from one dashboard.',
                    'Pantau akses akun, status pengguna, dan kepatuhan hari ini dari satu dashboard.',
                  ),
                  badge: AppStrings.tr('ADMIN', 'ADMIN'),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.5),
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
                        child: Text(
                          AppStrings.tr(
                            'Manage educational articles for users.',
                            'Kelola artikel edukasi untuk pengguna.',
                          ),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => context.push(AppRoutes.adminEducation),
                        icon: const Icon(Icons.chevron_right_rounded, size: 18),
                        label: Text(AppStrings.tr('Manage', 'Kelola')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AdminSectionTitle(
                  title: AppStrings.tr('System Snapshot', 'Ringkasan Sistem'),
                  subtitle: AppStrings.tr(
                    'Quick metrics for users and daily adherence.',
                    'Metrik cepat pengguna dan kepatuhan harian.',
                  ),
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
                  title: AppStrings.tr('User Management', 'Manajemen Pengguna'),
                  subtitle: AppStrings.tr(
                    'Activate, suspend, or reset user access securely.',
                    'Aktifkan, nonaktifkan, atau reset akses pengguna dengan aman.',
                  ),
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
                        message: AppStrings.tr(
                          'No user data available yet.',
                          'Belum ada data pengguna.',
                        ),
                        subtitle: AppStrings.tr(
                          'User data will appear here.',
                          'Data user akan tampil di sini.',
                        ),
                        icon: Icons.group_outlined,
                      );
                    }

                    final currentUserId =
                        SupabaseClientRef.maybeClient?.auth.currentUser?.id;

                    return Column(
                      children: users
                          .map(
                            (user) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _UserItem(
                                user: user,
                                isBusy: actionState.isLoading,
                                isSelf: currentUserId == user.id,
                                onToggleStatus: () =>
                                    _onToggleStatus(context, ref, user),
                                onResetAccess: () =>
                                    _onResetAccess(context, ref, user),
                              ),
                            ),
                          )
                          .toList(),
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

  Future<void> _onToggleStatus(
    BuildContext context,
    WidgetRef ref,
    AdminManagedUser user,
  ) async {
    final suspend = user.accountStatus != 'suspended';
    final confirmed = await AppDialog.showConfirm(
      context,
      title: suspend
          ? AppStrings.tr('Suspend account?', 'Nonaktifkan akun?')
          : AppStrings.tr('Activate account?', 'Aktifkan akun?'),
      message: suspend
          ? AppStrings.tr(
              'The user will not be able to sign in while suspended.',
              'User tidak bisa login selama status dinonaktifkan.',
            )
          : AppStrings.tr(
              'The user will be able to sign in again.',
              'User akan bisa login kembali.',
            ),
      confirmLabel: suspend
          ? AppStrings.tr('Suspend', 'Nonaktifkan')
          : AppStrings.tr('Activate', 'Aktifkan'),
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
          ? AppStrings.tr('User account suspended.', 'Akun user dinonaktifkan.')
          : AppStrings.tr(
              'User account reactivated.',
              'Akun user diaktifkan kembali.',
            ),
    );
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
      title: AppStrings.tr('Reset user access?', 'Reset akses user?'),
      message: AppStrings.tr(
        'Reset instructions will be sent via the registered internal account channel.',
        'Instruksi reset akan dikirim melalui kanal akun internal yang terdaftar.',
      ),
      confirmLabel: AppStrings.tr('Send Reset', 'Kirim Reset'),
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

    context.showSuccessSnackBar(
      AppStrings.tr(
        'Reset access instructions sent successfully.',
        'Instruksi reset akses berhasil dikirim.',
      ),
    );
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
  });

  final int totalUsers;
  final int activeUsers;
  final int suspendedUsers;
  final int adminUsers;
  final int todayTasks;
  final int todayCompleted;
  final int adherencePercent;
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
      fullName:
          (map['full_name'] as String?) ??
          AppStrings.tr('No Name', 'Tanpa Nama'),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: AppStrings.tr('Total Users', 'Total User'),
                value: data.totalUsers.toString(),
                icon: Icons.groups_2_outlined,
                color: const Color(0xFF2B6CB0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: AppStrings.tr('Active Users', 'User Aktif'),
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
                title: AppStrings.tr('Suspended Users', 'User Suspended'),
                value: data.suspendedUsers.toString(),
                icon: Icons.block_outlined,
                color: const Color(0xFFC53030),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: AppStrings.tr('Admin Accounts', 'Akun Admin'),
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
                  AppStrings.tr(
                    'Today task adherence: ${data.todayCompleted}/${data.todayTasks} (${data.adherencePercent}%)',
                    'Kepatuhan tugas hari ini: ${data.todayCompleted}/${data.todayTasks} (${data.adherencePercent}%)',
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
    return AppCard(
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

class _UserItem extends StatelessWidget {
  const _UserItem({
    required this.user,
    required this.isBusy,
    required this.isSelf,
    required this.onToggleStatus,
    required this.onResetAccess,
  });

  final AdminManagedUser user;
  final bool isBusy;
  final bool isSelf;
  final VoidCallback onToggleStatus;
  final VoidCallback onResetAccess;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = user.accountStatus == 'suspended'
        ? const Color(0xFFC53030)
        : const Color(0xFF2F855A);
    final statusLabel = user.accountStatus == 'suspended'
        ? AppStrings.tr('SUSPENDED', 'DINONAKTIFKAN')
        : AppStrings.tr('ACTIVE', 'AKTIF');
    final canManage = !isSelf && user.role != 'admin';
    final createdAtLabel = user.createdAt == null
        ? '-'
        : DateFormat('dd MMM yyyy').format(user.createdAt!.toLocal());
    final initials = _initials(user.fullName);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
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
                      AppStrings.tr(
                        'Created: $createdAtLabel',
                        'Dibuat: $createdAtLabel',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy || !canManage ? null : onResetAccess,
                  icon: const Icon(Icons.key_outlined, size: 18),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                  ),
                  label: Text(AppStrings.tr('Reset Access', 'Reset Akses')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isBusy || !canManage ? null : onToggleStatus,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                  icon: Icon(
                    user.accountStatus == 'suspended'
                        ? Icons.check_circle_outline
                        : Icons.block,
                    size: 18,
                  ),
                  label: Text(
                    user.accountStatus == 'suspended'
                        ? AppStrings.tr('Activate', 'Aktifkan')
                        : AppStrings.tr('Suspend', 'Suspend'),
                  ),
                ),
              ),
            ],
          ),
          if (!canManage) ...[
            const SizedBox(height: 8),
            Text(
              isSelf
                  ? AppStrings.tr(
                      'This account is your own account.',
                      'Akun ini adalah akun Anda sendiri.',
                    )
                  : AppStrings.tr(
                      'Other admin accounts cannot be managed from this screen.',
                      'Akun admin lain tidak bisa dikelola dari layar ini.',
                    ),
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
