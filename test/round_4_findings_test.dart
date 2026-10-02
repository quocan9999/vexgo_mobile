import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/datasources/remote/seat_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/trip_remote_data_source.dart';
import 'package:vexgo_app/data/models/payment_transaction_model.dart';
import 'package:vexgo_app/data/models/seat_hold_model.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
  });

  tearDown(() {
    TokenStorage.resetStorageAdapter();
  });

  group('Track 1: Schema Contract Alignment with Backend develop', () {
    test(
      'SeatModel.fromJson correctly parses backend TripsController.getSeats payload',
      () {
        final backendLowerSeatJson = {
          'tripSeatId': 101,
          'seatNumber': 'A01',
          'position': 'Tầng dưới',
          'status': 'TRONG',
          'price': 290000,
        };

        final seat1 = SeatModel.fromJson(backendLowerSeatJson);
        expect(seat1.id, equals('101'));
        expect(seat1.numericSeatId, equals(101));
        expect(seat1.name, equals('A01'));
        expect(seat1.floor, equals(1));
        expect(seat1.status, equals(SeatStatus.available));
        expect(seat1.price, equals(290000));
        expect(seat1.row, equals(1));
        expect(seat1.col, equals(1));

        final backendUpperSeatJson = {
          'tripSeatId': 202,
          'seatNumber': 'B05',
          'position': 'Tầng trên',
          'status': 'DA_DAT',
          'price': 290000,
        };

        final seat2 = SeatModel.fromJson(backendUpperSeatJson);
        expect(seat2.id, equals('202'));
        expect(seat2.numericSeatId, equals(202));
        expect(seat2.name, equals('B05'));
        expect(seat2.floor, equals(2));
        expect(seat2.status, equals(SeatStatus.booked));
      },
    );

    test(
      'TripModel.fromJson correctly parses backend nested route and vehicle payload',
      () {
        final backendTripJson = {
          'tripId': 10,
          'departureTime': '2026-10-05T08:00:00Z',
          'arrivalTime': '2026-10-05T15:00:00Z',
          'price': 250000,
          'availableSeats': 18,
          'busCompany': {'id': 1, 'name': 'Phương Trang'},
          'route': {
            'id': 50,
            'origin': 'TP. Hồ Chí Minh',
            'destination': 'Đà Lạt',
            'distanceKm': 300,
            'durationHours': 7,
          },
          'vehicle': {
            'id': 9,
            'type': 'Limousine 34 Phòng VIP',
            'capacity': 34,
            'amenities': ['WiFi miễn phí', 'Nước suối', 'Cổng sạc USB'],
          },
        };

        final trip = TripModel.fromJson(backendTripJson);
        expect(trip.id, equals('10'));
        expect(trip.numericTripId, equals(10));
        expect(trip.routeId, equals('50'));
        expect(trip.operatorName, equals('Phương Trang'));
        expect(trip.fromCityName, equals('TP. Hồ Chí Minh'));
        expect(trip.toCityName, equals('Đà Lạt'));
        expect(trip.vehicleType, equals('Limousine 34 Phòng VIP'));
        expect(trip.totalSeats, equals(34));
        expect(trip.availableSeats, equals(18));
        expect(trip.amenities, contains('WiFi miễn phí'));
        expect(trip.duration, contains('7 giờ'));
      },
    );
  });

  group('Track 2: Eliminate Mock Fallbacks in Real Mode', () {
    test(
      'HybridTripRepository rethrows and does NOT inject mock when remote fails',
      () async {
        final failingClient = MockClient((request) async {
          throw http.ClientException('Network down');
        });

        final repo = HybridTripRepository(
          remoteDataSource: TripRemoteDataSourceImpl(
            client: ApiClient(httpClient: failingClient),
          ),
          mockFallback: MockTripRepository(),
        );

        expect(
          () => repo.searchTrips(fromCityId: 'HCM', toCityId: 'DL'),
          throwsA(isA<NetworkException>()),
        );
      },
    );

    test(
      'HybridTripRepository returns empty list when backend returns [] and does NOT fallback',
      () async {
        final emptyClient = MockClient((request) async {
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        });

        final repo = HybridTripRepository(
          remoteDataSource: TripRemoteDataSourceImpl(
            client: ApiClient(httpClient: emptyClient),
          ),
          mockFallback: MockTripRepository(),
        );

        final results = await repo.searchTrips(
          fromCityId: 'HCM',
          toCityId: 'DL',
        );
        expect(results, isEmpty);
      },
    );

    test(
      'HybridSeatRepository returns empty list and does NOT inject mock layout when remote seats is empty',
      () async {
        final emptyClient = MockClient((request) async {
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        });

        final repo = HybridSeatRepository(
          remoteDataSource: SeatRemoteDataSourceImpl(
            client: ApiClient(httpClient: emptyClient),
          ),
          mockFallback: MockSeatRepository(),
        );

        final seats = await repo.getTripSeats(10);
        expect(seats, isEmpty);
      },
    );
  });

  group('Track 3: ApiClient requiresAuth Semantics', () {
    test(
      'requiresAuth: true throws UnauthorizedException fail-fast before network call if no token',
      () async {
        var callMade = false;
        final client = ApiClient(
          httpClient: MockClient((request) async {
            callMade = true;
            return http.Response('{}', 200);
          }),
        );

        expect(
          () => client.get('/protected-endpoint', requiresAuth: true),
          throwsA(isA<UnauthorizedException>()),
        );
        expect(callMade, isFalse);
      },
    );

    test(
      'requiresAuth: false does NOT attach Authorization header even if token exists in storage',
      () async {
        await TokenStorage.saveAccessToken('test_jwt_token_123');

        String? sentAuthHeader;
        final client = ApiClient(
          httpClient: MockClient((request) async {
            sentAuthHeader = request.headers['Authorization'];
            return http.Response('{"success": true}', 200);
          }),
        );

        await client.get('/public-endpoint', requiresAuth: false);
        expect(sentAuthHeader, isNull);
      },
    );

    test(
      'requiresAuth: true attaches Bearer token when token is stored',
      () async {
        await TokenStorage.saveAccessToken('valid_jwt_token_456');

        String? sentAuthHeader;
        final client = ApiClient(
          httpClient: MockClient((request) async {
            sentAuthHeader = request.headers['Authorization'];
            return http.Response('{"success": true}', 200);
          }),
        );

        await client.get('/protected-endpoint', requiresAuth: true);
        expect(sentAuthHeader, equals('Bearer valid_jwt_token_456'));
      },
    );
  });

  group('Track 4: Financial Safety, Payment PENDING State & Expired Hold', () {
    test(
      'Expired hold with remainingSeconds <= 0 fails fast without inventing 600s TTL',
      () async {
        final seatRepo = _MockSeatRepoWithExpiredHold();
        final bookingRepo = MockBookingRepository();

        final bloc = BookingFlowBloc(
          seatRepository: seatRepo,
          bookingRepository: bookingRepo,
        );

        const testTrip = TripModel(
          id: '10',
          operatorId: 'OP_1',
          operatorName: 'Phương Trang',
          vehicleType: 'Limousine',
          fromCityId: 'HCM',
          fromCityName: 'TP. HCM',
          toCityId: 'DL',
          toCityName: 'Đà Lạt',
          departureTime: '23:00',
          arrivalTime: '06:00',
          duration: '7h',
          pickupPoint: 'BX Miền Đông',
          pickupAddress: 'Bình Thạnh',
          dropoffPoint: 'BX Đà Lạt',
          dropoffAddress: 'Đà Lạt',
          originalPrice: 250000,
          discountPrice: 250000,
          availableSeats: 10,
          totalSeats: 34,
          seatLayoutType: 'SLEEPER_34',
          rating: 4.8,
          reviewCount: 120,
        );

        bloc.add(InitBookingFlowEvent(trip: testTrip, date: DateTime.now()));
        await Future.delayed(const Duration(milliseconds: 50));

        bloc.add(
          const ToggleSeatEvent(
            SeatModel(
              id: '1',
              name: 'A01',
              floor: 1,
              status: SeatStatus.available,
              price: 250000,
              row: 1,
              col: 1,
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        bloc.add(const NextStepEvent());
        await Future.delayed(const Duration(milliseconds: 100));

        // Must fail and NOT assign 600s or advance to pickupPoint
        expect(bloc.state.status, equals(BookingFlowStatus.failure));
        expect(bloc.state.step, equals(BookingStep.seatSelection));
        expect(bloc.state.errorMessage, contains('hết hạn'));
        await bloc.close();
      },
    );

    test(
      'Payment pending stores payment context and does NOT call createBooking twice on retry',
      () async {
        final countingRepo = _MockCountingBookingRepository();
        final seatRepo = _MockSeatRepoValidHold();

        final bloc = BookingFlowBloc(
          seatRepository: seatRepo,
          bookingRepository: countingRepo,
        );

        const testTrip = TripModel(
          id: '10',
          operatorId: 'OP_1',
          operatorName: 'Phương Trang',
          vehicleType: 'Limousine',
          fromCityId: 'HCM',
          fromCityName: 'TP. HCM',
          toCityId: 'DL',
          toCityName: 'Đà Lạt',
          departureTime: '23:00',
          arrivalTime: '06:00',
          duration: '7h',
          pickupPoint: 'BX Miền Đông',
          pickupAddress: 'Bình Thạnh',
          dropoffPoint: 'BX Đà Lạt',
          dropoffAddress: 'Đà Lạt',
          originalPrice: 250000,
          discountPrice: 250000,
          availableSeats: 10,
          totalSeats: 34,
          seatLayoutType: 'SLEEPER_34',
          rating: 4.8,
          reviewCount: 120,
        );

        bloc.add(InitBookingFlowEvent(trip: testTrip, date: DateTime.now()));
        await Future.delayed(const Duration(milliseconds: 50));

        bloc.add(
          const ToggleSeatEvent(
            SeatModel(
              id: '1',
              name: 'A01',
              floor: 1,
              status: SeatStatus.available,
              price: 250000,
              row: 1,
              col: 1,
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        // Advance through steps to payment
        bloc.add(const NextStepEvent());
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(
          const SelectPickupPointEvent(
            StopPointModel(
              id: 'P1',
              name: 'Đón 1',
              time: '23:00',
              address: 'A1',
            ),
          ),
        );
        bloc.add(const NextStepEvent());
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(
          const SelectDropoffPointEvent(
            StopPointModel(
              id: 'D1',
              name: 'Trả 1',
              time: '06:00',
              address: 'A2',
            ),
          ),
        );
        bloc.add(const NextStepEvent());
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const NextStepEvent());
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const NextStepEvent());
        await Future.delayed(const Duration(milliseconds: 50));

        // First confirm: throws PaymentPendingException
        bloc.add(const ConfirmPaymentEvent());
        await Future.delayed(const Duration(milliseconds: 1400));

        expect(bloc.state.status, equals(BookingFlowStatus.paymentPending));
        expect(bloc.state.pendingPaymentId, equals(777));
        expect(countingRepo.createBookingCallCount, equals(1));

        // Second confirm (retry/resume): must check getPaymentStatus and NOT call createBooking again!
        bloc.add(const ConfirmPaymentEvent());
        await Future.delayed(const Duration(milliseconds: 1400));

        expect(
          countingRepo.createBookingCallCount,
          equals(1),
        ); // ZERO duplicate!
        expect(countingRepo.getPaymentStatusCallCount, equals(1));

        await bloc.close();
      },
    );
  });
}

class _MockSeatRepoWithExpiredHold extends FakeSeatRepository {
  @override
  Future<SeatHoldModel> createSeatHold({
    required int tripId,
    required List<int> seatIds,
  }) async {
    return SeatHoldModel(
      holdToken: 'expired_token',
      tripId: tripId,
      seatIds: seatIds,
      expiresAt: DateTime.now().subtract(
        const Duration(seconds: 10),
      ), // EXPIRED
    );
  }
}

class _MockSeatRepoValidHold extends FakeSeatRepository {
  @override
  Future<SeatHoldModel> createSeatHold({
    required int tripId,
    required List<int> seatIds,
  }) async {
    return SeatHoldModel(
      holdToken: 'valid_token',
      tripId: tripId,
      seatIds: seatIds,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );
  }
}

class _MockCountingBookingRepository extends MockBookingRepository {
  int createBookingCallCount = 0;
  int getPaymentStatusCallCount = 0;

  @override
  Future<TicketModel> createBooking({
    required TicketTripSummary trip,
    required List<String> seats,
    required int totalAmount,
    required int discountAmount,
    required int finalAmount,
    required String paymentMethod,
    required PassengerInfo passenger,
    List<int>? seatIds,
    String? holdToken,
    String? promotionCode,
  }) async {
    createBookingCallCount++;
    throw const PaymentPendingException(
      message: 'Chờ thanh toán',
      paymentId: 777,
      paymentUrl: 'https://pay.vn/777',
    );
  }

  @override
  Future<PaymentTransactionModel> getPaymentStatus(dynamic paymentId) async {
    getPaymentStatusCallCount++;
    return const PaymentTransactionModel(
      paymentId: 777,
      bookingId: 888,
      provider: PaymentProvider.momo,
      amount: 250000,
      status: PaymentStatus.pending,
    );
  }
}

class FakeSeatRepository implements SeatRepository {
  @override
  Future<SeatLayoutModel> getSeatLayout(String seatLayoutType) async {
    return const SeatLayoutModel(
      vehicleType: 'Limousine',
      hasTwoFloors: false,
      lowerFloor: [],
      upperFloor: [],
    );
  }

  @override
  Future<List<SeatModel>> getTripSeats(dynamic tripId) async => [];

  @override
  Future<SeatHoldModel> createSeatHold({
    required int tripId,
    required List<int> seatIds,
  }) async => throw UnimplementedError();

  @override
  Future<bool> releaseSeatHold(String holdToken) async => true;
}
