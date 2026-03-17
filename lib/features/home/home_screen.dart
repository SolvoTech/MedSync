import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/extensions/datetime_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_widget.dart';
import '../../core/widgets/app_loading_skeleton.dart';
import '../../data/remote/supabase_client.dart';
import '../../domain/models/user_streak.dart';
import 'home_controller.dart';
import 'widgets/home_permissions_banner.dart';
import 'widgets/today_task_card.dart';

final streakProvider = FutureProvider<UserStreak?>((ref) async {
  final client = SupabaseClientRef.maybeClient;
  if (client == null) return null;
  final user = client.auth.currentUser;
  if (user == null) return null;

  final row = await client
      .from('user_streaks')
      .select()
      .eq('owner_id', user.id)
      .maybeSingle();

  if (row == null) return null;
  return UserStreak.fromMap(row);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return AppStrings.homeGreetingMorning;
    if (hour >= 11 && hour < 15) return AppStrings.homeGreetingAfternoon;
    if (hour >= 15 && hour < 18) return AppStrings.homeGreetingEvening;
    return AppStrings.homeGreetingNight;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksState = ref.watch(todayTasksProvider);
    final streakState = ref.watch(streakProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(streakProvider);
          await ref.read(todayTasksProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            // App Bar with greeting
            SliverAppBar(
              floating: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: textTheme.titleMedium,
                  ),
                  Text(
                    DateTime.now().toFullIndonesianDate(),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              toolbarHeight: 72,
            ),

            // Permissions Banner (if needed)
            const SliverToBoxAdapter(
              child: HomePermissionsBanner(),
            ),

            // Streak Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: streakState.when(
                  data: (streak) => _StreakCard(streak: streak),
                  loading: () => const AppLoadingSkeleton(
                    width: double.infinity,
                    height: 80,
                    borderRadius: 16,
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Quick Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: tasksState.when(
                  data: (tasks) {
                    final total = tasks.length;
                    final completed = tasks
                        .where((t) =>
                            t.status == 'done' || t.status == 'skipped')
                        .length;
                    final percent =
                        total > 0 ? (completed / total * 100).round() : 0;

                    return AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              label: 'Selesai',
                              value: '$completed/$total',
                              icon: Icons.check_circle_outline,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: colorScheme.outlineVariant,
                          ),
                          Expanded(
                            child: _StatItem(
                              label: 'Progres',
                              value: '$percent%',
                              icon: Icons.trending_up,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const AppLoadingSkeleton(
                    width: double.infinity,
                    height: 64,
                    borderRadius: 16,
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  AppStrings.todayTasks,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Task List
            tasksState.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const SliverFillRemaining(
                    child: AppEmptyState(
                      message: AppStrings.noTasksToday,
                      icon: Icons.task_alt,
                      subtitle: 'Tambahkan jadwal obat atau aktivitas\nuntuk mulai melacak kesehatan Anda.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TodayTaskCard(
                        task: task,
                        onDone: () async {
                          await ref
                              .read(todayTasksProvider.notifier)
                              .markDone(task.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(AppStrings.taskDone),
                              ),
                            );
                          }
                        },
                        onSkip: () async {
                          await ref
                              .read(todayTasksProvider.notifier)
                              .markSkipped(task.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(AppStrings.taskSkipped),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: List.generate(
                      3,
                      (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: AppLoadingSkeleton(
                          width: double.infinity,
                          height: 72,
                          borderRadius: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              error: (error, _) => SliverFillRemaining(
                child: AppErrorWidget(
                  message: 'Gagal memuat tugas hari ini',
                  onRetry: () => ref.invalidate(todayTasksProvider),
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({this.streak});
  final UserStreak? streak;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentStreak = streak?.currentStreak ?? 0;
    final message =
        streak?.motivationMessage ?? 'Mulai hari pertamamu hari ini!';

    return AppCard(
      color: currentStreak >= 7
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Text(
            currentStreak >= 7 ? '🔥' : '💪',
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$currentStreak',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.streakDays,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
                Text(
                  message,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
