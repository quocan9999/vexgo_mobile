import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'cancellation_policy.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/datasources/remote/review_remote_data_source.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'my_tickets_event.dart';
import 'my_tickets_state.dart';

class MyTicketsBloc extends Bloc<MyTicketsEvent, MyTicketsState> {
  final BookingRepository bookingRepository;
  int _generation = 0;
  int get sessionGeneration => _generation;
  String? _sessionKey;
  bool _sessionInitialized = false;
  bool _authenticated;
  bool _reviewSubmitting = false;
  int? _cancellationFlight;
  final _uncertainCancellations = <String>{};
  bool cancellationUncertain(String id) =>
      _uncertainCancellations.contains('${TokenStorage.sessionVersion}:$id');

  void setSession(String? key) {
    if (_sessionInitialized &&
        _sessionKey == key &&
        _authenticated == (key != null)) {
      return;
    }
    _sessionInitialized = true;
    _sessionKey = key;
    _authenticated = key != null;
    _generation++;
    _reviewSubmitting = false;
    // Clear synchronously before pending account requests can complete.
    // ignore: invalid_use_of_visible_for_testing_member
    emit(MyTicketsState(requiresLogin: !_authenticated));
    if (_authenticated) add(const LoadMyTicketsEvent());
  }

  final ReviewRemoteDataSource reviewRemoteDataSource;

  MyTicketsBloc({
    BookingRepository? bookingRepository,
    bool authenticated = true,
    ReviewRemoteDataSource? reviewRemoteDataSource,
  }) : _authenticated = authenticated,
       bookingRepository = bookingRepository ?? HybridBookingRepository(),
       reviewRemoteDataSource =
           reviewRemoteDataSource ??
           ReviewRemoteDataSourceImpl(client: ApiClient()),
       super(const MyTicketsState()) {
    on<SyncTicketDetailsEvent>((event, emit) {
      if (!_authenticated || event.sessionGeneration != _generation) return;
      final tickets = List<TicketModel>.from(state.tickets);
      final index = tickets.indexWhere((t) => t.id == event.ticket.id);
      if (index < 0) return;
      tickets[index] = event.ticket;
      emit(
        state.copyWith(
          tickets: tickets,
          detailsRevision: state.detailsRevision + 1,
          clearMessages: true,
        ),
      );
    });
    on<LoadMyTicketsEvent>(_onLoadMyTickets);
    on<AddNewTicketEvent>(_onAddNewTicket);
    on<ChangeTabEvent>(_onChangeTab);
    on<SearchTicketsEvent>(_onSearchTickets);
    on<CancelTicketEvent>(_onCancelTicket);
    on<CheckCancellationEvent>(_onCheckCancellation);
    on<SubmitTicketReviewEvent>(_onSubmitReview);
  }

  Future<void> _onLoadMyTickets(
    LoadMyTicketsEvent event,
    Emitter<MyTicketsState> emit,
  ) async {
    if (!_authenticated) return;
    final generation = _generation;
    emit(state.copyWith(status: MyTicketsStatus.loading, clearMessages: true));

    try {
      final loadedTickets = await bookingRepository.getMyTickets();
      if (generation != _generation) return;

      emit(
        state.copyWith(
          status: MyTicketsStatus.loaded,
          tickets: loadedTickets,
          clearMessages: true,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: MyTicketsStatus.error,
          errorMessage: 'Không thể tải danh sách vé: $e',
        ),
      );
    }
  }

