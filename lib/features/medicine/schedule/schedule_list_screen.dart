import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../measurement/measurement_controller.dart';
import '../../physical_activity/activity_controller.dart';
import 'schedule_controller.dart';
import 'widgets/activity_tab.dart';
import 'widgets/care_person_filter.dart';
import 'widgets/measurement_tab.dart';
import 'widgets/medicine_tab.dart';

enum ScheduleSection { medicine, measurement, activity }

class ScheduleListScreen extends ConsumerStatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  ConsumerState<ScheduleListScreen> createState() =>
      _ScheduleListScreenState();
}

class _ScheduleListScreenState extends ConsumerState<ScheduleListScreen> {
  ScheduleSection _selected = ScheduleSection.medicine;

  static const _pages = [MedicineTab(), MeasurementTab(), ActivityTab()];

  void _onCarePersonSelected(String? carePersonId) {
    // Update all three filter providers simultaneously
    ref.read(medicineCarePersonFilterProvider.notifier).state = carePersonId;
    ref.read(measurementCarePersonFilterProvider.notifier).state = carePersonId;
    ref.read(activityCarePersonFilterProvider.notifier).state = carePersonId;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final appBarTitleStyle = textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: colorScheme.onSurface,
    );

    // Watch the current filter (any of them since they're synced)
    final selectedCarePersonId = ref.watch(medicineCarePersonFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.scheduleTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: appBarTitleStyle,
        ),
      ),
      body: Column(
        children: [
          // Care person filter
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: CarePersonFilter(
              selectedCarePersonId: selectedCarePersonId,
              onSelected: _onCarePersonSelected,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 16,
              4,
              compact ? 12 : 16,
              0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                child: SegmentedButton<ScheduleSection>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: WidgetStatePropertyAll(
                      EdgeInsets.symmetric(
                        horizontal: compact ? 6 : 8,
                        vertical: compact ? 9 : 10,
                      ),
                    ),
                    textStyle: WidgetStatePropertyAll(
                      TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  segments: [
                    ButtonSegment(
                      value: ScheduleSection.medicine,
                      label: Text(
                        AppStrings.scheduleTabMedicine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ButtonSegment(
                      value: ScheduleSection.measurement,
                      label: Text(
                        AppStrings.scheduleTabMeasurement,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ButtonSegment(
                      value: ScheduleSection.activity,
                      label: Text(
                        AppStrings.scheduleTabActivity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  selected: {_selected},
                  onSelectionChanged: (selected) {
                    setState(() => _selected = selected.first);
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 10 : 12),
          Expanded(child: _pages[_selected.index]),
        ],
      ),
    );
  }
}
