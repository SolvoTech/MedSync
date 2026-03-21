import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import 'widgets/activity_tab.dart';
import 'widgets/measurement_tab.dart';
import 'widgets/medicine_tab.dart';

enum ScheduleSection { medicine, measurement, activity }

class ScheduleListScreen extends StatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  State<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  ScheduleSection _selected = ScheduleSection.medicine;

  static const _pages = [MedicineTab(), MeasurementTab(), ActivityTab()];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final appBarTitleStyle = textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: colorScheme.onSurface,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.scheduleTitle, style: appBarTitleStyle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ScheduleSection>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                segments: [
                  ButtonSegment(
                    value: ScheduleSection.medicine,
                    label: Text(AppStrings.scheduleTabMedicine, maxLines: 1),
                  ),
                  ButtonSegment(
                    value: ScheduleSection.measurement,
                    label: Text(AppStrings.scheduleTabMeasurement, maxLines: 1),
                  ),
                  ButtonSegment(
                    value: ScheduleSection.activity,
                    label: Text(AppStrings.scheduleTabActivity, maxLines: 1),
                  ),
                ],
                selected: {_selected},
                onSelectionChanged: (selected) {
                  setState(() => _selected = selected.first);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _pages[_selected.index]),
        ],
      ),
    );
  }
}
