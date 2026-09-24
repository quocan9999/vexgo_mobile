import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

class RatingBadge extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final bool showReviewCount;

  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewCount,
    this.showReviewCount = true,
  });

  String _formatCount(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      return '(${k.toStringAsFixed(1)}k)';
    }
    return '($count)';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.sm,
            vertical: 2.0,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 14,
                color: Color(0xFFFFD700),
              ),
              const SizedBox(width: 3),
              Text(
                rating.toStringAsFixed(1),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (showReviewCount && reviewCount != null) ...[
          const SizedBox(width: AppDimensions.xs),
          Flexible(
            child: Text(
              _formatCount(reviewCount!),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutral500,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
