import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'booking_flow_event.dart';
import 'booking_flow_state.dart';

class BookingFlowBloc extends Bloc<BookingFlowEvent, BookingFlowState> {
  final SeatRepository seatRepository;
  final BookingRepository bookingRepository;
  Timer? _countdownTimer;

  BookingFlowBloc({
    required this.seatRepository,
    required this.bookingRepository,
  }) : super(const BookingFlowState()) {
    on<InitBookingFlowEvent>(_onInit);
    on<ToggleSeatEvent>(_onToggleSeat);
    on<ChangeFloorEvent>(_onChangeFloor);
    on<SelectPickupPointEvent>(_onSelectPickupPoint);
    on<SelectDropoffPointEvent>(_onSelectDropoffPoint);
    on<UpdatePassengerInfoEvent>(_onUpdatePassengerInfo);
    on<ApplyVoucherEvent>(_onApplyVoucher);
    on<RemoveVoucherEvent>(_onRemoveVoucher);
    on<SelectPaymentMethodEvent>(_onSelectPaymentMethod);
    on<TickCountdownEvent>(_onTickCountdown);
    on<NextStepEvent>(_onNextStep);
    on<PreviousStepEvent>(_onPreviousStep);
    on<GoToStepEvent>(_onGoToStep);
    on<ConfirmPaymentEvent>(_onConfirmPayment);
  }

  Future<void> _onInit(
    InitBookingFlowEvent event,
    Emitter<BookingFlowState> emit,
  ) async {
    emit(state.copyWith(
      status: BookingFlowStatus.loading,
      trip: event.trip,
      date: event.date,
      targetTicketCount: event.ticketCount,
    ));

    try {
      final seatLayout = await seatRepository.getSeatLayout(event.trip.seatLayoutType);
      final vouchers = await bookingRepository.getVouchers();

      final pickups = event.trip.pickupPoints;
      final dropoffs = event.trip.dropoffPoints;

      StopPointModel? defaultPickup;
      if (pickups.isNotEmpty) {
        defaultPickup = pickups.firstWhere(
          (p) => p.isDefault,
          orElse: () => pickups.first,
        );
      }

      StopPointModel? defaultDropoff;
      if (dropoffs.isNotEmpty) {
        defaultDropoff = dropoffs.firstWhere(
          (p) => p.isDefault,
          orElse: () => dropoffs.first,
        );
      }

      emit(state.copyWith(
        status: BookingFlowStatus.loaded,
        seatLayout: seatLayout,
        availableVouchers: vouchers,
        availablePickupPoints: pickups,
        selectedPickupPoint: defaultPickup,
        availableDropoffPoints: dropoffs,
        selectedDropoffPoint: defaultDropoff,
        selectedFloor: 1,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BookingFlowStatus.failure,
        errorMessage: 'Không thể tải sơ đồ xe: $e',
      ));
    }
  }

  void _onToggleSeat(
    ToggleSeatEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    if (event.seat.status == SeatStatus.booked) return;

    final currentSelected = List<SeatModel>.from(state.selectedSeats);
    final exists = currentSelected.any((s) => s.id == event.seat.id);

    if (exists) {
      currentSelected.removeWhere((s) => s.id == event.seat.id);
      emit(state.copyWith(
        selectedSeats: currentSelected,
        errorMessage: null,
      ));
    } else {
      if (currentSelected.length >= 6) {
        emit(state.copyWith(
          errorMessage: 'Bạn chỉ có thể chọn tối đa 6 chỗ trong một lần đặt!',
        ));
        return;
      }
      currentSelected.add(event.seat);
      emit(state.copyWith(
        selectedSeats: currentSelected,
        errorMessage: null,
      ));
    }
  }

  void _onChangeFloor(
    ChangeFloorEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    emit(state.copyWith(selectedFloor: event.floor));
  }

  void _onSelectPickupPoint(
    SelectPickupPointEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    emit(state.copyWith(selectedPickupPoint: event.point));
  }

  void _onSelectDropoffPoint(
    SelectDropoffPointEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    emit(state.copyWith(selectedDropoffPoint: event.point));
  }

