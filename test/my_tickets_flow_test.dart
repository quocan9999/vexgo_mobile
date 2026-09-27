import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/data/models/review_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MyTicketsBloc & Business Rules Tests', () {
    late MyTicketsBloc bloc;

    final sampleTicketFuture = TicketModel(
      id: 'TKT_TEST_FUTURE',
      ticketCode: 'VXG-999001',
      status: TicketStatus.upcoming,
      bookingDate: '24/09/2026 10:00',
      trip: const TicketTripSummary(
        id: 'TRIP_001',
        operatorName: 'Phương Trang (FUTA Bus Lines)',
        vehicleType: 'Limousine 34 Phòng VIP',
        departureTime: '23:30',
        departureDate: '28/09/2026', // Way in the future (> 3h)
        arrivalTime: '06:00',
        arrivalDate: '29/09/2026',
        fromCity: 'TP. Hồ Chí Minh',
        toCity: 'Đà Lạt',
        pickupPoint: 'Bến xe Miền Đông mới',
        pickupAddress: 'TP. Thủ Đức',
        dropoffPoint: 'Bến xe Đà Lạt',
        dropoffAddress: '01 Tô Hiến Thành',
      ),
      seats: const ['A01', 'A02'],
      totalAmount: 580000,
      discountAmount: 0,
      finalAmount: 580000,
      paymentMethod: 'Ví MoMo',
      passenger: const PassengerInfo(
        fullName: 'Nguyễn Văn An',
        phone: '0987654321',
        email: 'nguyenvanan@gmail.com',
      ),
    );

    final sampleTicketUrgent = TicketModel(
      id: 'TKT_TEST_URGENT',
      ticketCode: 'VXG-999002',
      status: TicketStatus.upcoming,
      bookingDate: '24/09/2026 19:00',
      trip: const TicketTripSummary(
        id: 'TRIP_002',
        operatorName: 'Thành Bưởi Limousine',
        vehicleType: 'Cabin 22 VIP',
        departureTime: '21:00',
        departureDate: '24/09/2026', // Under 3h from now
        arrivalTime: '03:00',
        arrivalDate: '25/09/2026',
        fromCity: 'TP. Hồ Chí Minh',
        toCity: 'Cần Thơ',
        pickupPoint: 'Bến xe Miền Tây',
        pickupAddress: 'Bình Tân',
        dropoffPoint: 'Bến xe Cần Thơ',
        dropoffAddress: 'Cái Răng',
      ),
      seats: const ['VIP01'],
      totalAmount: 260000,
      discountAmount: 0,
      finalAmount: 260000,
      paymentMethod: 'Chuyển khoản VietQR',
      passenger: const PassengerInfo(
        fullName: 'Nguyễn Văn An',
        phone: '0987654321',
        email: 'nguyenvanan@gmail.com',
      ),
    );

    setUp(() {
      bloc = MyTicketsBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('Initial state is clean', () {
      expect(bloc.state.status, MyTicketsStatus.initial);
      expect(bloc.state.tickets, isEmpty);
      expect(bloc.state.selectedTab, TicketStatus.upcoming);
    });

    test('AddNewTicketEvent adds ticket to list and switches to upcoming tab', () {
      bloc.add(AddNewTicketEvent(sampleTicketFuture));

      expectLater(
        bloc.stream,
        emits(predicate<MyTicketsState>((state) {
          return state.tickets.length == 1 &&
              state.tickets.first.ticketCode == 'VXG-999001' &&
              state.selectedTab == TicketStatus.upcoming &&
              state.upcomingTickets.length == 1;
        })),
      );
    });

    test('ChangeTabEvent switches tabs smoothly', () {
      bloc.add(AddNewTicketEvent(sampleTicketFuture));
      bloc.add(const ChangeTabEvent(TicketStatus.completed));

      expectLater(
        bloc.stream,
        emitsThrough(predicate<MyTicketsState>((state) {
          return state.selectedTab == TicketStatus.completed;
        })),
      );
    });

    test('SearchTicketsEvent filters correctly by code and phone', () {
      bloc.add(AddNewTicketEvent(sampleTicketFuture));
      bloc.add(const SearchTicketsEvent('999001'));

      expectLater(
        bloc.stream,
        emitsThrough(predicate<MyTicketsState>((state) {
          return state.filteredTickets.length == 1 &&
              state.filteredTickets.first.ticketCode == 'VXG-999001';
        })),
      );
    });

    test('CancelTicketEvent succeeds when departure is >= 3 hours (sub_uc_huy_ve)', () {
      expect(sampleTicketFuture.canCancel, isTrue);

      bloc.add(AddNewTicketEvent(sampleTicketFuture));
      bloc.add(const CancelTicketEvent(
        ticketId: 'TKT_TEST_FUTURE',
        reason: 'Thay đổi kế hoạch cá nhân',
        refundAmount: 522000,
      ));

      expectLater(
        bloc.stream,
        emitsThrough(predicate<MyTicketsState>((state) {
          final cancelled = state.cancelledTickets;
          return cancelled.any((t) => t.id == 'TKT_TEST_FUTURE') &&
              state.selectedTab == TicketStatus.cancelled &&
              state.successMessage != null;
        })),
      );
    });

    test('CancelTicketEvent rejects cancellation when departure is < 3 hours (sub_uc_huy_ve)', () {
      // Simulate urgent ticket that departs soon (< 3 hours)
      expect(sampleTicketUrgent.canCancel, isFalse);

      bloc.add(AddNewTicketEvent(sampleTicketUrgent));
      bloc.add(const CancelTicketEvent(
        ticketId: 'TKT_TEST_URGENT',
        reason: 'Thay đổi kế hoạch cá nhân',
        refundAmount: 234000,
      ));

      expectLater(
        bloc.stream,
        emitsThrough(predicate<MyTicketsState>((state) {
          // Ticket must remain upcoming, not cancelled
          final upcoming = state.upcomingTickets;
          return upcoming.any((t) => t.id == 'TKT_TEST_URGENT') &&
              state.errorMessage != null &&
              state.errorMessage!.contains('dưới 3 giờ');
        })),
      );
    });

    test('SubmitTicketReviewEvent records review and rating on completed ticket (UC12)', () {
      final completedTicket = sampleTicketFuture.copyWith(
        id: 'TKT_COMPLETED_TEST',
        ticketCode: 'VXG-777001',
        status: TicketStatus.completed,
      );

      bloc.add(AddNewTicketEvent(completedTicket));

      const review = ReviewModel(
        rating: 5,
        comment: 'Tài xế lái xe an toàn, xe rất êm ái!',
        tags: ['Đúng giờ', 'Xe sạch sẽ', 'Lái xe an toàn'],
        createdAt: '24/09/2026 20:00',
      );

      bloc.add(const SubmitTicketReviewEvent(
        ticketId: 'TKT_COMPLETED_TEST',
        review: review,
      ));

      expectLater(
        bloc.stream,
        emitsThrough(predicate<MyTicketsState>((state) {
          final ticket = state.tickets.firstWhere((t) => t.id == 'TKT_COMPLETED_TEST');
          return ticket.review != null &&
              ticket.review!.rating == 5 &&
              ticket.review!.tags.contains('Đúng giờ');
        })),
      );
    });
  });
}
