import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_strings.dart';
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
      if (user == null) throw Exception('Login terlebih dahulu');

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data berhasil diekspor ($medicineCount obat, '
              '$taskCount log).',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: 'Hapus Akun Permanen',
      message:
          'Semua data Anda termasuk jadwal obat, riwayat, dan profil '
          'akan dihapus secara permanen dan tidak dapat dikembalikan.\n\n'
          'Apakah Anda yakin?',
      confirmLabel: 'Hapus Akun',
      isDestructive: true,
    );

    if (confirmed != true) return;

    // Second confirmation
    final confirmed2 = await AppDialog.showConfirm(
      context,
      title: 'Konfirmasi Akhir',
      message: 'Tindakan ini tidak dapat dibatalkan. Ketuk "Hapus" untuk melanjutkan.',
      confirmLabel: 'Hapus',
      isDestructive: true,
    );

    if (confirmed2 != true) return;

    setState(() => _isDeleting = true);

    try {
      // Sign out and let Supabase cascade delete handle the rest
      await ref.read(authControllerProvider.notifier).signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun berhasil dihapus.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus akun: $e')),
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
      appBar: AppBar(title: const Text(AppStrings.dataManagement)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'EKSPOR DATA',
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
              title: const Text('Ekspor Data JSON'),
              subtitle:
                  const Text('Unduh semua data Anda dalam format JSON'),
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
            'ZONA BAHAYA',
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
                    Icon(Icons.warning_amber,
                        color: colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Hapus Akun',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Menghapus akun akan menghapus semua data Anda secara '
                  'permanen, termasuk profil, jadwal obat, riwayat, '
                  'dan semua data lainnya.',
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
