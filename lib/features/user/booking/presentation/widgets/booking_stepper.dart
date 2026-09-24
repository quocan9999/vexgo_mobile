import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';

class BookingStepper extends StatelessWidget {
  final BookingStep currentStep;
  final Function(int) onStepTapped;

  const BookingStepper({
    super.key,
    required this.currentStep,
    required this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    final currentIdx = currentStep.index;
    final totalSteps = BookingStep.values.length;
    final progress = (currentIdx + 1) / totalSteps;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.base,
        AppDimensions.sm,
        AppDimensions.base,
        AppDimensions.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step Counter & Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Bước ${currentStep.stepNumber}/$totalSteps',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Text(
                    currentStep.title,
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.neutral900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.sm),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.neutral200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 5,
            ),
          ),

          const SizedBox(height: AppDimensions.sm),

          // Scrollable Mini Step Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(totalSteps, (index) {
                final step = BookingStep.values[index];
                final isCurrent = index == currentIdx;
                final isPassed = index < currentIdx;

                Color bgColor = AppColors.neutral100;
                Color textColor = AppColors.neutral500;
                Color borderColor = AppColors.neutral300;

                if (isCurrent) {
                  bgColor = AppColors.primary;
                  textColor = Colors.white;
                  borderColor = AppColors.primary;
                } else if (isPassed) {
                  bgColor = AppColors.primaryLight;
                  textColor = AppColors.primary;
                  borderColor = AppColors.primary.withValues(alpha: 0.3);
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: isPassed ? () => onStepTapped(index) : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPassed) ...[
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '${index + 1}. ${step.shortTitle}',
                            style: AppTextStyles.caption.copyWith(
                              color: textColor,
                              fontWeight: isCurrent || isPassed ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
