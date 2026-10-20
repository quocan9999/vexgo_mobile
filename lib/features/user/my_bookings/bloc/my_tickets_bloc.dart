import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
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

  Future<void> _onCancelTicket(
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
      final updatedTicket = ticket.copyWith(review: savedReview);
      final updatedList = List<TicketModel>.from(state.tickets);
      final currentIndex = updatedList.indexWhere((t) => t.id == ticket.id);
      if (currentIndex < 0) return;
      updatedList[currentIndex] = updatedTicket;

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
