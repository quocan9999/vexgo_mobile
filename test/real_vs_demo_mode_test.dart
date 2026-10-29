import 'package:vexgo_app/data/models/booking_cargo_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:vexgo_app/core/network/api_response.dart';
import 'package:vexgo_app/data/datasources/remote/booking_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/seat_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/ticket_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/trip_remote_data_source.dart';
import 'package:vexgo_app/data/models/booking_model.dart';
import 'package:vexgo_app/data/models/booking_quote_model.dart';
import 'package:vexgo_app/data/models/operator_model.dart';
import 'package:vexgo_app/data/models/popular_route_model.dart';
import 'package:vexgo_app/data/models/promotion_validation_model.dart';
import 'package:vexgo_app/data/models/seat_hold_model.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';

// --- FAKE DATASOURCES ---

class FakeTicketRemoteDataSource implements TicketRemoteDataSource {
  List<TicketModel> ticketsToReturn = [];
  bool shouldThrow = false;
  ApiException? exceptionToThrow;

  @override
  Future<List<TicketModel>> getCustomerTickets({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ??
          const ApiException(
            ApiError(
              statusCode: 500,
              errorCode: 'INTERNAL_ERROR',
              message: 'Server error',
            ),
          );
    }
    return ticketsToReturn;
  }

  @override
  Future<TicketModel> getCustomerTicketById(dynamic ticketId) async {
    if (shouldThrow) {
      throw exceptionToThrow ??
          const ApiException(
            ApiError(
              statusCode: 500,
              errorCode: 'INTERNAL_ERROR',
              message: 'Server error',
            ),
          );
    }
    return ticketsToReturn.firstWhere((t) => t.id == 'TKT_$ticketId');
  }

  @override
  Future<Map<String, dynamic>> cancelTicket({
    required String ticketCode,
    required String phoneNumber,
    String? reason,
    required double expectedCancelFeeRate,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ??
          const ApiException(
            ApiError(
              statusCode: 400,
              errorCode: 'BAD_REQUEST',
              message: 'Cancel error',
            ),
          );
    }
    return {'success': true};
  }

  @override
  Future<TicketModel> lookupTicket({
    required String ticketCode,
    required String phoneNumber,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ??
          const ApiException(
            ApiError(
              statusCode: 404,
              errorCode: 'NOT_FOUND',
              message: 'Ticket not found',
            ),
          );
    }
    return ticketsToReturn.first;
  }
}

class FakeBookingRemoteDataSource implements BookingRemoteDataSource {
  bool shouldThrow = false;

  @override
  Future<BookingQuoteModel> getBookingQuote({
    required int tripId,
    required List<int> seatIds,
    String? promotionCode,
    String? contactPhone,
  }) async {
    if (shouldThrow) {
      throw const ApiException(
        ApiError(
          statusCode: 500,
          errorCode: 'QUOTE_ERROR',
          message: 'Backend quote failed',
        ),
      );
    }
    return const BookingQuoteModel(
      unitPrice: 200000,
      seatCount: 1,
      originalTotal: 200000,
      discountAmount: 0,
      finalTotal: 200000,
    );
  }

  @override
  Future<PromotionValidationModel> validatePromotion({
    required String code,
    required int tripId,
    required int seatCount,
    required int totalAmount,
  }) async {
    if (shouldThrow) {
      throw const ApiException(
        ApiError(
          statusCode: 400,
          errorCode: 'INVALID_PROMO',
          message: 'Promo service unavailable',
        ),
      );
    }
    return const PromotionValidationModel(
      code: 'TEST10',
      isValid: true,
      discountAmount: 20000,
    );
  }

