import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../services/health_connect_service.dart';

/// State for Health Connect authorization.
final healthConnectAuthorizedProvider = StateProvider<bool>((ref) => false);

/// State for Health Connect availability.
final healthConnectAvailableProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  return HealthConnectService.isAvailable();
});

/// Provider for today's step count.
final todayStepsProvider = FutureProvider.autoDispose<int>((ref) async {
  final authorized = ref.watch(healthConnectAuthorizedProvider);
  if (!authorized) return 0;
  return HealthConnectService.getTodaySteps();
});

class HealthConnectScreen extends ConsumerWidget {
  const HealthConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAsync = ref.watch(healthConnectAvailableProvider);
    final authorized = ref.watch(healthConnectAuthorizedProvider);
    final stepsAsync = ref.watch(todayStepsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final compact = MediaQuery.sizeOf(context).width < 340;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Connect',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: availableAsync.when(
        data: (available) {
          if (!available) {
            return const AppEmptyState(
              icon: Icons.health_and_safety_outlined,
              message: 'Health Connect tidak tersedia',
              subtitle:
                  'Perangkat Anda belum mendukung Health Connect. Pastikan Health Connect terinstall.',
            );
          }

          return ListView(
            padding: EdgeInsets.all(compact ? 12 : 16),
            children: [
              // Status card
              AppCard(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stackButton = constraints.maxWidth < 300;
                    final statusContent = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          authorized ? Icons.check_circle : Icons.info_outline,
                          color: authorized
                              ? Colors.green
                              : colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authorized ? 'Terhubung' : 'Belum Terhubung',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                authorized
                                    ? 'Data kesehatan tersinkronisasi.'
                                    : 'Hubungkan untuk akses data kesehatan.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                    final connectButton = AppButton(
                      label: 'Hubungkan',
                      isFullWidth: stackButton,
                      onPressed: () async {
                        final ok =
                            await HealthConnectService.requestAuthorization();
                        ref
                                .read(healthConnectAuthorizedProvider.notifier)
                                .state =
                            ok;
                      },
                    );

                    if (authorized) {
                      return statusContent;
                    }

                    if (stackButton) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          statusContent,
                          const SizedBox(height: 12),
                          connectButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: statusContent),
                        const SizedBox(width: 12),
                        connectButton,
                      ],
                    );
                  },
                ),
              ),

              if (authorized) ...[
                const SizedBox(height: 16),

                Text(
                  'DATA HARI INI',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),

                // Steps card
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue.withValues(alpha: 0.12),
                        child: const Icon(
                          Icons.directions_walk,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Langkah', style: textTheme.labelMedium),
                            stepsAsync.when(
                              data: (steps) => Text(
                                '$steps langkah',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              loading: () =>
                                  const CircularProgressIndicator.adaptive(),
                              error: (_, error) => const Text(
                                'Gagal memuat data. Silakan coba lagi.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Supported data types
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data yang Didukung',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _DataChip('Langkah', Icons.directions_walk),
                          _DataChip('Detak Jantung', Icons.favorite),
                          _DataChip('Tekanan Darah', Icons.monitor_heart),
                          _DataChip('Gula Darah', Icons.bloodtype),
                          _DataChip('Suhu Tubuh', Icons.thermostat),
                          _DataChip('Berat Badan', Icons.scale),
                          _DataChip('Kalori', Icons.local_fire_department),
                          _DataChip('Tidur', Icons.bedtime_outlined),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, error) => const AppEmptyState(
          icon: Icons.error_outline,
          message: 'Gagal memeriksa Health Connect. Silakan coba lagi.',
        ),
      ),
    );
  }
}

class _DataChip extends StatelessWidget {
  const _DataChip(this.label, this.icon);
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.5,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