  void _onUpdatePassengerInfo(
    UpdatePassengerInfoEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    emit(state.copyWith(
      passengerName: event.name,
      passengerPhone: event.phone,
      passengerEmail: event.email,
      passengerNote: event.note,
      savePassengerInfo: event.saveInfo,
    ));
  }

  void _onApplyVoucher(
    ApplyVoucherEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    emit(state.copyWith(appliedVoucher: event.voucher));
  }

  void _onRemoveVoucher(
    RemoveVoucherEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    emit(state.copyWith(clearVoucher: true));
  }

  void _onSelectPaymentMethod(
    SelectPaymentMethodEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    emit(state.copyWith(selectedPaymentMethod: event.method));
  }

  void _onTickCountdown(
    TickCountdownEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    if (state.countdownSeconds > 0) {
      emit(state.copyWith(countdownSeconds: state.countdownSeconds - 1));
    }
  }

  void _onNextStep(
    NextStepEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    if (!state.canProceed) return;

    final nextIndex = state.step.index + 1;
    if (nextIndex < BookingStep.values.length) {
      final nextStep = BookingStep.values[nextIndex];
      emit(state.copyWith(step: nextStep, errorMessage: null));

      if (nextStep == BookingStep.payment) {
        _startCountdown();
      }
    }
  }

  void _onPreviousStep(
    PreviousStepEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    final prevIndex = state.step.index - 1;
    if (prevIndex >= 0) {
      emit(state.copyWith(
        step: BookingStep.values[prevIndex],
        errorMessage: null,
      ));
    }
  }

  void _onGoToStep(
    GoToStepEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    if (event.stepIndex >= 0 && event.stepIndex < BookingStep.values.length) {
      // Allow going back to previous steps without re-validation
      if (event.stepIndex <= state.step.index || state.canProceed) {
        final targetStep = BookingStep.values[event.stepIndex];
        emit(state.copyWith(step: targetStep, errorMessage: null));
        if (targetStep == BookingStep.payment) {
          _startCountdown();
        }
      }
    }
  }

  Future<void> _onConfirmPayment(
    ConfirmPaymentEvent event,
    Emitter<BookingFlowState> emit,
  ) async {
    final trip = state.trip;
    if (trip == null) return;

    emit(state.copyWith(status: BookingFlowStatus.submitting));

    // Simulate safe payment gateway processing delay
    await Future.delayed(const Duration(milliseconds: 1200));

    try {
      final date = state.date ?? DateTime.now();
      final dateFormatted =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

      final summary = TicketTripSummary(
        id: trip.id,
        operatorName: trip.operatorName,
        vehicleType: trip.vehicleType,
        departureTime: state.selectedPickupPoint?.time ?? trip.departureTime,
        departureDate: dateFormatted,
        arrivalTime: state.selectedDropoffPoint?.time ?? trip.arrivalTime,
        arrivalDate: dateFormatted,
        fromCity: trip.fromCityName,
        toCity: trip.toCityName,
        pickupPoint: state.selectedPickupPoint?.name ?? trip.pickupPoint,
        pickupAddress: state.selectedPickupPoint?.address ?? trip.pickupAddress,
        dropoffPoint: state.selectedDropoffPoint?.name ?? trip.dropoffPoint,
        dropoffAddress: state.selectedDropoffPoint?.address ?? trip.dropoffAddress,
      );

      final passenger = PassengerInfo(
        fullName: state.passengerName.trim(),
        phone: state.passengerPhone.trim(),
        email: state.passengerEmail.trim(),
      );

      final seatNames = state.selectedSeats.map((s) => s.name).toList();

      final createdTicket = await bookingRepository.createBooking(
        trip: summary,
        seats: seatNames,
        totalAmount: state.seatsTotalAmount,
        discountAmount: state.discountAmount,
        finalAmount: state.finalAmount,
        paymentMethod: state.selectedPaymentMethod,
        passenger: passenger,
      );

      _stopCountdown();

      emit(state.copyWith(
        status: BookingFlowStatus.success,
        createdTicket: createdTicket,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BookingFlowStatus.failure,
        errorMessage: 'Giao dịch thanh toán không thành công: $e',
      ));
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(const TickCountdownEvent());
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  Future<void> close() {
    _stopCountdown();
    return super.close();
  }
}
