import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/extensions/string_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/app_loading_skeleton.dart';
import '../../../data/remote/datasources/care_person_remote_datasource.dart';
import '../../../domain/models/care_person.dart';
import 'care_person_form_screen.dart';

final carePersonDataSourceProvider = Provider<CarePersonRemoteDataSource>(
  (ref) => CarePersonRemoteDataSource(),
);

final carePersonListProvider =
    AutoDisposeAsyncNotifierProvider<
      CarePersonListController,
      List<CarePerson>
    >(CarePersonListController.new);

class CarePersonListController
    extends AutoDisposeAsyncNotifier<List<CarePerson>> {
  @override
  Future<List<CarePerson>> build() => _fetch();

  Future<List<CarePerson>> _fetch() =>
      ref.read(carePersonDataSourceProvider).getCarePersons();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> delete(String id) async {
    await ref.read(carePersonDataSourceProvider).deleteCarePerson(id);
    await refresh();
  }
}

class CarePersonListScreen extends ConsumerWidget {
  const CarePersonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(carePersonListProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.carePersons)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(carePersonListProvider.notifier).refresh(),
        child: listState.when(
          data: (persons) {
            if (persons.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: 80),
                  AppEmptyState(
                    message: 'Belum ada anggota yang ditambahkan',
                    subtitle:
                        'Tambahkan anggota keluarga\nuntuk membantu mengelola kesehatan mereka.',
                    icon: Icons.people_outline,
                    actionLabel: AppStrings.addCarePerson,
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: persons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final person = persons[index];
                final avatarColor = person.avatarColor != null
                    ? Color(
                        int.parse(
                          '0xFF${person.avatarColor!.replaceFirst('#', '')}',
                        ),
                      )
                    : colorScheme.primaryContainer;

                return AppCard(
                  onTap: () => _openForm(context, ref, existing: person),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: avatarColor,
                        child: Text(
                          person.displayName.initials,
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.displayName,
                              style: textTheme.titleSmall,
                            ),
                            if (person.relationship != null)
                              Text(
                                person.relationship!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openForm(context, ref, existing: person);
                          } else if (value == 'delete') {
                            _confirmDelete(context, ref, person);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Hapus',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const AppListSkeleton(itemCount: 3, itemHeight: 80),
          error: (e, _) => AppErrorWidget(
            message: 'Gagal memuat daftar anggota. Silakan coba lagi.',
            onRetry: () => ref.invalidate(carePersonListProvider),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.person_add),
        label: Text(AppStrings.addCarePerson),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    CarePerson? existing,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CarePersonFormScreen(existing: existing),
      ),
    );

    if (result == true) {
      ref.read(carePersonListProvider.notifier).refresh();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CarePerson person,
  ) async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: 'Hapus Anggota',
      message:
          'Hapus ${person.displayName}? Semua data terkait akan ikut dihapus.',
      confirmLabel: 'Hapus',
      isDestructive: true,
    );

    if (confirmed == true) {
      await ref.read(carePersonListProvider.notifier).delete(person.id);
      if (context.mounted) {
        context.showSuccessSnackBar('${person.displayName} dihapus.');
      }
    }
  }
}
