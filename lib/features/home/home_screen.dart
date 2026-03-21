import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_strings.dart';
import '../../core/extensions/context_ext.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(streakProvider);
          await ref.read(todayTasksProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            // Gradient Hero App Bar
            SliverAppBar(
              floating: true,
              expandedHeight: 132,
              toolbarHeight: 64,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryFor(
                    isDark ? Brightness.dark : Brightness.light,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circle
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: -15,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                    // Content
                    SafeArea(
                      bottom: false,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxHeight < 64;
                          final showDate = constraints.maxHeight >= 76;

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _greeting(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        (isCompact
                                                ? textTheme.titleMedium
                                                : textTheme.titleLarge)
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                  ),
                                  if (showDate) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat(
                                        'EEEE, d MMMM yyyy',
                                        AppStrings.languageCode == 'id'
                                            ? 'id_ID'
                                            : 'en_US',
                                      ).format(DateTime.now()),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Permissions Banner (if needed)
            const SliverToBoxAdapter(child: HomePermissionsBanner()),

            // Streak Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: streakState.when(
                  data: (streak) => _StreakCard(streak: streak),
                  loading: () => const AppLoadingSkeleton(
                    width: double.infinity,
                    height: 80,
                    borderRadius: 20,
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
                        .where(
                          (t) => t.status == 'done' || t.status == 'skipped',
                        )
                        .length;
                    final percent = total > 0
                        ? (completed / total * 100).round()
                        : 0;

                    return AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              label: AppStrings.completedLabel,
                              value: '$completed/$total',
                              icon: Icons.check_circle_outline,
                              color: AppColors.success,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          Expanded(
                            child: _StatItem(
                              label: AppStrings.progressLabel,
                              value: '$percent%',
                              icon: Icons.trending_up,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const AppLoadingSkeleton(
                    width: double.infinity,
                    height: 64,
                    borderRadius: 20,
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.todayTasks,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Task List
            tasksState.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return SliverFillRemaining(
                    child: AppEmptyState(
                      message: AppStrings.noTasksToday,
                      icon: Icons.task_alt,
                      subtitle: AppStrings.tr(
                        'Add medication or activity schedules\nto start tracking your health.',
                        'Tambahkan jadwal obat atau aktivitas\nuntuk mulai melacak kesehatan Anda.',
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TodayTaskCard(
                        task: task,
                        onDone: () async {
                          await ref
                              .read(todayTasksProvider.notifier)
                              .markDone(task.id);
                          if (context.mounted) {
                            context.showSuccessSnackBar(AppStrings.taskDone);
                          }
                        },
                        onSkip: () async {
                          await ref
                              .read(todayTasksProvider.notifier)
                              .markSkipped(task.id);
                          if (context.mounted) {
                            context.showInfoSnackBar(AppStrings.taskSkipped);
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
                          borderRadius: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              error: (error, _) => SliverFillRemaining(
                child: AppErrorWidget(
                  message: AppStrings.tasksLoadFailed,
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
    final message = streak?.motivationMessage ?? AppStrings.firstDayMotivation;
    final isHot = currentStreak >= 7;

    return AppCard(
      gradient: isHot
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF6B35), Color(0xFFE53E3E)],
            )
          : null,
      color: isHot ? null : colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isHot
                  ? Colors.white.withValues(alpha: 0.2)
                  : colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isHot ? '🔥' : '💪',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$currentStreak',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isHot ? Colors.white : colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.streakDays,
                      style: textTheme.bodyMedium?.copyWith(
                        color: isHot
                            ? Colors.white.withValues(alpha: 0.9)
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  message,
                  style: textTheme.bodySmall?.copyWith(
                    color: isHot
                        ? Colors.white.withValues(alpha: 0.8)
                        : colorScheme.onSurface.withValues(alpha: 0.6),
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
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
