import 'package:vexgo_app/data/repositories/cargo_repository.dart';
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/network/vietqr_config.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import '../booking/presentation/widgets/payment_display_state.dart';
import 'round_trip_request.dart';

enum RoundTripPhase {
  editing,
  submitting,
  partiallyCreated,
  paymentPending,
  partiallyPaid,
  success,
  verificationRequired,
  invalidated,
}

class RoundTripCheckoutState extends Equatable {
  final BookingFlowState outbound;
  final BookingFlowState inbound;
  final bool busy;
  final bool invalidated;
  final String? error;
  const RoundTripCheckoutState({
    this.outbound = const BookingFlowState(),
    this.inbound = const BookingFlowState(),
    this.busy = false,
    this.invalidated = false,
    this.error,
  });

  BookingFlowState leg(TripLeg leg) =>
      leg == TripLeg.outbound ? outbound : inbound;
  bool get hasUnknownOutcome =>
      outbound.bookingOutcomeUnknown || inbound.bookingOutcomeUnknown;
  bool get hasAnyOrder =>
      outbound.pendingBookingId != null || inbound.pendingBookingId != null;
  bool get hasBothOrders =>
      outbound.pendingBookingId != null && inbound.pendingBookingId != null;
  bool get ordersConflict =>
      hasBothOrders &&
      (outbound.pendingBookingId == inbound.pendingBookingId ||
          (outbound.checkoutBooking?.orderCode != null &&
              outbound.checkoutBooking?.orderCode ==
                  inbound.checkoutBooking?.orderCode));
  bool canDisplayTransfer(TripLeg leg, DateTime now) =>
      !invalidated &&
      !busy &&
      !ordersConflict &&
      this.leg(leg).canDisplayBankTransfer(now);
  bool get isComplete =>
      !invalidated &&
      !ordersConflict &&
      outbound.status == BookingFlowStatus.success &&
      inbound.status == BookingFlowStatus.success &&
      outbound.paymentConfirmed &&
      inbound.paymentConfirmed;
  int? get totalAmount {
    int? amount(BookingFlowState s) =>
        s.checkoutBooking?.totalAmount ??
        (s.hasUsableQuote && s.quote != null ? s.finalAmount : null);
    final a = amount(outbound);
    final b = amount(inbound);
    return invalidated || ordersConflict || a == null || b == null
        ? null
        : a + b;
  }

  RoundTripPhase get phase {
    if (invalidated) return RoundTripPhase.invalidated;
    if (busy) return RoundTripPhase.submitting;
    if (isComplete) return RoundTripPhase.success;
    if (hasUnknownOutcome ||
        ordersConflict ||
        [outbound, inbound].any(
          (s) =>
              s.pendingBookingId != null &&
              (s.status == BookingFlowStatus.failure ||
                  s.status == BookingFlowStatus.blockedByBackend),
        )) {
      return RoundTripPhase.verificationRequired;
    }
    if (outbound.paymentConfirmed || inbound.paymentConfirmed) {
      return RoundTripPhase.partiallyPaid;
    }
    if (hasBothOrders) return RoundTripPhase.paymentPending;
    if (hasAnyOrder) return RoundTripPhase.partiallyCreated;
    return RoundTripPhase.editing;
  }

  @override
  List<Object?> get props => [outbound, inbound, busy, invalidated, error];
}

/// Same contract as Web: two independent orders, never one combined QR.
/// Owns both one-way BLoCs. UI must dispatch through this coordinator, not
/// instantiate BookingFlowScreen twice (that would submit independently).
class RoundTripCheckoutCubit extends Cubit<RoundTripCheckoutState> {
  final RoundTripRequest request;
  final DateTime Function() _now;
  late final Map<TripLeg, BookingFlowBloc> _flows;
  final List<StreamSubscription<BookingFlowState>> _subscriptions = [];
  late final StreamSubscription<void> _sessionSubscription;
  final int _sessionVersion = TokenStorage.sessionVersion;
  bool _busy = false;
  bool _invalidated = false;
  bool _closing = false;
  String? _lastError;
  int _pendingEdits = 0;

