import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/string_ext.dart';
import '../../../profile/care_persons/care_person_list_screen.dart';

class CarePersonFilter extends ConsumerWidget {
  const CarePersonFilter({
    super.key,
    required this.selectedCarePersonId,
    required this.onSelected,
  });

  /// null means "Saya sendiri" (the user themselves).
  final String? selectedCarePersonId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(carePersonListProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final compact = MediaQuery.sizeOf(context).width < 340;

    return listState.when(
      data: (persons) {
        if (persons.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: compact ? 38 : 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
            itemCount: persons.length + 1, // +1 for "Saya sendiri"
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final bool isSelected;
              final String label;
              final String? personId;
              final Color? avatarColor;

              if (index == 0) {
                // "Saya sendiri" chip
                isSelected = selectedCarePersonId == null;
                label = AppStrings.tr('Myself', 'Saya');
                personId = null;
                avatarColor = null;
              } else {
                final person = persons[index - 1];
                isSelected = selectedCarePersonId == person.id;
                label = person.displayName;
                personId = person.id;
                avatarColor = person.avatarColor != null
                    ? Color(
                        int.parse(
                          '0xFF${person.avatarColor!.replaceFirst('#', '')}',
                        ),
                      )
                    : null;
              }

              return _FilterChip(
                label: label,
                isSelected: isSelected,
                avatarColor: avatarColor,
                personId: personId,
                colorScheme: colorScheme,
                textTheme: textTheme,
                compact: compact,
                onTap: () => onSelected(personId),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.avatarColor,
    required this.personId,
    required this.colorScheme,
    required this.textTheme,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color? avatarColor;
  final String? personId;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final fgColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final borderColor = isSelected
        ? colorScheme.primary
        : colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (personId == null)
                Icon(
                  Icons.person,
                  size: compact ? 14 : 16,
                  color: fgColor,
                )
              else
                CircleAvatar(
                  radius: compact ? 8 : 9,
                  backgroundColor: avatarColor ??
                      colorScheme.primaryContainer,
                  child: Text(
                    label.initials,
                    style: TextStyle(
                      fontSize: compact ? 7 : 8,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              SizedBox(width: compact ? 4 : 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: fgColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
