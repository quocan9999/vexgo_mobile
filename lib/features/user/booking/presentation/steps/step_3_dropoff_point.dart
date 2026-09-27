import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import '../widgets/stop_point_item.dart';

class Step3DropoffPoint extends StatelessWidget {
  final BookingFlowState state;
  final BookingFlowBloc bloc;

  const Step3DropoffPoint({
    super.key,
    required this.state,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    final trip = state.trip;
    final points = state.availableDropoffPoints;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & City info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.secondaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pin_drop_rounded, color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn điểm trả tại ${trip?.toCityName ?? ""}',
                      style: AppTextStyles.h4.copyWith(fontSize: 16),
                    ),
                    Text(
                      'Có ${points.length} điểm trả / trung chuyển tại nơi đến',
                      style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.base),

          // Transfer Assistance Tip
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.successLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đối với điểm trả trung chuyển tận nơi nội thành, bác tài hoặc phụ xe sẽ liên hệ trước khi xe gần đến nơi để hướng dẫn xuống xe an toàn.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutral700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.base),

          // Points List
          ...points.map((point) {
            final isSelected = state.selectedDropoffPoint?.id == point.id;
            return StopPointItem(
              point: point,
              isSelected: isSelected,
              onTap: () => bloc.add(SelectDropoffPointEvent(point)),
            );
          }),
        ],
      ),
    );
  }
}