  RoundTripCheckoutCubit({
    required this.request,
    required TripModel outbound,
    required TripModel inbound,
    required SeatRepository seatRepository,
    required BookingRepository bookingRepository,
    CargoRepository? cargoRepository,
    DateTime Function()? now,
    VietQrReceivingAccount receivingAccount = VietQrConfig.account,
  }) : _now = now ?? DateTime.now,
       super(const RoundTripCheckoutState()) {
    if (!request.acceptsPair(outbound, inbound)) {
      throw ArgumentError(
        'Hai chuyến không đúng tuyến/ngày hoặc thời gian bị chồng lấn.',
      );
    }
    if (bookingRepository is MockBookingRepository) {
      throw ArgumentError('Khứ hồi yêu cầu repository API, không tạo vé demo.');
    }
    _flows = {
      for (final leg in TripLeg.values)
        leg: BookingFlowBloc(
          seatRepository: seatRepository,
          bookingRepository: bookingRepository,
          cargoRepository: cargoRepository,
          now: _now,
          receivingAccount: receivingAccount,
        ),
    };
    for (final leg in TripLeg.values) {
      _subscriptions.add(_flows[leg]!.stream.listen((_) => _publish()));
      _flows[leg]!.add(
        InitBookingFlowEvent(
          trip: leg == TripLeg.outbound ? outbound : inbound,
          date: request.dateFor(leg),
          ticketCount: request.ticketCount,
        ),
      );
    }
    _sessionSubscription = TokenStorage.sessionChanges.listen(
      (_) => invalidateSession(),
    );
  }

  bool get _active {
    if (_closing || isClosed || _invalidated) return false;
    if (TokenStorage.sessionVersion != _sessionVersion) {
      invalidateSession();
      return false;
    }
    return true;
  }

  void _publish({String? error, bool clearError = false}) {
    if (!_active) return;
    if (clearError) _lastError = null;
    if (error != null) _lastError = error;
    emit(
      RoundTripCheckoutState(
        outbound: _flows[TripLeg.outbound]!.state,
        inbound: _flows[TripLeg.inbound]!.state,
        busy: _busy || _pendingEdits > 0,
        error: _lastError,
      ),
    );
  }

  void invalidateSession() {
    if (_invalidated || _closing || isClosed) return;
    _invalidated = true;
    for (final flow in _flows.values) {
      flow.invalidateSession();
    }
    // Hide all contacts, QR, order and ticket payloads synchronously.
    emit(const RoundTripCheckoutState(invalidated: true));
  }

  /// Seat/floor/stops/steps/promotion commands only. Init, payment method and
  /// ConfirmPaymentEvent are intentionally not accepted from presentation.
  bool dispatch(TripLeg leg, BookingFlowEvent event) {
    if (!_active || _busy || state.hasUnknownOutcome) return false;
    final allowed =
        event is SetBookingCargoEnabledEvent ||
        event is RefreshBookingCargoEvent ||
        event is UpdateBookingCargoEvent ||
        event is ToggleSeatEvent ||
        event is ChangeFloorEvent ||
        event is SelectPickupPointEvent ||
        event is SelectDropoffPointEvent ||
        event is NextStepEvent ||
        event is PreviousStepEvent ||
        event is GoToStepEvent ||
        event is ApplyPromotionCodeEvent ||
        event is RemoveVoucherEvent ||
        event is RefreshBookingQuoteEvent ||
        event is ReleaseSeatHoldEvent;
    if (!allowed || _flows[leg]!.state.isCheckoutLocked) return false;
    final draft = _flows[leg]!.state;
    if (event is SelectPickupPointEvent &&
        !draft.availablePickupPoints.contains(event.point)) {
      return false;
    }
    if (event is SelectDropoffPointEvent &&
        !draft.availableDropoffPoints.contains(event.point)) {
      return false;
    }
    _publish(clearError: true);
    _applyDraft(leg, event);
    return true;
  }

  void _applyDraft(TripLeg leg, BookingFlowEvent event) {
    _pendingEdits++;
    _publish(clearError: true);
    unawaited(
      _flows[leg]!.applyDraftAction(event).whenComplete(() {
        _pendingEdits--;
        _publish();
      }),
    );
  }