  @override
  Future<BookingModel> createBooking({
    required int tripId,
    required List<int> seatIds,
    required String pickupPoint,
    required String dropoffPoint,
    required PassengerInfo contact,
    String? promotionCode,
    String? holdToken,
    BookingQuoteModel? expectedPromotionQuote,
    BookingCargoDraft? cargo,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<BookingModel> getBookingById(dynamic bookingId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<BookingModel>> getMyBookings({
    int page = 1,
    int pageSize = 10,
  }) async {
    throw UnimplementedError();
  }
}

class FakeSeatRemoteDataSource implements SeatRemoteDataSource {
  bool shouldThrow = false;
  List<SeatModel> seatsToReturn = [];

  @override
  Future<List<SeatModel>> getTripSeats(dynamic tripId) async {
    if (shouldThrow) {
      throw const ApiException(
        ApiError(
          statusCode: 500,
          errorCode: 'TRIP_NOT_FOUND',
          message: 'Trip error',
        ),
      );
    }
    return seatsToReturn;
  }

  @override
  Future<SeatHoldModel> createSeatHold({
    required int tripId,
    required List<int> seatIds,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> releaseSeatHold(String holdToken) async => true;
}

class FakeTripRemoteDataSource implements TripRemoteDataSource {
  bool shouldThrow = false;
  List<TripModel> tripsToReturn = [];

  @override
  Future<List<TripModel>> searchTrips({
    String? from,
    String? to,
    String? departureDate,
    int? busCompanyId,
    int page = 1,
    int pageSize = 10,
    String? sortBy,
    String? sortDirection,
  }) async {
    if (shouldThrow) {
      throw const ApiException(
        ApiError(
          statusCode: 500,
          errorCode: 'SEARCH_FAILED',
          message: 'Search failed',
        ),
      );
    }
    return tripsToReturn;
  }

  @override
  Future<TripModel> getTripById(dynamic tripId) async {
    if (shouldThrow) {
      throw const ApiException(
        ApiError(
          statusCode: 404,
          errorCode: 'TRIP_NOT_FOUND',
          message: 'Not found',
        ),
      );
    }
    return tripsToReturn.first;
  }

  @override
  Future<List<PopularRouteModel>> getPopularRoutes() async => const [];

  @override
  Future<List<OperatorModel>> getBusCompanies() async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Finding 4 - Real Mode vs Demo Mode Separation', () {
    late FakeTicketRemoteDataSource fakeTicketDataSource;
    late FakeBookingRemoteDataSource fakeBookingDataSource;
    late FakeSeatRemoteDataSource fakeSeatDataSource;
    late FakeTripRemoteDataSource fakeTripDataSource;

    setUp(() {
      ApiConfig.isDemoMode = false; // Default: Real Mode
      fakeTicketDataSource = FakeTicketRemoteDataSource();
      fakeBookingDataSource = FakeBookingRemoteDataSource();
      fakeSeatDataSource = FakeSeatRemoteDataSource();
      fakeTripDataSource = FakeTripRemoteDataSource();
    });

    tearDown(() {
      ApiConfig.isDemoMode = false;
    });

    test(
      'RealBookingRepository.getMyTickets() returns [] when remote returns [] and never injects mock tickets',
      () async {
        final repo = RealBookingRepository(
          remoteTicketDataSource: fakeTicketDataSource,
        );

        fakeTicketDataSource.ticketsToReturn = [];
        final tickets = await repo.getMyTickets();

        // Must be empty, NOT filled with mock fallback tickets!
        expect(tickets, isEmpty);
      },
    );

    test(
      'RealBookingRepository.getMyTickets() rethrows when remote fails and never falls back to mock',
      () async {
        final repo = RealBookingRepository(
          remoteTicketDataSource: fakeTicketDataSource,
        );

        fakeTicketDataSource.shouldThrow = true;
        fakeTicketDataSource.exceptionToThrow = const ApiException(
          ApiError(
            statusCode: 401,
            errorCode: 'UNAUTHORIZED',
            message: 'Session expired',
          ),
        );

        expect(
          () => repo.getMyTickets(),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
          ),
        );
      },
    );

    test(
      'RealBookingRepository.getBookingQuote() rethrows when backend fails',
      () async {
        final repo = RealBookingRepository(
          remoteBookingDataSource: fakeBookingDataSource,
        );

        fakeBookingDataSource.shouldThrow = true;

        expect(
          () => repo.getBookingQuote(tripId: 10, seatIds: [1]),
          throwsA(
            isA<ApiException>().having(
              (e) => e.errorCode,
              'errorCode',
              'QUOTE_ERROR',
            ),
          ),
        );
      },
    );

    test(
      'RealBookingRepository.validatePromotion() rethrows when backend fails',
      () async {
        final repo = RealBookingRepository(
          remoteBookingDataSource: fakeBookingDataSource,
        );

        fakeBookingDataSource.shouldThrow = true;

        expect(
          () => repo.validatePromotion(
            code: 'TEST',
            tripId: 10,
            seatCount: 1,
            totalAmount: 200000,
          ),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400),
          ),
        );
      },
    );

    test(
      'HybridBookingRepository does NOT fallback to mock when isDemoMode is false',
      () async {
        ApiConfig.isDemoMode = false;
        final repo = HybridBookingRepository(
          remoteTicketDataSource: fakeTicketDataSource,
          remoteBookingDataSource: fakeBookingDataSource,
        );

        fakeTicketDataSource.ticketsToReturn = [];
        final tickets = await repo.getMyTickets();
        expect(tickets, isEmpty); // Real empty, not mock!

        fakeBookingDataSource.shouldThrow = true;
        expect(
          () => repo.getBookingQuote(tripId: 10, seatIds: [1]),
          throwsA(isA<ApiException>()),
        );
      },
    );

    test(
      'HybridBookingRepository DOES fallback to mock when isDemoMode is true',
      () async {
        ApiConfig.isDemoMode = true;
        final repo = HybridBookingRepository(
          remoteTicketDataSource: fakeTicketDataSource,
          remoteBookingDataSource: fakeBookingDataSource,
        );

        // When remote returns empty, demo mode falls back to mock tickets
        fakeTicketDataSource.ticketsToReturn = [];
        final tickets = await repo.getMyTickets();
        expect(tickets, isNotEmpty);

        // When remote quote throws, demo mode falls back to mock quote
        fakeBookingDataSource.shouldThrow = true;
        final quote = await repo.getBookingQuote(
          tripId: 10,
          seatIds: [1],
          promotionCode: 'SUMMER26',
        );
        expect(quote.discountAmount, greaterThan(0));
      },
    );

    test('RealSeatRepository rethrows when remote fails', () async {
      final repo = RealSeatRepository(remoteDataSource: fakeSeatDataSource);
      fakeSeatDataSource.shouldThrow = true;

      expect(() => repo.getTripSeats(10), throwsA(isA<ApiException>()));
    });

    test('RealTripRepository rethrows when remote fails', () async {
      final repo = RealTripRepository(remoteDataSource: fakeTripDataSource);
      fakeTripDataSource.shouldThrow = true;

      expect(
        () => repo.searchTrips(fromCityId: 'HCM', toCityId: 'DL'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
