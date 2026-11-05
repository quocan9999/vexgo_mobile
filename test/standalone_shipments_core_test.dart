import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/network/vietqr_config.dart';
import 'package:vexgo_app/data/repositories/shipment_repository.dart';
import 'package:vexgo_app/features/user/shipments/shipment_flow_cubit.dart';

const bank = VietQrReceivingAccount(
  bankId: 'MB',
  accountNumber: '0000000001',
  accountName: 'SANDBOX',
);
final time = DateTime.utc(2026, 11, 10, 1);
ShipmentDraft draft({
  int route = 1,
  int sender = 10,
  ShipmentPaymentMethod method = ShipmentPaymentMethod.counter,
  ShipmentPayer payer = ShipmentPayer.sender,
  List<ShipmentItem>? items,
}) => ShipmentDraft(
  routeId: route,
  sendDate: '11-11-2026',
  senderPointId: sender,
  receiverPointId: 11,
  senderName: 'Fixture Sender',
  senderPhone: '0901234567',
  receiverName: 'Fixture Receiver',
  receiverPhone: '0907654321',
  payer: payer,
  paymentMethod: method,
  items:
      items ?? [const ShipmentItem(name: 'Parcel', categoryId: 3, weight: 5)],
);
Map<String, dynamic> receipt({
  ShipmentPaymentMethod method = ShipmentPaymentMethod.counter,
  ShipmentPayer payer = ShipmentPayer.sender,
  int trip = 1,
}) => {
  'expectedSendDate': '11-11-2026',
  'dropoffDeadline': time.add(const Duration(hours: 72)).toIso8601String(),
  'shipmentId': 50,
  'orderId': 60,
  'paymentId': 70,
  'waybillCode': 'WAY-50',
  'orderCode': 'HMGD-60',
  'trip': {
    'tripId': null,
    'code': null,
    'departureTime': null,
    'route': {'origin': 'A', 'destination': 'B'},
    'busCompany': {'name': 'Fixture carrier'},
  },
  'pickupPoint': {'id': 10, 'name': 'Sender office', 'address': 'Address A'},
  'dropoffPoint': {'id': 11, 'name': 'Receiver office', 'address': 'Address B'},
  'pricing': <String, dynamic>{
    'baseFee': 50000,
    'serviceFee': 0,
    'discount': 0,
    'totalFee': 50000,
  },
  'sender': {'fullName': 'Fixture Sender', 'phoneNumber': '+84901234567'},
  'receiver': {'fullName': 'Fixture Receiver', 'phoneNumber': '+84907654321'},
  'sentAt': time.toIso8601String(),
  'items': [
    {
      'id': 1,
      'name': 'Parcel',
      'quantity': 1,
      'weight': 5,
      'category': 'Parcel',
      'dimensions': null,
      'note': null,
    },
  ],
  'status': 'MOI_TAO',
  'paymentStatus': 'CHO_THANH_TOAN',
  'paymentMethod': method.code,
  'freightPayer': payer.code,
  'paymentExpiresAt': time.add(const Duration(minutes: 10)).toIso8601String(),
};
Map<String, dynamic> lookupJson({String method = 'SEPAY'}) => {
  'waybillCode': 'WAY-50',
  'orderCode': 'HMGD-60',
  'status': 'MOI_TAO',
  'orderStatus': 'CHO_THANH_TOAN',
  'paymentStatus': 'DANG_XU_LY',
  'paymentMethod': method,
  'amount': 50000,
  'packageCount': 1,
  'requiresReconciliation': false,
  'serverTime': time.toIso8601String(),
  'paymentExpiresAt': time.add(const Duration(minutes: 10)).toIso8601String(),
  'pickupPoint': {'name': 'Sender office', 'address': 'Address A'},
  'dropoffPoint': {'name': 'Receiver office', 'address': 'Address B'},
  'carrier': {'name': 'Fixture carrier'},
  'route': {'origin': 'A', 'destination': 'B'},
  'timeline': [
    {'status': 'MOI_TAO', 'time': time.toIso8601String()},
  ],
};
http.Response response(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json'},
);

