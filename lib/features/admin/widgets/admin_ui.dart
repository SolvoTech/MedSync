import 'package:flutter/material.dart';

import '../../../core/constants/app_gradients.dart';
import '../../../core/widgets/app_card.dart';

class AdminIntroCard extends StatelessWidget {
  const AdminIntroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact =
        media.size.width < 380 || media.textScaler.scale(1) > 1.15;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tone = accentColor ?? colorScheme.primary;

    return AppCard(
      gradient: AppGradients.softSky,
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isCompact ? 40 : 44,
            height: isCompact ? 40 : 44,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: tone, size: isCompact ? 20 : 22),
          ),
          SizedBox(width: isCompact ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.66),
                    height: 1.35,
                  ),
                  maxLines: isCompact ? 3 : 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isCompact ? 54 : 72),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 8 : 10,
                  vertical: isCompact ? 4 : 5,
                ),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact =
        media.size.width < 380 || media.textScaler.scale(1) > 1.15;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 0 : 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isCompact ? 24 : 28,
            height: isCompact ? 24 : 28,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: isCompact ? 14 : 16,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(width: isCompact ? 7 : 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: isCompact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminMetricTile extends StatelessWidget {
  const AdminMetricTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact =
        media.size.width < 380 || media.textScaler.scale(1) > 1.15;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isCompact ? 30 : 34,
                height: isCompact ? 30 : 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: isCompact ? 17 : 19),
              ),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.58),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AdminStatusPill extends StatelessWidget {
  const AdminStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminCollapsibleSection extends StatelessWidget {
  const AdminCollapsibleSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.trailing,
    this.initiallyExpanded = false,
    this.padding,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? subtitle;
  final Widget? trailing;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact =
        media.size.width < 380 || media.textScaler.scale(1) > 1.15;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 14,
            vertical: 2,
          ),
          childrenPadding:
              padding ??
              EdgeInsets.fromLTRB(
                isCompact ? 12 : 14,
                8,
                isCompact ? 12 : 14,
                isCompact ? 12 : 14,
              ),
          leading: Container(
            width: isCompact ? 30 : 34,
            height: isCompact ? 30 : 34,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: isCompact ? 17 : 19,
              color: colorScheme.primary,
            ),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
          trailing: trailing,
          children: [child],
        ),
      ),
    );
  }
}

class AdminToolbarCard extends StatelessWidget {
  const AdminToolbarCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isCompact =
        MediaQuery.sizeOf(context).width < 380 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.15;

    return AppCard(
      padding: padding ?? EdgeInsets.all(isCompact ? 10 : 12),
      hasShadow: false,
      child: child,
    );
  }
}
