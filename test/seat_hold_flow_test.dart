import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:vexgo_app/core/network/api_response.dart';
import 'package:vexgo_app/data/datasources/remote/seat_remote_data_source.dart';
import 'package:vexgo_app/data/models/seat_hold_model.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/seat_hold_countdown_bar.dart';

class MockSeatRemoteDataSourceThrows409 implements SeatRemoteDataSource {
  @override
  Future<List<SeatModel>> getTripSeats(dynamic tripId) async => [];

  @override
  Future<SeatHoldModel> createSeatHold({
    required int tripId,
    required List<int> seatIds,
  }) async {
    throw const ApiException(
      ApiError(
        statusCode: 409,
        errorCode: 'SEAT_UNAVAILABLE',
        message: 'Ghế A01 vừa có người khác giữ.',
      ),
    );
  }

  @override
  Future<bool> releaseSeatHold(String holdToken) async => true;
}

class MockSeatRepositoryWithHoldSpy implements SeatRepository {
  bool holdCreated = false;
  bool holdReleased = false;
  bool shouldThrowUnavailable = false;

  @override
  Future<SeatLayoutModel> getSeatLayout(String seatLayoutType) async {
    return const SeatLayoutModel(
      vehicleType: 'Limousine 34 Phòng',
      hasTwoFloors: true,
      lowerFloor: [
        SeatModel(
          id: '10',
          name: 'A01',
          floor: 1,
          status: SeatStatus.available,
          price: 290000,
          row: 1,
          col: 1,
        ),
        SeatModel(
          id: '11',
          name: 'A02',
          floor: 1,
          status: SeatStatus.available,
          price: 290000,
          row: 1,
          col: 2,
        ),
      ],
      upperFloor: [],
    );
  }

  @override
  Future<List<SeatModel>> getTripSeats(dynamic tripId) async {
    final layout = await getSeatLayout('Limousine 34 Phòng');
    return layout.lowerFloor;
  }

  @override
  Future<SeatHoldModel> createSeatHold({
    required int tripId,
    required List<int> seatIds,
  }) async {
    if (shouldThrowUnavailable) {
      throw const ApiException(
        ApiError(
          statusCode: 409,
          errorCode: 'SEAT_UNAVAILABLE',
          message: 'Ghế A01 vừa có người khác giữ. Vui lòng chọn ghế khác.',
        ),
      );
    }
    holdCreated = true;
    return SeatHoldModel(
      holdToken: 'spy_hold_token_123',
      tripId: tripId,
      seatIds: seatIds,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );
  }

  @override
  Future<bool> releaseSeatHold(String holdToken) async {
    holdReleased = true;
    return true;
  }
}

