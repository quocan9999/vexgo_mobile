import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';

class SeatLegend extends StatelessWidget {
  const SeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.base,
        vertical: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(
            color: Colors.white,
            borderColor: AppColors.neutral400,
            label: 'Ghế trống',
          ),
          _buildItem(
            color: AppColors.primary,
            borderColor: AppColors.primary,
            label: 'Đang chọn',
          ),
          _buildItem(
            color: AppColors.neutral200,
            borderColor: AppColors.neutral300,
            label: 'Đã bán',
            hasLock: true,
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required Color color,
    required Color borderColor,
    required String label,
    bool hasLock = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: hasLock
              ? const Icon(Icons.close_rounded, size: 14, color: AppColors.neutral500)
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.neutral700,
          ),
        ),
      ],
    );
  }
}
