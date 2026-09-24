import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import '../widgets/seat_legend.dart';
import '../widgets/seat_map_view.dart';

class Step1SeatSelection extends StatelessWidget {
  final BookingFlowState state;
  final BookingFlowBloc bloc;

  const Step1SeatSelection({
    super.key,
    required this.state,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    final trip = state.trip;
    final layout = state.seatLayout;

    if (layout == null || trip == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final dateStr = state.date != null ? DateFormatter.formatFullDate(state.date!) : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppDimensions.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip Info Quick Header
          Container(
            margin: const EdgeInsets.all(AppDimensions.base),
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.operatorName,
                        style: AppTextStyles.h4.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${trip.departureTime} • $dateStr',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${trip.fromCityName} -> ${trip.toCityName} • ${trip.vehicleType}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.neutral500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Legend
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.base),
            child: SeatLegend(),
          ),

          const SizedBox(height: AppDimensions.base),

          // Seat Map
          SeatMapView(
            layout: layout,
            selectedFloor: state.selectedFloor,
            selectedSeats: state.selectedSeats,
            onFloorChanged: (floor) => bloc.add(ChangeFloorEvent(floor)),
            onSeatToggled: (seat) => bloc.add(ToggleSeatEvent(seat)),
          ),

          const SizedBox(height: AppDimensions.md),

          // Max seats guideline note
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.neutral600),
                  const SizedBox(width: 6),
                  Text(
                    'Mỗi khách hàng được chọn tối đa 6 chỗ/lượt đặt',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutral600,
                      fontWeight: FontWeight.w500,
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
