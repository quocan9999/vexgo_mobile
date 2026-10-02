import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';

/// Sticky banner displaying seat hold status and countdown timer per rule-ui-ux.md
class SeatHoldCountdownBar extends StatelessWidget {
  final int remainingSeconds;
  final List<String> seatCodes;
  final VoidCallback? onTimeout;

  const SeatHoldCountdownBar({
    super.key,
    required this.remainingSeconds,
    this.seatCodes = const [],
    this.onTimeout,
  });

  String get formattedTime {
    final secs = remainingSeconds.clamp(0, 3600);
    final minutes = (secs ~/ 60).toString().padLeft(2, '0');
    final seconds = (secs % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = remainingSeconds <= 60;
    final seatsText = seatCodes.isNotEmpty ? ' (${seatCodes.join(', ')})' : '';

    final bgColor = isUrgent
        ? AppColors.error.withValues(alpha: 0.1)
        : AppColors.warning.withValues(alpha: 0.1);
    final borderColor = isUrgent
        ? AppColors.error.withValues(alpha: 0.4)
        : AppColors.warning.withValues(alpha: 0.4);
    final primaryColor = isUrgent ? AppColors.error : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.base,
        vertical: AppDimensions.sm + 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Icon(
            isUrgent ? Icons.alarm_rounded : Icons.timer_outlined,
            size: 20,
            color: primaryColor,
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutral800,
                ),
                children: [
                  TextSpan(
                    text: isUrgent
                        ? 'Sắp hết hạn giữ ghế$seatsText: '
                        : 'Ghế đang được giữ$seatsText: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: formattedTime,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
