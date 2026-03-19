import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Reusable avatar widget supporting image URL, initials, gradient ring, and custom color.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.color,
    required this.size,
    this.showRing = false,
  });

  final String? imageUrl;
  final String? name;
  final Color? color;
  final double size;
  final bool showRing;

  String _placeholderUrlFor(String? rawName) {
    final cleanName = (rawName ?? '').trim();
    final displayName = cleanName.isEmpty ? 'User' : cleanName;
    final encodedName = Uri.encodeComponent(displayName);
    return 'https://ui-avatars.com/api/?name=$encodedName&background=E2E8F0&color=334155&size=256';
  }

  Widget _networkAvatarImage({
    required String primaryUrl,
    required String fallbackUrl,
  }) {
    return Image.network(
      primaryUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        if (primaryUrl == fallbackUrl) {
          return const Icon(Icons.person);
        }

        return Image.network(
          fallbackUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = color ?? colorScheme.primaryContainer;
    final fallbackUrl = _placeholderUrlFor(name);
    final trimmedImageUrl = imageUrl?.trim();
    final resolvedImageUrl =
        (trimmedImageUrl != null && trimmedImageUrl.isNotEmpty)
        ? trimmedImageUrl
        : fallbackUrl;

    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: bgColor,
      child: ClipOval(
        child: _networkAvatarImage(
          primaryUrl: resolvedImageUrl,
          fallbackUrl: fallbackUrl,
        ),
      ),
    );

    if (!showRing) return avatar;

    // Gradient ring around avatar
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gradientStart,
            AppColors.gradientEnd,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surface,
        ),
        child: avatar,
      ),
    );
  }
}
