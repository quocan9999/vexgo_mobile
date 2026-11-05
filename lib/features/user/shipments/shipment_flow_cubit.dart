import 'dart:convert';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/network/vietqr_config.dart';
import '../../../data/models/shipment_model.dart';
import '../../../data/repositories/shipment_repository.dart';

export '../../../data/models/shipment_model.dart';

enum ShipmentCreationPhase {
  editing,
  submitting,
  created,
  uncertain,
  invalidated,
}

class ShipmentFlowState {
  final ShipmentCreationPhase phase;
  final ShipmentDraft? draft;
  final List<ShipmentRoute> routes;
  final int? selectedRouteId;
  final ShipmentOptions? options;
  final ShipmentQuote? quote;
  final bool quoting;
  final String? quoteError, quoteFingerprint;
  final DateTime? quotedAt;
  final String? sendDate;
  final ShipmentRecord? record;
  final ShipmentIdentity? recovery;
  final ShipmentLookup? lookup;
  final ShipmentLookup? paymentSnapshot;
  final ShipmentPage? myShipments;
  final bool searching, loadingOptions, lookingUp, loadingMine, refreshing;
  final String? searchError,
      optionsError,
      createError,
      lookupError,
      listError,
      refreshError;
  final Map<String, String> fieldErrors;
  final DateTime? verifiedAt;
  final DateTime? nextPaymentReadAt;
  const ShipmentFlowState({
    this.phase = ShipmentCreationPhase.editing,
    this.draft,
    this.routes = const [],
    this.selectedRouteId,
    this.options,
    this.record,
    this.quote,
    this.quoting = false,
    this.quoteError,
    this.quoteFingerprint,
    this.quotedAt,
    this.sendDate,
    this.recovery,
    this.lookup,
    this.paymentSnapshot,
    this.myShipments,
    this.searching = false,
    this.loadingOptions = false,
    this.lookingUp = false,
    this.loadingMine = false,
    this.refreshing = false,
    this.searchError,
    this.optionsError,
    this.createError,
    this.lookupError,
    this.listError,
    this.refreshError,
    this.fieldErrors = const {},
    this.verifiedAt,
    this.nextPaymentReadAt,
  });

  // Explicit null setters avoid silently retaining data after a failed/new read.
  ShipmentFlowState copyWith({
    ShipmentCreationPhase? phase,
    ShipmentDraft? Function()? draft,
    List<ShipmentRoute>? routes,
    int? Function()? selectedRouteId,
    ShipmentOptions? Function()? options,
    ShipmentQuote? Function()? quote,
    bool? quoting,
    String? Function()? quoteError,
    String? Function()? quoteFingerprint,
    DateTime? Function()? quotedAt,
    String? Function()? sendDate,
    ShipmentRecord? Function()? record,
    ShipmentIdentity? Function()? recovery,
    ShipmentLookup? Function()? lookup,
    ShipmentLookup? Function()? paymentSnapshot,
    ShipmentPage? Function()? myShipments,
    bool? searching,
    bool? loadingOptions,
    bool? lookingUp,
    bool? loadingMine,
    bool? refreshing,
    String? Function()? searchError,
    String? Function()? optionsError,
    String? Function()? createError,
    String? Function()? lookupError,
    String? Function()? listError,
    String? Function()? refreshError,
    Map<String, String>? fieldErrors,
    DateTime? Function()? verifiedAt,
    DateTime? Function()? nextPaymentReadAt,
  }) => ShipmentFlowState(
    phase: phase ?? this.phase,
    draft: draft != null ? draft() : this.draft,
    routes: routes ?? this.routes,
    selectedRouteId: selectedRouteId != null
        ? selectedRouteId()
        : this.selectedRouteId,
    options: options != null ? options() : this.options,
    quote: quote != null ? quote() : this.quote,
    quoting: quoting ?? this.quoting,
    quoteError: quoteError != null ? quoteError() : this.quoteError,
    quoteFingerprint: quoteFingerprint != null
        ? quoteFingerprint()
        : this.quoteFingerprint,
    quotedAt: quotedAt != null ? quotedAt() : this.quotedAt,
    sendDate: sendDate != null ? sendDate() : this.sendDate,
    record: record != null ? record() : this.record,
    recovery: recovery != null ? recovery() : this.recovery,
    lookup: lookup != null ? lookup() : this.lookup,
    paymentSnapshot: paymentSnapshot != null
        ? paymentSnapshot()
        : this.paymentSnapshot,
    myShipments: myShipments != null ? myShipments() : this.myShipments,
    searching: searching ?? this.searching,
    loadingOptions: loadingOptions ?? this.loadingOptions,
    lookingUp: lookingUp ?? this.lookingUp,
    loadingMine: loadingMine ?? this.loadingMine,
    refreshing: refreshing ?? this.refreshing,
    searchError: searchError != null ? searchError() : this.searchError,
    optionsError: optionsError != null ? optionsError() : this.optionsError,
    createError: createError != null ? createError() : this.createError,
    lookupError: lookupError != null ? lookupError() : this.lookupError,
    listError: listError != null ? listError() : this.listError,
    refreshError: refreshError != null ? refreshError() : this.refreshError,
    fieldErrors: Map.unmodifiable(fieldErrors ?? this.fieldErrors),
    verifiedAt: verifiedAt != null ? verifiedAt() : this.verifiedAt,
    nextPaymentReadAt: nextPaymentReadAt != null
        ? nextPaymentReadAt()
        : this.nextPaymentReadAt,
  );
}

