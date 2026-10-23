import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';

/// Compact visual stepper with circle badges for the 3 selection steps
class BookingStepperCompact extends StatelessWidget {
  final int currentStepIndex;
  final ValueChanged<int>? onStepTapped;

  const BookingStepperCompact({
    super.key,
    required this.currentStepIndex,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    const stepTitles = ['Chọn chỗ', 'Điểm đón', 'Điểm trả'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0)
                Container(
                  width: 20,
                  height: 1.5,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              _buildStepItem(
                index: i,
                title: stepTitles[i],
                isActive: i == currentStepIndex,
                isPassed: i < currentStepIndex,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required int index,
    required String title,
    required bool isActive,
    required bool isPassed,
  }) {
    final canTap = isPassed && onStepTapped != null;

    final badgeChild = isPassed
        ? const Icon(Icons.check, size: 12, color: Colors.white)
        : Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isActive
                  ? DiscoveryColors.header
                  : Colors.white.withValues(alpha: 0.85),
            ),
          );

    final badgeDecoration = BoxDecoration(
      color: isActive
          ? Colors.white
          : isPassed
          ? Colors.white.withValues(alpha: 0.35)
          : Colors.transparent,
      shape: BoxShape.circle,
      border: isActive || isPassed
          ? null
          : Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
      boxShadow: isActive
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ]
          : null,
    );

    final labelStyle = TextStyle(
      fontSize: 12.5,
      fontWeight: isActive
          ? FontWeight.w800
          : isPassed
          ? FontWeight.w600
          : FontWeight.w500,
      color: isActive
          ? Colors.white
          : isPassed
          ? Colors.white.withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.75),
    );

    return InkWell(
      onTap: canTap ? () => onStepTapped!(index) : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: badgeDecoration,
              child: badgeChild,
            ),
            const SizedBox(width: 6),
            Text(title, style: labelStyle),
          ],
        ),
      ),
    );
  }
}

/// Legacy multi-step stepper retained for subsequent checkout steps if needed
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.neutral200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
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
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        step.title,
                        style: AppTextStyles.caption.copyWith(
                          color: textColor,
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.normal,
                          fontSize: 11,
                        ),
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
