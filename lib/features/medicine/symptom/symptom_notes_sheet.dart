import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/user_error_message.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/app_button.dart';

/// Bottom sheet shown after marking a medicine task as done.
/// Collects optional mood + symptom notes per spec §15.2.
class SymptomNotesSheet extends ConsumerStatefulWidget {
  const SymptomNotesSheet({
    super.key,
    required this.taskLogId,
    required this.medicineName,
  });

  final String taskLogId;
  final String medicineName;

  /// Show as a modal bottom sheet and return true if saved.
  static Future<bool?> show(
    BuildContext context, {
    required String taskLogId,
    required String medicineName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: SymptomNotesSheet(
              taskLogId: taskLogId,
              medicineName: medicineName,
            ),
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<SymptomNotesSheet> createState() => _SymptomNotesSheetState();
}

class _SymptomNotesSheetState extends ConsumerState<SymptomNotesSheet> {
  String? _mood;
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final updates = <String, dynamic>{};
      if (_mood != null) updates['mood'] = _mood;
      if (_notesController.text.trim().isNotEmpty) {
        updates['symptom_notes'] = _notesController.text.trim();
      }

      if (updates.isNotEmpty) {
        await Supabase.instance.client
            .from('task_logs')
            .update(updates)
            .eq('id', widget.taskLogId);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(
          toUserErrorMessage(
            e,
            fallback: AppStrings.tr(
              'Failed to save notes. Please try again.',
              'Gagal menyimpan catatan. Silakan coba lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final compact = MediaQuery.sizeOf(context).width < 340;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 20,
        16,
        compact ? 14 : 20,
        20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Success indication
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.tr(
                    '${widget.medicineName} marked successfully',
                    '${widget.medicineName} berhasil dicatat',
                  ),
                  style: textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mood section
          Text(
            AppStrings.tr(
              'How are you feeling right now?',
              'Bagaimana kondisimu sekarang?',
            ),
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _MoodChip(
                emoji: '😊',
                label: AppStrings.tr('Good', 'Baik'),
                value: 'good',
                selected: _mood == 'good',
                onTap: () =>
                    setState(() => _mood = _mood == 'good' ? null : 'good'),
              ),
              _MoodChip(
                emoji: '😐',
                label: AppStrings.tr('Neutral', 'Biasa'),
                value: 'neutral',
                selected: _mood == 'neutral',
                onTap: () => setState(
                  () => _mood = _mood == 'neutral' ? null : 'neutral',
                ),
              ),
              _MoodChip(
                emoji: '😔',
                label: AppStrings.tr('Not Well', 'Kurang'),
                value: 'bad',
                selected: _mood == 'bad',
                onTap: () =>
                    setState(() => _mood = _mood == 'bad' ? null : 'bad'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notes field
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: AppStrings.tr(
                'Short notes (optional), e.g. slight headache, nausea...',
                'Catatan singkat (opsional), e.g. sedikit pusing, mual...',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          LayoutBuilder(
            builder: (context, constraints) {
              final stackActions = constraints.maxWidth < 260;
              final skipButton = TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  AppStrings.skip,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
              final saveButton = AppButton(
                label: AppStrings.save,
                onPressed: _save,
                isLoading: _isSaving,
              );

              if (stackActions) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    saveButton,
                    const SizedBox(height: 8),
                    skipButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: skipButton),
                  const SizedBox(width: 12),
                  Expanded(child: saveButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.emoji,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String emoji, label, value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 340;
    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(width: compact ? 78 : 88),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
