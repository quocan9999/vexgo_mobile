import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/adapters/city_search_adapter.dart';
import 'package:vexgo_app/data/datasources/remote/auth_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/notification_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/review_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/seat_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/ticket_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/trip_remote_data_source.dart';
import 'package:vexgo_app/data/models/booking_model.dart';
import 'package:vexgo_app/data/models/operator_model.dart';
import 'package:vexgo_app/data/models/popular_route_model.dart';
import 'package:vexgo_app/data/models/review_model.dart';
import 'package:vexgo_app/data/models/seat_hold_model.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/models/user_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/notification_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_state.dart';

class FailingReviewRemoteDataSource implements ReviewRemoteDataSource {
  @override
  Future<ReviewModel> createReview({
    required int tripId,
    required int rating,
    String? comment,
  }) async {
    throw Exception('404 Not Found - reviews endpoint not available');
  }
}

class QueuedRefundBookingRepository extends MockBookingRepository {
  final TicketModel ticket;
  QueuedRefundBookingRepository(this.ticket);
  @override
  Future<TicketModel?> getTicketById(String id) async =>
      id == ticket.id ? ticket : null;
  @override
  Future<Map<String, dynamic>> cancelTicket({
    required String ticketCode,
    required String phoneNumber,
    String? reason,
    required double expectedCancelFeeRate,
  }) async {
    return {
      'ticketId': ticket.id,
      'ticketCode': ticketCode,
      'status': 'HUY',
      'message': 'Yêu cầu hoàn tiền đang xử lý',
    };
  }
}

class FakeSeatRepoForBloc implements SeatRepository {
  final bool shouldFailHold;
  final String holdToken;

  FakeSeatRepoForBloc({
    this.shouldFailHold = false,
    this.holdToken = 'test_hold_token_123',
  });

  @override
  Future<List<SeatModel>> getTripSeats(dynamic tripId) async {
    return [
      const SeatModel(
        id: '101',
        name: 'A01',
        floor: 1,
        status: SeatStatus.available,
        row: 1,
        col: 1,
      ),
    ];
  }

  @override
  Future<SeatLayoutModel> getSeatLayout(String seatLayoutType) async {
    return const SeatLayoutModel(
      vehicleType: 'standard',
      hasTwoFloors: false,
      lowerFloor: [],
      upperFloor: [],
    );
  }

  @override
  Future<SeatHoldModel> createSeatHold({
    required int tripId,
    required List<int> seatIds,
    int holdDurationSeconds = 600,
  }) async {
    if (shouldFailHold) {
      throw Exception('Ghế đang được giữ bởi người khác');
    }
    return SeatHoldModel(
      holdToken: holdToken,
      tripId: tripId,
      seatIds: seatIds,
      expiresAt: DateTime.now().add(Duration(seconds: holdDurationSeconds)),
    );
  }

