import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      appBar: AppBar(title: const Text('Akses Dibagikan')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Buat Akses'),
        onPressed: () => _createToken(context, ref),
      ),
      body: tokensState.when(
        data: (tokens) {
          if (tokens.isEmpty) {
            return const AppEmptyState(
              icon: Icons.share_outlined,
              message: 'Belum ada akses dibagikan',
              subtitle: 'Buat akses agar keluarga bisa memantau status.',
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
                  carePerson['display_name'] as String? ?? 'Tidak diketahui';
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
                          Icon(Icons.visibility_outlined,
                              size: 20, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            displayName,
                            style: textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isActive ? Colors.green : Colors.grey)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? 'Aktif' : 'Nonaktif',
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
                          'Terakhir dilihat: ${_formatRelative(lastAccessed)}',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Salin'),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: tokenDisplay));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Kode disalin')),
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
                                  isActive ? 'Nonaktifkan' : 'Aktifkan'),
                              onPressed: () => _toggleActive(
                                  context, ref, token['id'] as String,
                                  isActive),
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
        loading: () =>
            const AppListSkeleton(itemCount: 3, itemHeight: 120),
        error: (e, _) => AppErrorWidget(
          message: 'Gagal memuat data akses',
          onRetry: () => ref.invalidate(sharedTokensProvider),
        ),
      ),
    );
  }

  Future<void> _createToken(BuildContext context, WidgetRef ref) async {
    // For simplicity, generate a random token
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rawToken = List.generate(6, (_) => chars[random.nextInt(chars.length)])
        .join();
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Tambahkan anggota terlebih dahulu.')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Token $displayToken berhasil dibuat')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat token: $e')),
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
          .update({'is_active': !currentlyActive}).eq('id', tokenId);

      ref.invalidate(sharedTokensProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui: $e')),
        );
      }
    }
  }

  String _formatRelative(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
