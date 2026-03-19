import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import 'widgets/activity_tab.dart';
import 'widgets/measurement_tab.dart';
import 'widgets/medicine_tab.dart';

class ScheduleListScreen extends StatelessWidget {
  const ScheduleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.scheduleTitle),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: TabBar(
                  isScrollable: false,
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.zero,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurface,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Obat'),
                    Tab(text: 'Pengukuran'),
                    Tab(text: 'Aktivitas'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [MedicineTab(), MeasurementTab(), ActivityTab()],
        ),
      ),
    );
  }
}
