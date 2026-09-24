import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/data/models/seat_model.dart';

class SeatItem extends StatelessWidget {
  final SeatModel seat;
  final bool isSelected;
  final VoidCallback onTap;

  const SeatItem({
    super.key,
    required this.seat,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBooked = seat.status == SeatStatus.booked;

    Color bgColor = Colors.white;
    Color borderColor = AppColors.neutral300;
    Color textColor = AppColors.neutral800;
    Color priceColor = AppColors.neutral500;

    if (isBooked) {
      bgColor = AppColors.neutral200;
      borderColor = AppColors.neutral300;
      textColor = AppColors.neutral400;
      priceColor = AppColors.neutral400;
    } else if (isSelected) {
      bgColor = AppColors.primary;
      borderColor = AppColors.primary;
      textColor = Colors.white;
      priceColor = Colors.white.withValues(alpha: 0.9);
    }

    // Price string in short (e.g. 290k)
    final priceShort = '${seat.price ~/ 1000}k';

    return GestureDetector(
      onTap: isBooked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bed headboard / seat header bar
            Container(
              width: 24,
              height: 4,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.6)
                    : (isBooked ? AppColors.neutral300 : AppColors.primaryLight),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Seat Name & Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isBooked)
                  const Icon(Icons.close_rounded, size: 13, color: AppColors.neutral400)
                else if (isSelected)
                  const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                else
                  const Icon(Icons.airline_seat_recline_extra_rounded, size: 13, color: AppColors.primary),
                const SizedBox(width: 2),
                Text(
                  seat.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 2),

            // Seat Price
            Text(
              isBooked ? 'Đã bán' : priceShort,
              style: AppTextStyles.caption.copyWith(
                color: priceColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