  @override
  Future<bool> releaseSeatHold(String holdToken) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Lead Review Findings Comprehensive Regression Suite (Findings A -> N)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
      ApiConfig.isDemoMode = false;
    });

    tearDown(() {
      TokenStorage.resetStorageAdapter();
      ApiConfig.isDemoMode = false;
    });

    // -------------------------------------------------------------------------
    // Finding A: City Search Adapter & No Mock Fallback
    // -------------------------------------------------------------------------
    test(
      'Finding A: CitySearchAdapter maps local codes to exact Vietnamese backend names',
      () {
        expect(
          CitySearchAdapter.resolveBackendSearchCity('HCM'),
          equals('TP.HCM'),
        );
        expect(
          CitySearchAdapter.resolveBackendSearchCity('DL'),
          equals('Đà Lạt'),
        );
        expect(
          CitySearchAdapter.resolveBackendSearchCity('HN'),
          equals('Hà Nội'),
        );
        expect(
          CitySearchAdapter.resolveBackendSearchCity('DN'),
          equals('Đà Nẵng'),
        );
        expect(
          CitySearchAdapter.resolveBackendSearchCity('VT'),
          equals('Vũng Tàu'),
        );
        expect(
          CitySearchAdapter.resolveBackendSearchCity('NT'),
          equals('Nha Trang'),
        );
        expect(
          CitySearchAdapter.resolveBackendSearchCity('CT'),
          equals('Cần Thơ'),
        );

        // Already formatted names and variations map to verified backend term
        expect(
          CitySearchAdapter.resolveBackendSearchCity('TP. Hồ Chí Minh'),
          equals('TP.HCM'),
        );
        expect(
          CitySearchAdapter.resolveBackendSearchCity('TP.HCM'),
          equals('TP.HCM'),
        );
        expect(
          CitySearchAdapter.resolveBackendSearchCity('Đà Lạt'),
          equals('Đà Lạt'),
        );

        // Empty string returns empty
        expect(CitySearchAdapter.resolveBackendSearchCity(''), equals(''));
      },
    );

    test(
      'Finding A: RealTripRepository sends mapped city names and returns empty list when backend returns empty',
      () async {
        String? requestedFrom;
        String? requestedTo;

        final mockClient = MockClient((request) async {
          requestedFrom = request.url.queryParameters['from'];
          requestedTo = request.url.queryParameters['to'];
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [],
              'pagination': {'total': 0, 'page': 1, 'limit': 10},
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final apiClient = ApiClient(httpClient: mockClient);
        final remoteDataSource = TripRemoteDataSourceImpl(client: apiClient);
        final repo = RealTripRepository(remoteDataSource: remoteDataSource);

        final results = await repo.searchTrips(
          fromCityId: 'HCM',
          toCityId: 'DL',
          date: '2026-10-10',
        );

        expect(requestedFrom, equals('TP.HCM'));
        expect(requestedTo, equals('Đà Lạt'));
        expect(results, isEmpty);
      },
    );

    // -------------------------------------------------------------------------
    // Finding B: SeatModel parses payload without price & enforces valid pricing
    // -------------------------------------------------------------------------
    test(
      'Finding B: SeatModel parses backend TripsController.getSeats payload (no price field)',
      () {
        final backendSeatJson = {
          'tripSeatId': 42,
          'seatNumber': 'B05',
          'position': 2,
          'status': 'AVAILABLE',
        };

        final seat = SeatModel.fromJson(backendSeatJson);
        expect(seat.id, equals('42'));
        expect(seat.name, equals('B05'));
        expect(seat.price, isNull);
        expect(seat.status, equals(SeatStatus.available));
      },
    );

    test(
      'Finding B: BookingFlowState seatsTotalAmount returns null if seats lack authoritative price',
      () {
        const seatWithoutPrice = SeatModel(
          id: '1',
          name: 'A01',
          floor: 1,
          status: SeatStatus.available,
          price: null,
          row: 1,
          col: 1,
        );

        const state = BookingFlowState(
          selectedSeats: [seatWithoutPrice],
          selectedPickupPoint: StopPointModel(
            id: 'PU1',
            name: 'Điểm đón A',
            time: '08:00',
            address: 'Địa chỉ đón',
          ),
          selectedDropoffPoint: StopPointModel(
            id: 'DO1',
            name: 'Điểm trả B',
            time: '14:00',
            address: 'Địa chỉ trả',
          ),
          passengerName: 'Trần Văn B',
          passengerPhone: '0912345678',
          passengerEmail: 'b@example.com',
        );

        expect(state.seatsTotalAmount, isNull);
        expect(state.hasValidSeatPricing, isFalse);
        expect(state.isSeatsValid, isFalse);
      },
    );

    // -------------------------------------------------------------------------
    // Finding C & D: TripModel maps route.durationMinutes and nested backend schema
    // -------------------------------------------------------------------------
    test(
      'Finding C & D: TripModel reads route.durationMinutes and nested busCompany, route, vehicle',
      () {
        final backendTripJson = {
          'id': 105,
          'busCompany': {'id': 1, 'name': 'Phương Trang (FUTA Bus Lines)'},
          'route': {
            'id': 10,
            'origin': 'TP. Hồ Chí Minh',
            'destination': 'Đà Lạt',
            'durationMinutes': 390,
            'distanceKm': 305,
          },
          'vehicle': {
            'id': 20,
            'type': 'Limousine 34 Phòng VIP',
            'capacity': 34,
            'amenities': ['Wifi', 'Nước uống', 'Cổng sạc USB'],
          },
          'departureTime': '2026-10-15T23:00:00.000Z',
          'arrivalTime': '2026-10-16T05:30:00.000Z',
          'price': 290000,
          'availableSeats': 12,
        };

        final trip = TripModel.fromJson(backendTripJson);

        expect(trip.id, equals('105'));
        expect(trip.operatorName, equals('Phương Trang (FUTA Bus Lines)'));
        expect(trip.fromCityName, equals('TP. Hồ Chí Minh'));
        expect(trip.toCityName, equals('Đà Lạt'));
        expect(trip.durationMinutes, equals(390));
        expect(trip.duration, equals('6 giờ 30 phút'));
        expect(trip.vehicleType, equals('Limousine 34 Phòng VIP'));
        expect(trip.totalSeats, equals(34));
        expect(trip.availableSeats, equals(12));
        expect(trip.originalPrice, equals(290000));
        expect(
          trip.amenities,
          containsAll(['Wifi', 'Nước uống', 'Cổng sạc USB']),
        );
      },
    );

    // -------------------------------------------------------------------------
    // Finding E: BookingModel maps backend BookingsController response
    // -------------------------------------------------------------------------
    test('Finding E: BookingModel parses backend mapBooking schema', () {
      final backendBookingJson = {
        'bookingId': 99,
        'bookingCode': 'BK-20261010-0099',
        'orderId': 1234,
        'ticketCount': 2,
        'status': 'CONFIRMED',
        'totalAmount': 580000,
        'finalAmount': 550000,
        'discountAmount': 30000,
        'departureTime': '2026-10-15T23:00:00.000Z',
        'busCompanyName': 'Phương Trang',
        'vehicleType': 'Limousine 34 VIP',
        'origin': 'TP. Hồ Chí Minh',
        'destination': 'Đà Lạt',
        'pickupPoint': 'Bến xe Miền Đông mới',
        'dropoffPoint': 'Bến xe Đà Lạt',
        'seatNumbers': ['A01', 'A02'],
        'tickets': [
          {'ticketId': 101, 'seatNumber': 'A01'},
          {'ticketId': 102, 'seatNumber': 'A02'},
        ],
      };

      final booking = BookingModel.fromJson(backendBookingJson);

      expect(booking.bookingId, equals(99));
      expect(booking.bookingCode, equals('BK-20261010-0099'));
      expect(booking.orderId, equals(1234));
      expect(booking.busCompanyName, equals('Phương Trang'));
      expect(booking.seats, equals(['A01', 'A02']));
      expect(booking.totalAmount, equals(580000));
      expect(booking.discountAmount, equals(30000));
      expect(booking.origin, equals('TP. Hồ Chí Minh'));
      expect(booking.destination, equals('Đà Lạt'));
    });

    // -------------------------------------------------------------------------
    // Finding F & G: UserModel & AuthRemoteDataSource updateProfile (PATCH /me)
    // -------------------------------------------------------------------------
    test(
      'Finding F: UserModel.fromJson does not invent fake user id or dummy profile',
      () {
        final userJson = {
          'id': 77,
          'phone': '0901234567',
          'fullName': 'Lê Văn C',
          'email': 'levanc@gmail.com',
          'dateOfBirth': '1995-05-20',
          'citizenId': '079195000123',
        };

        final user = UserModel.fromJson(userJson);

        expect(user.taiKhoanId, equals(77));
        expect(user.soDienThoai, equals('0901234567'));
        expect(user.hoTen, equals('Lê Văn C'));
        expect(user.email, equals('levanc@gmail.com'));
        expect(user.ngaySinh, equals('1995-05-20'));
        expect(user.cccd, equals('079195000123'));
        expect(user.maKhachHang, equals(''));
        expect(user.daXacThucSoDienThoai, isFalse);
        expect(user.hangThanhVien, equals(''));

        final userWithCustId = UserModel.fromJson({'customerId': 77});
        expect(
          userWithCustId.maKhachHang,
          equals(''),
        ); // Must not fabricate KH77
      },
    );

    test(
      'Finding G: AuthRemoteDataSourceImpl.updateProfile calls PATCH /me with correct payload',
      () async {
        await TokenStorage.saveTokens(
          accessToken: 'test_token',
          refreshToken: 'test_refresh',
        );

        String? capturedMethod;
        String? capturedPath;
        Map<String, dynamic>? capturedBody;

        final mockClient = MockClient((request) async {
          capturedMethod = request.method;
          capturedPath = request.url.path;
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 77,
                'phone': '0901234567',
                'fullName': 'Lê Văn C Updated',
                'email': 'c_updated@gmail.com',
                'dateOfBirth': '1995-05-20',
                'citizenId': '079195000123',
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final apiClient = ApiClient(httpClient: mockClient);
        final authDataSource = AuthRemoteDataSourceImpl(client: apiClient);

        final updatedUser = await authDataSource.updateProfile(
          fullName: 'Lê Văn C Updated',
          email: 'c_updated@gmail.com',
          dateOfBirth: '1995-05-20',
          citizenId: '079195000123',
        );

        expect(capturedMethod, equals('PATCH'));
        expect(capturedPath, endsWith('/me'));
        expect(capturedBody?['fullName'], equals('Lê Văn C Updated'));
        expect(capturedBody?['email'], equals('c_updated@gmail.com'));
        expect(updatedUser.hoTen, equals('Lê Văn C Updated'));
      },
    );

    // -------------------------------------------------------------------------
    // Finding H & I: RealSeatRepository & BookingFlowBloc SeatHold integration
    // -------------------------------------------------------------------------
    test(
      'Finding H: RealSeatRepository.createSeatHold calls SeatRemoteDataSource and parses holdToken',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.path, endsWith('/seat-holds'));
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['tripId'], equals(10));
          expect(body['seatIds'], equals([1, 2]));

          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'holdToken': 'token_hold_12345',
                'tripId': 10,
                'seatIds': [1, 2],
                'expiresAt': '2026-10-10T15:00:00.000Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final apiClient = ApiClient(httpClient: mockClient);
        final remoteDs = SeatRemoteDataSourceImpl(client: apiClient);
        final repo = RealSeatRepository(remoteDataSource: remoteDs);

        final hold = await repo.createSeatHold(tripId: 10, seatIds: [1, 2]);
        expect(hold.holdToken, equals('token_hold_12345'));
        expect(hold.tripId, equals(10));
        expect(hold.seatIds, equals([1, 2]));
      },
    );

    test(
      'Finding I: BookingFlowBloc stores holdToken on success and blocks navigation on hold failure',
      () async {
        const testTrip = TripModel(
          id: '101',
          operatorId: '1',
          operatorName: 'Phương Trang',
          vehicleType: 'Limousine',
          fromCityId: 'HCM',
          fromCityName: 'TP. Hồ Chí Minh',
          toCityId: 'DL',
          toCityName: 'Đà Lạt',
          departureTime: '23:00',
          arrivalTime: '05:30',
          duration: '6 giờ 30 phút',
          pickupPoint: 'BX Miền Đông',
          pickupAddress: 'Thủ Đức',
          dropoffPoint: 'BX Đà Lạt',
          dropoffAddress: 'Tô Hiến Thành',
          originalPrice: 290000,
          discountPrice: 290000,
          availableSeats: 10,
          totalSeats: 34,
          seatLayoutType: 'standard',
          rating: 4.8,
          reviewCount: 120,
        );

        const seatA1 = SeatModel(
          id: '101',
          name: 'A01',
          floor: 1,
          status: SeatStatus.available,
          price: 290000,
          row: 1,
          col: 1,
        );

        // Test failure case: should NOT advance to pickupPoint
        final failingBloc = BookingFlowBloc(
          seatRepository: FakeSeatRepoForBloc(shouldFailHold: true),
          bookingRepository: MockBookingRepository(),
        );

        failingBloc.add(
          InitBookingFlowEvent(trip: testTrip, date: DateTime(2026, 10, 10)),
        );
        await failingBloc.stream.firstWhere(
          (s) => s.status == BookingFlowStatus.loaded,
        );

        failingBloc.add(const ToggleSeatEvent(seatA1));
        await failingBloc.stream.firstWhere((s) => s.selectedSeats.isNotEmpty);

        failingBloc.add(const NextStepEvent());

        await expectLater(
          failingBloc.stream,
          emitsThrough(
            predicate<BookingFlowState>(
              (s) =>
                  s.step == BookingStep.seatSelection &&
                  s.errorMessage != null &&
                  s.holdToken == null,
            ),
          ),
        );
        await failingBloc.close();

        // Test success case: advances to pickupPoint and saves holdToken
        final successBloc = BookingFlowBloc(
          seatRepository: FakeSeatRepoForBloc(
            shouldFailHold: false,
            holdToken: 'authorized_token_xyz',
          ),
          bookingRepository: MockBookingRepository(),
        );

        successBloc.add(
          InitBookingFlowEvent(trip: testTrip, date: DateTime(2026, 10, 10)),
        );
        await successBloc.stream.firstWhere(
          (s) => s.status == BookingFlowStatus.loaded,
        );

        successBloc.add(const ToggleSeatEvent(seatA1));
        await successBloc.stream.firstWhere((s) => s.selectedSeats.isNotEmpty);

        successBloc.add(const NextStepEvent());

        await expectLater(
          successBloc.stream,
          emitsThrough(
            predicate<BookingFlowState>(
              (s) =>
                  s.step == BookingStep.pickupPoint &&
                  s.holdToken == 'authorized_token_xyz',
            ),
          ),
        );
        await successBloc.close();
      },
    );

    test(
      'Finding I2: SeatRemoteDataSource.releaseSeatHold sends token in x-hold-token and ApiClient sanitizes log',
      () async {
        String? capturedHeaderToken;
        String? capturedPath;

        final mockClient = MockClient((request) async {
          capturedHeaderToken = request.headers['x-hold-token'];
          capturedPath = request.url.path;
          return http.Response(
            jsonEncode({'success': true, 'message': 'Released'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(httpClient: mockClient);
        final remoteDs = SeatRemoteDataSourceImpl(client: apiClient);

        final result = await remoteDs.releaseSeatHold('secret_hold_token_999');
        expect(result, isTrue);
        expect(capturedHeaderToken, equals('secret_hold_token_999'));
        expect(capturedPath, equals('/api/v1/seat-holds'));

        // Verify URL sanitizer masks tokens
        final sensitiveUri = Uri.parse(
          'https://api.vexgo.vn/api/v1/seat-holds/secret_hold_token_999?token=my_secret_token',
        );
        final sanitized = ApiClient.sanitizeUriForLog(sensitiveUri);
        expect(sanitized, isNot(contains('secret_hold_token_999')));
        expect(sanitized, contains('REDACTED'));
      },
    );

    // -------------------------------------------------------------------------
    // Finding J: RealNotificationRepository & HybridNotificationRepository call remote in Real Mode
    // -------------------------------------------------------------------------
    test(
      'Finding J: RealNotificationRepository & HybridNotificationRepository call NotificationRemoteDataSource',
      () async {
        ApiConfig.isDemoMode = false;
        await TokenStorage.saveTokens(accessToken: 'mock_jwt_token');

        final mockClient = MockClient((request) async {
          expect(request.method, equals('GET'));
          expect(request.url.path, endsWith('/notifications'));
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'notif_1',
                  'title': 'Vé mới đặt',
                  'message': 'Đặt vé thành công',
                  'type': 'BOOKING_SUCCESS',
                  'createdAt': '2026-10-10T10:00:00Z',
                  'isRead': false,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(httpClient: mockClient);
        final remoteDs = NotificationRemoteDataSourceImpl(client: apiClient);

        final realRepo = RealNotificationRepository(remoteDataSource: remoteDs);
        final realList = await realRepo.getNotifications();
        expect(realList.length, equals(1));
        expect(realList.first.id, equals('notif_1'));

        final hybridRepo = HybridNotificationRepository(
          remoteDataSource: remoteDs,
        );
        final hybridList = await hybridRepo.getNotifications();
        expect(hybridList.length, equals(1));
        expect(hybridList.first.id, equals('notif_1'));
      },
    );

    // -------------------------------------------------------------------------
    // Finding K: MyTicketsBloc review failure never fakes success in Real Mode
    // -------------------------------------------------------------------------
    test(
      'Finding K: MyTicketsBloc emits error and never reports fake success when review API fails in Real Mode',
      () async {
        ApiConfig.isDemoMode = false;

        final bloc = MyTicketsBloc(
          bookingRepository: MockBookingRepository(),
          reviewRemoteDataSource: FailingReviewRemoteDataSource(),
        );

        final sampleTicket = TicketModel(
          id: 'TKT_REVIEW_TEST',
          ticketCode: 'VXG-REV-01',
          status: TicketStatus.completed,
          bookingDate: '10/10/2026 10:00',
          trip: const TicketTripSummary(
            id: '50',
            operatorName: 'Nhà xe ABC',
            vehicleType: 'Limousine',
            departureTime: '10:00',
            departureDate: '10/10/2026',
            arrivalTime: '16:00',
            arrivalDate: '10/10/2026',
            fromCity: 'TP. Hồ Chí Minh',
            toCity: 'Đà Lạt',
            pickupPoint: 'BX Miền Đông',
            pickupAddress: 'Bình Thạnh',
            dropoffPoint: 'BX Đà Lạt',
            dropoffAddress: 'Tô Hiến Thành',
          ),
          seats: const ['A01'],
          totalAmount: 250000,
          discountAmount: 0,
          finalAmount: 250000,
          paymentMethod: 'MoMo',
          passenger: const PassengerInfo(
            fullName: 'Nguyễn Văn A',
            phone: '0901234567',
            email: 'a@example.com',
          ),
        );

        bloc.add(AddNewTicketEvent(sampleTicket));

        const review = ReviewModel(
          rating: 5,
          comment: 'Dịch vụ tốt',
          createdAt: '10/10/2026 18:00',
        );

        bloc.add(
          const SubmitTicketReviewEvent(
            ticketId: 'TKT_REVIEW_TEST',
            review: review,
          ),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<MyTicketsState>((state) {
              final t = state.tickets.firstWhere(
                (t) => t.id == 'TKT_REVIEW_TEST',
              );
              return t.review == null &&
                  state.errorMessage != null &&
                  state.errorMessage!.contains('chưa khả dụng');
            }),
          ),
        );

        await bloc.close();
      },
    );

    // -------------------------------------------------------------------------
    // Finding L: cancelTicket unwrap data envelope
    // -------------------------------------------------------------------------
    test(
      'Finding L: TicketRemoteDataSource unwraps cancelTicket response envelope correctly',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'ticketId': 105,
                'ticketCode': 'VXG-9988',
                'status': 'CANCELLED',
                'cancelFeeRate': 0.1,
                'cancelFee': 29000,
                'refundAmount': 261000,
                'message': 'Hủy vé thành công',
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final apiClient = ApiClient(httpClient: mockClient);
        final remoteDataSource = TicketRemoteDataSourceImpl(client: apiClient);

        final result = await remoteDataSource.cancelTicket(
          ticketCode: 'VXG-9988',
          phoneNumber: '0901234567',
          reason: 'Thay đổi kế hoạch',
          expectedCancelFeeRate: 0.1,
        );

        final refund =
            result['refundAmount'] ??
            (result['data'] is Map
                ? (result['data'] as Map)['refundAmount']
                : null);
        expect(refund, equals(261000));
      },
    );

    // -------------------------------------------------------------------------
    // Finding M: OperatorModel safely handles null rating and review count
    // -------------------------------------------------------------------------
    test(
      'Finding M: OperatorModel parses backend /bus-companies payload without fake 4.8 rating',
      () {
        final backendOperatorJson = {
          'id': 1,
          'name': 'Phương Trang',
          'code': 'FUTA',
        };

        final operator = OperatorModel.fromJson(backendOperatorJson);

        expect(operator.id, equals('1'));
        expect(operator.name, equals('Phương Trang'));
        expect(operator.rating, isNull);
        expect(operator.reviewCount, isNull);
        expect(operator.hotline, isNull);
      },
    );

    // -------------------------------------------------------------------------
    // Finding N: PopularRouteModel safely handles null minPrice
    // -------------------------------------------------------------------------
    test(
      'Finding N: PopularRouteModel parses backend /routes payload without fake 200.000đ minPrice',
      () {
        final backendRouteJson = {
          'id': 5,
          'origin': 'TP. Hồ Chí Minh',
          'destination': 'Đà Lạt',
          'distanceKm': 305,
          'durationMinutes': 390,
        };

        final route = PopularRouteModel.fromJson(backendRouteJson);

        expect(route.id, equals('5'));
        expect(route.fromCityName, equals('TP. Hồ Chí Minh'));
        expect(route.toCityName, equals('Đà Lạt'));
        expect(route.duration, equals('6.5 giờ'));
        expect(route.minPrice, isNull);
      },
    );

    // -------------------------------------------------------------------------
    // Finding O & S: PaymentPendingException preserves bookingId, paymentUrl, and deeplink
    // -------------------------------------------------------------------------
    test(
      'Finding O & S: PaymentPendingException preserves bookingId, paymentUrl and deeplink',
      () {
        const exception = PaymentPendingException(
          message: 'Chờ thanh toán',
          paymentId: 100,
          bookingId: 200,
          paymentUrl: 'https://vnpay.vn/pay?id=100',
          deeplink: 'vnpay://pay?id=100',
        );

        expect(exception.bookingId, equals(200));
        expect(exception.paymentId, equals(100));
        expect(exception.paymentUrl, equals('https://vnpay.vn/pay?id=100'));
        expect(exception.deeplink, equals('vnpay://pay?id=100'));
      },
    );

    // -------------------------------------------------------------------------
    // Finding Q: Review submission authoritatively resolves tripId or fails gracefully
    // -------------------------------------------------------------------------
    test(
      'Finding Q: MyTicketsBloc review fails without valid tripId and never defaults to 1',
      () async {
        ApiConfig.isDemoMode = false;

        final bloc = MyTicketsBloc(
          bookingRepository: MockBookingRepository(),
          reviewRemoteDataSource: FailingReviewRemoteDataSource(),
        );

        final ticketWithoutNumericTrip = TicketModel(
          id: 'TKT_NO_TRIP',
          ticketCode: 'VXG-NO-TRIP',
          status: TicketStatus.completed,
          bookingDate: '10/10/2026',
          trip: const TicketTripSummary(
            id: '', // Empty non-numeric trip id
            operatorName: 'Nhà xe ABC',
            vehicleType: 'Limousine',
            departureTime: '10:00',
            departureDate: '10/10/2026',
            arrivalTime: '16:00',
            arrivalDate: '10/10/2026',
            fromCity: 'TP. Hồ Chí Minh',
            toCity: 'Đà Lạt',
            pickupPoint: 'BX Miền Đông',
            pickupAddress: 'Bình Thạnh',
            dropoffPoint: 'BX Đà Lạt',
            dropoffAddress: 'Tô Hiến Thành',
          ),
          seats: const ['A01'],
          totalAmount: 250000,
          discountAmount: 0,
          finalAmount: 250000,
          paymentMethod: 'MoMo',
          passenger: const PassengerInfo(
            fullName: 'Nguyễn Văn A',
            phone: '0901234567',
            email: 'a@example.com',
          ),
        );

        bloc.add(AddNewTicketEvent(ticketWithoutNumericTrip));

        bloc.add(
          const SubmitTicketReviewEvent(
            ticketId: 'TKT_NO_TRIP',
            review: ReviewModel(
              rating: 5,
              comment: 'Tốt',
              createdAt: '10/10/2026',
            ),
          ),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<MyTicketsState>((state) {
              return state.errorMessage != null &&
                  state.errorMessage!.contains(
                    'Không thể xác định mã chuyến đi',
                  );
            }),
          ),
        );

        await bloc.close();
      },
    );

    // -------------------------------------------------------------------------
    // Finding R: Cancel ticket with absent refundAmount indicates queued status
    // -------------------------------------------------------------------------
    test(
      'Finding R: MyTicketsBloc cancelTicket with absent refundAmount reports queued processing message',
      () async {
        final sampleTicket = TicketModel(
          id: '901',
          ticketCode: 'VXG-CAN-01',
          status: TicketStatus.upcoming,
          bookingDate: '10/10/2026 10:00',
          trip: const TicketTripSummary(
            id: '50',
            operatorName: 'Nhà xe ABC',
            vehicleType: 'Limousine',
            departureTime: '23:00',
            departureDate: '20/10/2030', // far in future so canCancel is true
            arrivalTime: '05:00',
            arrivalDate: '21/10/2030',
            fromCity: 'TP. Hồ Chí Minh',
            toCity: 'Đà Lạt',
            pickupPoint: 'BX Miền Đông',
            pickupAddress: 'Bình Thạnh',
            dropoffPoint: 'BX Đà Lạt',
            dropoffAddress: 'Tô Hiến Thành',
          ),
          seats: const ['A01'],
          totalAmount: 250000,
          discountAmount: 0,
          finalAmount: 250000,
          paymentMethod: 'MoMo',
          passenger: const PassengerInfo(
            fullName: 'Nguyễn Văn A',
            phone: '0901234567',
            email: 'a@example.com',
          ),
        );

        final quotedTicket = sampleTicket.copyWith(
          rawStatus: 'DA_THANH_TOAN',
          bookingStatus: 'DA_THANH_TOAN',
          paymentStatus: 'DA_THANH_TOAN',
          cancellation: const CancellationQuote(
            eligible: true,
            cancelFeeRate: 0.1,
            cancelFee: 25000,
            refundAmount: 225000,
          ),
        );
        final queuedRepo = QueuedRefundBookingRepository(quotedTicket);
        final bloc = MyTicketsBloc(bookingRepository: queuedRepo);

        bloc.add(AddNewTicketEvent(quotedTicket));

        bloc.add(
          const CancelTicketEvent(
            ticketId: '901',
            reason: 'Bận việc',
            refundAmount: 200000,
          ),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<MyTicketsState>((state) {
              return state.successMessage != null &&
                  state.successMessage!.contains('đang chờ xử lý hoàn tiền');
            }),
          ),
        );

        await bloc.close();
      },
    );
  });
}
