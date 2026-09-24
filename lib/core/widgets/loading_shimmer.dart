import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppDimensions.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
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

class TripCardShimmer extends StatelessWidget {
  const TripCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.base,
        vertical: AppDimensions.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                LoadingShimmer(width: 120, height: 18),
                LoadingShimmer(width: 80, height: 20),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            Row(
              children: const [
                LoadingShimmer(width: 50, height: 24),
                SizedBox(width: AppDimensions.sm),
                LoadingShimmer(width: 80, height: 14),
                SizedBox(width: AppDimensions.sm),
                LoadingShimmer(width: 50, height: 24),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            const Divider(),
            const SizedBox(height: AppDimensions.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                LoadingShimmer(width: 100, height: 14),
                LoadingShimmer(width: 90, height: 36, borderRadius: AppDimensions.radiusMd),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
