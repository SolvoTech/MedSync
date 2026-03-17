import 'package:flutter/material.dart';

import '../extensions/string_ext.dart';

/// Reusable avatar widget supporting image URL, initials, and custom color.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.color,
    required this.size,
  });

  final String? imageUrl;
  final String? name;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = color ?? colorScheme.primaryContainer;
    final fgColor = colorScheme.onPrimaryContainer;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: bgColor,
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bgColor,
      backgroundImage: const AssetImage('assets/images/default_avatar.png'),
    );
  }
}
