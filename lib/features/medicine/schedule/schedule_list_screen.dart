import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import 'widgets/activity_tab.dart';
import 'widgets/measurement_tab.dart';
import 'widgets/medicine_tab.dart';

class ScheduleListScreen extends StatelessWidget {
  const ScheduleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.scheduleTitle),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Obat'),
              Tab(text: 'Pengukuran'),
              Tab(text: 'Aktivitas Fisik'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [MedicineTab(), MeasurementTab(), ActivityTab()],
        ),
      ),
    );
  }
}
