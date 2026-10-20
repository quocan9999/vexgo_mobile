import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/data/datasources/remote/ticket_remote_data_source.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_state.dart';

class FakeTicketRemoteDataSource implements TicketRemoteDataSource {
  bool shouldThrow = false;
  List<TicketModel> mockTickets = [];
  Map<String, dynamic>? lastCancelPayload;

  @override
  Future<List<TicketModel>> getCustomerTickets({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    if (shouldThrow) throw Exception('Network timeout');
    return mockTickets;
  }

  @override
  Future<TicketModel> getCustomerTicketById(dynamic ticketId) async {
    if (shouldThrow) throw Exception('Network timeout');
    return mockTickets.firstWhere((t) => t.id == ticketId.toString());
  }

  @override
  Future<TicketModel> lookupTicket({
    required String ticketCode,
    required String phoneNumber,
  }) async {
    if (shouldThrow) throw Exception('Network timeout');
    return mockTickets.firstWhere((t) => t.ticketCode == ticketCode);
  }

  @override
  Future<Map<String, dynamic>> cancelTicket({
    required String ticketCode,
    required String phoneNumber,
    String? reason,
    required double expectedCancelFeeRate,
  }) async {
    lastCancelPayload = {
      'ticketCode': ticketCode,
      'phoneNumber': phoneNumber,
      'reason': reason,
      'expectedCancelFeeRate': expectedCancelFeeRate,
    };
    if (shouldThrow) throw Exception('Backend reject');
    return {'success': true, 'refundAmount': 270000, 'cancelFee': 30000};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2: Tickets & Cancellation Integration Tests', () {
    late FakeTicketRemoteDataSource fakeRemoteDataSource;
    late MockBookingRepository mockFallback;
    late HybridBookingRepository hybridRepo;

    final sampleTicket = TicketModel(
      id: 'TKT_100',
      ticketCode: 'VXG-100001',
      status: TicketStatus.upcoming,
      bookingDate: '09/10/2026 10:00',
      trip: const TicketTripSummary(
        id: '10',
        operatorName: 'Phương Trang',
        vehicleType: 'Limousine',
        departureTime: '10:00',
        departureDate: '20/10/2026',
        arrivalTime: '16:00',
        arrivalDate: '20/10/2026',
        fromCity: 'TP. Hồ Chí Minh',
        toCity: 'Đà Lạt',
        pickupPoint: 'BX Miền Đông',
        pickupAddress: 'Bình Thạnh',
        dropoffPoint: 'BX Đà Lạt',
        dropoffAddress: 'Tô Hiến Thành',
      ),
      seats: const ['A01'],
      totalAmount: 300000,
      discountAmount: 0,
      finalAmount: 300000,
      paymentMethod: 'MoMo',
      passenger: const PassengerInfo(
        fullName: 'Nguyễn Văn An',
        phone: '0901234567',
        email: 'an@gmail.com',
      ),
      cancellation: const CancellationQuote(
        eligible: true,
        cancelFeeRate: 0.1,
        cancelFee: 30000,
        refundAmount: 270000,
      ),
    );

    setUp(() {
      fakeRemoteDataSource = FakeTicketRemoteDataSource();
      mockFallback = MockBookingRepository();
      hybridRepo = HybridBookingRepository(
        remoteTicketDataSource: fakeRemoteDataSource,
        mockFallback: mockFallback,
      );
    });

    test(
      'HybridBookingRepository.getMyTickets returns remote data when available',
      () async {
        fakeRemoteDataSource.mockTickets = [sampleTicket];
        final tickets = await hybridRepo.getMyTickets();

        expect(tickets.length, equals(1));
        expect(tickets.first.ticketCode, equals('VXG-100001'));
      },
    );

    test(
      'HybridBookingRepository.getMyTickets falls back to mock if remote throws in demo mode',
      () async {
        ApiConfig.isDemoMode = true;
        try {
          fakeRemoteDataSource.shouldThrow = true;
          final tickets = await hybridRepo.getMyTickets();

          // Mock tickets loaded from JSON fallback
          expect(tickets, isNotEmpty);
        } finally {
          ApiConfig.isDemoMode = false;
        }
      },
    );

    test(
      'HybridBookingRepository.cancelTicket calls remote and sends expected fee rate',
      () async {
        fakeRemoteDataSource.mockTickets = [sampleTicket];
        final res = await hybridRepo.cancelTicket(
          ticketCode: 'VXG-100001',
          phoneNumber: '0901234567',
          reason: 'Thay đổi lịch trình',
          expectedCancelFeeRate: 0.1,
        );

        expect(res['success'], isTrue);
        expect(
          fakeRemoteDataSource.lastCancelPayload?['expectedCancelFeeRate'],
          equals(0.1),
        );
        expect(
          fakeRemoteDataSource.lastCancelPayload?['ticketCode'],
          equals('VXG-100001'),
        );
      },
    );

    test(
      'MyTicketsBloc with HybridBookingRepository loads tickets from repository',
      () async {
        fakeRemoteDataSource.mockTickets = [sampleTicket];
        final bloc = MyTicketsBloc(bookingRepository: hybridRepo);

        bloc.add(const LoadMyTicketsEvent());

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<MyTicketsState>((state) {
              return state.status == MyTicketsStatus.loaded &&
                  state.tickets.any((t) => t.ticketCode == 'VXG-100001');
            }),
          ),
        );

        await bloc.close();
      },
    );

    test(
      'MyTicketsBloc successfully cancels ticket via cancelTicket API',
      () async {
        fakeRemoteDataSource.mockTickets = [sampleTicket];
        final bloc = MyTicketsBloc(bookingRepository: hybridRepo);

        bloc.add(AddNewTicketEvent(sampleTicket));
        bloc.add(
          const CancelTicketEvent(
            ticketId: 'TKT_100',
            reason: 'Bận việc',
            refundAmount: 270000,
          ),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<MyTicketsState>((state) {
              return state.selectedTab == TicketStatus.cancelled &&
                  state.cancelledTickets.any(
                    (t) => t.ticketCode == 'VXG-100001',
                  ) &&
                  state.successMessage != null &&
                  state.successMessage!.contains('270000');
            }),
          ),
        );

        await bloc.close();
      },
    );
  });
}
