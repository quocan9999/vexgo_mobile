import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
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
    final layout = state.seatLayout;
    if (layout == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SeatLegend(),
          const SizedBox(height: 14),
          if (layout.lowerFloor.isEmpty && layout.upperFloor.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Chuyến xe chưa có ghế mở bán.'),
            ),
          SeatMapView(
            layout: layout,
            selectedFloor: state.selectedFloor,
            selectedSeats: state.selectedSeats,
            onFloorChanged: (floor) => bloc.add(ChangeFloorEvent(floor)),
            onSeatToggled: (seat) => bloc.add(ToggleSeatEvent(seat)),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Chọn tối đa ${BookingFlowState.maxSeatsPerTrip} chỗ cho mỗi lượt đặt.',
              style: DiscoveryTextStyles.caption.copyWith(
                color: DiscoveryColors.neutral500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
