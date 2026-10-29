import 'package:flutter/material.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import '../widgets/stop_point_selection.dart';

class Step3DropoffPoint extends StatelessWidget {
  final BookingFlowState state;
  final BookingFlowBloc bloc;

  const Step3DropoffPoint({super.key, required this.state, required this.bloc});

  @override
  Widget build(BuildContext context) => StopPointSelection(
    title: 'Chọn điểm trả tại ${state.trip?.toCityName ?? ""}',
    points: state.availableDropoffPoints,
    selected: state.selectedDropoffPoint,
    onSelected: (point) => bloc.add(SelectDropoffPointEvent(point)),
  );
}
