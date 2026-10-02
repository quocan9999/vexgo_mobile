import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
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
    on<ReleaseSeatHoldEvent>(_onReleaseSeatHold);
  }

  Future<void> _onInit(
    InitBookingFlowEvent event,
    Emitter<BookingFlowState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BookingFlowStatus.loading,
        trip: event.trip,
        date: event.date,
        targetTicketCount: event.ticketCount,
      ),
    );

    try {
      final tripId = event.trip.numericTripId ?? int.tryParse(event.trip.id);
      SeatLayoutModel seatLayout;
      if (tripId != null && tripId > 0) {
        final realSeats = await seatRepository.getTripSeats(tripId);
        if (realSeats.isNotEmpty) {
          final lower = realSeats.where((s) => s.floor == 1).toList();
          final upper = realSeats.where((s) => s.floor == 2).toList();
          seatLayout = SeatLayoutModel(
            vehicleType: event.trip.vehicleType,
            hasTwoFloors: upper.isNotEmpty,
            lowerFloor: lower,
            upperFloor: upper,
          );
        } else {
          seatLayout = await seatRepository.getSeatLayout(
            event.trip.seatLayoutType,
          );
        }
      } else {
        seatLayout = await seatRepository.getSeatLayout(
          event.trip.seatLayoutType,
        );
      }
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

      emit(
        state.copyWith(
          status: BookingFlowStatus.loaded,
          seatLayout: seatLayout,
          availableVouchers: vouchers,
          availablePickupPoints: pickups,
          selectedPickupPoint: defaultPickup,
          availableDropoffPoints: dropoffs,
          selectedDropoffPoint: defaultDropoff,
          selectedFloor: 1,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingFlowStatus.failure,
          errorMessage: 'Không thể tải sơ đồ xe: $e',
        ),
      );
    }
  }

  void _onToggleSeat(ToggleSeatEvent event, Emitter<BookingFlowState> emit) {
    if (event.seat.status == SeatStatus.booked ||
        event.seat.status == SeatStatus.held) {
      return;
    }

    if (state.seatHold != null) {
      seatRepository.releaseSeatHold(state.seatHold!.holdToken);
      _stopCountdown();
    }

    final currentSelected = List<SeatModel>.from(state.selectedSeats);
    final exists = currentSelected.any((s) => s.id == event.seat.id);

    if (exists) {
      currentSelected.removeWhere((s) => s.id == event.seat.id);
      emit(
        state.copyWith(
          selectedSeats: currentSelected,
          clearSeatHold: state.seatHold != null,
          errorMessage: null,
        ),
      );
    } else {
      if (currentSelected.length >= 6) {
        emit(
          state.copyWith(
            errorMessage: 'Bạn chỉ có thể chọn tối đa 6 chỗ trong một lần đặt!',
          ),
        );
        return;
      }
      currentSelected.add(event.seat);
      emit(
        state.copyWith(
          selectedSeats: currentSelected,
          clearSeatHold: state.seatHold != null,
          errorMessage: null,
        ),
      );
    }
  }

  void _onChangeFloor(ChangeFloorEvent event, Emitter<BookingFlowState> emit) {
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
    emit(
      state.copyWith(
        passengerName: event.name,
        passengerPhone: event.phone,
        passengerEmail: event.email,
        passengerNote: event.note,
        savePassengerInfo: event.saveInfo,
      ),
    );
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
    if (state.countdownSeconds > 1) {
      emit(state.copyWith(countdownSeconds: state.countdownSeconds - 1));
    } else {
      _stopCountdown();
      final hold = state.seatHold;
      if (hold != null) {
        seatRepository.releaseSeatHold(hold.holdToken);
      }
      emit(
        state.copyWith(
          countdownSeconds: 0,
          status: BookingFlowStatus.failure,
          errorMessage: 'Hết thời gian giữ ghế. Vui lòng chọn lại chỗ ngồi.',
          step: BookingStep.seatSelection,
          clearSeatHold: true,
        ),
      );
    }
  }

  Future<void> _onNextStep(
    NextStepEvent event,
    Emitter<BookingFlowState> emit,
  ) async {
    if (!state.canProceed) return;

    // Moving from seatSelection: reserve seats via SeatHold API
    if (state.step == BookingStep.seatSelection && state.seatHold == null) {
      final tripId =
          state.trip?.numericTripId ?? int.tryParse(state.trip?.id ?? '');
      if (tripId == null || tripId <= 0) {
        emit(
          state.copyWith(
            status: BookingFlowStatus.failure,
            errorMessage: 'Thông tin chuyến đi không hợp lệ.',
          ),
        );
        return;
      }

      final seatIds = state.selectedSeats
          .map((s) => s.numericSeatId ?? int.tryParse(s.id))
          .whereType<int>()
          .toList();

      if (seatIds.length != state.selectedSeats.length || seatIds.isEmpty) {
        emit(
          state.copyWith(
            status: BookingFlowStatus.failure,
            errorMessage: 'Danh sách ghế không hợp lệ.',
          ),
        );
        return;
      }

      emit(state.copyWith(status: BookingFlowStatus.loading));
      try {
        final hold = await seatRepository.createSeatHold(
          tripId: tripId,
          seatIds: seatIds,
        );
        if (hold.remainingSeconds <= 0) {
          emit(
            state.copyWith(
              status: BookingFlowStatus.failure,
              errorMessage:
                  'Thời gian giữ chỗ đã hết hạn. Vui lòng chọn lại ghế.',
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            status: BookingFlowStatus.loaded,
            seatHold: hold,
            countdownSeconds: hold.remainingSeconds,
            step: BookingStep.pickupPoint,
            errorMessage: null,
          ),
        );
        _startCountdown();
        return;
      } on ApiException catch (e) {
        emit(
          state.copyWith(
            status: BookingFlowStatus.failure,
            errorMessage: e.message,
          ),
        );
        if (state.trip != null) {
          final tripId =
              state.trip!.numericTripId ?? int.tryParse(state.trip!.id);
          if (tripId != null && tripId > 0) {
            final realSeats = await seatRepository.getTripSeats(tripId);
            if (realSeats.isNotEmpty) {
              final lower = realSeats.where((s) => s.floor == 1).toList();
              final upper = realSeats.where((s) => s.floor == 2).toList();
              emit(
                state.copyWith(
                  seatLayout: SeatLayoutModel(
                    vehicleType: state.trip!.vehicleType,
                    hasTwoFloors: upper.isNotEmpty,
                    lowerFloor: lower,
                    upperFloor: upper,
                  ),
                ),
              );
            }
          }
        }
        return;
      } catch (e) {
        emit(
          state.copyWith(
            status: BookingFlowStatus.failure,
            errorMessage: 'Không thể giữ chỗ ngồi này. Vui lòng thử lại.',
          ),
        );
        return;
      }
    }

    final nextIndex = state.step.index + 1;
    if (nextIndex < BookingStep.values.length) {
      final nextStep = BookingStep.values[nextIndex];
      emit(state.copyWith(step: nextStep, errorMessage: null));
    }
  }

  Future<void> _onReleaseSeatHold(
    ReleaseSeatHoldEvent event,
    Emitter<BookingFlowState> emit,
  ) async {
    if (state.seatHold != null) {
      try {
        await seatRepository.releaseSeatHold(state.seatHold!.holdToken);
      } catch (_) {}
    }
    _stopCountdown();
    emit(state.copyWith(clearSeatHold: true, countdownSeconds: 600));
  }

  void _onPreviousStep(
    PreviousStepEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    final prevIndex = state.step.index - 1;
    if (prevIndex >= 0) {
      emit(
        state.copyWith(step: BookingStep.values[prevIndex], errorMessage: null),
      );
    }
  }

  void _onGoToStep(GoToStepEvent event, Emitter<BookingFlowState> emit) {
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

    // If there is an existing pending payment, poll its status and NEVER create a duplicate booking
    if (state.pendingPaymentId != null) {
      try {
        final paymentStatus = await bookingRepository.getPaymentStatus(
          state.pendingPaymentId!,
        );
        if (paymentStatus.isSuccess) {
          _stopCountdown();
          emit(
            state.copyWith(
              status: BookingFlowStatus.success,
              clearPendingPayment: true,
            ),
          );
          return;
        } else if (paymentStatus.isPending) {
          emit(
            state.copyWith(
              status: BookingFlowStatus.paymentPending,
              errorMessage:
                  'Giao dịch thanh toán đang chờ xử lý. Vui lòng hoàn tất thanh toán.',
            ),
          );
          return;
        } else {
          emit(
            state.copyWith(
              status: BookingFlowStatus.failure,
              clearPendingPayment: true,
              errorMessage:
                  paymentStatus.failureReason ??
                  'Giao dịch thanh toán thất bại.',
            ),
          );
          return;
        }
      } catch (e) {
        emit(
          state.copyWith(
            status: BookingFlowStatus.failure,
            errorMessage: 'Không thể kiểm tra trạng thái thanh toán: $e',
          ),
        );
        return;
      }
    }

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
        dropoffAddress:
            state.selectedDropoffPoint?.address ?? trip.dropoffAddress,
      );

      final passenger = PassengerInfo(
        fullName: state.passengerName.trim(),
        phone: state.passengerPhone.trim(),
        email: state.passengerEmail.trim(),
      );

      final seatNames = state.selectedSeats.map((s) => s.name).toList();
      final seatIds = state.selectedSeats
          .map((s) => s.numericSeatId ?? int.tryParse(s.id))
          .whereType<int>()
          .toList();

      if (seatIds.length != state.selectedSeats.length || seatIds.isEmpty) {
        emit(
          state.copyWith(
            status: BookingFlowStatus.failure,
            errorMessage:
                'Danh sách ghế không hợp lệ. Vui lòng chọn lại chỗ ngồi.',
          ),
        );
        return;
      }

      final holdToken = state.seatHold?.holdToken;

      final createdTicket = await bookingRepository.createBooking(
        trip: summary,
        seats: seatNames,
        seatIds: seatIds,
        holdToken: holdToken,
        promotionCode: state.appliedVoucher?.code,
        totalAmount: state.seatsTotalAmount,
        discountAmount: state.discountAmount,
        finalAmount: state.finalAmount,
        paymentMethod: state.selectedPaymentMethod,
        passenger: passenger,
      );

      _stopCountdown();

      emit(
        state.copyWith(
          status: BookingFlowStatus.success,
          createdTicket: createdTicket,
          clearPendingPayment: true,
        ),
      );
    } on PaymentFailedException catch (e) {
      emit(
        state.copyWith(
          status: BookingFlowStatus.failure,
          clearPendingPayment: true,
          errorMessage: e.message,
        ),
      );
    } on PaymentPendingException catch (e) {
      emit(
        state.copyWith(
          status: BookingFlowStatus.paymentPending,
          pendingPaymentId: e.paymentId,
          pendingPaymentUrl: e.paymentUrl,
          pendingQrCodeUrl: e.qrCodeUrl,
          pendingDeeplink: e.deeplink,
          errorMessage: e.message,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: BookingFlowStatus.failure,
          errorMessage: e.message,
        ),
      );
    } on NetworkException catch (e) {
      emit(
        state.copyWith(
          status: BookingFlowStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingFlowStatus.failure,
          errorMessage: 'Giao dịch thanh toán không thành công: $e',
        ),
      );
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
    if (state.seatHold != null && state.createdTicket == null) {
      seatRepository.releaseSeatHold(state.seatHold!.holdToken);
    }
    return super.close();
  }
}
