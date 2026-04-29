import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_colors.dart';

class AppLoadingSkeleton extends StatelessWidget {
  const AppLoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
      highlightColor: isDark
          ? AppColors.darkShimmerHighlight
          : AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton for a list of cards (e.g. medicine list, task list)
class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({super.key, this.itemCount = 4, this.itemHeight = 80});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 340;
    return ListView.separated(
      padding: EdgeInsets.all(compact ? 12 : 16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => AppLoadingSkeleton(
        width: double.infinity,
        height: itemHeight,
        borderRadius: 12,
      ),
    );
  }
}
