import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/voucher_model.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/data/models/seat_layout_resolver.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/vietqr_config.dart';
import 'package:vexgo_app/core/utils/payment_provider_mapper.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'booking_flow_event.dart';
import 'booking_flow_state.dart';

class BookingFlowBloc extends Bloc<BookingFlowEvent, BookingFlowState> {
  final SeatRepository seatRepository;
  final BookingRepository bookingRepository;
  Timer? _countdownTimer;
  final DateTime Function() _now;
  bool _holdBusy = false;
  bool _confirmBusy = false;
  bool _closing = false;
  Completer<void>? _holdFinished;
  int _quoteRevision = 0;
  String? _acceptedQuoteKey;
  bool _sessionInvalidated = false;

  bool get sessionInvalidated => _sessionInvalidated;

  /// Fence synchronously: already queued events and late responses must not
  /// continue checkout using the next account's credentials.
  void invalidateSession() {
    if (_sessionInvalidated || _closing || isClosed) return;
    _sessionInvalidated = true;
    _invalidateQuote();
    _stopCountdown();
    add(const InvalidateBookingSessionEvent());
  }

  BookingFlowBloc({
    required this.seatRepository,
    required this.bookingRepository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const BookingFlowState()) {
    on<InitBookingFlowEvent>(_onInit);
    on<ToggleSeatEvent>(_onToggleSeat);
    on<ChangeFloorEvent>(_onChangeFloor);
    on<SelectPickupPointEvent>(_onSelectPickupPoint);
    on<SelectDropoffPointEvent>(_onSelectDropoffPoint);
    on<UpdatePassengerInfoEvent>(_onUpdatePassengerInfo);
    on<ApplyVoucherEvent>(_onApplyVoucher);
    on<RemoveVoucherEvent>(_onRemoveVoucher);
    on<ApplyPromotionCodeEvent>(_onApplyPromotionCode);
    on<RefreshBookingQuoteEvent>((event, emit) => _loadQuote(emit));
    on<SelectPaymentMethodEvent>(_onSelectPaymentMethod);
    on<TickCountdownEvent>(_onTickCountdown);
    on<NextStepEvent>(_onNextStep);
    on<PreviousStepEvent>(_onPreviousStep);
    on<GoToStepEvent>(_onGoToStep);
    on<ConfirmPaymentEvent>(_onConfirmPayment);
    on<ReleaseSeatHoldEvent>(_onReleaseSeatHold);
    on<InvalidateBookingSessionEvent>(_onInvalidateSession);
  }

  Future<void> _onInvalidateSession(
    InvalidateBookingSessionEvent event,
    Emitter<BookingFlowState> emit,
  ) async {
    final releaseHold = !state.isCheckoutLocked && !_confirmBusy;
    final hold = releaseHold ? state.seatHold : null;
    emit(
      state.copyWith(
        passengerName: '',
        passengerPhone: '',
        passengerEmail: '',
        passengerNote: '',
        savePassengerInfo: false,
        clearQuote: true,
        clearVoucher: true,
        requestedPromotionCode: '',
        quoteLoading: false,
        quoteError: null,
        selectedSeats: releaseHold ? const [] : null,
        step: releaseHold ? BookingStep.seatSelection : null,
        clearSeatHold: releaseHold,
        errorMessage: null,
      ),
    );
    if (hold != null) await _releaseOnClose(hold.holdToken);
    // A failed release remains subject to the authoritative backend deadline.
    // This route stays fenced, so its hold can never be reused by a new actor.
  }

  Future<void> _onInit(
    InitBookingFlowEvent event,
    Emitter<BookingFlowState> emit,
  ) async {
    if (_sessionInvalidated) return;
    _invalidateQuote();
    emit(
      state.copyWith(
        requiresAuthoritativeQuote: bookingRepository is! MockBookingRepository,
        clearQuote: true,
        quoteLoading: false,
        quoteError: null,
        status: BookingFlowStatus.loading,
        trip: event.trip,
        date: event.date,
        targetTicketCount: event.ticketCount,
        selectedPaymentMethod: ApiConfig.isDemoMode ? 'momo' : 'vietqr',
      ),
    );

    try {
      final tripId = event.trip.numericTripId ?? int.tryParse(event.trip.id);
      SeatLayoutModel seatLayout;
      if (tripId != null && tripId > 0) {
        final authoritativePrice = event.trip.discountPrice > 0
            ? event.trip.discountPrice
            : (event.trip.originalPrice > 0 ? event.trip.originalPrice : null);
        final rawSeats = await seatRepository.getTripSeats(tripId);
        final realSeats = rawSeats.map((s) {
          if (s.price != null && s.price! > 0) return s;
          return s.copyWith(price: authoritativePrice);
        }).toList();

        seatLayout = resolveSeatLayout(
          vehicleType: event.trip.vehicleType,
          seats: realSeats,
        );
      } else {
        seatLayout = await seatRepository.getSeatLayout(
          event.trip.seatLayoutType,
        );
      }
      if (_sessionInvalidated || _closing || emit.isDone) return;
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

      final initialPassengerName = event.passengerName?.trim() ?? '';
      final initialPassengerPhone = event.passengerPhone?.trim() ?? '';
      final initialPassengerEmail = event.passengerEmail?.trim() ?? '';

      if (_sessionInvalidated || _closing || emit.isDone) return;
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
          passengerName: initialPassengerName.isNotEmpty
              ? initialPassengerName
              : state.passengerName,
          passengerPhone: initialPassengerPhone.isNotEmpty
              ? initialPassengerPhone
              : state.passengerPhone,
          passengerEmail: initialPassengerEmail.isNotEmpty
              ? initialPassengerEmail
              : state.passengerEmail,
        ),
      );
    } catch (e) {
      if (_sessionInvalidated || _closing || emit.isDone) return;
      emit(
        state.copyWith(
          status: BookingFlowStatus.failure,
          errorMessage: 'Không thể tải sơ đồ xe: $e',
        ),
      );
    }
  }

  Future<void> _onToggleSeat(
    ToggleSeatEvent event,
    Emitter<BookingFlowState> emit,
  ) async {
    if (_sessionInvalidated ||
        state.isCheckoutLocked ||
        _holdBusy ||
        state.status == BookingFlowStatus.loading) {
      return;
    }
    final current = List<SeatModel>.from(state.selectedSeats);
    final exists = current.any((s) => s.id == event.seat.id);
    final inventory = [
      ...?state.seatLayout?.lowerFloor,
      ...?state.seatLayout?.upperFloor,
    ];
    final seat = inventory.where((s) => s.id == event.seat.id).firstOrNull;
    if (!exists && (seat == null || !seat.isAvailable)) return;
    if (!exists && current.length >= BookingFlowState.maxSeatsPerTrip) {
      emit(
        state.copyWith(
          errorMessage:
              'Bạn chỉ có thể chọn tối đa ${BookingFlowState.maxSeatsPerTrip} chỗ trong một lần đặt!',
        ),
      );
      return;
    }
    if (exists) {
      current.removeWhere((s) => s.id == event.seat.id);
    } else {
      current.add(seat!);
    }
    _invalidateQuote();
    _holdBusy = true;
    final hold = state.seatHold;
    _stopCountdown();
    emit(
      state.copyWith(
        selectedSeats: current,
        clearQuote: true,
        quoteLoading: false,
        quoteError: null,
        clearSeatHold: true,
        errorMessage: null,
      ),
    );
    try {
      if (hold != null) await seatRepository.releaseSeatHold(hold.holdToken);
    } catch (_) {
      // The backend deadline still releases the old hold; no fake release result.
    } finally {
      _holdBusy = false;
    }
  }

  void _onChangeFloor(ChangeFloorEvent event, Emitter<BookingFlowState> emit) {
    if (_sessionInvalidated) return;
    emit(state.copyWith(selectedFloor: event.floor));
  }

  void _onSelectPickupPoint(
    SelectPickupPointEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    if (_sessionInvalidated || state.isCheckoutLocked) return;
    emit(state.copyWith(selectedPickupPoint: event.point));
  }

  void _onSelectDropoffPoint(
    SelectDropoffPointEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    if (_sessionInvalidated || state.isCheckoutLocked) return;
    emit(state.copyWith(selectedDropoffPoint: event.point));
  }

  Future<void> _onUpdatePassengerInfo(
    UpdatePassengerInfoEvent event,
    Emitter<BookingFlowState> emit,
  ) async {
    if (_sessionInvalidated || state.isCheckoutLocked) return;
    final changed =
        state.passengerName.trim() != event.name.trim() ||
        state.passengerPhone.trim() != event.phone.trim() ||
        state.passengerEmail.trim() != event.email.trim();
    if (changed) _invalidateQuote();
    emit(
      state.copyWith(
        passengerName: event.name,
        passengerPhone: event.phone,
        passengerEmail: event.email,
        passengerNote: event.note,
        savePassengerInfo: event.saveInfo,
        clearQuote: changed,
        quoteLoading: changed ? false : null,
        quoteError: changed ? null : state.quoteError,
      ),
    );
    if (changed &&
        state.step.index >= BookingStep.tripSummary.index &&
        state.isPassengerValid) {
      await _loadQuote(emit);
    }
  }

  Future<void> _onApplyVoucher(
    ApplyVoucherEvent event,
    Emitter<BookingFlowState> emit,
  ) async {
    if (_sessionInvalidated || state.isCheckoutLocked) return;
    if (!state.requiresAuthoritativeQuote) {
      emit(state.copyWith(appliedVoucher: event.voucher));
      return;
    }
    await _applyCode(event.voucher.code, emit);
  }

  Future<void> _onApplyPromotionCode(
    ApplyPromotionCodeEvent event,
    Emitter<BookingFlowState> emit,
  ) async {
    if (_sessionInvalidated || state.isCheckoutLocked) return;
    await _applyCode(event.code, emit);
  }

  Future<void> _applyCode(String code, Emitter<BookingFlowState> emit) async {
    final normalized = code.trim().toUpperCase();
    if (state.quoteLoading && normalized == state.requestedPromotionCode) {
      return;
    }
    _invalidateQuote();
    emit(
      state.copyWith(
        requestedPromotionCode: normalized,
        clearVoucher: true,
        clearQuote: true,
        quoteLoading: false,
        quoteError: null,
      ),
    );
    await _loadQuote(emit);
  }

  Future<void> _onRemoveVoucher(
    RemoveVoucherEvent event,
    Emitter<BookingFlowState> emit,
  ) async {
    if (_sessionInvalidated || state.isCheckoutLocked) return;
    _invalidateQuote();
    emit(
      state.copyWith(
        clearVoucher: true,
        requestedPromotionCode: '',
        clearQuote: true,
        quoteLoading: false,
        quoteError: null,
      ),
    );
    if (state.requiresAuthoritativeQuote) await _loadQuote(emit);
  }

  void _invalidateQuote() {
    _quoteRevision++;
    _acceptedQuoteKey = null;
  }

  String _quoteKey(BookingFlowState draft) {
    final ids = draft.selectedSeats.map((seat) => seat.id).toList()..sort();
    return '${draft.trip?.id}|${ids.join(',')}|${draft.passengerName.trim()}|${draft.passengerPhone.trim()}|${draft.passengerEmail.trim()}|${draft.requestedPromotionCode}|${TokenStorage.sessionVersion}';
  }

  bool get _hasCurrentQuote =>
      state.hasUsableQuote &&
      (!state.requiresAuthoritativeQuote ||
          _acceptedQuoteKey == _quoteKey(state));

  Future<void> _loadQuote(Emitter<BookingFlowState> emit) async {
    if (_sessionInvalidated ||
        !state.requiresAuthoritativeQuote ||
        state.quoteLoading ||
        state.isCheckoutLocked ||
        !state.isSeatsValid ||
        !state.isPassengerValid ||
        _closing) {
      return;
    }
    final revision = ++_quoteRevision;
    final draft = state;
    final key = _quoteKey(draft);
    _acceptedQuoteKey = null;
    emit(
      state.copyWith(quoteLoading: true, clearQuote: true, quoteError: null),
    );
    try {
      final quote = await bookingRepository.getBookingQuote(
        tripId: draft.trip!.numericTripId ?? int.parse(draft.trip!.id),
        seatIds: draft.selectedSeats
            .map((seat) => seat.numericSeatId!)
            .toList(),
        promotionCode: draft.requestedPromotionCode.isEmpty
            ? null
            : draft.requestedPromotionCode,
        contactPhone: draft.passengerPhone.trim(),
      );
      if (_sessionInvalidated ||
          _closing ||
          emit.isDone ||
          revision != _quoteRevision) {
        return;
      }
      if (_quoteKey(state) != key) {
        emit(
          state.copyWith(
            quoteLoading: false,
            clearQuote: true,
            quoteError: 'Thông tin đặt vé đã thay đổi. Vui lòng cập nhật giá.',
          ),
        );
        return;
      }
      if (quote.seatCount != draft.selectedSeats.length ||
          quote.requiresPhoneBeforeBooking ||
          (draft.requestedPromotionCode.isNotEmpty &&
              (quote.appliedPromotionCode?.toUpperCase() !=
                      draft.requestedPromotionCode ||
                  (!quote.identityChecked &&
                      !quote.phoneEligibilityChecked)))) {
        throw StateError(
          'Máy chủ chưa xác thực mã khuyến mãi cho thông tin liên hệ hiện tại.',
        );
      }
      _acceptedQuoteKey = key;
      final code = quote.appliedPromotionCode;
      emit(
        state.copyWith(
          quote: quote,
          quoteLoading: false,
          quoteError: null,
          clearVoucher: code == null || code.isEmpty,
          appliedVoucher: code == null || code.isEmpty
              ? null
              : VoucherModel(
                  code: code,
                  title: code,
                  description: quote.promotionDescription ?? '',
                  discountAmount: quote.discountAmount,
                  discountPercent: 0,
                  minOrderAmount: 0,
                  expiryDate: '',
                  isApplicable: true,
                ),
        ),
      );
    } catch (error) {
      if (_sessionInvalidated ||
          _closing ||
          emit.isDone ||
          revision != _quoteRevision) {
        return;
      }
      emit(
        state.copyWith(
          quoteLoading: false,
          clearQuote: true,
          quoteError: error is ApiException
              ? error.message
              : 'Chưa xác minh được giá vé hoặc mã khuyến mãi. Vui lòng cập nhật giá.',
        ),
      );
    }
  }

  void _onSelectPaymentMethod(
    SelectPaymentMethodEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    if (_sessionInvalidated || state.isCheckoutLocked) return;
    emit(state.copyWith(selectedPaymentMethod: event.method));
  }

  int _remainingSeconds(DateTime expiresAt) {
    final millis = expiresAt.difference(_now()).inMilliseconds;
    return millis <= 0 ? 0 : (millis + 999) ~/ 1000;
  }

  Future<void> _onTickCountdown(
    TickCountdownEvent event,
    Emitter<BookingFlowState> emit,
  ) async {
    final hold = state.seatHold;
    if (_sessionInvalidated ||
        hold == null ||
        state.pendingBookingId != null ||
        state.bookingOutcomeUnknown) {
      return;
    }
    final remaining = _remainingSeconds(hold.expiresAt);
    if (remaining > 0) {
      emit(state.copyWith(countdownSeconds: remaining));
      return;
    }
    _stopCountdown();
    _invalidateQuote();
    emit(
      state.copyWith(
        clearQuote: true,
        quoteLoading: false,
        quoteError: null,
        countdownSeconds: 0,
        status: BookingFlowStatus.failure,
        errorMessage: 'Hết thời gian giữ ghế. Vui lòng chọn lại chỗ ngồi.',
        step: BookingStep.seatSelection,
        clearSeatHold: true,
        selectedSeats: const [],
      ),
    );
    try {
      await seatRepository.releaseSeatHold(hold.holdToken);
    } catch (_) {}
    await _refreshInventory(emit);
  }

  Future<void> _refreshInventory(Emitter<BookingFlowState> emit) async {
    final trip = state.trip;
    final tripId = trip?.numericTripId ?? int.tryParse(trip?.id ?? '');
    if (trip == null || tripId == null) return;
    try {
      final seats = await seatRepository.getTripSeats(tripId);
      if (_sessionInvalidated ||
          _closing ||
          emit.isDone ||
          state.isCheckoutLocked) {
        return;
      }
      final price = trip.discountPrice > 0
          ? trip.discountPrice
          : trip.originalPrice;
      final priced = seats
          .map(
            (seat) => seat.price != null && seat.price! > 0
                ? seat
                : seat.copyWith(price: price > 0 ? price : null),
          )
          .toList();
      emit(
        state.copyWith(
          seatLayout: resolveSeatLayout(
            vehicleType: trip.vehicleType,
            seats: priced,
          ),
        ),
      );
    } catch (_) {
      // Keep the original actionable error. Selection is cleared, so stale
      // inventory cannot proceed without a new backend hold.
    }
  }

  Future<void> _onNextStep(
    NextStepEvent event,
    Emitter<BookingFlowState> emit,
  ) async {
    if (_sessionInvalidated ||
        !state.canProceed ||
        state.isCheckoutLocked ||
        _holdBusy ||
        state.status == BookingFlowStatus.loading) {
      return;
    }

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

      _holdBusy = true;
      _holdFinished = Completer<void>();
      emit(
        state.copyWith(status: BookingFlowStatus.loading, errorMessage: null),
      );
      try {
        final hold = await seatRepository.createSeatHold(
          tripId: tripId,
          seatIds: seatIds,
        );
        if (_sessionInvalidated || _closing || emit.isDone) {
          await seatRepository.releaseSeatHold(hold.holdToken);
          return;
        }
        if (_remainingSeconds(hold.expiresAt) <= 0) {
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
            countdownSeconds: _remainingSeconds(hold.expiresAt),
            step: BookingStep.pickupPoint,
            errorMessage: null,
          ),
        );
        _startCountdown();
        return;
      } on ApiException catch (e) {
        if (_sessionInvalidated || _closing || emit.isDone) return;
        emit(
          state.copyWith(
            status: BookingFlowStatus.failure,
            errorMessage: e.message,
          ),
        );
        emit(state.copyWith(selectedSeats: const []));
        await _refreshInventory(emit);
        return;
      } catch (e) {
        if (_sessionInvalidated || _closing || emit.isDone) return;
        emit(
          state.copyWith(
            status: BookingFlowStatus.failure,
            errorMessage: 'Không thể giữ chỗ ngồi này. Vui lòng thử lại.',
          ),
        );
        return;
      } finally {
        _holdBusy = false;
        if (!(_holdFinished?.isCompleted ?? true)) _holdFinished!.complete();
      }
    }

    if (state.seatHold == null) return;
    if (_remainingSeconds(state.seatHold!.expiresAt) <= 0) {
      await _onTickCountdown(const TickCountdownEvent(), emit);
      return;
    }

    if (state.requiresAuthoritativeQuote &&
        state.step == BookingStep.tripSummary &&
        !_hasCurrentQuote) {
      await _loadQuote(emit);
      return;
    }
    final nextIndex = state.step.index + 1;
    if (nextIndex < BookingStep.values.length) {
      final nextStep = BookingStep.values[nextIndex];
      emit(state.copyWith(step: nextStep, errorMessage: null));
      if (nextStep == BookingStep.tripSummary) await _loadQuote(emit);
    }
  }

  Future<void> _onReleaseSeatHold(
    ReleaseSeatHoldEvent event,
    Emitter<BookingFlowState> emit,
  ) async {
    if (_holdBusy || _confirmBusy || state.isCheckoutLocked) return;
    if (state.seatHold != null) {
      try {
        final released = await seatRepository.releaseSeatHold(
          state.seatHold!.holdToken,
        );
        if (!released) {
          emit(
            state.copyWith(
              errorMessage:
                  'Chưa xác nhận được việc giải phóng ghế. Vui lòng thử lại.',
            ),
          );
          return;
        }
      } catch (_) {
        emit(
          state.copyWith(
            errorMessage:
                'Không thể giải phóng ghế do lỗi kết nối. Vui lòng thử lại.',
          ),
        );
        return;
      }
    }
    _stopCountdown();
    emit(state.copyWith(clearSeatHold: true, countdownSeconds: 600));
  }

  void _onPreviousStep(
    PreviousStepEvent event,
    Emitter<BookingFlowState> emit,
  ) {
    if (_sessionInvalidated ||
        state.isCheckoutLocked ||
        _holdBusy ||
        state.status == BookingFlowStatus.loading) {
      return;
    }
    final prevIndex = state.step.index - 1;
    if (prevIndex >= 0) {
      emit(
        state.copyWith(step: BookingStep.values[prevIndex], errorMessage: null),
      );
    }
  }

  void _onGoToStep(GoToStepEvent event, Emitter<BookingFlowState> emit) {
    if (_sessionInvalidated ||
        state.isCheckoutLocked ||
        _holdBusy ||
        state.status == BookingFlowStatus.loading) {
      return;
    }
    if (event.stepIndex >= 0 && event.stepIndex < BookingStep.values.length) {
      // Allow going back to previous steps without re-validation
      if (event.stepIndex < state.step.index) {
        final targetStep = BookingStep.values[event.stepIndex];
        emit(state.copyWith(step: targetStep, errorMessage: null));
      }
    }
  }

  Future<void> _onConfirmPayment(
    ConfirmPaymentEvent event,
    Emitter<BookingFlowState> emit,
  ) async {
    if (_sessionInvalidated ||
        _confirmBusy ||
        _holdBusy ||
        state.status == BookingFlowStatus.success ||
        state.status == BookingFlowStatus.blockedByBackend) {
      return;
    }
    if (state.bookingOutcomeUnknown) {
      emit(
        state.copyWith(
          status: BookingFlowStatus.failure,
          errorMessage:
              'Kết quả tạo đơn chưa xác định. Không gửi lại yêu cầu; vui lòng kiểm tra Vé của tôi hoặc liên hệ hỗ trợ.',
        ),
      );
      return;
    }
    final trip = state.trip;
    if (trip == null) return;
    if (state.pendingBookingId == null &&
        (!state.isSeatsValid ||
            !state.isPickupValid ||
            !state.isDropoffValid ||
            !state.isPassengerValid ||
            state.seatHold == null)) {
      emit(
        state.copyWith(
          status: BookingFlowStatus.failure,
          errorMessage:
              'Vui lòng hoàn tất thông tin hành khách và giữ chỗ trước khi thanh toán.',
        ),
      );
      return;
    }
    if (state.pendingBookingId == null &&
        _remainingSeconds(state.seatHold!.expiresAt) <= 0) {
      await _onTickCountdown(const TickCountdownEvent(), emit);
      return;
    }
    if (state.pendingBookingId == null &&
        state.requiresAuthoritativeQuote &&
        !_hasCurrentQuote) {
      if (state.quoteLoading) return;
      _confirmBusy = true;
      try {
        await _loadQuote(emit);
      } finally {
        _confirmBusy = false;
      }
      if (_sessionInvalidated || _closing || emit.isDone || !_hasCurrentQuote) {
        return;
      }
    }
    _confirmBusy = true;
    final draft = state;
    emit(
      state.copyWith(status: BookingFlowStatus.submitting, errorMessage: null),
    );
    try {
      // Only the explicitly selected mock repository may produce demo fixtures.
      if (bookingRepository is MockBookingRepository) {
        final ticket = await bookingRepository.createBooking(
          trip: _buildTripSummary(draft),
          seats: draft.selectedSeats.map((s) => s.name).toList(),
          seatIds: draft.selectedSeats.map((s) => s.numericSeatId!).toList(),
          holdToken: draft.holdToken,
          totalAmount: draft.seatsTotalAmount!,
          discountAmount: draft.discountAmount,
          finalAmount: draft.finalAmount!,
          paymentMethod: draft.selectedPaymentMethod,
          passenger: PassengerInfo(
            fullName: draft.passengerName.trim(),
            phone: draft.passengerPhone.trim(),
            email: draft.passengerEmail.trim(),
          ),
          promotionCode: draft.appliedVoucher?.code,
        );
        if (_sessionInvalidated || _closing || emit.isDone) return;
        _stopCountdown();
        emit(
          state.copyWith(
            status: BookingFlowStatus.success,
            createdTicket: ticket,
            createdTickets: [ticket],
            clearSeatHold: true,
          ),
        );
        return;
      }
      final bankTransfer =
          draft.selectedPaymentMethod == 'vietqr' && !ApiConfig.isDemoMode;
      if (bankTransfer &&
          state.pendingBookingId == null &&
          !VietQrConfig.isConfigured &&
          draft.finalAmount != 0) {
        emit(
          state.copyWith(
            status: BookingFlowStatus.failure,
            errorMessage:
                'Chưa có cấu hình tài khoản nhận VietQR. Vui lòng liên hệ hỗ trợ.',
          ),
        );
        return;
      }
      final provider = bankTransfer
          ? 'SEPAY'
          : PaymentProviderMapper.toBackendProvider(
              draft.selectedPaymentMethod,
            );
      if (state.pendingBookingId == null) {
        // Once dispatched, a lost POST response is an unknown outcome. Backend
        // has no idempotency key contract, so never automatically replay it.
        emit(state.copyWith(bookingOutcomeUnknown: true));
        final booking = await bookingRepository.createApiBooking(
          tripId: trip.numericTripId ?? int.parse(trip.id),
          seatIds: draft.selectedSeats.map((s) => s.numericSeatId!).toList(),
          pickupPoint: draft.selectedPickupPoint!.name,
          dropoffPoint: draft.selectedDropoffPoint!.name,
          contact: PassengerInfo(
            fullName: draft.passengerName.trim(),
            phone: draft.passengerPhone.trim(),
            email: draft.passengerEmail.trim(),
          ),
          holdToken: draft.holdToken,
          promotionCode: draft.appliedVoucher?.code,
        );
        if (_closing || emit.isDone) return;
        if (booking.bookingId <= 0) {
          throw StateError('Máy chủ không trả mã đơn hợp lệ.');
        }
        _stopCountdown();
        emit(
          state.copyWith(
            pendingBookingId: booking.bookingId,
            checkoutBooking: booking,
            bookingOutcomeUnknown: false,
            clearSeatHold: true,
          ),
        );
      }
      if (_sessionInvalidated) return;
      if (bankTransfer || state.checkoutBooking?.totalAmount == 0) {
        final expected = state.checkoutBooking!;
        final verified = await bookingRepository.getBookingById(
          expected.bookingId,
        );
        if (_sessionInvalidated || _closing || emit.isDone) return;
        if (verified == null ||
            verified.bookingId != expected.bookingId ||
            verified.bookingCode != expected.bookingCode ||
            verified.orderCode != expected.orderCode ||
            verified.totalAmount != expected.totalAmount ||
            verified.totalAmount < 0 ||
            verified.orderCode == null ||
            verified.orderCode!.isEmpty) {
          throw StateError('Thông tin đơn thanh toán không khớp.');
        }
        emit(
          state.copyWith(
            checkoutBooking: verified,
            pendingPaymentAmount: verified.totalAmount,
          ),
        );
        if (!verified.isPaid || verified.paymentStatus != 'DA_THANH_TOAN') {
          final pending =
              verified.totalAmount > 0 &&
              verified.isPending &&
              verified.paymentStatus == 'CHO_THANH_TOAN' &&
              verified.expiresAt != null &&
              verified.expiresAt!.isAfter(_now());
          emit(
            state.copyWith(
              status: pending
                  ? BookingFlowStatus.paymentPending
                  : BookingFlowStatus.failure,
              pendingQrCodeUrl: pending
                  ? VietQrConfig.imageUrl(
                      verified.totalAmount,
                      verified.orderCode!,
                    )
                  : null,
              errorMessage: pending
                  ? 'Chuyển khoản đúng số tiền và nội dung mã đơn. Hệ thống sẽ xác minh thanh toán; nhấn kiểm tra lại sau khi chuyển khoản.'
                  : 'Đơn chưa đủ điều kiện xuất vé, đã hết hạn hoặc bị hủy. Vui lòng liên hệ hỗ trợ nếu đã chuyển tiền.',
            ),
          );
          return;
        }
        emit(state.copyWith(paymentConfirmed: true));
      } else {
        if (state.pendingPaymentId == null) {
          final payment = await bookingRepository.createPayment(
            bookingId: state.pendingBookingId!,
            provider: provider,
          );
          if (_closing || emit.isDone) return;
          if (payment.paymentId <= 0 ||
              payment.bookingId != state.pendingBookingId ||
              payment.amount <= 0 ||
              payment.amount != state.checkoutBooking?.totalAmount) {
            throw StateError('Máy chủ trả thông tin thanh toán không hợp lệ.');
          }
          emit(
            state.copyWith(
              pendingPaymentId: payment.paymentId,
              pendingPaymentAmount: payment.amount,
              pendingPaymentUrl: payment.paymentUrl,
              pendingQrCodeUrl: payment.qrCodeUrl,
              pendingDeeplink: payment.deeplink,
            ),
          );
          if (_sessionInvalidated) return;
          if (!ApiConfig.isDemoMode && payment.isDemo) {
            emit(
              state.copyWith(
                status: BookingFlowStatus.blockedByBackend,
                errorMessage:
                    'BLOCKED_BY_BACKEND: Máy chủ chỉ hỗ trợ cổng thanh toán thử nghiệm, chưa hỗ trợ thanh toán thực tế.',
              ),
            );
            return;
          }
        }
        if (!state.paymentConfirmed) {
          final payment = await bookingRepository.getPaymentStatus(
            state.pendingPaymentId!,
          );
          if (_sessionInvalidated || _closing || emit.isDone) return;
          if (payment.paymentId != state.pendingPaymentId ||
              payment.bookingId != state.pendingBookingId ||
              payment.amount != state.pendingPaymentAmount ||
              (!ApiConfig.isDemoMode && payment.isDemo)) {
            throw StateError('Kết quả thanh toán không khớp với đơn hiện tại.');
          }
          if (!payment.isSuccess) {
            emit(
              state.copyWith(
                status: payment.isPending
                    ? BookingFlowStatus.paymentPending
                    : BookingFlowStatus.failure,
                errorMessage: payment.isPending
                    ? 'Thanh toán đang chờ xử lý. Hoàn tất tại cổng thanh toán rồi kiểm tra lại.'
                    : 'Thanh toán không thành công. Đơn và giao dịch hiện tại được giữ để kiểm tra, không tạo lại đơn.',
              ),
            );
            return;
          }
          emit(state.copyWith(paymentConfirmed: true));
        }
      }
      final tickets = await resolvePaidBookingTickets(
        bookingRepository,
        state.pendingBookingId!,
        isCurrentSession: () => !_sessionInvalidated && !_closing,
      );
      if (_sessionInvalidated || _closing || emit.isDone) return;
      emit(
        state.copyWith(
          status: BookingFlowStatus.success,
          createdTicket: tickets.first,
          createdTickets: tickets,
          errorMessage: null,
        ),
      );
    } on ApiException catch (error) {
      if (_sessionInvalidated || _closing || emit.isDone) return;
      final definiteRejection =
          state.pendingBookingId == null &&
          error.statusCode >= 400 &&
          error.statusCode < 500;
      final blocked =
          error.errorCode == 'BLOCKED_BY_BACKEND_GUEST_CHECKOUT' ||
          error.statusCode == 503;
      emit(
        state.copyWith(
          status: blocked
              ? BookingFlowStatus.blockedByBackend
              : BookingFlowStatus.failure,
          bookingOutcomeUnknown: definiteRejection
              ? false
              : state.bookingOutcomeUnknown,
          errorMessage: blocked
              ? (error.statusCode == 503
                    ? 'BLOCKED_BY_BACKEND: Cổng thanh toán chưa khả dụng trên máy chủ. Đơn hiện tại được giữ để kiểm tra.'
                    : error.message)
              : error.message,
        ),
      );
    } catch (error) {
      if (_sessionInvalidated || _closing || emit.isDone) return;
      emit(
        state.copyWith(
          status: BookingFlowStatus.failure,
          errorMessage: state.bookingOutcomeUnknown
              ? 'Kết quả tạo đơn chưa xác định do lỗi kết nối. Không gửi lại yêu cầu; kiểm tra Vé của tôi hoặc liên hệ hỗ trợ.'
              : 'Chưa xác minh được thanh toán hoặc vé. Vui lòng kiểm tra lại đơn hiện tại.',
        ),
      );
    } finally {
      _confirmBusy = false;
    }
  }

  TicketTripSummary _buildTripSummary(BookingFlowState draft) {
    final trip = draft.trip!;
    final date = draft.date ?? _now();
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return TicketTripSummary(
      id: trip.id,
      operatorName: trip.operatorName,
      vehicleType: trip.vehicleType,
      departureTime: draft.selectedPickupPoint?.time ?? trip.departureTime,
      departureDate: formatted,
      arrivalTime: draft.selectedDropoffPoint?.time ?? trip.arrivalTime,
      arrivalDate: formatted,
      fromCity: trip.fromCityName,
      toCity: trip.toCityName,
      pickupPoint: draft.selectedPickupPoint?.name ?? trip.pickupPoint,
      pickupAddress: draft.selectedPickupPoint?.address ?? trip.pickupAddress,
      dropoffPoint: draft.selectedDropoffPoint?.name ?? trip.dropoffPoint,
      dropoffAddress:
          draft.selectedDropoffPoint?.address ?? trip.dropoffAddress,
    );
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

  Future<void> _releaseOnClose(String token) async {
    try {
      await seatRepository.releaseSeatHold(token);
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    _closing = true;
    _stopCountdown();
    if (state.seatHold != null &&
        state.createdTicket == null &&
        !state.isCheckoutLocked &&
        !_confirmBusy) {
      await _releaseOnClose(state.seatHold!.holdToken);
    }
    await super.close();
    await _holdFinished?.future;
  }
}
