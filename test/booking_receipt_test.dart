import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/datasources/remote/booking_receipt_remote_data_source.dart';
import 'package:vexgo_app/data/models/booking_receipt_model.dart';
import 'package:vexgo_app/data/repositories/booking_receipt_repository.dart';
import 'package:vexgo_app/features/user/receipts/bloc/booking_receipt_cubit.dart';
import 'package:vexgo_app/features/user/receipts/presentation/booking_receipt_screen.dart';

Map<String, dynamic> paidReceipt([int id = 12]) => {
  'bookingId': id,
  'bookingCode': 'QA-PDV-0123456789ABCDEF0123456789ABCD',
  'orderCode': 'QA-ORDER-12',
  'status': 'DA_THANH_TOAN',
  'paymentStatus': 'DA_THANH_TOAN',
  'createdAt': '2026-10-22T01:00:00.000Z',
  'departureTime': '2026-10-23T01:00:00.000Z',
  'busCompanyName': 'Nhà xe kiểm thử',
  'route': 'TP.HCM - Đà Lạt',
  'vehicleType': 'Giường nằm',
  'pickup': 'Bến xe A',
  'dropoff': 'Bến xe B',
  'passenger': {
    'fullName': 'Khách kiểm thử',
    'phoneNumber': '0901234567',
    'email': 'qa@example.test',
  },
  'originalTicketSubtotal': '600000.00',
  'discountAmount': '100000.00',
  'ticketSubtotal': '500000.00',
  'cargoFee': '20000',
  'totalAmount': '520000.00',
  'promotionCode': 'QA100',
  'paymentMethod': 'CHUYEN_KHOAN',
  'cargoItems': [
    {'name': 'Kiện kiểm thử', 'quantity': 1},
  ],
  'tickets': [
    {
      'ticketCode': 'QA-VE-01',
      'seatNumber': 'A01',
      'price': '250000.00',
      'status': 'DA_DAT',
    },
    {
      'ticketCode': 'QA-VE-02',
      'seatNumber': 'A02',
      'price': 250000,
      'status': 'DA_DAT',
    },
  ],
};
http.Response response(dynamic data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
RealBookingReceiptRepository repository(
  Future<http.Response> Function(http.Request) handler,
) => RealBookingReceiptRepository(
  remote: BookingReceiptRemoteDataSource(
    ApiClient(httpClient: MockClient(handler)),
  ),
);
Map<String, dynamic> ticketLink() => {
  'bookingId': 12,
  'bookingCode': paidReceipt()['bookingCode'],
  'ticketCode': 'QA-VE-01',
};

class DeferredReceiptRepository implements BookingReceiptRepository {
  final calls = <Completer<BookingReceipt>>[];
  @override
  Future<BookingReceipt> lookup({required String code, required String phone}) {
    final result = Completer<BookingReceipt>();
    calls.add(result);
    return result.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    ApiConfig.setCustomBaseUrl('http://localhost:4012/api/v1');
  });
  tearDown(() {
    TokenStorage.resetStorageAdapter();
    ApiConfig.resetBaseUrl();
  });

  test(
    'maps decimal strings, multiple tickets and cargo from server without recomputing money',
    () {
      final receipt = BookingReceipt.fromJson(paidReceipt());
      expect(receipt.total, 520000);
      expect(receipt.discount, 100000);
      expect(receipt.tickets.map((t) => t.code), ['QA-VE-01', 'QA-VE-02']);
      expect(receipt.cargo.single.quantity, 1);
    },
  );
  test('allows an authoritative paid zero-total order', () {
    final json = paidReceipt()..['totalAmount'] = 0;
    expect(BookingReceipt.fromJson(json).total, 0);
  });
  for (final status in [
    'CHO_THANH_TOAN',
    'HET_HAN',
    'DA_HUY',
    'UNKNOWN',
    null,
  ]) {
    test('rejects booking status $status even when payment claims paid', () {
      expect(
        () => BookingReceipt.fromJson(paidReceipt()..['status'] = status),
        throwsA(isA<ReceiptUnavailable>()),
      );
    });
  }
  for (final status in [
    'CHO_THANH_TOAN',
    'HET_HAN',
    'DA_HUY',
    'UNKNOWN',
    null,
  ]) {
    test('rejects payment status $status even when booking claims paid', () {
      expect(
        () =>
            BookingReceipt.fromJson(paidReceipt()..['paymentStatus'] = status),
        throwsA(isA<ReceiptUnavailable>()),
      );
    });
  }
  for (final value in [null, 'NaN', 'Infinity', -1, 'bad']) {
    test('does not default invalid total $value to zero', () {
      expect(
        () => BookingReceipt.fromJson(paidReceipt()..['totalAmount'] = value),
        throwsFormatException,
      );
    });
  }
  test(
    'rejects missing codes, missing money, empty and duplicated ticket lists',
    () {
      for (final patch in <String, dynamic>{
        'orderCode': '',
        'bookingCode': '',
        'ticketSubtotal': null,
        'tickets': [],
        'createdAt': 'bad',
      }.entries) {
        expect(
          () =>
              BookingReceipt.fromJson(paidReceipt()..[patch.key] = patch.value),
          throwsFormatException,
        );
      }
      final duplicate = paidReceipt();
      duplicate['tickets'] = [duplicate['tickets'][0], duplicate['tickets'][0]];
      expect(() => BookingReceipt.fromJson(duplicate), throwsFormatException);
    },
  );
  test(
    'guest resolves code+phone, then sends capability headers only to the existing detail endpoint',
    () async {
      final requests = <http.Request>[];
      final repo = repository((request) async {
        requests.add(request);
        return response({
          'data': request.method == 'POST' ? ticketLink() : paidReceipt(),
        });
      });
      await repo.lookup(code: ' QA-VE-01 ', phone: ' 0901234567 ');
      expect(requests[0].url.path, '/api/v1/tickets/lookup');
      expect(jsonDecode(requests[0].body), {
        'ticketCode': 'QA-VE-01',
        'phoneNumber': '0901234567',
      });
      expect(
        requests[1].url.toString(),
        'http://localhost:4012/api/v1/bookings/12/detail',
      );
      expect(
        requests[1].headers['x-booking-code'],
        paidReceipt()['bookingCode'],
      );
      expect(requests[1].headers['x-booking-phone'], '0901234567');
      expect(requests[1].headers['authorization'], isNull);
      expect(requests[1].url.hasQuery, isFalse);
    },
  );
  test(
    'owned receipt includes JWT and refuses a forbidden detail without fallback',
    () async {
      await TokenStorage.saveAccessToken('owner-token');
      var details = 0;
      final repo = repository((request) async {
        if (request.method == 'POST') return response({'data': ticketLink()});
        details++;
        expect(request.headers['authorization'], 'Bearer owner-token');
        return response({
          'statusCode': 403,
          'error': 'FORBIDDEN_BOOKING_ACCESS',
          'message': 'Forbidden',
        }, 403);
      });
      await expectLater(
        repo.lookup(code: 'QA-VE-01', phone: '0901234567'),
        throwsA(anything),
      );
      expect(details, 1);
    },
  );
  for (final code in [
    'QA-VE-01',
    'QA-PDV-0123456789ABCDEF0123456789ABCD',
    'QA-ORDER-12',
  ]) {
    test('accepts backend lookup by $code', () async {
      final repo = repository(
        (request) async => response({
          'data': request.method == 'POST' ? ticketLink() : paidReceipt(),
        }),
      );
      expect(
        (await repo.lookup(code: code, phone: '0901234567')).bookingId,
        12,
      );
    });
  }
  test('rejects mismatched booking identity and ticket membership', () async {
    for (final raw in [
      paidReceipt(99),
      paidReceipt()..['bookingCode'] = 'OTHER',
      paidReceipt()
        ..['tickets'] = [
          {'ticketCode': 'OTHER', 'price': 1},
        ],
    ]) {
      final repo = repository(
        (request) async =>
            response({'data': request.method == 'POST' ? ticketLink() : raw}),
      );
      await expectLater(
        repo.lookup(code: 'QA-VE-01', phone: '0901234567'),
        throwsFormatException,
      );
    }
  });
  test(
    'session change after lookup prevents requesting another session receipt',
    () async {
      var details = 0;
      final repo = repository((request) async {
        if (request.method == 'POST') {
          await TokenStorage.saveAccessToken('different-account');
          return response({'data': ticketLink()});
        }
        details++;
        return response({'data': paidReceipt()});
      });
      await expectLater(
        repo.lookup(code: 'QA-VE-01', phone: '0901234567'),
        throwsA(isA<ReceiptUnavailable>()),
      );
      expect(details, 0);
    },
  );
  test(
    'new lookup wins over late old lookup; refresh hides old evidence and failure keeps it hidden',
    () async {
      final repo = DeferredReceiptRepository();
      final cubit = BookingReceiptCubit(repo);
      final old = cubit.lookup('old', '0901234567');
      final fresh = cubit.lookup('new', '0901234567');
      repo.calls[1].complete(BookingReceipt.fromJson(paidReceipt(13)));
      await fresh;
      repo.calls[0].complete(BookingReceipt.fromJson(paidReceipt()));
      await old;
      expect(cubit.state.receipt!.bookingId, 13);
      final retry = cubit.refresh();
      expect(cubit.state.status, ReceiptStatus.loading);
      expect(cubit.state.receipt, isNull);
      repo.calls[2].completeError(Exception('network'));
      await retry;
      expect(cubit.state.status, ReceiptStatus.failure);
      expect(cubit.state.receipt, isNull);
      await cubit.close();
    },
  );
  test(
    'logout clears loaded state and ignores a pending late response',
    () async {
      final repo = DeferredReceiptRepository();
      final cubit = BookingReceiptCubit(repo);
      final first = cubit.lookup('first', '0901234567');
      repo.calls[0].complete(BookingReceipt.fromJson(paidReceipt()));
      await first;
      final refresh = cubit.refresh();
      await TokenStorage.clearTokens();
      expect(cubit.state.status, ReceiptStatus.invalidated);
      expect(cubit.state.receipt, isNull);
      repo.calls[1].complete(BookingReceipt.fromJson(paidReceipt()));
      await refresh;
      expect(cubit.state.status, ReceiptStatus.invalidated);
      await cubit.close();
    },
  );
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'receipt layout fits $width, shows all tickets and clears private data on logout',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = DeferredReceiptRepository();
        await tester.pumpWidget(
          RepositoryProvider<BookingReceiptRepository>.value(
            value: repo,
            child: MaterialApp(
              home: BookingReceiptScreen(
                initialRequest: ReceiptLookupRequest(
                  'QA-VE-01',
                  '0901234567',
                  TokenStorage.sessionVersion,
                ),
              ),
            ),
          ),
        );
        repo.calls.single.complete(BookingReceipt.fromJson(paidReceipt()));
        await tester.pumpAndSettle();
        expect(find.text('Đã thanh toán'), findsOneWidget);
        expect(find.textContaining('QA-VE-01\n'), findsOneWidget);
        expect(find.textContaining('QA-VE-02\n'), findsOneWidget);
        expect(find.textContaining('không phải hóa đơn GTGT'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.runAsync(TokenStorage.clearTokens);
        await tester.pumpAndSettle();
        expect(find.text('Đã thanh toán'), findsNothing);
        expect(find.text('Khách kiểm thử'), findsNothing);
        expect(
          tester
              .widget<TextFormField>(find.byKey(const Key('receipt-phone')))
              .controller!
              .text,
          isEmpty,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'expired navigation request never preloads old credentials or fetches',
    (tester) async {
      final request = ReceiptLookupRequest(
        'PRIVATE-CODE',
        '0901234567',
        TokenStorage.sessionVersion,
      );
      await tester.runAsync(TokenStorage.clearTokens);
      final repo = DeferredReceiptRepository();
      await tester.pumpWidget(
        RepositoryProvider<BookingReceiptRepository>.value(
          value: repo,
          child: MaterialApp(
            home: BookingReceiptScreen(initialRequest: request),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('receipt-code')))
            .controller!
            .text,
        isEmpty,
      );
    },
  );
}
