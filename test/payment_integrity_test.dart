import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:vexgo_app/core/network/api_response.dart';
import 'package:vexgo_app/core/utils/payment_provider_mapper.dart';
import 'package:vexgo_app/data/datasources/remote/booking_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/payment_remote_data_source.dart';
import 'package:vexgo_app/data/models/booking_model.dart';
import 'package:vexgo_app/data/models/booking_quote_model.dart';
import 'package:vexgo_app/data/models/payment_transaction_model.dart';
import 'package:vexgo_app/data/models/promotion_validation_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';

class FakeBookingRemoteDataSource implements BookingRemoteDataSource {
  BookingModel? nextBooking;
  Exception? errorToThrow;

  @override
  Future<BookingModel> createBooking({
    required int tripId,
    required List<int> seatIds,
    required String pickupPoint,
    required String dropoffPoint,
    required PassengerInfo contact,
    String? promotionCode,
    String? holdToken,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return nextBooking ??
        BookingModel(
          bookingId: 888,
          bookingCode: 'VG888TEST',
          tripId: tripId,
          status: BookingStatus.paid,
          contact: contact,
          pickupPoint: pickupPoint,
          dropoffPoint: dropoffPoint,
          seats: seatIds.map((s) => 'Seat_$s').toList(),
          seatIds: seatIds,
          totalAmount: 250000,
          originalAmount: 300000,
          discountAmount: 50000,
        );
  }

  @override
  Future<BookingModel> getBookingById(dynamic bookingId) async =>
      throw UnimplementedError();

  @override
  Future<BookingQuoteModel> getBookingQuote({
    required int tripId,
    required List<int> seatIds,
    String? promotionCode,
  }) async => throw UnimplementedError();

  @override
  Future<List<BookingModel>> getMyBookings({
    int page = 1,
    int pageSize = 10,
  }) async => [];

  @override
  Future<PromotionValidationModel> validatePromotion({
    required String code,
    required int tripId,
    required int seatCount,
    required int totalAmount,
  }) async => throw UnimplementedError();
}

class FakePaymentRemoteDataSource implements PaymentRemoteDataSource {
  PaymentTransactionModel? nextPayment;
  PaymentTransactionModel? nextStatus;
  Exception? createPaymentError;
  Exception? getStatusError;
  String? lastPassedProvider;

  @override
  Future<PaymentTransactionModel> createPayment({
    required int bookingId,
    required String provider,
  }) async {
    lastPassedProvider = provider;
    if (createPaymentError != null) throw createPaymentError!;
    return nextPayment ??
        PaymentTransactionModel(
          paymentId: 1001,
          bookingId: bookingId,
          provider: PaymentProvider.momo,
          amount: 250000,
          status: PaymentStatus.pending,
        );
  }

