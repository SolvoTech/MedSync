import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/type_labels.dart';
import '../../core/errors/user_error_message.dart';
import '../../core/observability/app_monitoring.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_widget.dart';
import '../../core/widgets/app_loading_skeleton.dart';
import '../../data/remote/datasources/admin_user_activity_remote_datasource.dart';
import 'widgets/admin_ui.dart';

part 'admin_user_activity_widgets.dart';

final adminUserActivityDataSourceProvider =
    Provider<AdminUserActivityRemoteDataSource>((ref) {
      return AdminUserActivityRemoteDataSource();
    });

final adminUserActivityPeriodProvider = StateProvider.autoDispose
    .family<AdminActivityPeriod, String>((ref, userId) {
      return AdminActivityPeriod.today;
    });

final adminUserActivityDataProvider = FutureProvider.autoDispose
    .family<AdminUserActivityData, AdminUserActivityArgs>((ref, args) async {
      try {
        return await ref
            .read(adminUserActivityDataSourceProvider)
            .getUserActivity(userId: args.userId, period: args.period);
      } catch (error, stackTrace) {
        unawaited(
          AppMonitoring.logQueryFailure(
            source: 'admin_user_activity_screen',
            event: 'admin_user_activity_query_failed',
            error: error,
            stackTrace: stackTrace,
            metadata: {
              'target_user_id': args.userId,
              'period': args.period.name,
            },
          ),
        );
        rethrow;
      }
    });

class AdminUserActivityArgs {
  const AdminUserActivityArgs({required this.userId, required this.period});

  final String userId;
  final AdminActivityPeriod period;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminUserActivityArgs &&
        other.userId == userId &&
        other.period == period;
  }

  @override
  int get hashCode => Object.hash(userId, period);
}

class AdminUserActivityScreen extends ConsumerWidget {
  const AdminUserActivityScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            AppStrings.adminUserActivityTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: AppEmptyState(
          message: AppStrings.adminUserActivityInvalidUser,
          subtitle: AppStrings.adminUserActivityInvalidUserHint,
          icon: Icons.person_off_outlined,
        ),
      );
    }

    final period = ref.watch(adminUserActivityPeriodProvider(userId));
    final args = AdminUserActivityArgs(userId: userId, period: period);
    final state = ref.watch(adminUserActivityDataProvider(args));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.adminUserActivityTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.adminRefreshTooltip,
            onPressed: () =>
                ref.invalidate(adminUserActivityDataProvider(args)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminUserActivityDataProvider(args));
          await ref.read(adminUserActivityDataProvider(args).future);
        },
        child: state.when(
          loading: () => const _AdminUserActivityLoading(),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              AppErrorWidget(
                message: toUserErrorMessage(error),
                onRetry: () =>
                    ref.invalidate(adminUserActivityDataProvider(args)),
              ),
            ],
          ),
          data: (data) {
            final media = MediaQuery.of(context);
            final isCompact =
                media.size.width < 390 || media.textScaler.scale(1) > 1.1;
            final padding = EdgeInsets.fromLTRB(
              isCompact ? 12 : 16,
              isCompact ? 10 : 12,
              isCompact ? 12 : 16,
              isCompact ? 20 : 24,
            );

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: padding,
              children: [
                AdminIntroCard(
                  icon: Icons.person_search_outlined,
                  title: data.user.fullName,
                  subtitle: AppStrings.adminUserActivityProfileSubtitle(
                    username: data.user.username,
                    status: _statusLabel(data.user.accountStatus),
                  ),
                  badge: _statusLabel(data.user.accountStatus),
                  accentColor: data.user.accountStatus == 'suspended'
                      ? const Color(0xFFC53030)
                      : const Color(0xFF2F855A),
                ),
                const SizedBox(height: 14),
                AdminSectionTitle(
                  title: AppStrings.adminUserActivityPeriodSectionTitle,
                  subtitle: AppStrings.adminAdherenceStrictHint,
                  icon: Icons.date_range_outlined,
                ),
                const SizedBox(height: 8),
                _PeriodSelector(
                  selected: period,
                  onChanged: (next) {
                    ref
                            .read(
                              adminUserActivityPeriodProvider(userId).notifier,
                            )
                            .state =
                        next;
                  },
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.timeline_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppStrings.adminUserActivityRangeLabel(
                            _formatRange(
                              data.rangeStart,
                              data.rangeEnd,
                              AppStrings.languageCode == 'id'
                                  ? 'id_ID'
                                  : 'en_US',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SummaryGrid(data: data),
                const SizedBox(height: 16),
                AdminSectionTitle(
                  title: AppStrings.adminTaskProofSection,
                  subtitle: AppStrings.adminTaskProofSectionHint,
                  icon: Icons.photo_camera_outlined,
                ),
                const SizedBox(height: 8),
                _CompletionProofsList(items: data.completionProofs),
                const SizedBox(height: 14),
                AdminCollapsibleSection(
                  title: AppStrings.adminUserActivityMedicineSection,
                  icon: Icons.medication_outlined,
                  subtitle: AppStrings.tr(
                    '${data.medicineSchedules.length} schedules. ${AppStrings.adminUserActivityMedicineSectionHint}',
                    '${data.medicineSchedules.length} jadwal. ${AppStrings.adminUserActivityMedicineSectionHint}',
                  ),
                  child: _MedicineSchedulesList(items: data.medicineSchedules),
                ),
                const SizedBox(height: 14),
                AdminCollapsibleSection(
                  title: AppStrings.adminUserActivityMeasurementSection,
                  icon: Icons.monitor_heart_outlined,
                  subtitle: AppStrings.tr(
                    '${data.measurementSchedules.length} schedules. ${AppStrings.adminUserActivityMeasurementSectionHint}',
                    '${data.measurementSchedules.length} jadwal. ${AppStrings.adminUserActivityMeasurementSectionHint}',
                  ),
                  child: _MeasurementSchedulesList(
                    items: data.measurementSchedules,
                  ),
                ),
                const SizedBox(height: 14),
                AdminCollapsibleSection(
                  title: AppStrings.adminUserActivityActivitySection,
                  icon: Icons.directions_walk_outlined,
                  subtitle: AppStrings.tr(
                    '${data.activitySchedules.length} schedules. ${AppStrings.adminUserActivityActivitySectionHint}',
                    '${data.activitySchedules.length} jadwal. ${AppStrings.adminUserActivityActivitySectionHint}',
                  ),
                  child: _ActivitySchedulesList(items: data.activitySchedules),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    return status == 'suspended'
        ? AppStrings.adminStatusSuspended
        : AppStrings.adminStatusActive;
  }

  String _formatRange(DateTime start, DateTime end, String locale) {
    final formatter = DateFormat('dd MMM yyyy', locale);
    final endExclusive = end.subtract(const Duration(days: 1));
    return '${formatter.format(start)} - ${formatter.format(endExclusive)}';
  }
}