  void _onAddNewTicket(AddNewTicketEvent event, Emitter<MyTicketsState> emit) {
    if (!_authenticated) return;
    if (event.sessionGeneration != null &&
        event.sessionGeneration != _generation) {
      return;
    }
    if (event.tokenSessionVersion != null &&
        event.tokenSessionVersion != TokenStorage.sessionVersion) {
      return;
    }
    // Avoid duplicate
    final existingIndex = state.tickets.indexWhere(
      (t) => t.id == event.ticket.id,
    );
    List<TicketModel> updatedList;
    if (existingIndex >= 0) {
      updatedList = List.from(state.tickets);
      updatedList[existingIndex] = event.ticket;
    } else {
      updatedList = [event.ticket, ...state.tickets];
    }

    emit(
      state.copyWith(
        status: MyTicketsStatus.loaded,
        tickets: updatedList,
        selectedTab: TicketStatus.upcoming,
        successMessage:
            'Đặt vé thành công! Mã vé ${event.ticket.ticketCode} đã được lưu.',
      ),
    );
  }

  void _onChangeTab(ChangeTabEvent event, Emitter<MyTicketsState> emit) {
    emit(state.copyWith(selectedTab: event.status, clearMessages: true));
  }

  void _onSearchTickets(
    SearchTicketsEvent event,
    Emitter<MyTicketsState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query, clearMessages: true));
  }

  void _cancellationResult(
    Emitter<MyTicketsState> emit,
    TicketModel ticket,
    TicketCancellationStatus status,
    String message,
  ) {
    final tickets = List<TicketModel>.from(state.tickets);
    final index = tickets.indexWhere((t) => t.id == ticket.id);
    if (index >= 0) tickets[index] = ticket;
    emit(
      state
          .copyWith(clearMessages: true)
          .copyWith(
            tickets: tickets,
            cancellationStatus: status,
            cancellationTicketId: ticket.id,
            cancellationMessage: message,
            selectedTab: status == TicketCancellationStatus.succeeded
                ? TicketStatus.cancelled
                : null,
            successMessage: status == TicketCancellationStatus.succeeded
                ? message
                : null,
          ),
    );
  }

  Future<void> _onCancelTicket(
    CancelTicketEvent event,
    Emitter<MyTicketsState> emit,
  ) async {
    if (ApiConfig.isDemoMode) {
      await _onDemoCancelTicket(event, emit);
      return;
    }
    if (!_authenticated ||
        (event.sessionGeneration != null &&
            event.sessionGeneration != _generation) ||
        (event.tokenSessionVersion != null &&
            event.tokenSessionVersion != TokenStorage.sessionVersion) ||
        _cancellationFlight == _generation) {
      return;
    }
    final matches = state.tickets.where(
      (t) => t.id == event.ticketId || t.ticketCode == event.ticketId,
    );
    final consented =
        event.quotedTicket ?? (matches.isEmpty ? null : matches.first);
    if (consented == null) return;
    final generation = _generation;
    final version = TokenStorage.sessionVersion;
    bool current() =>
        !isClosed &&
        _authenticated &&
        generation == _generation &&
        version == TokenStorage.sessionVersion;
    if (cancellationUncertain(consented.id)) {
      _cancellationResult(
        emit,
        consented,
        TicketCancellationStatus.uncertain,
        'Chưa xác minh kết quả hủy trước đó. Chỉ kiểm tra trạng thái, không gửi lại yêu cầu.',
      );
      return;
    }
    final reason = event.reason.trim();
    if (!hasUsableCancellationQuote(consented) ||
        reason.isEmpty ||
        reason.length > 500) {
      _cancellationResult(
        emit,
        consented,
        TicketCancellationStatus.failed,
        'Thông tin phí hoặc lý do hủy chưa hợp lệ. Vui lòng tải lại và xác nhận.',
      );
      return;
    }
    _cancellationFlight = generation;
    _cancellationResult(
      emit,
      consented,
      TicketCancellationStatus.submitting,
      'Đang xác nhận yêu cầu hủy vé...',
    );
    TicketModel latest = consented;
    var submitted = false;
    try {
      final fresh = await bookingRepository.getTicketById(consented.id);
      if (!current()) return;
      if (fresh == null ||
          !fresh.hasFullDetails ||
          fresh.id != consented.id ||
          fresh.ticketCode != consented.ticketCode) {
        throw StateError('Không xác minh được vé cần hủy.');
      }
      latest = fresh;
      if (!state.tickets.any((t) => t.id == fresh.id)) {
        emit(state.copyWith(tickets: [...state.tickets, fresh]));
      }
      if (!hasUsableCancellationQuote(fresh) ||
          !sameCancellationQuote(consented, fresh)) {
        _cancellationResult(
          emit,
          fresh,
          TicketCancellationStatus.failed,
          fresh.cancellation?.reason ??
              'Phí hủy hoặc thông tin vé đã thay đổi. Vui lòng xem và đồng ý lại.',
        );
        return;
      }
      submitted = true;
      final response = await bookingRepository.cancelTicket(
        ticketCode: fresh.ticketCode,
        phoneNumber: fresh.passenger.phone,
        reason: reason,
        expectedCancelFeeRate: consented.cancellation!.cancelFeeRate,
      );
      if (!current()) return;
      final payload = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      if (!confirmsCancellation(payload, fresh)) {
        throw StateError('Phản hồi hủy không khớp vé.');
      }
      final cancelled = fresh.copyWith(
        status: TicketStatus.cancelled,
        rawStatus: 'HUY',
        cancelReason: reason,
        refundAmount: (payload['refundAmount'] as num?)?.toInt(),
      );
      _cancellationResult(
        emit,
        cancelled,
        TicketCancellationStatus.succeeded,
        payload['refundAmount'] != null
            ? 'Hủy vé ${fresh.ticketCode} thành công. Số tiền dự kiến hoàn: ${payload['refundAmount']} đ. Việc hoàn tiền cần được xác nhận riêng.'
            : 'Hủy vé ${fresh.ticketCode} thành công, đang chờ xử lý hoàn tiền. Kết quả hoàn tiền cần được xác nhận riêng.',
      );
    } catch (error) {
      if (!current()) return;
      final rejected =
          error is ApiException &&
          error.statusCode >= 400 &&
          error.statusCode < 500 &&
          error.statusCode != 408;
      if (submitted && !rejected) {
        _uncertainCancellations.add('$version:${consented.id}');
        try {
          final checked = await bookingRepository.getTicketById(consented.id);
          if (!current()) return;
          if (checked != null &&
              checked.hasFullDetails &&
              checked.id == consented.id &&
              checked.ticketCode == consented.ticketCode &&
              checked.status == TicketStatus.cancelled &&
              TicketModel.parseSupportedStatus(checked.rawStatus) ==
                  TicketStatus.cancelled) {
            _uncertainCancellations.remove('$version:${consented.id}');
            _cancellationResult(
              emit,
              checked,
              TicketCancellationStatus.succeeded,
              'Đã xác nhận vé bị hủy. Việc hoàn tiền cần được xác nhận riêng.',
            );
            return;
          }
        } catch (_) {
          if (!current()) return;
        }
        _cancellationResult(
          emit,
          latest,
          TicketCancellationStatus.uncertain,
          'Chưa xác minh kết quả hủy vé. Vui lòng kiểm tra trạng thái; không gửi lại yêu cầu.',
        );
      } else {
        _cancellationResult(
          emit,
          latest,
          TicketCancellationStatus.failed,
          error is ApiException &&
                  error.errorCode == 'CANCELLATION_QUOTE_EXPIRED'
              ? 'Phí hủy đã thay đổi. Vui lòng xem và đồng ý lại mức phí mới.'
              : 'Không thể hủy vé. Vui lòng tải lại thông tin và xác nhận mức phí.',
        );
      }
    } finally {
      if (_cancellationFlight == generation) _cancellationFlight = null;
    }
  }

  Future<void> _onCheckCancellation(
    CheckCancellationEvent event,
    Emitter<MyTicketsState> emit,
  ) async {
    if (!_authenticated ||
        _cancellationFlight == _generation ||
        !cancellationUncertain(event.ticketId)) {
      return;
    }
    final generation = _generation;
    final version = TokenStorage.sessionVersion;
    final matches = state.tickets.where((t) => t.id == event.ticketId);
    if (matches.isEmpty) return;
    final ticket = matches.first;
    _cancellationFlight = generation;
    _cancellationResult(
      emit,
      ticket,
      TicketCancellationStatus.submitting,
      'Đang kiểm tra trạng thái vé...',
    );
    try {
      final checked = await bookingRepository.getTicketById(event.ticketId);
      if (generation != _generation ||
          version != TokenStorage.sessionVersion ||
          isClosed) {
        return;
      }
      if (checked != null &&
          checked.hasFullDetails &&
          checked.id == ticket.id &&
          checked.ticketCode == ticket.ticketCode &&
          checked.status == TicketStatus.cancelled &&
          TicketModel.parseSupportedStatus(checked.rawStatus) ==
              TicketStatus.cancelled) {
        _uncertainCancellations.remove('$version:${ticket.id}');
        _cancellationResult(
          emit,
          checked,
          TicketCancellationStatus.succeeded,
          'Đã xác nhận vé bị hủy. Việc hoàn tiền cần được xác nhận riêng.',
        );
        return;
      }
    } catch (_) {
      if (generation != _generation ||
          version != TokenStorage.sessionVersion ||
          isClosed) {
        return;
      }
    } finally {
      if (_cancellationFlight == generation) _cancellationFlight = null;
    }
    _cancellationResult(
      emit,
      ticket,
      TicketCancellationStatus.uncertain,
      'Chưa xác minh kết quả hủy vé. Vui lòng kiểm tra lại sau; không gửi lại yêu cầu.',
    );
  }

  Future<void> _onDemoCancelTicket(
    CancelTicketEvent event,
    Emitter<MyTicketsState> emit,
  ) async {
    if (!_authenticated) return;
    final generation = _generation;
    final ticketIndex = state.tickets.indexWhere(
      (t) => t.id == event.ticketId || t.ticketCode == event.ticketId,
    );
    if (ticketIndex == -1) {
      emit(
        state.copyWith(
          errorMessage: 'Không tìm thấy thông tin vé cần hủy.',
          clearMessages: false,
        ),
      );
      return;
    }

    final ticket = state.tickets[ticketIndex];

    // Business Rule sub_uc_huy_ve: Cancellation requires departure eligibility
    if (!ticket.canCancel) {
      emit(
        state.copyWith(
          errorMessage:
              'Không thể hủy vé vì chuyến xe khởi hành trong vòng dưới 12 giờ (dưới 3 giờ theo quy định tối thiểu nhà xe)! Vui lòng liên hệ tổng đài để được trợ giúp.',
          clearMessages: false,
        ),
      );
      return;
    }

    try {
      final cancelResult = await bookingRepository.cancelTicket(
        ticketCode: ticket.ticketCode,
        phoneNumber: ticket.passenger.phone,
        reason: event.reason,
        expectedCancelFeeRate: ticket.cancelFeeRate,
      );

      if (generation != _generation) return;
      final payload = cancelResult['data'] is Map<String, dynamic>
          ? cancelResult['data'] as Map<String, dynamic>
          : cancelResult;

      final serverRefund = (payload['refundAmount'] as num?)?.toInt();

      final updatedTicket = ticket.copyWith(
        status: TicketStatus.cancelled,
        cancelReason: event.reason,
        refundAmount: serverRefund,
      );

      final updatedList = List<TicketModel>.from(state.tickets);
      final currentIndex = updatedList.indexWhere((t) => t.id == ticket.id);
      if (currentIndex < 0) return;
      updatedList[currentIndex] = updatedTicket;

      final successMessage = serverRefund != null
          ? 'Hủy vé ${ticket.ticketCode} thành công! Số tiền hoàn lại: $serverRefund đ.'
          : 'Yêu cầu hủy vé ${ticket.ticketCode} đã được tiếp nhận và đang chờ xử lý hoàn tiền.';

      emit(
        state.copyWith(
          tickets: updatedList,
          selectedTab: TicketStatus.cancelled,
          successMessage: successMessage,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          errorMessage: 'Không thể hủy vé: $e',
          clearMessages: false,
        ),
      );
    }
  }

  Future<void> _onSubmitReview(
    SubmitTicketReviewEvent event,
    Emitter<MyTicketsState> emit,
  ) async {
    if (!_authenticated || _reviewSubmitting) return;
    final generation = _generation;
    final ticketIndex = state.tickets.indexWhere(
      (t) => t.id == event.ticketId || t.ticketCode == event.ticketId,
    );
    if (ticketIndex == -1) {
      emit(state.copyWith(errorMessage: 'Không tìm thấy vé để đánh giá.'));
      return;
    }

    final ticket = state.tickets[ticketIndex];

    if (ticket.review != null) {
      emit(state.copyWith(clearMessages: true));
      emit(state.copyWith(errorMessage: 'Bạn đã đánh giá chuyến đi này rồi.'));
      return;
    }

    if (ApiConfig.isDemoMode) {
      if (generation != _generation) return;
      final updatedTicket = ticket.copyWith(review: event.review);
      final updatedList = List<TicketModel>.from(state.tickets);
      final currentIndex = updatedList.indexWhere((t) => t.id == ticket.id);
      if (currentIndex < 0) return;
      updatedList[currentIndex] = updatedTicket;

      emit(
        state.copyWith(
          tickets: updatedList,
          successMessage:
              '[Demo] Đánh giá đã được ghi nhận cục bộ (chế độ thử nghiệm).',
        ),
      );
      return;
    }

    _reviewSubmitting = true;
    emit(state.copyWith(clearMessages: true));
    try {
      // Resolve tripId authoritatively: check ticket.trip.id, or query booking
      int? tripId;
      final parsedTripId = int.tryParse(ticket.trip.id);
      if (parsedTripId != null && parsedTripId > 0) {
        tripId = parsedTripId;
      } else if (ticket.bookingId != null) {
        final booking = await bookingRepository.getBookingById(
          ticket.bookingId,
        );
        if (generation != _generation) return;
        if (booking != null &&
            booking.bookingId.toString() == ticket.bookingId.toString() &&
            booking.tripId > 0) {
          tripId = booking.tripId;
        }
      }

      if (tripId == null || tripId <= 0) {
        emit(
          state.copyWith(
            errorMessage:
                'Không thể xác định mã chuyến đi hợp lệ để gửi đánh giá.',
          ),
        );
        return;
      }

      final savedReview = await reviewRemoteDataSource.createReview(
        tripId: tripId,
        rating: event.review.rating.round(),
        comment: event.review.comment,
      );

      if (generation != _generation) return;
      final updatedList = List<TicketModel>.from(state.tickets);
      final currentIndex = updatedList.indexWhere((t) => t.id == ticket.id);
      if (currentIndex < 0) return;
      for (var i = 0; i < updatedList.length; i++) {
        final current = updatedList[i];
        if (current.id == ticket.id ||
            int.tryParse(current.trip.id) == tripId) {
          updatedList[i] = current.copyWith(review: savedReview);
        }
      }

      emit(
        state.copyWith(
          tickets: updatedList,
          successMessage:
              'Cảm ơn bạn đã gửi đánh giá cho chuyến đi của nhà xe ${ticket.trip.operatorName}!',
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          errorMessage:
              'Tính năng đánh giá chuyến đi chưa khả dụng trên máy chủ hiện tại ($e).',
        ),
      );
    } finally {
      if (generation == _generation) _reviewSubmitting = false;
    }
  }
}
