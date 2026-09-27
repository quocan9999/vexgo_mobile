import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'my_tickets_event.dart';
import 'my_tickets_state.dart';

class MyTicketsBloc extends Bloc<MyTicketsEvent, MyTicketsState> {
  MyTicketsBloc() : super(const MyTicketsState()) {
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
    // If already loaded and we have tickets, don't overwrite if not necessary
    if (state.tickets.isNotEmpty && state.status == MyTicketsStatus.loaded) {
      return;
    }

    emit(state.copyWith(status: MyTicketsStatus.loading, clearMessages: true));

    try {
      final jsonStr = await rootBundle.loadString('assets/mock_data/my_tickets.json');
      final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
      final loadedTickets = jsonList
          .map((item) => TicketModel.fromJson(item as Map<String, dynamic>))
          .toList();

      emit(state.copyWith(
        status: MyTicketsStatus.loaded,
        tickets: loadedTickets,
        clearMessages: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MyTicketsStatus.error,
        errorMessage: 'Không thể tải danh sách vé: $e',
      ));
    }
  }

  void _onAddNewTicket(
    AddNewTicketEvent event,
    Emitter<MyTicketsState> emit,
  ) {
    // Avoid duplicate
    final existingIndex = state.tickets.indexWhere((t) => t.id == event.ticket.id);
    List<TicketModel> updatedList;
    if (existingIndex >= 0) {
      updatedList = List.from(state.tickets);
      updatedList[existingIndex] = event.ticket;
    } else {
      updatedList = [event.ticket, ...state.tickets];
    }

    emit(state.copyWith(
      status: MyTicketsStatus.loaded,
      tickets: updatedList,
      selectedTab: TicketStatus.upcoming,
      successMessage: 'Đặt vé thành công! Mã vé ${event.ticket.ticketCode} đã được lưu.',
    ));
  }

  void _onChangeTab(
    ChangeTabEvent event,
    Emitter<MyTicketsState> emit,
  ) {
    emit(state.copyWith(
      selectedTab: event.status,
      clearMessages: true,
    ));
  }

  void _onSearchTickets(
    SearchTicketsEvent event,
    Emitter<MyTicketsState> emit,
  ) {
    emit(state.copyWith(
      searchQuery: event.query,
      clearMessages: true,
    ));
  }

  void _onCancelTicket(
    CancelTicketEvent event,
    Emitter<MyTicketsState> emit,
  ) {
    final ticketIndex = state.tickets.indexWhere((t) => t.id == event.ticketId);
    if (ticketIndex == -1) {
      emit(state.copyWith(
        errorMessage: 'Không tìm thấy thông tin vé cần hủy.',
        clearMessages: false,
      ));
      return;
    }

    final ticket = state.tickets[ticketIndex];

    // Business Rule sub_uc_huy_ve: Cancellation requires >= 3 hours before departure
    if (!ticket.canCancel) {
      emit(state.copyWith(
        errorMessage:
            'Không thể hủy vé vì chuyến xe khởi hành trong vòng dưới 3 giờ theo quy định nhà xe! Vui lòng liên hệ tổng đài để được trợ giúp.',
        clearMessages: false,
      ));
      return;
    }

    final updatedTicket = ticket.copyWith(
      status: TicketStatus.cancelled,
      cancelReason: event.reason,
      refundAmount: event.refundAmount,
    );

    final updatedList = List<TicketModel>.from(state.tickets);
    updatedList[ticketIndex] = updatedTicket;

    emit(state.copyWith(
      tickets: updatedList,
      selectedTab: TicketStatus.cancelled,
      successMessage: 'Hủy vé ${ticket.ticketCode} thành công! Số tiền hoàn lại: ${event.refundAmount} đ.',
    ));
  }

  void _onSubmitReview(
    SubmitTicketReviewEvent event,
    Emitter<MyTicketsState> emit,
  ) {
    final ticketIndex = state.tickets.indexWhere((t) => t.id == event.ticketId);
    if (ticketIndex == -1) {
      emit(state.copyWith(errorMessage: 'Không tìm thấy vé để đánh giá.'));
      return;
    }

    final ticket = state.tickets[ticketIndex];
    final updatedTicket = ticket.copyWith(review: event.review);

    final updatedList = List<TicketModel>.from(state.tickets);
    updatedList[ticketIndex] = updatedTicket;

    emit(state.copyWith(
      tickets: updatedList,
      successMessage: 'Cảm ơn bạn đã gửi đánh giá cho chuyến đi của nhà xe ${ticket.trip.operatorName}!',
    ));
  }
}
