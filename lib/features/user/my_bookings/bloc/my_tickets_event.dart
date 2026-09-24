import 'package:equatable/equatable.dart';
import 'package:vexgo_app/data/models/review_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';

abstract class MyTicketsEvent extends Equatable {
  const MyTicketsEvent();

  @override
  List<Object?> get props => [];
}

class LoadMyTicketsEvent extends MyTicketsEvent {
  const LoadMyTicketsEvent();
}

class AddNewTicketEvent extends MyTicketsEvent {
  final TicketModel ticket;

  const AddNewTicketEvent(this.ticket);

  @override
  List<Object?> get props => [ticket];
}

class ChangeTabEvent extends MyTicketsEvent {
  final TicketStatus status;

  const ChangeTabEvent(this.status);

  @override
  List<Object?> get props => [status];
}

class SearchTicketsEvent extends MyTicketsEvent {
  final String query;

  const SearchTicketsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class CancelTicketEvent extends MyTicketsEvent {
  final String ticketId;
  final String reason;
  final int refundAmount;

  const CancelTicketEvent({
    required this.ticketId,
    required this.reason,
    required this.refundAmount,
  });

  @override
  List<Object?> get props => [ticketId, reason, refundAmount];
}

class SubmitTicketReviewEvent extends MyTicketsEvent {
  final String ticketId;
  final ReviewModel review;

  const SubmitTicketReviewEvent({
    required this.ticketId,
    required this.review,
  });

  @override
  List<Object?> get props => [ticketId, review];
}
