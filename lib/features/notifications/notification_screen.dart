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
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        groupKey,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
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
        return Icons.medication;
      case 'measurement':
        return Icons.monitor_heart;
      case 'activity':
        return Icons.directions_run;
      case 'stock_warning':
        return Icons.warning_amber;
      case 'streak':
        return Icons.local_fire_department;
      case 'followup':
        return Icons.notification_important;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => ref
          .read(notificationListProvider.notifier)
          .deleteNotification(notif.id),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notif.isRead
              ? colorScheme.surfaceContainerHighest
              : colorScheme.primaryContainer,
          child: Icon(
            _typeIcon(),
            size: 20,
            color: notif.isRead
                ? colorScheme.onSurface.withValues(alpha: 0.5)
                : colorScheme.primary,
          ),
        ),
        title: Text(
          notif.title,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          notif.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Text(
          notif.scheduledAt.toTimeString(),
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.4),
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
    );
  }
}
