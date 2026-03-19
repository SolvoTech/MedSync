import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/extensions/datetime_ext.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_widget.dart';
import '../../core/widgets/app_loading_skeleton.dart';
import '../../data/remote/supabase_client.dart';
import '../../domain/models/notification_item.dart';

final notificationListProvider =
    AutoDisposeAsyncNotifierProvider<NotificationListController,
        List<NotificationItem>>(NotificationListController.new);

class NotificationListController
    extends AutoDisposeAsyncNotifier<List<NotificationItem>> {
  @override
  Future<List<NotificationItem>> build() => _fetch();

  Future<List<NotificationItem>> _fetch() async {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) throw Exception('Supabase belum diinisialisasi.');

    final user = client.auth.currentUser;
    if (user == null) throw Exception('Anda harus login terlebih dahulu.');

    final rows = await client
        .from('notification_logs')
        .select()
        .eq('owner_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    return (rows as List<dynamic>)
        .map((row) => NotificationItem.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> markAllRead() async {
    final client = SupabaseClientRef.maybeClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    await client
        .from('notification_logs')
        .update({'is_read': true})
        .eq('owner_id', user.id)
        .eq('is_read', false);

    await refresh();
  }

  Future<void> markRead(String notificationId) async {
    final client = SupabaseClientRef.maybeClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    await client
        .from('notification_logs')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('owner_id', user.id);

    await refresh();
  }

  Future<void> deleteNotification(String notificationId) async {
    final client = SupabaseClientRef.maybeClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    await client
        .from('notification_logs')
        .delete()
        .eq('id', notificationId)
        .eq('owner_id', user.id);

    await refresh();
  }
}

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notificationTitle),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationListProvider.notifier).markAllRead(),
            child: const Text(AppStrings.markAllRead),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(notificationListProvider.notifier).refresh(),
        child: notifState.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  AppEmptyState(
                    message: AppStrings.noNotifications,
                    icon: Icons.notifications_off_outlined,
                  ),
                ],
              );
            }

            // Group notifications by day
            final grouped = <String, List<NotificationItem>>{};
            for (final notif in notifications) {
              final key = (notif.createdAt ?? notif.scheduledAt).groupLabel;
              grouped.putIfAbsent(key, () => []).add(notif);
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: grouped.length,
              itemBuilder: (context, sectionIndex) {
                final groupKey = grouped.keys.elementAt(sectionIndex);
                final items = grouped[groupKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            groupKey,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    ...items.map((notif) => _NotificationTile(notif: notif)),
                  ],
                );
              },
            );
          },
          loading: () =>
              const AppListSkeleton(itemCount: 5, itemHeight: 72),
          error: (error, _) => AppErrorWidget(
            message: 'Gagal memuat notifikasi',
            onRetry: () => ref.invalidate(notificationListProvider),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notif});
  final NotificationItem notif;

  IconData _typeIcon() {
    switch (notif.notificationType) {
      case 'medicine':
        return Icons.medication_rounded;
      case 'measurement':
        return Icons.monitor_heart_rounded;
      case 'activity':
        return Icons.directions_run_rounded;
      case 'stock_warning':
        return Icons.warning_amber_rounded;
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'followup':
        return Icons.notification_important_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _typeColor(BuildContext context) {
    switch (notif.notificationType) {
      case 'medicine':
        return const Color(0xFF0077B6);
      case 'measurement':
        return const Color(0xFF38A169);
      case 'activity':
        return const Color(0xFFED8936);
      case 'stock_warning':
        return const Color(0xFFE53E3E);
      case 'streak':
        return const Color(0xFFE53E3E);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _typeColor(context);

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => ref
          .read(notificationListProvider.notifier)
          .deleteNotification(notif.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: notif.isRead
              ? Colors.transparent
              : colorScheme.primaryContainer.withValues(alpha: isDark ? 0.15 : 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: notif.isRead
                  ? colorScheme.surfaceContainerHighest
                  : accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _typeIcon(),
              size: 20,
              color: notif.isRead
                  ? colorScheme.onSurface.withValues(alpha: 0.4)
                  : accentColor,
            ),
          ),
          title: Text(
            notif.title,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              notif.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          trailing: Text(
            notif.scheduledAt.toTimeString(),
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
          onTap: () {
            if (!notif.isRead) {
              ref
                  .read(notificationListProvider.notifier)
                  .markRead(notif.id);
            }
          },
        ),
      ),
    );
  }
}
