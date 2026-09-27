import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import '../widgets/stop_point_item.dart';

class Step2PickupPoint extends StatelessWidget {
  final BookingFlowState state;
  final BookingFlowBloc bloc;

  const Step2PickupPoint({
    super.key,
    required this.state,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    final trip = state.trip;
    final points = state.availablePickupPoints;

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
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.departure_board_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn điểm đón tại ${trip?.fromCityName ?? ""}',
                      style: AppTextStyles.h4.copyWith(fontSize: 16),
                    ),
                    Text(
                      'Có ${points.length} điểm đón phù hợp cho chuyến xe này',
                      style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.base),

          // Punctuality Tip
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.alarm_on_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Quý khách vui lòng có mặt tại điểm đón trước giờ khởi hành từ 15 - 30 phút để nhà xe sắp xếp hành lý và xuất vé kịp thời.',
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
            final isSelected = state.selectedPickupPoint?.id == point.id;
            return StopPointItem(
              point: point,
              isSelected: isSelected,
              onTap: () => bloc.add(SelectPickupPointEvent(point)),
            );
          }),
        ],
      ),
    );
  }
}
