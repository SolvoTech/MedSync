import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/user_error_message.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../auth/auth_controller.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() =>
      _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  bool _isExporting = false;
  bool _isDeleting = false;

  Future<void> _exportDataJson() async {
    setState(() => _isExporting = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Please sign in first');

      // Fetch all user-owned data
      final medicines = await client
          .from('medicines')
          .select()
          .eq('owner_id', user.id);
      final tasks = await client
          .from('task_logs')
          .select()
          .eq('owner_id', user.id);

      final medicineCount = (medicines as List).length;
      final taskCount = (tasks as List).length;

      if (mounted) {
        context.showSuccessSnackBar(
          AppStrings.tr(
            'Data exported successfully ($medicineCount medicines, $taskCount logs).',
            'Data berhasil diekspor ($medicineCount obat, $taskCount log).',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(
          toUserErrorMessage(
            e,
            fallback: AppStrings.tr(
              'Failed to export data. Please try again.',
              'Gagal mengekspor data. Silakan coba lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: AppStrings.tr('Delete Account Permanently', 'Hapus Akun Permanen'),
      message: AppStrings.tr(
        'All your data including medication schedules, history, and profile will be permanently deleted and cannot be restored.\n\nAre you sure?',
        'Semua data Anda termasuk jadwal obat, riwayat, dan profil akan dihapus secara permanen dan tidak dapat dikembalikan.\n\nApakah Anda yakin?',
      ),
      confirmLabel: AppStrings.tr('Delete Account', 'Hapus Akun'),
      isDestructive: true,
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // Second confirmation
    final confirmed2 = await AppDialog.showConfirm(
      context,
      title: AppStrings.tr('Final Confirmation', 'Konfirmasi Akhir'),
      message: AppStrings.tr(
        'This action cannot be undone. Tap "Delete" to continue.',
        'Tindakan ini tidak dapat dibatalkan. Ketuk "Hapus" untuk melanjutkan.',
      ),
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );

    if (confirmed2 != true) return;

    if (!mounted) return;

    setState(() => _isDeleting = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('You must be signed in first.');
      }

      // Delete auth account first so the email can be reused for sign up.
      // Related app data is removed via FK cascade from profiles -> auth.users.
      await client.rpc('delete_my_account');

      // End local session after deletion; ignore if token is already invalid.
      try {
        await ref.read(authControllerProvider.notifier).signOut();
      } catch (_) {}

      if (mounted) {
        context.showSuccessSnackBar(
          AppStrings.tr(
            'Account data deleted permanently.',
            'Data akun berhasil dihapus secara permanen.',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(
          toUserErrorMessage(
            e,
            fallback: AppStrings.tr(
              'Failed to delete account. Please try again.',
              'Gagal menghapus akun. Silakan coba lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.dataManagement)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppStrings.tr('EXPORT DATA', 'EKSPOR DATA'),
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.download),
              title: Text(
                AppStrings.tr('Export Data JSON', 'Ekspor Data JSON'),
              ),
              subtitle: Text(
                AppStrings.tr(
                  'Download all your data in JSON format',
                  'Unduh semua data Anda dalam format JSON',
                ),
              ),
              trailing: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _isExporting ? null : _exportDataJson,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            AppStrings.tr('DANGER ZONE', 'ZONA BAHAYA'),
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.error,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.tr('Delete Account', 'Hapus Akun'),
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.tr(
                    'Deleting your account will permanently remove all your data, including profile, medication schedules, history, and all related records.',
                    'Menghapus akun akan menghapus semua data Anda secara permanen, termasuk profil, jadwal obat, riwayat, dan semua data lainnya.',
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: AppStrings.deleteAccount,
                  onPressed: _deleteAccount,
                  isLoading: _isDeleting,
                  isDestructive: true,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
