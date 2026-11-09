import 'package:vexgo_app/core/localization/locale_controller.dart';
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
    title: context.l10n.uiSelectDropOffIn(state.trip?.toCityName ?? ""),
    points: state.availableDropoffPoints,
    selected: state.selectedDropoffPoint,
    onSelected: (point) => bloc.add(SelectDropoffPointEvent(point)),
  );
}
