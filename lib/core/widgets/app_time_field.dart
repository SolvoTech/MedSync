import 'package:flutter/material.dart';

class AppTimeField extends StatelessWidget {
  const AppTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.prefixIcon,
  });

  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;
  final IconData? prefixIcon;

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        isEmpty: false,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: const Icon(Icons.access_time_rounded),
        ),
        child: Text(
          _formatTime(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