class SpyBookingRepository extends MockBookingRepository {
  List<int>? lastSeatIds;
  String? lastHoldToken;
  String? lastPromotionCode;

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
    lastSeatIds = seatIds;
    lastHoldToken = holdToken;
    lastPromotionCode = promotionCode;
    return super.createBooking(
      trip: trip,
      seats: seats,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      finalAmount: finalAmount,
      paymentMethod: paymentMethod,
      passenger: passenger,
      seatIds: seatIds,
      holdToken: holdToken,
      promotionCode: promotionCode,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BookingFlowBloc bloc;
  late MockSeatRepositoryWithHoldSpy seatRepo;
  late MockBookingRepository bookingRepo;

  final testTrip = TripModel(
    id: '101',
    operatorId: '1',
    operatorName: 'Phương Trang FUTA',
    vehicleType: 'Limousine 34 Phòng',
    fromCityId: 'SGN',
    fromCityName: 'TP. Hồ Chí Minh',
    toCityId: 'DLT',
    toCityName: 'Đà Lạt',
    departureTime: '23:00',
    arrivalTime: '06:00',
    duration: '7h',
    pickupPoint: 'Bến xe Miền Đông mới',
    pickupAddress: 'Thủ Đức',
    dropoffPoint: 'Bến xe Đà Lạt',
    dropoffAddress: 'Tô Hiến Thành',
    originalPrice: 290000,
    discountPrice: 290000,
    availableSeats: 10,
    totalSeats: 34,
    seatLayoutType: 'SLEEPER_34',
    rating: 4.8,
    reviewCount: 120,
    pickupPoints: const [
      StopPointModel(
        id: 'PU1',
        name: 'Bến xe Miền Đông mới',
        time: '23:00',
        address: 'Thủ Đức',
        type: 'point',
        isDefault: true,
      ),
    ],
    dropoffPoints: const [
      StopPointModel(
        id: 'DO1',
        name: 'Bến xe Đà Lạt',
        time: '06:00',
        address: 'Tô Hiến Thành',
        type: 'point',
        isDefault: true,
      ),
    ],
  );

  setUp(() {
    seatRepo = MockSeatRepositoryWithHoldSpy();
    bookingRepo = MockBookingRepository();
    bloc = BookingFlowBloc(
      seatRepository: seatRepo,
      bookingRepository: bookingRepo,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('Task 3: Seat Hold & Countdown Timer Tests', () {
    test(
      'NextStepEvent from seatSelection calls createSeatHold and starts countdown',
      () async {
        bloc.add(
          InitBookingFlowEvent(trip: testTrip, date: DateTime(2026, 10, 1)),
        );
        await bloc.stream.firstWhere(
          (s) => s.status == BookingFlowStatus.loaded,
        );

        // Select seat
        const seat = SeatModel(
          id: '10',
          name: 'A01',
          floor: 1,
          status: SeatStatus.available,
          price: 290000,
          row: 1,
          col: 1,
        );
        bloc.add(const ToggleSeatEvent(seat));
        await bloc.stream.firstWhere((s) => s.selectedSeats.isNotEmpty);

        // Advance: should acquire hold
        bloc.add(const NextStepEvent());
        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<BookingFlowState>((s) {
              return s.step == BookingStep.pickupPoint &&
                  s.seatHold != null &&
                  s.seatHold!.holdToken == 'spy_hold_token_123' &&
                  s.countdownSeconds > 0;
            }),
          ),
        );

        expect(seatRepo.holdCreated, isTrue);
      },
    );

    test(
      'Handles 409 SEAT_UNAVAILABLE gracefully with error message',
      () async {
        seatRepo.shouldThrowUnavailable = true;

        bloc.add(
          InitBookingFlowEvent(trip: testTrip, date: DateTime(2026, 10, 1)),
        );
        await bloc.stream.firstWhere(
          (s) => s.status == BookingFlowStatus.loaded,
        );

        const seat = SeatModel(
          id: '10',
          name: 'A01',
          floor: 1,
          status: SeatStatus.available,
          price: 290000,
          row: 1,
          col: 1,
        );
        bloc.add(const ToggleSeatEvent(seat));
        await bloc.stream.firstWhere((s) => s.selectedSeats.isNotEmpty);

        bloc.add(const NextStepEvent());
        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<BookingFlowState>((s) {
              return s.status == BookingFlowStatus.failure &&
                  s.step == BookingStep.seatSelection &&
                  s.errorMessage!.contains('vừa có người khác giữ');
            }),
          ),
        );
      },
    );

    test(
      'TickCountdownEvent decrements countdown and triggers timeout at 0',
      () async {
        bloc.add(
          InitBookingFlowEvent(trip: testTrip, date: DateTime(2026, 10, 1)),
        );
        await bloc.stream.firstWhere(
          (s) => s.status == BookingFlowStatus.loaded,
        );

        const seat = SeatModel(
          id: '10',
          name: 'A01',
          floor: 1,
          status: SeatStatus.available,
          price: 290000,
          row: 1,
          col: 1,
        );
        bloc.add(const ToggleSeatEvent(seat));
        await bloc.stream.firstWhere((s) => s.selectedSeats.isNotEmpty);

        bloc.add(const NextStepEvent());
        await bloc.stream.firstWhere((s) => s.seatHold != null);

        // Decrement tick
        bloc.add(const TickCountdownEvent());
        await expectLater(
          bloc.stream,
          emits(predicate<BookingFlowState>((s) => s.countdownSeconds < 600)),
        );
      },
    );

    test('ReleaseSeatHoldEvent explicitly releases held seats', () async {
      bloc.add(
        InitBookingFlowEvent(trip: testTrip, date: DateTime(2026, 10, 1)),
      );
      await bloc.stream.firstWhere((s) => s.status == BookingFlowStatus.loaded);

      const seat = SeatModel(
        id: '10',
        name: 'A01',
        floor: 1,
        status: SeatStatus.available,
        price: 290000,
        row: 1,
        col: 1,
      );
      bloc.add(const ToggleSeatEvent(seat));
      await bloc.stream.firstWhere((s) => s.selectedSeats.isNotEmpty);

      bloc.add(const NextStepEvent());
      await bloc.stream.firstWhere((s) => s.seatHold != null);

      // Release hold event
      bloc.add(const ReleaseSeatHoldEvent());
      await expectLater(
        bloc.stream,
        emits(predicate<BookingFlowState>((s) => s.seatHold == null)),
      );

      expect(seatRepo.holdReleased, isTrue);
    });

    test(
      'TickCountdownEvent reaching 0 triggers timeout, releases seat hold and resets step',
      () async {
        bloc.add(
          InitBookingFlowEvent(trip: testTrip, date: DateTime(2026, 10, 1)),
        );
        await bloc.stream.firstWhere(
          (s) => s.status == BookingFlowStatus.loaded,
        );

        const seat = SeatModel(
          id: '10',
          name: 'A01',
          floor: 1,
          status: SeatStatus.available,
          price: 290000,
          row: 1,
          col: 1,
        );
        bloc.add(const ToggleSeatEvent(seat));
        await bloc.stream.firstWhere((s) => s.selectedSeats.isNotEmpty);

        bloc.add(const NextStepEvent());
        await bloc.stream.firstWhere((s) => s.seatHold != null);

        // Fast-forward countdown down to 1 second
        for (int i = 0; i < 599; i++) {
          bloc.add(const TickCountdownEvent());
        }
        await bloc.stream.firstWhere((s) => s.countdownSeconds == 1);

        // Final tick: hits 0 -> timeout!
        bloc.add(const TickCountdownEvent());
        await expectLater(
          bloc.stream,
          emits(
            predicate<BookingFlowState>((s) {
              return s.countdownSeconds == 0 &&
                  s.status == BookingFlowStatus.failure &&
                  s.step == BookingStep.seatSelection &&
                  s.seatHold == null &&
                  s.errorMessage!.contains('Hết thời gian giữ ghế');
            }),
          ),
        );

        // Verify that releaseSeatHold was explicitly invoked on timeout
        expect(seatRepo.holdReleased, isTrue);
      },
    );

    test(
      'Regression: HybridSeatRepository rethrows 409 ApiException and NEVER falls back to mock',
      () async {
        final mockDataSource = MockSeatRemoteDataSourceThrows409();
        final hybridRepo = HybridSeatRepository(
          remoteDataSource: mockDataSource,
          mockFallback: MockSeatRepository(),
        );

        expect(
          () => hybridRepo.createSeatHold(tripId: 101, seatIds: [10]),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409),
          ),
        );
      },
    );

