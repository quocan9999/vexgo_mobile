import 'package:flutter/material.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import '../widgets/stop_point_selection.dart';

class Step2PickupPoint extends StatelessWidget {
  final BookingFlowState state;
  final BookingFlowBloc bloc;

  const Step2PickupPoint({super.key, required this.state, required this.bloc});

  @override
  Widget build(BuildContext context) => StopPointSelection(
    title: 'Chọn điểm đón tại ${state.trip?.fromCityName ?? ""}',
    points: state.availablePickupPoints,
    selected: state.selectedPickupPoint,
    onSelected: (point) => bloc.add(SelectPickupPointEvent(point)),
  );
}