class Server {
  final requests = <http.Request>[];
  final optionGates = <int, Completer<void>>{};
  Completer<void>? quoteGate, createGate;
  int posts = 0;
  bool failCreate = false, corrupt = false;
  int? reject;
  bool failQuote = false;
  int quoteCategory = 3;
  Map<String, dynamic> result = receipt();
  late final client = ApiClient(httpClient: MockClient(handle));
  late final repository = RealShipmentRepository(client: client);
  Future<http.Response> handle(http.Request r) async {
    requests.add(r);
    final path = r.url.path.replaceFirst('/api/v1', '');
    if (path == '/shipments/options') {
      return response({
        'data': [
          for (final id in [1, 2])
            {
              'routeId': id,
              'busCompany': {'id': 1, 'name': 'Fixture carrier'},
              'route': {'origin': 'A', 'destination': 'B'},
              'minimumEstimatedFee': 50000,
            },
        ],
        'meta': {'totalPages': 1},
      });
    }
    if (path == '/shipments/categories') {
      return response({
        'data': [
          {'categoryId': 3, 'name': 'Parcel', 'capacityGroup': 'HANG_NHE'},
        ],
      });
    }
    if (path.endsWith('/route-points')) {
      await optionGates[int.parse(path.split('/')[3])]?.future;
      return response({
        'data': {
          'senderPoints': [
            {'id': 10, 'name': 'Sender office', 'address': 'Address A'},
          ],
          'receiverPoints': [
            {'id': 11, 'name': 'Receiver office', 'address': 'Address B'},
          ],
          'rates': [],
        },
      });
    }
    if (path == '/shipments/quotes') {
      await quoteGate?.future;
      if (failQuote) {
        return response({
          'message': 'Quote unavailable',
          'statusCode': 409,
          'error': 'CARGO_RATE_NOT_FOUND',
        }, 409);
      }
      return response({
        'data': {
          'baseFee': 50000,
          'serviceFee': 0,
          'totalFee': 50000,
          'rates': [
            {
              'categoryId': quoteCategory,
              'rateId': 7,
              'billableWeight': 5,
              'fee': 50000,
            },
          ],
        },
      });
    }
    if (path == '/shipments' && r.method == 'POST') {
      posts++;
      await createGate?.future;
      if (failCreate) throw const SocketException('fixture timeout');
      if (reject != null) {
        return response({
          'message': 'Fixture rejected',
          'error': 'REJECTED',
          'statusCode': reject,
        }, reject!);
      }
      final value = jsonDecode(jsonEncode(result)) as Map<String, dynamic>;
      if (corrupt) (value['pricing'] as Map)['totalFee'] = 1;
      return response({'data': value}, 201);
    }
    if (path == '/shipments/lookup') {
      return response({'data': lookupJson(method: 'TAI_BEN')});
    }
    if (path == '/shipments/50') return response({'data': result});
    if (path == '/shipments') {
      return response({
        'data': [],
        'meta': {'page': 1, 'pageSize': 10, 'totalItems': 0, 'totalPages': 0},
      });
    }
    throw StateError('Unexpected endpoint $path');
  }
}

Future<void> prepare(ShipmentFlowCubit c, [ShipmentDraft? d]) async {
  await c.searchRoutes(from: 'A', to: 'B', date: '11-11-2026');
  await c.selectRoute(1);
  c.updateDraft(d ?? draft());
  await c.refreshQuote();
}