    test(
      'Regression: SeatHoldModel.fromJson enforces strict contract validation',
      () {
        // Missing or empty holdToken
        expect(
          () => SeatHoldModel.fromJson({
            'tripId': 101,
            'seatIds': [1, 2],
            'expiresAt': '2026-10-01T12:00:00Z',
          }),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('holdToken is required'),
            ),
          ),
        );

        expect(
          () => SeatHoldModel.fromJson({
            'holdToken': '   ',
            'tripId': 101,
            'seatIds': [1, 2],
            'expiresAt': '2026-10-01T12:00:00Z',
          }),
          throwsA(isA<FormatException>()),
        );

        // Missing or invalid tripId
        expect(
          () => SeatHoldModel.fromJson({
            'holdToken': 'token_abc',
            'tripId': 0,
            'seatIds': [1, 2],
            'expiresAt': '2026-10-01T12:00:00Z',
          }),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('tripId must be a positive integer'),
            ),
          ),
        );

        // Missing or empty seatIds
        expect(
          () => SeatHoldModel.fromJson({
            'holdToken': 'token_abc',
            'tripId': 101,
            'seatIds': [],
            'expiresAt': '2026-10-01T12:00:00Z',
          }),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('seatIds must be a non-empty list'),
            ),
          ),
        );

        // Missing or invalid expiresAt
        expect(
          () => SeatHoldModel.fromJson({
            'holdToken': 'token_abc',
            'tripId': 101,
            'seatIds': [1, 2],
            'expiresAt': 'not-a-valid-date',
          }),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('expiresAt has invalid datetime format'),
            ),
          ),
        );

        // Valid payload parses successfully
        final valid = SeatHoldModel.fromJson({
          'holdToken': 'valid_token_xyz',
          'tripId': 101,
          'seatIds': [10, 11],
          'expiresAt': '2026-10-01T12:00:00Z',
        });
        expect(valid.holdToken, equals('valid_token_xyz'));
        expect(valid.tripId, equals(101));
        expect(valid.seatIds, equals([10, 11]));
      },
    );

    test(
      'Regression: BookingFlowBloc propagates holdToken and numeric seatIds to createBooking',
      () async {
        final spyBookingRepo = SpyBookingRepository();
        final testBloc = BookingFlowBloc(
          bookingRepository: spyBookingRepo,
          seatRepository: seatRepo,
        );

        testBloc.add(
          InitBookingFlowEvent(trip: testTrip, date: DateTime(2026, 10, 1)),
        );
        await testBloc.stream.firstWhere(
          (s) => s.status == BookingFlowStatus.loaded,
        );

        const seat = SeatModel(
          id: '10',
          name: 'A01',
          floor: 1,
          status: SeatStatus.available,
          price: 290000,
          row: 1,
          col: 1,
        );
        testBloc.add(const ToggleSeatEvent(seat));
        await testBloc.stream.firstWhere((s) => s.selectedSeats.isNotEmpty);

        // Advance to reserve seats -> creates seatHold
        testBloc.add(const NextStepEvent());
        await testBloc.stream.firstWhere((s) => s.seatHold != null);

        expect(
          testBloc.state.seatHold!.holdToken,
          equals('spy_hold_token_123'),
        );

        // Confirm booking
        testBloc.add(const ConfirmPaymentEvent());
        await testBloc.stream.firstWhere(
          (s) => s.status == BookingFlowStatus.success,
        );

        // Verify that createBooking received the exact holdToken and numeric seatIds
        expect(spyBookingRepo.lastHoldToken, equals('spy_hold_token_123'));
        expect(spyBookingRepo.lastSeatIds, equals([10]));

        testBloc.close();
      },
    );

    testWidgets(
      'SeatHoldCountdownBar renders properly and reflects urgent state',
      (tester) async {
        // Normal state: 580 seconds (> 60s)
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SeatHoldCountdownBar(
                remainingSeconds: 580,
                seatCodes: ['A01', 'A02'],
              ),
            ),
          ),
        );

        expect(
          find.textContaining('Ghế đang được giữ (A01, A02)'),
          findsOneWidget,
        );
        expect(find.textContaining('09:40'), findsOneWidget);

        // Urgent state: 45 seconds (<= 60s)
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SeatHoldCountdownBar(
                remainingSeconds: 45,
                seatCodes: ['A01'],
              ),
            ),
          ),
        );

        expect(
          find.textContaining('Sắp hết hạn giữ ghế (A01)'),
          findsOneWidget,
        );
        expect(find.textContaining('00:45'), findsOneWidget);
      },
    );
  });
}