  @override
  Future<PaymentTransactionModel> getPaymentStatus(dynamic paymentId) async {
    if (getStatusError != null) throw getStatusError!;
    return nextStatus ??
        PaymentTransactionModel(
          paymentId: paymentId as int,
          bookingId: 888,
          provider: PaymentProvider.momo,
          amount: 250000,
          status: PaymentStatus.success,
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const dummyTrip = TicketTripSummary(
    id: '101',
    operatorName: 'Phương Trang',
    vehicleType: 'Limousine',
    departureTime: '23:00',
    departureDate: '02/10/2026',
    arrivalTime: '06:00',
    arrivalDate: '03/10/2026',
    fromCity: 'TP. Hồ Chí Minh',
    toCity: 'Đà Lạt',
    pickupPoint: 'BX Miền Tây',
    pickupAddress: 'Kinh Dương Vương',
    dropoffPoint: 'BX Đà Lạt',
    dropoffAddress: 'Đà Lạt',
  );

  const dummyPassenger = PassengerInfo(
    fullName: 'Nguyễn Văn An',
    phone: '0901234567',
    email: 'an@example.com',
  );

  group('Lead Review Round 3 - Finding 2: Payment Provider Mapping', () {
    test('Maps all UI options to supported backend providers', () {
      expect(PaymentProviderMapper.toBackendProvider('momo'), equals('MOMO'));
      expect(PaymentProviderMapper.toBackendProvider('MOMO'), equals('MOMO'));
      expect(
        PaymentProviderMapper.toBackendProvider('zalopay'),
        equals('ZALOPAY'),
      );
      expect(
        PaymentProviderMapper.toBackendProvider('ZALOPAY'),
        equals('ZALOPAY'),
      );

      // Banking and Card options must map to VNPAY
      expect(
        PaymentProviderMapper.toBackendProvider('vietqr'),
        equals('VNPAY'),
      );
      expect(
        PaymentProviderMapper.toBackendProvider('VIETQR'),
        equals('VNPAY'),
      );
      expect(PaymentProviderMapper.toBackendProvider('napas'), equals('VNPAY'));
      expect(PaymentProviderMapper.toBackendProvider('NAPAS'), equals('VNPAY'));
      expect(PaymentProviderMapper.toBackendProvider('visa'), equals('VNPAY'));
      expect(PaymentProviderMapper.toBackendProvider('VISA'), equals('VNPAY'));
      expect(
        PaymentProviderMapper.toBackendProvider('mastercard'),
        equals('VNPAY'),
      );
      expect(PaymentProviderMapper.toBackendProvider('jcb'), equals('VNPAY'));
      expect(PaymentProviderMapper.toBackendProvider('vnpay'), equals('VNPAY'));

      // Fail closed: reject unknown, typos, empty, null
      expect(
        () => PaymentProviderMapper.toBackendProvider(''),
        throwsArgumentError,
      );
      expect(
        () => PaymentProviderMapper.toBackendProvider(null),
        throwsArgumentError,
      );
      expect(
        () => PaymentProviderMapper.toBackendProvider('momoo'),
        throwsArgumentError,
      );
      expect(
        () => PaymentProviderMapper.toBackendProvider('unknown_gateway'),
        throwsArgumentError,
      );
    });

    test(
      'HybridBookingRepository maps UI paymentMethod before sending to backend createPayment',
      () async {
        final fakeBookingDs = FakeBookingRemoteDataSource();
        final fakePaymentDs = FakePaymentRemoteDataSource();

        final repo = HybridBookingRepository(
          remoteBookingDataSource: fakeBookingDs,
          remotePaymentDataSource: fakePaymentDs,
          mockFallback: MockBookingRepository(),
        );

        // UI passes 'vietqr'
        await repo.createBooking(
          trip: dummyTrip,
          seats: ['A01'],
          seatIds: [1],
          totalAmount: 100,
          discountAmount: 0,
          finalAmount: 100,
          paymentMethod: 'vietqr',
          passenger: dummyPassenger,
        );

        expect(fakePaymentDs.lastPassedProvider, equals('VNPAY'));

        // UI passes 'zalopay'
        await repo.createBooking(
          trip: dummyTrip,
          seats: ['A01'],
          seatIds: [1],
          totalAmount: 100,
          discountAmount: 0,
          finalAmount: 100,
          paymentMethod: 'zalopay',
          passenger: dummyPassenger,
        );

        expect(fakePaymentDs.lastPassedProvider, equals('ZALOPAY'));
      },
    );
  });

  group(
    'Lead Review Round 3 - Finding 1: Payment Success Verification (BLOCKER)',
    () {
      late FakeBookingRemoteDataSource fakeBookingDs;
      late FakePaymentRemoteDataSource fakePaymentDs;
      late HybridBookingRepository repo;

      setUp(() {
        fakeBookingDs = FakeBookingRemoteDataSource();
        fakePaymentDs = FakePaymentRemoteDataSource();
        repo = HybridBookingRepository(
          remoteBookingDataSource: fakeBookingDs,
          remotePaymentDataSource: fakePaymentDs,
          mockFallback: MockBookingRepository(),
        );
      });

      test(
        'Throws PaymentPendingException when payment status is PENDING and does NOT return ticket',
        () async {
          fakePaymentDs.nextPayment = const PaymentTransactionModel(
            paymentId: 99,
            bookingId: 888,
            provider: PaymentProvider.momo,
            amount: 250000,
            status: PaymentStatus.pending,
          );
          fakePaymentDs.nextStatus = const PaymentTransactionModel(
            paymentId: 99,
            bookingId: 888,
            provider: PaymentProvider.momo,
            amount: 250000,
            status: PaymentStatus.pending,
            paymentUrl: 'https://pay.momo.vn/order123',
          );

          expect(
            () => repo.createBooking(
              trip: dummyTrip,
              seats: ['A01'],
              seatIds: [1],
              totalAmount: 250000,
              discountAmount: 0,
              finalAmount: 250000,
              paymentMethod: 'momo',
              passenger: dummyPassenger,
            ),
            throwsA(
              isA<PaymentPendingException>().having(
                (e) => e.paymentId,
                'paymentId',
                equals(99),
              ),
            ),
          );
        },
      );

      test(
        'Throws PaymentFailedException when payment status is FAILED and does NOT return ticket',
        () async {
          fakePaymentDs.nextStatus = const PaymentTransactionModel(
            paymentId: 100,
            bookingId: 888,
            provider: PaymentProvider.momo,
            amount: 250000,
            status: PaymentStatus.failed,
            failureReason: 'Số dư không đủ',
          );

          expect(
            () => repo.createBooking(
              trip: dummyTrip,
              seats: ['A01'],
              seatIds: [1],
              totalAmount: 250000,
              discountAmount: 0,
              finalAmount: 250000,
              paymentMethod: 'momo',
              passenger: dummyPassenger,
            ),
            throwsA(
              isA<PaymentFailedException>().having(
                (e) => e.failureReason,
                'failureReason',
                equals('Số dư không đủ'),
              ),
            ),
          );
        },
      );

      test(
        'Rethrows NetworkException from payment call without swallowing or emitting ticket',
        () async {
          fakePaymentDs.getStatusError = const NetworkException(
            message: 'Mất kết nối cổng thanh toán',
          );

          expect(
            () => repo.createBooking(
              trip: dummyTrip,
              seats: ['A01'],
              seatIds: [1],
              totalAmount: 250000,
              discountAmount: 0,
              finalAmount: 250000,
              paymentMethod: 'momo',
              passenger: dummyPassenger,
            ),
            throwsA(isA<NetworkException>()),
          );
        },
      );

      test(
        'Rethrows ApiException from payment call without swallowing',
        () async {
          fakePaymentDs.getStatusError = const ApiException(
            ApiError(
              statusCode: 400,
              errorCode: 'PAYMENT_EXPIRED',
              message: 'Hết hạn',
            ),
          );

          expect(
            () => repo.createBooking(
              trip: dummyTrip,
              seats: ['A01'],
              seatIds: [1],
              totalAmount: 250000,
              discountAmount: 0,
              finalAmount: 250000,
              paymentMethod: 'momo',
              passenger: dummyPassenger,
            ),
            throwsA(isA<ApiException>()),
          );
        },
      );

      test('Returns TicketModel ONLY when payment status is SUCCESS', () async {
        fakePaymentDs.nextStatus = const PaymentTransactionModel(
          paymentId: 101,
          bookingId: 888,
          provider: PaymentProvider.momo,
          amount: 250000,
          status: PaymentStatus.success,
        );

        final ticket = await repo.createBooking(
          trip: dummyTrip,
          seats: ['A01'],
          seatIds: [1],
          totalAmount: 250000,
          discountAmount: 0,
          finalAmount: 250000,
          paymentMethod: 'momo',
          passenger: dummyPassenger,
        );

        expect(ticket, isNotNull);
        expect(ticket.ticketCode, equals('VG888TEST'));
        expect(ticket.status, equals(TicketStatus.upcoming));
      });
    },
  );

  group(
    'Lead Review Round 3 - Finding 3: Authoritative Ticket Pricing from Backend',
    () {
      test(
        'Uses authoritative amounts from BookingModel and overrides client input values',
        () async {
          final fakeBookingDs = FakeBookingRemoteDataSource();
          final fakePaymentDs = FakePaymentRemoteDataSource();

          fakeBookingDs.nextBooking = const BookingModel(
            bookingId: 999,
            bookingCode: 'VG999PRICE',
            tripId: 101,
            status: BookingStatus.paid,
            contact: dummyPassenger,
            pickupPoint: 'BX Miền Tây',
            dropoffPoint: 'BX Đà Lạt',
            seats: ['A01'],
            seatIds: [1],
            totalAmount: 270000, // Final after voucher
            originalAmount: 320000, // Base fare
            discountAmount: 50000, // Voucher discount
          );

          final repo = HybridBookingRepository(
            remoteBookingDataSource: fakeBookingDs,
            remotePaymentDataSource: fakePaymentDs,
            mockFallback: MockBookingRepository(),
          );

          // Client passes different/stale amounts:
          final ticket = await repo.createBooking(
            trip: dummyTrip,
            seats: ['A01'],
            seatIds: [1],
            totalAmount: 111111,
            discountAmount: 1111,
            finalAmount: 110000,
            paymentMethod: 'momo',
            passenger: dummyPassenger,
          );

          // Verify authoritative numbers took precedence
          expect(ticket.totalAmount, equals(320000));
          expect(ticket.discountAmount, equals(50000));
          expect(ticket.finalAmount, equals(270000));
        },
      );
    },
  );

  group(
    'Lead Review Round 3 - Finding 4: Remove Fabricated Operational Data',
    () {
      test('Ticket does NOT fabricate license plate or driver phone', () async {
        final fakeBookingDs = FakeBookingRemoteDataSource();
        final fakePaymentDs = FakePaymentRemoteDataSource();

        final repo = HybridBookingRepository(
          remoteBookingDataSource: fakeBookingDs,
          remotePaymentDataSource: fakePaymentDs,
          mockFallback: MockBookingRepository(),
        );

        final ticket = await repo.createBooking(
          trip: dummyTrip,
          seats: ['A01'],
          seatIds: [1],
          totalAmount: 250000,
          discountAmount: 0,
          finalAmount: 250000,
          paymentMethod: 'momo',
          passenger: dummyPassenger,
        );

        // Neither fabricated string should exist
        expect(ticket.licensePlate, isNull);
        expect(ticket.driverPhone, isNull);
        expect(ticket.driverPhone != '0909 888 777', isTrue);
      });
    },
  );
}
