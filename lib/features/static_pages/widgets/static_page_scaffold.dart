import 'package:flutter/material.dart';

/// Consistent wrapper scaffold for static pages (about, privacy, terms, etc.)
class StaticPageScaffold extends StatelessWidget {
  const StaticPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.lastUpdated,
    this.actions,
  });

  final String title;
  final Widget child;
  final String? lastUpdated;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 340;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: actions,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastUpdated != null) ...[
              Text(
                'Terakhir diperbarui: $lastUpdated',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 16),
            ],
            child,
            const SizedBox(height: 32),
            Center(
              child: Text(
                '© 2025 MedSync. Hak cipta dilindungi undang-undang.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
