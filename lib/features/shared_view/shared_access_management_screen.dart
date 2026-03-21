import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/user_error_message.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/app_loading_skeleton.dart';

/// Provider for shared access tokens owned by current user.
final sharedTokensProvider = FutureProvider.autoDispose((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return <Map<String, dynamic>>[];

  final rows = await client
      .from('shared_access_tokens')
      .select('*, care_persons(display_name)')
      .eq('owner_id', user.id)
      .order('created_at', ascending: false);

  return (rows as List).cast<Map<String, dynamic>>();
});

class SharedAccessManagementScreen extends ConsumerWidget {
  const SharedAccessManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokensState = ref.watch(sharedTokensProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr('Shared Access', 'Akses Dibagikan')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(AppStrings.tr('Create Access', 'Buat Akses')),
        onPressed: () => _createToken(context, ref),
      ),
      body: tokensState.when(
        data: (tokens) {
          if (tokens.isEmpty) {
            return AppEmptyState(
              icon: Icons.share_outlined,
              message: AppStrings.tr(
                'No shared access yet',
                'Belum ada akses dibagikan',
              ),
              subtitle: AppStrings.tr(
                'Create access so family can monitor status.',
                'Buat akses agar keluarga bisa memantau status.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tokens.length,
            itemBuilder: (context, index) {
              final token = tokens[index];
              final carePerson =
                  token['care_persons'] as Map<String, dynamic>? ?? {};
              final displayName =
                  carePerson['display_name'] as String? ??
                  AppStrings.tr('Unknown', 'Tidak diketahui');
              final tokenDisplay =
                  token['token_display'] as String? ?? token['token'] ?? '';
              final isActive = token['is_active'] as bool? ?? true;
              final lastAccessed = token['last_accessed_at'] as String?;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            displayName,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (isActive ? Colors.green : Colors.grey)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive
                                  ? AppStrings.statusActive
                                  : AppStrings.statusInactive,
                              style: textTheme.labelSmall?.copyWith(
                                color: isActive ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tokenDisplay,
                        style: textTheme.titleMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      if (lastAccessed != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${AppStrings.tr('Last viewed', 'Terakhir dilihat')}: ${_formatRelative(lastAccessed)}',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.copy, size: 16),
                              label: Text(AppStrings.tr('Copy', 'Salin')),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: tokenDisplay),
                                );
                                context.showInfoSnackBar(
                                  AppStrings.tr(
                                    'Code copied.',
                                    'Kode disalin.',
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(
                                isActive
                                    ? Icons.block
                                    : Icons.check_circle_outline,
                                size: 16,
                              ),
                              label: Text(
                                isActive
                                    ? AppStrings.disableAction
                                    : AppStrings.reactivate,
                              ),
                              onPressed: () => _toggleActive(
                                context,
                                ref,
                                token['id'] as String,
                                isActive,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const AppListSkeleton(itemCount: 3, itemHeight: 120),
        error: (e, _) => AppErrorWidget(
          message: AppStrings.tr(
            'Failed to load access data',
            'Gagal memuat data akses',
          ),
          onRetry: () => ref.invalidate(sharedTokensProvider),
        ),
      ),
    );
  }

  Future<void> _createToken(BuildContext context, WidgetRef ref) async {
    // For simplicity, generate a random token
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rawToken = List.generate(
      6,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    final displayToken = 'MED-$rawToken';

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      // Get first care person as default
      final carePersons = await client
          .from('care_persons')
          .select('id')
          .eq('owner_id', user.id)
          .limit(1);

      if ((carePersons as List).isEmpty) {
        if (context.mounted) {
          context.showWarningSnackBar(
            AppStrings.tr(
              'Add a member first.',
              'Tambahkan anggota terlebih dahulu.',
            ),
          );
        }
        return;
      }

      await client.from('shared_access_tokens').insert({
        'owner_id': user.id,
        'care_person_id': carePersons[0]['id'],
        'token': rawToken,
        'token_display': displayToken,
      });

      ref.invalidate(sharedTokensProvider);

      if (context.mounted) {
        context.showSuccessSnackBar(
          AppStrings.tr(
            'Token $displayToken created successfully.',
            'Token $displayToken berhasil dibuat.',
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar(
          toUserErrorMessage(
            e,
            fallback: AppStrings.tr(
              'Failed to create access token. Please try again.',
              'Gagal membuat token akses. Silakan coba lagi.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    String tokenId,
    bool currentlyActive,
  ) async {
    try {
      await Supabase.instance.client
          .from('shared_access_tokens')
          .update({'is_active': !currentlyActive})
          .eq('id', tokenId);

      ref.invalidate(sharedTokensProvider);
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar(
          toUserErrorMessage(
            e,
            fallback: AppStrings.tr(
              'Failed to update access data. Please try again.',
              'Gagal memperbarui data akses. Silakan coba lagi.',
            ),
          ),
        );
      }
    }
  }

  String _formatRelative(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) {
        return AppStrings.tr(
          '${diff.inMinutes} min ago',
          '${diff.inMinutes} menit lalu',
        );
      }
      if (diff.inHours < 24) {
        return AppStrings.tr(
          '${diff.inHours} hours ago',
          '${diff.inHours} jam lalu',
        );
      }
      if (diff.inDays < 7) {
        return AppStrings.tr(
          '${diff.inDays} days ago',
          '${diff.inDays} hari lalu',
        );
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
