import 'package:equatable/equatable.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/models/voucher_model.dart';

abstract class BookingFlowEvent extends Equatable {
  const BookingFlowEvent();

  @override
  List<Object?> get props => [];
}

class InitBookingFlowEvent extends BookingFlowEvent {
  final TripModel trip;
  final DateTime date;
  final int ticketCount;

  const InitBookingFlowEvent({
    required this.trip,
    required this.date,
    this.ticketCount = 1,
  });

  @override
  List<Object?> get props => [trip, date, ticketCount];
}

class ToggleSeatEvent extends BookingFlowEvent {
  final SeatModel seat;

  const ToggleSeatEvent(this.seat);

  @override
  List<Object?> get props => [seat];
}

class ChangeFloorEvent extends BookingFlowEvent {
  final int floor;

  const ChangeFloorEvent(this.floor);

  @override
  List<Object?> get props => [floor];
}

class SelectPickupPointEvent extends BookingFlowEvent {
  final StopPointModel point;

  const SelectPickupPointEvent(this.point);

  @override
  List<Object?> get props => [point];
}

class SelectDropoffPointEvent extends BookingFlowEvent {
  final StopPointModel point;

  const SelectDropoffPointEvent(this.point);

  @override
  List<Object?> get props => [point];
}

class UpdatePassengerInfoEvent extends BookingFlowEvent {
  final String name;
  final String phone;
  final String email;
  final String note;
  final bool saveInfo;

  const UpdatePassengerInfoEvent({
    required this.name,
    required this.phone,
    required this.email,
    this.note = '',
    this.saveInfo = true,
  });

  @override
  List<Object?> get props => [name, phone, email, note, saveInfo];
}

class ApplyVoucherEvent extends BookingFlowEvent {
  final VoucherModel voucher;

  const ApplyVoucherEvent(this.voucher);

  @override
  List<Object?> get props => [voucher];
}

class RemoveVoucherEvent extends BookingFlowEvent {
  const RemoveVoucherEvent();
}

class SelectPaymentMethodEvent extends BookingFlowEvent {
  final String method; // 'momo', 'zalopay', 'vietqr', 'napas', 'visa'

  const SelectPaymentMethodEvent(this.method);

  @override
  List<Object?> get props => [method];
}

class TickCountdownEvent extends BookingFlowEvent {
  const TickCountdownEvent();
}

class NextStepEvent extends BookingFlowEvent {
  const NextStepEvent();
}

class PreviousStepEvent extends BookingFlowEvent {
  const PreviousStepEvent();
}

class GoToStepEvent extends BookingFlowEvent {
  final int stepIndex;

  const GoToStepEvent(this.stepIndex);

  @override
  List<Object?> get props => [stepIndex];
}

class ConfirmPaymentEvent extends BookingFlowEvent {
  const ConfirmPaymentEvent();
}
