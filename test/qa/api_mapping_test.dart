// Component integration: real Repository -> DataSource -> ApiClient -> DTO,
// using an in-process HTTP transport fixture. This is NOT backend/device E2E.
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/datasources/remote/booking_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/payment_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/ticket_remote_data_source.dart';
import 'package:vexgo_app/data/models/payment_transaction_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'qa_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockClient transport;
  late RealBookingRepository repository;
  late List<http.Request> requests;
  late String paymentStatus;
  late int ticketStatusCode;
  late int bookingStatusCode;
  late int statusCode;
  late int responseBookingId;
  late String bookingStatus;

  setUp(() async {
    ApiConfig.isDemoMode = false;
    ApiConfig.setCustomBaseUrl('https://qa-fixture.invalid/api/v1');
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(accessToken: 'qa-fixture-token');
    requests = [];
    paymentStatus = 'SUCCESS';
    ticketStatusCode = 200;
    bookingStatusCode = 201;
    statusCode = 200;
    responseBookingId = 888;
    bookingStatus = 'DA_THANH_TOAN';
    transport = MockClient((request) async {
      requests.add(request);
      http.Response response(Object data, [int code = 200]) => http.Response(
        jsonEncode(data),
        code,
        headers: {'content-type': 'application/json'},
      );
      final path = request.url.path;
      if (path == '/api/v1/bookings' && request.method == 'POST') {
        return response({
          'data': qaBookingJson(status: 'CHO_THANH_TOAN'),
        }, bookingStatusCode);
      }
      if (path == '/api/v1/bookings/888') {
        return response({'data': qaBookingJson(status: bookingStatus)});
      }
      if (path == '/api/v1/payments' || path == '/api/v1/payments/71/status') {
        return response({
          'data': {
            'paymentId': 71,
            'bookingId': responseBookingId,
            'provider': 'MOMO',
            'amount': 250000,
            'status': path.endsWith('/status') ? paymentStatus : 'PENDING',
            'paymentUrl': 'https://sandbox.example.invalid/pay/71',
          },
        }, path.endsWith('/status') ? statusCode : 201);
      }
      if (path == '/api/v1/tickets/91') {
        return response({'data': qaTicketJson()}, ticketStatusCode);
      }
      if (path == '/api/v1/tickets') {
        return response({
          'data': [],
          'meta': {'totalItems': 0},
        });
      }
      return response({'error': 'UNEXPECTED_QA_REQUEST', 'message': path}, 500);
    });
    final api = ApiClient(httpClient: transport);
    repository = RealBookingRepository(
      remoteBookingDataSource: BookingRemoteDataSourceImpl(client: api),
      remotePaymentDataSource: PaymentRemoteDataSourceImpl(client: api),
      remoteTicketDataSource: TicketRemoteDataSourceImpl(client: api),
    );
  });

  tearDown(() async {
    transport.close();
    await TokenStorage.clearTokens();
    TokenStorage.resetStorageAdapter();
    ApiConfig.resetBaseUrl();
    ApiConfig.isDemoMode = false;
  });

  Future<TicketModel> checkout({
    List<int> seats = const [1],
    String method = 'momo',
  }) => repository.createBooking(
    trip: qaSummary,
    seats: const ['A01'],
    seatIds: seats,
    totalAmount: 1,
    discountAmount: 0,
    finalAmount: 1,
    paymentMethod: method,
    passenger: qaPassenger,
    holdToken: 'qa-hold',
  );

  test(
    'QA-API-01 SUCCESS fetches full authoritative ticket, never booking code as ticket',
    () async {
      final ticket = await checkout();
      expect(ticket.id, '91');
      expect(ticket.ticketCode, 'TICKET-AUTH-91');
      expect(ticket.finalAmount, 250000);
      expect(ticket.trip.departureTime, '23:00');
      expect(ticket.trip.arrivalDate, '21/10/2030');
      expect(requests.any((r) => r.url.path.endsWith('/tickets/91')), isTrue);
      final create = requests.firstWhere(
        (r) => r.url.path.endsWith('/bookings'),
      );
      expect(jsonDecode(create.body), containsPair('holdToken', 'qa-hold'));
      expect(jsonDecode(create.body), containsPair('seatIds', [1]));
      expect(create.headers['Authorization'], 'Bearer qa-fixture-token');
    },
  );

  test(
    'QA-API-02 PENDING stays pending and returns recovery identifiers',
    () async {
      paymentStatus = 'PENDING';
      await expectLater(
        checkout(),
        throwsA(
          isA<PaymentPendingException>()
              .having((e) => e.paymentId, 'paymentId', 71)
              .having((e) => e.bookingId, 'bookingId', 888),
        ),
      );
      expect(requests.where((r) => r.url.path.contains('/tickets/')), isEmpty);
    },
  );

  for (final terminal in ['FAILED', 'CANCELLED']) {
    test('QA-API-03 $terminal cannot issue a successful ticket', () async {
      paymentStatus = terminal;
      await expectLater(checkout(), throwsA(isA<PaymentFailedException>()));
      expect(requests.where((r) => r.url.path.contains('/tickets/')), isEmpty);
    });
  }

  test('QA-API-04 SUCCESS with ticket API 503 must fail closed', () async {
    ticketStatusCode = 503;
    await expectLater(checkout(), throwsA(isA<Exception>()));
  });

  test(
    'QA-API-05 SUCCESS for another booking cannot issue this booking ticket',
    () async {
      responseBookingId = 999;
      await expectLater(checkout(), throwsA(isA<Exception>()));
    },
  );

  test(
    'QA-API-06 SUCCESS while authoritative booking is unpaid cannot issue ticket',
    () async {
      bookingStatus = 'CHO_THANH_TOAN';
      await expectLater(checkout(), throwsA(isA<Exception>()));
    },
  );

  test(
    'QA-API-07 status 503 does not turn backend error into mock success',
    () async {
      statusCode = 503;
      await expectLater(checkout(), throwsA(isA<Exception>()));
      expect(
        requests.where(
          (r) => r.method == 'POST' && r.url.path.endsWith('/bookings'),
        ),
        hasLength(1),
      );
      expect(requests.where((r) => r.url.path.contains('/tickets/')), isEmpty);
    },
  );

  test('QA-API-08 booking 409 stops before any payment create', () async {
    bookingStatusCode = 409;
    await expectLater(checkout(), throwsA(isA<Exception>()));
    expect(requests.where((r) => r.url.path.contains('/payments')), isEmpty);
  });

  for (final seats in [
    <int>[],
    [0],
    [-1],
    [1, 2],
  ]) {
    test('QA-API-09 rejects invalid seat IDs $seats before network', () async {
      await expectLater(checkout(seats: seats), throwsArgumentError);
      expect(requests, isEmpty);
    });
  }

  test(
    'QA-API-10 unknown provider must be rejected before booking side effect',
    () async {
      await expectLater(checkout(method: 'momo-typo'), throwsArgumentError);
      expect(requests, isEmpty);
    },
  );

  test(
    'QA-API-11 guest booking is accepted; unsupported guest wallet retains recovery identity',
    () async {
      await TokenStorage.clearTokens();
      await expectLater(
        checkout(),
        throwsA(
          isA<CheckoutProgressException>()
              .having((e) => e.bookingId, 'bookingId', 888)
              .having((e) => e.cause, 'cause', isA<UnauthorizedException>()),
        ),
      );
      expect(
        requests.where(
          (r) => r.method == 'POST' && r.url.path.endsWith('/bookings'),
        ),
        hasLength(1),
      );
      expect(
        requests.where(
          (r) => r.method == 'POST' && r.url.path.endsWith('/payments'),
        ),
        isEmpty,
      );
    },
  );

  test(
    'QA-API-12 empty server ticket list remains empty in real mode',
    () async {
      expect(await repository.getMyTickets(), isEmpty);
    },
  );

  for (final raw in ['PENDING', 'pending', 'PROCESSING', 'UNRECOGNIZED']) {
    test('QA-PAY-01 $raw is not classified as failed or successful', () {
      final payment = PaymentTransactionModel.fromJson({
        'paymentId': 71,
        'bookingId': 888,
        'status': raw,
      });
      expect(payment.isPending, isTrue);
      expect(payment.isFailed, isFalse);
      expect(payment.isSuccess, isFalse);
    });
  }
}
