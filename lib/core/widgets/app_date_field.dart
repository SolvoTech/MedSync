import 'package:flutter/material.dart';

class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.emptyText = 'Not selected',
    this.prefixIcon,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String emptyText;
  final IconData? prefixIcon;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasValue = value != null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        isEmpty: !hasValue,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: const Icon(Icons.calendar_month),
        ),
        child: Text(
          hasValue ? _formatDate(value!) : emptyText,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: hasValue
                ? colorScheme.onSurface
                : colorScheme.onSurface.withValues(alpha: 0.58),
          ),
        ),
      ),
    );
  }
}
