import 'package:flutter/material.dart';

/// Reusable bottom sheet wrapper with drag handle and consistent styling.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  /// Show this bottom sheet in a modal context.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    Widget? trailing,
    bool isScrollControlled = true,
    double heightFactor = 0.92,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: isScrollControlled ? heightFactor : null,
            child: AppBottomSheet(
              title: title,
              trailing: trailing,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 340;
    final horizontalPadding = compact ? 16.0 : 20.0;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 12, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                trailing ??
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Divider(color: colorScheme.outlineVariant),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: padding ?? EdgeInsets.all(compact ? 16 : 20),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
