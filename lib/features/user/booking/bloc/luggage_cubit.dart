import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/booking_cargo_model.dart';
import '../../../../data/models/luggage_policy.dart';
import '../../../../data/repositories/luggage_repository.dart';
import '../../../../core/network/token_storage.dart';

enum LuggagePhase { idle, loading, ready, failure, revoked }

class LuggageState {
  final LuggagePhase phase;
  final LuggageOptions? options;
  final LuggageSelection selection;
  final String? error;
  LuggageState({
    this.phase = LuggagePhase.idle,
    this.options,
    LuggageSelection? selection,
    this.error,
  }) : selection = selection ?? LuggageSelection();
}

/// One instance per trip/leg AND passenger count. No shared draft between legs.
class LuggageCubit extends Cubit<LuggageState> {
  final int tripId;
  final int passengerCount;
  final LuggageRepository repository;
  final DateTime Function() _now;
  final Duration maxPolicyAge;
  final int _session = TokenStorage.sessionVersion;
  StreamSubscription<void>? _subscription;
  int _revision = 0;
  DateTime? _loadedAt;
  bool _revoked = false;

  LuggageCubit({
    required this.tripId,
    required this.passengerCount,
    required this.repository,
    DateTime Function()? now,
    this.maxPolicyAge = const Duration(minutes: 5),
  }) : _now = now ?? DateTime.now,
       super(LuggageState()) {
    if (tripId <= 0 ||
        passengerCount < 1 ||
        passengerCount > 5 ||
        maxPolicyAge <= Duration.zero) {
      throw ArgumentError(
        'Chuyến/số hành khách/thời hạn chính sách không hợp lệ.',
      );
    }
    _subscription = TokenStorage.sessionChanges.listen((_) {
      _revoked = true;
      _revision++;
      _loadedAt = null;
      if (!isClosed) {
        emit(
          LuggageState(
            phase: LuggagePhase.revoked,
            error: 'Phiên đã thay đổi. Vui lòng mở lại hành lý.',
          ),
        );
      }
    });
  }

  bool get _active =>
      !isClosed && !_revoked && _session == TokenStorage.sessionVersion;
  bool get policyIsFresh =>
      _loadedAt != null &&
      !_now().isBefore(_loadedAt!) &&
      _now().difference(_loadedAt!) < maxPolicyAge;

  Future<void> load() async {
    if (!_active) return;
    final revision = ++_revision;
    final selection = state.selection;
    _loadedAt = null;
    emit(LuggageState(phase: LuggagePhase.loading, selection: selection));
    try {
      final options = await repository.load(tripId);
      if (!_active || revision != _revision) return;
      if (options.policy.tripId != tripId || options.cargo.tripId != tripId) {
        throw const FormatException('Sai chuyến hành lý.');
      }
      _loadedAt = _now();
      emit(
        LuggageState(
          phase: LuggagePhase.ready,
          options: options,
          selection: selection,
        ),
      );
    } catch (_) {
      if (!_active || revision != _revision) return;
      emit(
        LuggageState(
          phase: LuggagePhase.failure,
          selection: selection,
          error:
              'Không tải được chính sách hành lý. Thử lại hoặc bỏ qua để chỉ đặt vé.',
        ),
      );
    }
  }

  void select(LuggageSelection selection) {
    if (!_active || state.phase != LuggagePhase.ready) return;
    emit(
      LuggageState(
        phase: LuggagePhase.ready,
        options: state.options,
        selection: selection,
      ),
    );
  }

  void skip() {
    if (!_active) return;
    _revision++;
    _loadedAt = null;
    emit(LuggageState());
  }

  String? get validationError {
    if (!_active || state.phase == LuggagePhase.revoked) {
      return 'Phiên hành lý đã thay đổi.';
    }
    if (state.phase == LuggagePhase.idle) return null;
    if (state.phase != LuggagePhase.ready || state.options == null) {
      return state.error ?? 'Đang tải chính sách hành lý.';
    }
    if (!policyIsFresh) return 'Chính sách hành lý đã cũ. Vui lòng tải lại.';
    return state.selection.validate(
      state.options!.policy,
      state.options!.cargo,
      passengerCount,
    );
  }

  /// Only an estimate; NEVER use this amount to construct a payment or booking.
  int? get referenceFee => validationError != null
      ? null
      : state.phase == LuggagePhase.idle
      ? 0
      : state.selection.referenceFee(state.options!.policy);

  bool get requiresServerPricing => state.selection.checked.isNotEmpty;

  BookingCargoDraft? exportForBooking({
    required int expectedTripId,
    required int expectedPassengerCount,
  }) {
    if (expectedTripId != tripId || expectedPassengerCount != passengerCount) {
      throw StateError('Hành lý không thuộc chuyến/số khách hiện tại.');
    }
    final error = validationError;
    if (error != null) throw StateError(error);
    return state.selection.toBookingCargo();
  }

  @override
  Future<void> close() async {
    _revision++;
    _loadedAt = null;
    _revoked = true;
    await _subscription?.cancel();
    await super.close();
  }
}