/// One owner per shipments flow; UI must retain it across create/result screens.
/// No timers: UI may refresh while visible, at most once per 15 seconds.
class ShipmentFlowCubit extends Cubit<ShipmentFlowState> {
  final ShipmentRepository repository;
  final VietQrReceivingAccount account;
  final DateTime Function() now;
  late final int _session;
  late final StreamSubscription<void> _changes, _invalidations;
  int _quote = 0;
  int _search = 0,
      _options = 0,
      _lookup = 0,
      _list = 0,
      _refresh = 0,
      _detail = 0;
  bool _mutation = false;
  ShipmentFlowCubit({
    required this.repository,
    this.account = VietQrConfig.account,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now,
       super(const ShipmentFlowState()) {
    _session = TokenStorage.sessionVersion;
    _changes = TokenStorage.sessionChanges.listen((_) => invalidate());
    _invalidations = TokenStorage.sessionInvalidations.listen(
      (_) => invalidate(),
    );
  }
  bool get _current =>
      !isClosed &&
      _session == TokenStorage.sessionVersion &&
      state.phase != ShipmentCreationPhase.invalidated;
  bool get _editable =>
      _current && !_mutation && state.phase == ShipmentCreationPhase.editing;
  String _message(Object error) => error is ApiException
      ? error.message
      : error is ShipmentValidationException
      ? error.toString()
      : 'Không thể xác minh dữ liệu từ máy chủ. Vui lòng kiểm tra kết nối và thử tải lại.';
  void invalidate() {
    if (isClosed || state.phase == ShipmentCreationPhase.invalidated) return;
    _quote++;
    _search++;
    _options++;
    _lookup++;
    _list++;
    _refresh++;
    emit(const ShipmentFlowState(phase: ShipmentCreationPhase.invalidated));
  }

  void clearRouteSelection() {
    if (!_editable) return;
    _search++;
    _options++;
    _quote++;
    emit(
      state.copyWith(
        routes: [],
        selectedRouteId: () => null,
        options: () => null,
        draft: () => null,
        quote: () => null,
        quoteFingerprint: () => null,
        searching: false,
        loadingOptions: false,
        quoting: false,
        searchError: () => null,
        optionsError: () => null,
        quoteError: () => null,
      ),
    );
  }

  Future<void> searchRoutes({
    required String from,
    required String to,
    required String date,
    int page = 1,
  }) async {
    if (!_editable) return;
    final request = ++_search;
    ++_quote;
    ++_options;
    emit(
      state.copyWith(
        searching: true,
        sendDate: () => date,
        quote: () => null,
        quoting: false,
        quoteError: () => null,
        quoteFingerprint: () => null,
        loadingOptions: false,
        routes: [],
        selectedRouteId: () => null,
        options: () => null,
        draft: () => null,
        searchError: () => null,
        optionsError: () => null,
      ),
    );
    try {
      final routes = await repository.searchRoutes(
        from: from,
        to: to,
        date: date,
        page: page,
      );
      if (!_current || request != _search) return;
      emit(state.copyWith(searching: false, routes: List.unmodifiable(routes)));
    } catch (e) {
      if (_current && request == _search) {
        emit(state.copyWith(searching: false, searchError: () => _message(e)));
      }
    }
  }

  Future<void> selectRoute(int routeId) async {
    if (!_editable || !state.routes.any((t) => t.id == routeId)) return;
    final request = ++_options;
    ++_quote;
    emit(
      state.copyWith(
        selectedRouteId: () => routeId,
        quote: () => null,
        quoting: false,
        quoteError: () => null,
        quoteFingerprint: () => null,
        loadingOptions: true,
        options: () => null,
        draft: () => null,
        optionsError: () => null,
        createError: () => null,
        fieldErrors: {},
      ),
    );
    try {
      final options = await repository.loadOptions(routeId);
      if (!_current || request != _options) return;
      if (options.routeId != routeId) {
        throw const FormatException('Wrong trip');
      }
      emit(
        state.copyWith(
          loadingOptions: false,
          options: () => options,
          optionsError: () =>
              options.senders.isEmpty || options.receivers.isEmpty
              ? 'Tuyến chưa có đủ điểm gửi và nhận.'
              : null,
        ),
      );
    } catch (e) {
      if (_current && request == _options) {
        emit(
          state.copyWith(
            loadingOptions: false,
            optionsError: () => _message(e),
          ),
        );
      }
    }
  }

  void updateDraft(ShipmentDraft draft) {
    if (!_editable) return;
    ++_quote;
    emit(
      state.copyWith(
        quote: () => null,
        quoting: false,
        quoteError: () => null,
        quoteFingerprint: () => null,
        draft: () => draft,
        fieldErrors: {},
        createError: () => null,
      ),
    );
  }

  String _fingerprint(ShipmentDraft draft) => jsonEncode(draft.toJson());

  bool hasCurrentQuoteFor(ShipmentDraft draft) {
    final age = state.quotedAt == null
        ? null
        : now().toUtc().difference(state.quotedAt!);
    return _current &&
        draft.errors.isEmpty &&
        !state.quoting &&
        state.quote != null &&
        age != null &&
        !age.isNegative &&
        age <= const Duration(minutes: 2) &&
        state.quoteFingerprint == _fingerprint(draft);
  }

  void invalidateQuote() {
    if (!_editable) return;
    _quote++;
    emit(
      state.copyWith(
        quote: () => null,
        quoteFingerprint: () => null,
        quotedAt: () => null,
        quoteError: () => null,
        quoting: false,
      ),
    );
  }

  Future<void> refreshQuote() async {
    if (!_editable || state.draft == null) return;
    final draft = state.draft!;
    if (draft.errors.isNotEmpty ||
        draft.routeId != state.selectedRouteId ||
        draft.sendDate != state.sendDate) {
      emit(
        state.copyWith(
          fieldErrors: {
            ...draft.errors,
            'quote': 'Kiểm tra tuyến, ngày gửi và thông tin kiện hàng.',
          },
        ),
      );
      return;
    }
    final request = ++_quote, fingerprint = _fingerprint(draft);
    emit(
      state.copyWith(
        quoting: true,
        quote: () => null,
        quoteError: () => null,
        quoteFingerprint: () => null,
        quotedAt: () => null,
      ),
    );
    try {
      final quote = await repository.quote(draft);
      if (!_current ||
          request != _quote ||
          state.draft == null ||
          _fingerprint(state.draft!) != fingerprint) {
        return;
      }
      emit(
        state.copyWith(
          quoting: false,
          quote: () => quote,
          quoteFingerprint: () => fingerprint,
          quotedAt: () => now().toUtc(),
        ),
      );
    } catch (e) {
      if (_current && request == _quote) {
        emit(state.copyWith(quoting: false, quoteError: () => _message(e)));
      }
    }
  }

  Future<void> create() async {
    if (!_editable) return;
    final draft = state.draft, options = state.options;
    if (draft == null) {
      emit(state.copyWith(fieldErrors: {'draft': 'Nhập thông tin gửi hàng.'}));
      return;
    }
    final errors = {...draft.errors};
    if (options == null ||
        options.routeId != draft.routeId ||
        state.selectedRouteId != draft.routeId) {
      errors['routeId'] = 'Cần tải cấu hình nhận hàng của đúng tuyến.';
    } else {
      if (!(options.senders.any((p) => p.id == draft.senderPointId))) {
        errors['senderPointId'] = 'Điểm gửi không thuộc tuyến đã chọn.';
      }
      if (!(options.receivers.any((p) => p.id == draft.receiverPointId))) {
        errors['receiverPointId'] = 'Điểm nhận không thuộc tuyến đã chọn.';
      }
      for (var i = 0; i < draft.items.length; i++) {
        if (!options.categories.any((c) => c.id == draft.items[i].categoryId)) {
          errors['items.$i.categoryId'] = 'Loại hàng không còn hợp lệ.';
        }
      }
    }
    if (draft.sendDate != state.sendDate) {
      errors['sendDate'] = 'Ngày gửi đã thay đổi; tìm lại tuyến.';
    }
    final age = state.quotedAt == null
        ? null
        : now().toUtc().difference(state.quotedAt!);
    if (errors.isEmpty &&
        (state.quoting ||
            state.quote == null ||
            age == null ||
            age.isNegative ||
            age > const Duration(minutes: 2) ||
            state.quoteFingerprint != _fingerprint(draft))) {
      errors['quote'] = 'Cần báo giá lại cho thông tin hiện tại.';
    }
    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors));
      return;
    }
    await _submit(draft);
  }

  /// Explicit retry uses the same repository-held idempotency key and payload.
  Future<void> retryUncertainCreation() async {
    if (!_current ||
        _mutation ||
        state.phase != ShipmentCreationPhase.uncertain ||
        state.draft == null) {
      return;
    }
    await _submit(state.draft!, retryUncertain: true);
  }

  Future<void> _submit(
    ShipmentDraft draft, {
    bool retryUncertain = false,
  }) async {
    _mutation = true;
    emit(
      state.copyWith(
        phase: ShipmentCreationPhase.submitting,
        fieldErrors: {},
        createError: () => null,
      ),
    );
    try {
      final record = await repository.create(
        draft,
        retryUncertain: retryUncertain,
      );
      if (!_current) return;
      emit(
        state.copyWith(
          phase: ShipmentCreationPhase.created,
          record: () => record,
          recovery: () => record.identity,
          lookup: () => null,
          verifiedAt: () => null,
        ),
      );
    } catch (e) {
      if (!_current) return;
      final rejected =
          e is ApiException &&
          e.statusCode >= 400 &&
          e.statusCode < 500 &&
          e.statusCode != 408 &&
          e.statusCode != 409;
      emit(
        state.copyWith(
          phase: rejected
              ? ShipmentCreationPhase.editing
              : ShipmentCreationPhase.uncertain,
          recovery: () => e is ShipmentCreationUncertain ? e.identity : null,
          fieldErrors: e is ApiException
              ? {for (final d in e.details) d.field: d.message}
              : {},
          createError: () => rejected
              ? _message(e)
              : 'Chưa xác minh kết quả tạo đơn. Không tạo lại; hãy tra cứu vận đơn hoặc liên hệ hỗ trợ.',
        ),
      );
    } finally {
      _mutation = false;
    }
  }

  Future<void> lookup({
    required String waybillCode,
    required String phone,
  }) async {
    if (!_current) return;
    final request = ++_lookup;
    emit(
      state.copyWith(
        lookingUp: true,
        lookup: () => null,
        verifiedAt: () => null,
        lookupError: () => null,
      ),
    );
    try {
      final result = await repository.lookup(
        waybillCode: waybillCode,
        phone: phone,
      );
      if (!_current || request != _lookup) return;
      emit(
        state.copyWith(
          lookingUp: false,
          lookup: () => result,
          verifiedAt: () => now().toUtc(),
        ),
      );
    } catch (e) {
      if (_current && request == _lookup) {
        emit(state.copyWith(lookingUp: false, lookupError: () => _message(e)));
      }
    }
  }

  Future<void> loadMine({
    int page = 1,
    int pageSize = 10,
    String search = '',
    ShipmentStatus? status,
  }) async {
    if (!_current) return;
    final request = ++_list;
    emit(
      state.copyWith(
        loadingMine: true,
        myShipments: () => null,
        listError: () => null,
      ),
    );
    try {
      final result = await repository.listMine(
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
      );
      if (!_current || request != _list) return;
      emit(state.copyWith(loadingMine: false, myShipments: () => result));
    } catch (e) {
      if (_current && request == _list) {
        emit(state.copyWith(loadingMine: false, listError: () => _message(e)));
      }
    }
  }

  Future<void> openDetail(int shipmentId) async {
    if (!_current ||
        _mutation ||
        state.phase == ShipmentCreationPhase.uncertain) {
      return;
    }
    final request = ++_detail;
    ++_refresh;
    emit(
      state.copyWith(
        phase: ShipmentCreationPhase.created,
        refreshing: true,
        record: () => null,
        recovery: () => null,
        paymentSnapshot: () => null,
        verifiedAt: () => null,
        refreshError: () => null,
        nextPaymentReadAt: () => null,
      ),
    );
    try {
      final record = await repository.detail(shipmentId);
      if (!_current || request != _detail) return;
      emit(
        state.copyWith(
          refreshing: false,
          record: () => record,
          recovery: () => record.identity,
        ),
      );
    } catch (e) {
      if (_current && request == _detail) {
        emit(
          state.copyWith(refreshing: false, refreshError: () => _message(e)),
        );
      }
    }
  }

  Future<void> recoverKnownCreation() async {
    if (!_current ||
        _mutation ||
        state.refreshing ||
        state.recovery == null ||
        state.draft == null) {
      return;
    }
    final identity = state.recovery!, draft = state.draft!;
    emit(state.copyWith(refreshing: true, refreshError: () => null));
    try {
      final record = await repository.detail(identity.shipmentId);
      if (!_current) return;
      if (record.identity.orderId != identity.orderId ||
          record.identity.orderCode != identity.orderCode ||
          record.identity.waybillCode != identity.waybillCode ||
          record.senderPointId != draft.senderPointId ||
          record.receiverPointId != draft.receiverPointId ||
          record.expectedSendDate != draft.sendDate ||
          normalizeShipmentPhone(record.senderPhone) !=
              normalizeShipmentPhone(draft.senderPhone)) {
        throw const FormatException('Recovery record does not match creation');
      }
      emit(
        state.copyWith(
          refreshing: false,
          phase: ShipmentCreationPhase.created,
          record: () => record,
        ),
      );
    } catch (e) {
      if (_current) {
        emit(
          state.copyWith(refreshing: false, refreshError: () => _message(e)),
        );
      }
    }
  }

  Future<void> refreshPayment() async {
    if (!_current ||
        state.refreshing ||
        state.lookingUp ||
        state.record == null) {
      return;
    }
    final localNow = now().toUtc();
    if (state.nextPaymentReadAt != null &&
        localNow.isBefore(state.nextPaymentReadAt!)) {
      return;
    }
    final record = state.record!, request = ++_refresh;
    // Hide previous QR immediately; failure must never keep a stale payment action.
    emit(
      state.copyWith(
        refreshing: true,
        paymentSnapshot: () => null,
        verifiedAt: () => null,
        nextPaymentReadAt: () => localNow.add(const Duration(seconds: 15)),
        refreshError: () => null,
      ),
    );
    try {
      final result = await repository.lookup(
        waybillCode: record.identity.waybillCode,
        phone: record.senderPhone,
      );
      if (!_current || request != _refresh) return;
      if (result.orderCode != record.identity.orderCode ||
          result.amount != record.totalFee ||
          result.paymentMethod != record.paymentMethod ||
          result.waybillCode != record.identity.waybillCode) {
        throw const FormatException(
          'Payment lookup belongs to another order or amount',
        );
      }
      emit(
        state.copyWith(
          refreshing: false,
          paymentSnapshot: () => result,
          verifiedAt: () => now().toUtc(),
        ),
      );
    } catch (e) {
      if (_current && request == _refresh) {
        emit(
          state.copyWith(
            refreshing: false,
            refreshError: () => _message(e),
            nextPaymentReadAt: () => now().toUtc().add(
              Duration(
                seconds: e is ApiException && e.statusCode == 429 ? 60 : 15,
              ),
            ),
          ),
        );
      }
    }
  }

  ShipmentLookup? get verifiedPayment {
    if (!_current ||
        state.refreshing ||
        state.record == null ||
        state.paymentSnapshot == null ||
        state.verifiedAt == null) {
      return null;
    }
    final record = state.record!, value = state.paymentSnapshot!;
    final elapsed = now().toUtc().difference(state.verifiedAt!);
    if (elapsed.isNegative ||
        elapsed > const Duration(seconds: 30) ||
        value.orderCode != record.identity.orderCode ||
        value.waybillCode != record.identity.waybillCode ||
        value.amount != record.totalFee ||
        value.paymentMethod != record.paymentMethod) {
      return null;
    }
    return value;
  }

  /// UI recomputes this on ticks/lifecycle resume. A timer never marks a payment paid.
  String? get paymentQrUrl => null;

  @override
  Future<void> close() async {
    await _changes.cancel();
    await _invalidations.cancel();
    await super.close();
  }
}