class DelayedCredentialStorage extends InMemorySecureStorageAdapter {
  final gate = Completer<String?>();
  bool delay = false;
  @override
  Future<String?> read(String key) => delay ? gate.future : super.read(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    ApiConfig.resetBaseUrl();
  });
  tearDown(TokenStorage.resetStorageAdapter);
  test(
    'route payload uses DD-MM-YYYY, no trip/booking/admin fields and counter only',
    () {
      final j = draft().toJson();
      expect(j['routeId'], 1);
      expect(j['sendDate'], '11-11-2026');
      expect(j.containsKey('tripId'), false);
      expect(j['paymentMethod'], 'TAI_BEN');
      expect(
        draft(method: ShipmentPaymentMethod.online).errors,
        contains('paymentMethod'),
      );
      expect(draft(payer: ShipmentPayer.receiver).errors, isEmpty);
    },
  );
  test(
    'calendar validates real dates and party/item validation is retained',
    () {
      expect(validShipmentSendDate('29-02-2024'), true);
      for (final d in ['29-02-2026', '31-04-2026', '2026-11-11']) {
        expect(validShipmentSendDate(d), false);
      }
      expect(draft(sender: 0).errors, contains('senderPointId'));
      expect(draft(items: []).errors, contains('items'));
      expect(
        draft(
          items: [
            const ShipmentItem(name: '', categoryId: 3, weight: double.nan),
          ],
        ).errors,
        isNotEmpty,
      );
      expect(
        draft(
          items: [
            const ShipmentItem(name: 'Large parcel', categoryId: 3, weight: 70),
          ],
        ).errors,
        isEmpty,
      );
      expect(
        const ShipmentItem(
          name: 'Parcel',
          categoryId: 3,
          weight: 1,
          length: 1,
        ).errors,
        contains('dimensions'),
      );
    },
  );
  test(
    'unassigned trip parses without inventing an ID/date; server pricing and handover preserved',
    () {
      final j = receipt();
      j['pricing'] = <String, dynamic>{
        ...Map<String, dynamic>.from(j['pricing'] as Map),
        'estimatedFee': 50000,
        'paidAmount': 0,
        'outstandingAmount': 50000,
        'confirmedAt': null,
      };
      final r = ShipmentRecord.fromJson(j);
      expect(r.tripId, isNull);
      expect(r.trip.departure, isNull);
      expect(r.estimatedFee, 50000);
      expect(r.outstandingAmount, 50000);
      expect(r.dropoffDeadline, time.add(const Duration(hours: 72)));
    },
  );
  test('malformed money and unknown state fail closed', () {
    final j = receipt();
    (j['pricing'] as Map)['totalFee'] = 999;
    expect(() => ShipmentRecord.fromJson(j), throwsFormatException);
    expect(ShipmentStatus.parse('FUTURE'), ShipmentStatus.unknown);
    final lookup = lookupJson()
      ..['requiresReconciliation'] = true
      ..['orderStatus'] = 'DA_THANH_TOAN'
      ..['paymentStatus'] = 'THANH_CONG';
    expect(ShipmentLookup.fromJson(lookup).paid, false);
  });
  test('options uses route API, never trip search or cargo capacity', () async {
    final s = Server();
    final c = ShipmentFlowCubit(repository: s.repository);
    addTearDown(c.close);
    await prepare(c);
    expect(c.state.routes.length, 2);
    expect(c.state.options!.routeId, 1);
    expect(s.requests.any((r) => r.url.path.contains('/trips/')), false);
    expect(s.requests.first.url.queryParameters['sendDate'], '11-11-2026');
    final q =
        jsonDecode(
              s.requests.firstWhere((r) => r.url.path.endsWith('/quotes')).body,
            )
            as Map;
    expect(q.keys.toSet(), {
      'routeId',
      'sendDate',
      'senderPointId',
      'receiverPointId',
      'items',
    });
    expect(q.containsKey('sender'), false);
  });
  test(
    'create sends stable idempotency header and accepts unassigned response',
    () async {
      final s = Server();
      final c = ShipmentFlowCubit(repository: s.repository);
      addTearDown(c.close);
      await prepare(c);
      await c.create();
      expect(c.state.phase, ShipmentCreationPhase.created);
      final r = s.requests.singleWhere(
        (r) => r.method == 'POST' && r.url.path.endsWith('/shipments'),
      );
      expect(
        r.headers['Idempotency-Key'] ?? r.headers['idempotency-key'],
        matches(RegExp(r'^[a-f0-9]{48}$')),
      );
      expect(jsonDecode(r.body)['tripId'], isNull);
      expect(c.paymentQrUrl, isNull);
    },
  );
  test('no current quote and invalid point prevent POST', () async {
    final s = Server();
    final c = ShipmentFlowCubit(repository: s.repository);
    addTearDown(c.close);
    await prepare(c);
    c.updateDraft(draft(sender: 999));
    await c.create();
    expect(c.state.fieldErrors, contains('senderPointId'));
    expect(s.posts, 0);
    c.updateDraft(draft());
    await c.create();
    expect(c.state.fieldErrors, contains('quote'));
  });
  test(
    'editing draft invalidates a late quote and cannot submit stale money',
    () async {
      final s = Server();
      final c = ShipmentFlowCubit(repository: s.repository);
      addTearDown(c.close);
      await prepare(c);
      s.quoteGate = Completer<void>();
      final pending = c.refreshQuote();
      await Future<void>.delayed(Duration.zero);
      c.updateDraft(
        draft(
          items: [const ShipmentItem(name: 'Other', categoryId: 3, weight: 8)],
        ),
      );
      s.quoteGate!.complete();
      await pending;
      expect(c.state.quote, isNull);
      await c.create();
      expect(s.posts, 0);
    },
  );
  test('expired quote cannot submit', () async {
    var clock = time;
    final s = Server();
    final c = ShipmentFlowCubit(repository: s.repository, now: () => clock);
    addTearDown(c.close);
    await prepare(c);
    clock = clock.add(const Duration(minutes: 3));
    await c.create();
    expect(s.posts, 0);
  });
  test('late route options cannot replace current selection', () async {
    final s = Server();
    final c = ShipmentFlowCubit(repository: s.repository);
    addTearDown(c.close);
    await c.searchRoutes(from: 'A', to: 'B', date: '11-11-2026');
    s.optionGates[1] = Completer<void>();
    final old = c.selectRoute(1);
    await Future<void>.delayed(Duration.zero);
    await c.selectRoute(2);
    s.optionGates[1]!.complete();
    await old;
    expect(c.state.options!.routeId, 2);
  });
  test(
    'single flight and account switch discard late created record',
    () async {
      final s = Server();
      final c = ShipmentFlowCubit(repository: s.repository);
      addTearDown(c.close);
      await prepare(c);
      s.createGate = Completer<void>();
      final pending = c.create();
      await Future<void>.delayed(Duration.zero);
      await c.create();
      expect(s.posts, 1);
      await TokenStorage.saveTokens(accessToken: 'other');
      s.createGate!.complete();
      await pending;
      expect(c.state.phase, ShipmentCreationPhase.invalidated);
      expect(c.state.record, isNull);
    },
  );
  test(
    'timeout blocks ordinary repost; explicit retry uses exactly the same key/body',
    () async {
      final s = Server();
      final c = ShipmentFlowCubit(repository: s.repository);
      addTearDown(c.close);
      await prepare(c);
      s.failCreate = true;
      await c.create();
      expect(c.state.phase, ShipmentCreationPhase.uncertain);
      await c.create();
      expect(s.posts, 1);
      s.failCreate = false;
      await c.retryUncertainCreation();
      expect(s.posts, 2);
      final posts = s.requests
          .where((r) => r.method == 'POST' && r.url.path.endsWith('/shipments'))
          .toList();
      expect(
        posts[0].headers['Idempotency-Key'],
        posts[1].headers['Idempotency-Key'],
      );
      expect(posts[0].body, posts[1].body);
      expect(c.state.phase, ShipmentCreationPhase.created);
    },
  );
  test(
    'uncertain retry cannot swap payload and malformed success retains identity',
    () async {
      final s = Server();
      await s.repository.searchRoutes(from: 'A', to: 'B', date: '11-11-2026');
      await s.repository.loadOptions(1);
      s.corrupt = true;
      await expectLater(
        s.repository.create(draft()),
        throwsA(isA<ShipmentCreationUncertain>()),
      );
      await expectLater(
        s.repository.create(draft(sender: 99), retryUncertain: true),
        throwsA(isA<ShipmentCreationUncertain>()),
      );
      expect(s.posts, 1);
    },
  );
  test('definite rejection returns editing; 409 remains uncertain', () async {
    for (final status in [400, 409]) {
      final s = Server()..reject = status;
      final c = ShipmentFlowCubit(repository: s.repository);
      await prepare(c);
      await c.create();
      expect(
        c.state.phase,
        status == 400
            ? ShipmentCreationPhase.editing
            : ShipmentCreationPhase.uncertain,
      );
      await c.close();
    }
  });
  test(
    'mismatched response weight/party/route cannot become a created record',
    () async {
      for (final kind in ['weight', 'party', 'route']) {
        final s = Server();
        if (kind == 'weight') {
          (s.result['items'] as List).first['weight'] = 99;
        }
        if (kind == 'party') {
          (s.result['receiver'] as Map)['phoneNumber'] = '0909999999';
        }
        if (kind == 'route') {
          ((s.result['trip'] as Map)['route'] as Map)['origin'] = 'Elsewhere';
        }
        final c = ShipmentFlowCubit(repository: s.repository);
        await prepare(c);
        await c.create();
        expect(c.state.phase, ShipmentCreationPhase.uncertain);
        await c.close();
      }
    },
  );
  test(
    'session switch while secure headers await prevents dispatch under new account',
    () async {
      final storage = DelayedCredentialStorage();
      TokenStorage.setStorageAdapterForTesting(storage);
      final s = Server();
      await s.repository.searchRoutes(from: 'A', to: 'B', date: '11-11-2026');
      await s.repository.loadOptions(1);
      storage.delay = true;
      final pending = s.repository.create(draft());
      await Future<void>.delayed(Duration.zero);
      storage.delay = false;
      await TokenStorage.saveTokens(accessToken: 'new-account');
      final check = expectLater(pending, throwsA(isA<UnauthorizedException>()));
      storage.gate.complete(null);
      await check;
      expect(s.posts, 0);
    },
  );
  test(
    'private detail requires auth; logged in detail supports unassigned order',
    () async {
      final s = Server();
      await expectLater(
        s.repository.detail(50),
        throwsA(isA<UnauthorizedException>()),
      );
      await TokenStorage.saveTokens(accessToken: 'owner');
      final r = await s.repository.detail(50);
      expect(r.tripId, isNull);
      expect(s.requests.last.headers['Authorization'], 'Bearer owner');
    },
  );
  test(
    'lookup phone stays in body and counter never offers payment QR',
    () async {
      final s = Server();
      final c = ShipmentFlowCubit(repository: s.repository);
      addTearDown(c.close);
      await prepare(c);
      await c.create();
      await c.refreshPayment();
      final r = s.requests.last;
      expect(r.url.queryParameters, isEmpty);
      expect(jsonDecode(r.body)['phoneNumber'], '+84901234567');
      expect(c.paymentQrUrl, isNull);
      await TokenStorage.clearTokens();
      expect(c.state.record, isNull);
      expect(c.verifiedPayment, isNull);
    },
  );
  test('route discovery follows all option pages', () async {
    final pages = <String?>[];
    final repo = RealShipmentRepository(
      client: ApiClient(
        httpClient: MockClient((r) async {
          final page = r.url.queryParameters['page'];
          pages.add(page);
          return response({
            'data': [
              {
                'routeId': int.parse(page!),
                'busCompany': {'id': 1, 'name': 'Carrier'},
                'route': {'origin': 'A', 'destination': 'B'},
                'minimumEstimatedFee': null,
              },
            ],
            'meta': {'totalPages': 2},
          });
        }),
      ),
    );
    expect(
      (await repo.searchRoutes(from: 'A', to: 'B', date: '11-11-2026')).length,
      2,
    );
    expect(pages, ['1', '2']);
  });
  test('failed quote clears the previous amount and blocks create', () async {
    final s = Server();
    final c = ShipmentFlowCubit(repository: s.repository);
    addTearDown(c.close);
    await prepare(c);
    expect(c.state.quote, isNotNull);
    s.failQuote = true;
    await c.refreshQuote();
    expect(c.state.quote, isNull);
    expect(c.state.quoteError, isNotNull);
    await c.create();
    expect(s.posts, 0);
  });
  test('quote for unrelated category is rejected before create', () async {
    final s = Server()..quoteCategory = 999;
    final c = ShipmentFlowCubit(repository: s.repository);
    addTearDown(c.close);
    await prepare(c);
    expect(c.state.quote, isNull);
    await c.create();
    expect(s.posts, 0);
  });
  test(
    'new payload after definite rejection gets a new idempotency key',
    () async {
      final s = Server()..reject = 400;
      await s.repository.searchRoutes(from: 'A', to: 'B', date: '11-11-2026');
      await s.repository.loadOptions(1);
      await expectLater(
        s.repository.create(draft()),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        s.repository.create(draft(sender: 12)),
        throwsA(isA<ApiException>()),
      );
      final calls = s.requests
          .where((r) => r.method == 'POST' && r.url.path.endsWith('/shipments'))
          .toList();
      expect(
        calls[0].headers['Idempotency-Key'],
        isNot(calls[1].headers['Idempotency-Key']),
      );
    },
  );
  test(
    'changing search input invalidates an in-flight route selection',
    () async {
      final s = Server();
      final c = ShipmentFlowCubit(repository: s.repository);
      addTearDown(c.close);
      await c.searchRoutes(from: 'A', to: 'B', date: '11-11-2026');
      s.optionGates[1] = Completer<void>();
      final pending = c.selectRoute(1);
      await Future<void>.delayed(Duration.zero);
      c.clearRouteSelection();
      s.optionGates[1]!.complete();
      await pending;
      expect(c.state.options, isNull);
      expect(c.state.selectedRouteId, isNull);
      expect(c.state.routes, isEmpty);
    },
  );
  test('account change discards an in-flight quote', () async {
    final s = Server();
    final c = ShipmentFlowCubit(repository: s.repository);
    addTearDown(c.close);
    await prepare(c);
    s.quoteGate = Completer<void>();
    final pending = c.refreshQuote();
    await Future<void>.delayed(Duration.zero);
    await TokenStorage.saveTokens(accessToken: 'different');
    s.quoteGate!.complete();
    await pending;
    expect(c.state.phase, ShipmentCreationPhase.invalidated);
    expect(c.state.quote, isNull);
    expect(c.state.draft, isNull);
  });
}
