import 'package:equatable/equatable.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';

enum MyTicketsStatus { initial, loading, loaded, error }

class MyTicketsState extends Equatable {
  final MyTicketsStatus status;
  final List<TicketModel> tickets;
  final TicketStatus selectedTab;
  final String searchQuery;
  final String? errorMessage;
  final String? successMessage;

  const MyTicketsState({
    this.status = MyTicketsStatus.initial,
    this.tickets = const [],
    this.selectedTab = TicketStatus.upcoming,
    this.searchQuery = '',
    this.errorMessage,
    this.successMessage,
  });

  List<TicketModel> get upcomingTickets =>
      tickets.where((t) => t.status == TicketStatus.upcoming).toList();

  List<TicketModel> get completedTickets =>
      tickets.where((t) => t.status == TicketStatus.completed).toList();

  List<TicketModel> get cancelledTickets =>
      tickets.where((t) => t.status == TicketStatus.cancelled).toList();

  /// Tickets filtered by the current active tab and search query
  List<TicketModel> get filteredTickets {
    final listByTab = tickets.where((t) => t.status == selectedTab).toList();
    if (searchQuery.trim().isEmpty) {
      return listByTab;
    }
    final q = searchQuery.toLowerCase().trim();
    return listByTab.where((t) {
      final codeMatch = t.ticketCode.toLowerCase().contains(q);
      final phoneMatch = t.passenger.phone.contains(q);
      final opMatch = t.trip.operatorName.toLowerCase().contains(q);
      final fromMatch = t.trip.fromCity.toLowerCase().contains(q);
      final toMatch = t.trip.toCity.toLowerCase().contains(q);
      return codeMatch || phoneMatch || opMatch || fromMatch || toMatch;
    }).toList();
  }

  MyTicketsState copyWith({
    MyTicketsStatus? status,
    List<TicketModel>? tickets,
    TicketStatus? selectedTab,
    String? searchQuery,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return MyTicketsState(
      status: status ?? this.status,
      tickets: tickets ?? this.tickets,
      selectedTab: selectedTab ?? this.selectedTab,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        tickets,
        selectedTab,
        searchQuery,
        errorMessage,
        successMessage,
      ];
}