  bool updatePassenger(UpdatePassengerInfoEvent event) {
    if (!_active || _busy || state.hasAnyOrder || state.hasUnknownOutcome) {
      return false;
    }
    for (final leg in TripLeg.values) {
      _applyDraft(leg, event);
    }
    return true;
  }

  bool _ready(BookingFlowState s) =>
      (s.status == BookingFlowStatus.loaded ||
          s.status == BookingFlowStatus.failure) &&
      s.step == BookingStep.payment &&
      s.selectedPaymentMethod == 'vietqr' &&
      s.isSeatsValid &&
      s.isPickupValid &&
      s.isDropoffValid &&
      s.isPassengerValid &&
      s.cargo.isValid &&
      s.hasUsableQuote &&
      !s.quoteLoading &&
      s.quoteError == null &&
      s.seatHold != null &&
      s.seatHold!.expiresAt.isAfter(_now()) &&
      !s.bookingOutcomeUnknown;

  /// Explicit create action. Existing orders are never recreated or implicitly
  /// paid/cancelled. On partial failure the successful leg remains available.
  Future<void> submit() async {
    if (!_active || _busy || _pendingEdits > 0 || state.hasUnknownOutcome) {
      return;
    }
    final missing = TripLeg.values
        .where((leg) => _flows[leg]!.state.pendingBookingId == null)
        .toList();
    if (missing.isEmpty) return;
    if (TripLeg.values.any((leg) {
      final s = _flows[leg]!.state;
      return s.pendingBookingId != null &&
          s.status != BookingFlowStatus.paymentPending &&
          s.status != BookingFlowStatus.success;
    })) {
      _publish(
        error: 'Kiểm tra lại chặng đã tạo trước khi tiếp tục chặng còn lại.',
      );
      return;
    }
    if (missing.any((leg) => !_ready(_flows[leg]!.state))) {
      _publish(
        error: 'Hoàn tất ghế, đón/trả, hành khách và báo giá của cả hai chiều.',
      );
      return;
    }
    final a = _flows[TripLeg.outbound]!.state;
    final b = _flows[TripLeg.inbound]!.state;
    if (a.passengerName != b.passengerName ||
        a.passengerPhone != b.passengerPhone ||
        a.passengerEmail != b.passengerEmail ||
        (a.seatHold != null &&
            a.seatHold!.holdToken == b.seatHold?.holdToken)) {
      _publish(
        error: 'Thông tin hai chặng không khớp. Không gửi yêu cầu tạo đơn.',
      );
      return;
    }
    _busy = true;
    _publish(clearError: true);
    String? error;
    try {
      for (final leg in missing) {
        if (!_active) return;
        final flow = _flows[leg]!;
        if (!_ready(flow.state)) {
          error =
              'Chặng ${leg.name} chưa sẵn sàng hoặc giữ chỗ đã hết hạn. Đơn đã tạo được giữ nguyên.';
          break;
        }
        await flow.confirmPayment();
        if (!_active) return;
        final result = flow.state;
        if (result.bookingOutcomeUnknown ||
            result.pendingBookingId == null ||
            (result.status != BookingFlowStatus.paymentPending &&
                result.status != BookingFlowStatus.success)) {
          error =
              result.errorMessage ??
              'Chưa xác minh được chặng ${leg.name}. Đơn đã có được giữ nguyên.';
          break;
        }
      }
    } finally {
      _busy = false;
      if (_active) _publish(error: error);
    }
  }

  /// Read/reconcile ONLY an already known order. Never creates the other leg.
  Future<void> recheck(TripLeg leg) async {
    if (!_active ||
        _busy ||
        _pendingEdits > 0 ||
        _flows[leg]!.state.pendingBookingId == null) {
      return;
    }
    _busy = true;
    _publish(clearError: true);
    try {
      await _flows[leg]!.confirmPayment();
    } finally {
      _busy = false;
      if (_active) _publish();
    }
  }

  @override
  Future<void> close() async {
    _closing = true;
    await _sessionSubscription.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    // One-way close releases only holds that were never sent for booking.
    await Future.wait(_flows.values.map((flow) => flow.close()));
    return super.close();
  }
}
