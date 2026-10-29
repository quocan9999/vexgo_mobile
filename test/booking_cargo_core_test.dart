import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/network/vietqr_config.dart';
import 'package:vexgo_app/data/models/booking_cargo_model.dart';
import 'package:vexgo_app/data/models/booking_model.dart';
import 'package:vexgo_app/data/repositories/cargo_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/payment_display_state.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_checkout_cubit.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';
import 'round_trip_core_test.dart' as core;

const bank = VietQrReceivingAccount(
  bankId: 'MB',
  accountNumber: '0000000001',
  accountName: 'SANDBOX',
);
CargoItemDraft parcel({
  double weight = 5,
  int quantity = 1,
  int category = 3,
  CargoKind kind = CargoKind.parcel,
  double? length,
  double? width,
  double? height,
}) => CargoItemDraft(
  name: 'Fixture parcel',
  kind: kind,
  categoryId: category,
  weight: weight,
  quantity: quantity,
  length: length,
  width: width,
  height: height,
);
BookingCargoDraft draft(
  int tripId, {
  List<CargoItemDraft>? items,
  int? sender,
  int? receiver,
}) => BookingCargoDraft(
  items: items ?? [parcel()],
  senderPointId: sender ?? tripId * 10,
  receiverPointId: receiver ?? tripId * 10 + 1,
);

class CargoServer extends core.Server {
  final calls = <String>[];
  final optionGates = <int, Completer<void>>{};
  final optionStarted = <int, Completer<void>>{};
  bool accepts = true;
  bool wrongPointsTrip = false;
  bool malformedCategories = false;
  bool omitCreateShipment = false;
  bool omitReadFee = false;
  bool corruptReadItems = false;
  int remaining = 4;
  int fee(int trip) => trip == 101 ? 50000 : 80000;
  late final cargo = RealCargoRepository(client: client);
  void attachCargo(Map<String, dynamic> body) {
    if (body['cargoItems'] == null) return;
    final id = body['tripId'] as int;
    final order = orders[id + 900];
    if (order == null) return;
    final ticketSubtotal = order['totalAmount'] as int;
    final original = price(id) * (body['seatIds'] as List).length;
    order.addAll({
      'ticketSubtotal': ticketSubtotal,
      'originalTicketSubtotal': original,
      'discountAmount': original - ticketSubtotal,
      'shippingFee': fee(id),
      'totalAmount': ticketSubtotal + fee(id),
      'shipment': {
        'shipmentId': id + 2000,
        'shipmentCode': 'WAYBILL-$id',
        'shippingFee': fee(id),
        'itemCount': (body['cargoItems'] as List).length,
      },
      'cargoItems': body['cargoItems'],
    });
  }

  @override
  Future<http.Response> handle(http.Request req) async {
    final path = req.url.path.replaceFirst('/api/v1', '');
    calls.add('${req.method} $path');
    if (path == '/shipments/categories') {
      return response(
        malformedCategories
            ? [
                {'categoryId': 3},
              ]
            : [
                {
                  'categoryId': 1,
                  'name': 'Motorcycle',
                  'capacityGroup': 'XE_MAY',
                },
                {
                  'categoryId': 2,
                  'name': 'Bulky',
                  'capacityGroup': 'HANG_CONG_KENH',
                },
                {
                  'categoryId': 3,
                  'name': 'Parcel',
                  'capacityGroup': 'HANG_NHE',
                },
              ],
      );
    }
    if (path.endsWith('/cargo-capacity')) {
      final id = int.parse(path.split('/')[2]);
      final started = optionStarted.putIfAbsent(id, () => Completer());
      if (!started.isCompleted) started.complete();
      await optionGates[id]?.future;
      return response({
        'acceptsShipments': accepts,
        'capacities': {
          for (final key in ['motorcycles', 'bulkyGoods', 'parcels'])
            key: {'total': 4, 'used': 4 - remaining, 'remaining': remaining},
        },
      });
    }
    if (path.startsWith('/shipments/trips/')) {
      final id = int.parse(path.split('/')[3]);
      return response({
        'tripId': wrongPointsTrip ? id + 1 : id,
        'senderPoints': [
          {'id': id * 10, 'name': 'Sender $id', 'address': 'Fixture address'},
        ],
        'receiverPoints': [
          {
            'id': id * 10 + 1,
            'name': 'Receiver $id',
            'address': 'Fixture address',
          },
        ],
      });
    }
    if (path == '/bookings' && req.method == 'POST') {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      try {
        final result = await super.handle(req);
        if (result.statusCode >= 400 || body['cargoItems'] == null) {
          return result;
        }
        attachCargo(body);
        final data = {...orders[(body['tripId'] as int) + 900]!};
        if (omitCreateShipment) data.remove('shipment');
        return response(data);
      } on SocketException {
        // Simulate atomic server commit followed by a lost response.
        attachCargo(body);
        rethrow;
      }
    }
    final result = await super.handle(req);
    if (path.startsWith('/tickets/')) {
      final data =
          (jsonDecode(result.body) as Map)['data'] as Map<String, dynamic>;
      final bookingId = data['bookingId'] as int;
      if (orders[bookingId]?['shipment'] != null) {
        data['cancellation'] = {
          'eligible': false,
          'reason': 'ACTIVE_SHIPMENT',
          'cancelFeeRate': 0,
          'cancelFee': 0,
          'refundAmount': 0,
        };
      }
      return response(data);
    }
    if (path.startsWith('/bookings/') && !path.endsWith('/quote')) {
      final data =
          (jsonDecode(result.body) as Map)['data'] as Map<String, dynamic>;
      if (data['shipment'] != null) {
        data.remove('shipment'); // Real fresh booking reads omit the summary.
        data['cargoFee'] = data.remove('shippingFee');
        if (omitReadFee) data.remove('cargoFee');
        if (corruptReadItems) {
          data['cargoItems'] = [
            {'name': 'Other parcel', 'quantity': 1},
          ];
        }
      }
      return response(data);
    }
    return result;
  }

  @override
  RoundTripCheckoutCubit checkout() => RoundTripCheckoutCubit(
    request: core.request(),
    outbound: core.trip(101),
    inbound: core.trip(102),
    seatRepository: seats,
    bookingRepository: bookings,
    cargoRepository: cargo,
    now: () => now,
    receivingAccount: bank,
  );
}

Future<void> enable(
  RoundTripCheckoutCubit c,
  TripLeg leg,
  int id, {
  BookingCargoDraft? value,
}) async {
  await core.command(
    c,
    leg,
    const SetBookingCargoEnabledEvent(true),
    (s) => !s.cargo.loading && s.cargo.options != null,
  );
  await core.command(
    c,
    leg,
    UpdateBookingCargoEvent(value ?? draft(id)),
    (s) => s.cargo.draft != null,
  );
}

Future<BookingFlowBloc> oneWay(CargoServer s) async {
  final flow = BookingFlowBloc(
    seatRepository: s.seats,
    bookingRepository: s.bookings,
    cargoRepository: s.cargo,
    now: () => s.now,
    receivingAccount: bank,
  );
  flow.add(
    InitBookingFlowEvent(
      trip: core.trip(101),
      date: core.request().departureDate,
    ),
  );
  await flow.stream.firstWhere((s) => s.status == BookingFlowStatus.loaded);
  await flow.applyDraftAction(
    const UpdatePassengerInfoEvent(
      name: 'Fixture User',
      phone: '0901234567',
      email: 'fixture@example.com',
    ),
  );
  await flow.applyDraftAction(
    ToggleSeatEvent(flow.state.seatLayout!.lowerFloor.first),
  );
  for (var i = 0; i < 5; i++) {
    await flow.applyDraftAction(const NextStepEvent());
  }
  return flow;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(accessToken: 'cargo-fixture-owner');
  });
  tearDown(TokenStorage.resetStorageAdapter);

  test(
    'cargo DTO uses explicit IDs and vehicle metadata, no standalone shipment request',
    () {
      final item = CargoItemDraft(
        name: 'Bike',
        kind: CargoKind.motorcycle,
        categoryId: 1,
        vehicleModel: 'Model fixture',
        licensePlate: 'TEST-01',
        service: CargoService.fragile,
      );
      expect(item.toJson(), {
        'name': 'Bike',
        'type': 'Xe máy',
        'loaiHangHoaId': 1,
        'quantity': 1,
        'weight': 100.0,
        'category': 'fragile',
        'motorbikeModel': 'Model fixture',
        'licensePlate': 'TEST-01',
      });
      expect(draft(101).toJson()['senderPointId'], 1010);
      expect(
        () => BookingCargoDraft(items: [parcel()]).toJson(),
        throwsArgumentError,
      );
    },
  );
  test(
    'effective weight matches backend volumetric rounding and 40kg boundary',
    () {
      expect(
        parcel(weight: 1, length: 100, width: 50, height: 40).effectiveWeight,
        40,
      );
      expect(
        parcel(weight: 1, length: 100, width: 50, height: 40).validationError,
        isNull,
      );
      expect(
        parcel(weight: 1, length: 100, width: 50, height: 40.1).validationError,
        isNotNull,
      );
      expect(parcel(weight: 40).validationError, isNull);
      expect(parcel(weight: 40.01).validationError, isNotNull);
      expect(
        parcel(weight: 5, length: 10, width: null, height: 10).validationError,
        isNotNull,
      );
      expect(parcel(weight: double.nan).validationError, isNotNull);
      expect(parcel(weight: 0).validationError, isNotNull);
      expect(parcel(quantity: 0).validationError, isNotNull);
      expect(
        parcel(length: 151, width: 1, height: 1).validationError,
        isNotNull,
      );
    },
  );
  test(
    'vehicles have separate capacity groups and no parcel 40kg restriction',
    () {
      expect(
        parcel(kind: CargoKind.motorcycle, category: 1).effectiveWeight,
        100,
      );
      expect(
        parcel(kind: CargoKind.motorcycle, category: 1).validationError,
        isNull,
      );
      expect(
        parcel(kind: CargoKind.bicycle, category: 2).group,
        CargoGroup.bulky,
      );
      expect(parcel(weight: 20).group, CargoGroup.bulky);
    },
  );
  test(
    'options validate point role, distinct IDs, category/group and quantity capacity',
    () async {
      final s = CargoServer();
      final options = await s.cargo.loadOptions(101);
      expect(options.validate(draft(101)), isNull);
      expect(options.validate(draft(101, sender: 1020)), isNotNull);
      expect(
        options.validate(draft(101, sender: 1011, receiver: 1011)),
        isNotNull,
      );
      expect(
        options.validate(draft(101, items: [parcel(category: 1)])),
        isNotNull,
      );
      expect(
        options.validate(draft(101, items: [parcel(quantity: 5)])),
        isNotNull,
      );
      // Capacity counts quantities, not the parcel's kilograms.
      expect(
        options.validate(draft(101, items: [parcel(weight: 19, quantity: 4)])),
        isNull,
      );
    },
  );
  test(
    'unsupported cargo skips route lookup and does not masquerade as available',
    () async {
      final s = CargoServer()..accepts = false;
      final options = await s.cargo.loadOptions(101);
      expect(options.capacity.acceptsShipments, isFalse);
      expect(options.validate(draft(101)), isNotNull);
      expect(s.calls.where((v) => v.contains('route-points')), isEmpty);
    },
  );
  for (final failure in ['categories', 'points', 'capacity']) {
    test('malformed $failure fails closed', () async {
      final s = CargoServer();
      if (failure == 'categories') s.malformedCategories = true;
      if (failure == 'points') s.wrongPointsTrip = true;
      if (failure == 'capacity') {
        final repo = RealCargoRepository(
          client: ApiClient(
            httpClient: MockClient(
              (_) async => http.Response(
                jsonEncode({
                  'data': {'acceptsShipments': true},
                }),
                200,
              ),
            ),
          ),
        );
        await expectLater(repo.loadOptions(101), throwsA(anything));
        return;
      }
      await expectLater(s.cargo.loadOptions(101), throwsA(anything));
    });
  }
  test(
    'booking money parser keeps aliases and rejects conflicting/inconsistent totals',
    () {
      final json = <String, dynamic>{
        'bookingId': 1,
        'tripId': 101,
        'totalAmount': 240000,
        'ticketSubtotal': 190000,
        'originalTicketSubtotal': 200000,
        'discountAmount': 10000,
        'cargoFee': 50000,
        'shipment': {
          'shipmentId': 3,
          'shipmentCode': 'WAYBILL',
          'shippingFee': 50000,
          'itemCount': 1,
        },
        'cargoItems': [
          {'name': 'Parcel', 'quantity': 2},
        ],
      };
      final b = BookingModel.fromJson(json);
      expect(b.shippingFee, 50000);
      expect(b.originalAmount, 200000);
      expect(BookingModel.fromJson(b.toJson()).shipment!.code, 'WAYBILL');
      expect(
        () => BookingModel.fromJson({...json, 'shippingFee': 1}),
        throwsFormatException,
      );
      expect(
        () => BookingModel.fromJson({...json, 'totalAmount': 1}),
        throwsFormatException,
      );
      expect(
        BookingModel.fromJson({
          ...json,
          'cargoFee': null,
          'shipment': null,
        }).shippingFee,
        isNull,
      );
      expect(
        () => BookingModel.fromJson({...json, 'totalAmount': 240000.1}),
        throwsFormatException,
      );
    },
  );
  test(
    'one-way sends cargo in booking, keeps waybill on fresh read and uses full amount for QR',
    () async {
      final s = CargoServer();
      final flow = await oneWay(s);
      addTearDown(flow.close);
      await flow.applyDraftAction(const SetBookingCargoEnabledEvent(true));
      await flow.applyDraftAction(UpdateBookingCargoEvent(draft(101)));
      expect(flow.state.cargo.isValid, isTrue);
      expect(flow.state.finalAmount, isNull);
      expect(flow.state.ticketFinalAmount, 190000);
      expect(flow.state.canSubmitDraft, isTrue);
      await flow.confirmPayment();
      expect(s.posts.single['cargoItems'], draft(101).toJson()['cargoItems']);
      expect(s.calls.where((v) => v == 'POST /shipments'), isEmpty);
      expect(flow.state.status, BookingFlowStatus.paymentPending);
      expect(flow.state.pendingPaymentAmount, 240000);
      expect(
        Uri.parse(flow.state.pendingQrCodeUrl!).queryParameters['amount'],
        '240000',
      );
      expect(flow.state.checkoutBooking!.shipment!.code, 'WAYBILL-101');
      expect(flow.state.checkoutBooking!.shippingFee, 50000);
      expect(flow.state.canDisplayBankTransfer(s.now), isTrue);
    },
  );
  test(
    'round trip keeps distinct cargo/points/fee per leg and promotion quote stays ticket-only',
    () async {
      final s = CargoServer();
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      await enable(c, TripLeg.outbound, 101);
      await enable(c, TripLeg.inbound, 102);
      await core.command(
        c,
        TripLeg.outbound,
        const ApplyPromotionCodeEvent('SAVE10'),
        (s) => s.quote?.discountAmount == 10000 && !s.quoteLoading,
      );
      expect(c.state.totalAmount, isNull);
      await c.submit();
      expect(s.posts.length, 2);
      expect(s.posts[0]['senderPointId'], 1010);
      expect(s.posts[1]['senderPointId'], 1020);
      expect(s.posts[0]['expectedPromotionQuote'], {
        'originalTotal': '190000',
        'discountAmount': '10000',
        'finalTotal': '180000',
      });
      expect(c.state.outbound.pendingPaymentAmount, 230000);
      expect(c.state.inbound.pendingPaymentAmount, 340000);
      expect(c.state.totalAmount, 570000);
      expect(c.state.outbound.checkoutBooking!.shipment!.code, 'WAYBILL-101');
      expect(c.state.inbound.checkoutBooking!.shipment!.code, 'WAYBILL-102');
    },
  );
  test('removing cargo clears payload and restores ticket-only flow', () async {
    final s = CargoServer();
    final c = s.checkout();
    addTearDown(c.close);
    await core.ready(c);
    await enable(c, TripLeg.outbound, 101);
    await core.command(
      c,
      TripLeg.outbound,
      const SetBookingCargoEnabledEvent(false),
      (s) => !s.cargo.enabled,
    );
    await c.submit();
    expect(s.posts.every((p) => !p.containsKey('cargoItems')), isTrue);
    expect(c.state.totalAmount, 450000);
  });
  test(
    'invalid draft or full capacity blocks both create requests without dropping cargo',
    () async {
      final s = CargoServer()..remaining = 0;
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      await enable(c, TripLeg.outbound, 101);
      await c.submit();
      expect(s.posts, isEmpty);
      expect(c.state.outbound.cargo.enabled, isTrue);
      expect(c.state.outbound.cargo.validationError, isNotNull);
    },
  );
  test('late options response after disable cannot re-enable cargo', () async {
    final s = CargoServer()..optionGates[101] = Completer();
    final flow = await oneWay(s);
    addTearDown(flow.close);
    final loading = flow.applyDraftAction(
      const SetBookingCargoEnabledEvent(true),
    );
    await s.optionStarted.putIfAbsent(101, () => Completer()).future;
    await flow.applyDraftAction(const SetBookingCargoEnabledEvent(false));
    s.optionGates[101]!.complete();
    await loading;
    expect(flow.state.cargo.enabled, isFalse);
    expect(flow.state.cargo.options, isNull);
  });
  test('session invalidation fences a pending cargo response', () async {
    final s = CargoServer()..optionGates[101] = Completer();
    final c = s.checkout();
    addTearDown(c.close);
    await core.ready(c);
    c.dispatch(TripLeg.outbound, const SetBookingCargoEnabledEvent(true));
    await s.optionStarted.putIfAbsent(101, () => Completer()).future;
    await TokenStorage.saveTokens(accessToken: 'other-owner');
    s.optionGates[101]!.complete();
    await Future<void>.delayed(Duration.zero);
    expect(c.state.invalidated, isTrue);
    expect(c.state.outbound.cargo.options, isNull);
  });
  test(
    'partial create permits cargo edits only on missing leg, then creates only that leg',
    () async {
      final s = CargoServer()..reject.add(102);
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      await enable(c, TripLeg.outbound, 101);
      await enable(c, TripLeg.inbound, 102);
      await c.submit();
      expect(c.state.phase, RoundTripPhase.partiallyCreated);
      expect(
        c.dispatch(TripLeg.outbound, const SetBookingCargoEnabledEvent(false)),
        isFalse,
      );
      await core.command(
        c,
        TripLeg.inbound,
        UpdateBookingCargoEvent(draft(102, items: [parcel(quantity: 2)])),
        (s) => s.cargo.draft!.items.single.quantity == 2,
      );
      s.reject.clear();
      await c.submit();
      expect(s.posts.map((p) => p['tripId']), [101, 102, 102]);
      expect((s.posts.last['cargoItems'] as List).single['quantity'], 2);
    },
  );
  test(
    'unknown cargo booking POST is never replayed or converted to standalone shipment',
    () async {
      final s = CargoServer()..lose.add(101);
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      await enable(c, TripLeg.outbound, 101);
      await c.submit();
      await c.submit();
      expect(c.state.hasUnknownOutcome, isTrue);
      expect(s.posts.length, 1);
      expect(s.orders[1001]!['shipment'], isNotNull);
      expect(
        c.dispatch(TripLeg.outbound, const SetBookingCargoEnabledEvent(false)),
        isFalse,
      );
    },
  );
  for (final fault in ['missing-summary', 'missing-fee', 'wrong-items']) {
    test('$fault retains known booking but never permits transfer', () async {
      final s = CargoServer();
      s.omitCreateShipment = fault == 'missing-summary';
      s.omitReadFee = fault == 'missing-fee';
      s.corruptReadItems = fault == 'wrong-items';
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      await enable(c, TripLeg.outbound, 101);
      await c.submit();
      expect(c.state.outbound.pendingBookingId, 1001);
      expect(c.state.outbound.canDisplayBankTransfer(s.now), isFalse);
      expect(c.state.outbound.status, BookingFlowStatus.failure);
      await c.submit();
      expect(s.posts.length, 1);
    });
  }
  test(
    'cargo discovery failure is not silently turned into a ticket-only booking',
    () async {
      final s = CargoServer()..malformedCategories = true;
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      c.dispatch(TripLeg.outbound, const SetBookingCargoEnabledEvent(true));
      await core.until(c, (s) => s.outbound.cargo.error != null);
      await c.submit();
      expect(s.posts, isEmpty);
      await core.command(
        c,
        TripLeg.outbound,
        const SetBookingCargoEnabledEvent(false),
        (s) => !s.cargo.enabled,
      );
      await c.submit();
      expect(s.posts.length, 2);
    },
  );
  test('decimal half-up volumetric boundary agrees with Backend', () {
    expect(
      parcel(weight: 1, length: 100, width: 50, height: 40.05).effectiveWeight,
      40.1,
    );
    expect(
      parcel(weight: 1, length: 100, width: 50, height: 40.05).validationError,
      isNotNull,
    );
    expect(
      parcel(weight: 1, length: 100, width: 50, height: 40.04).effectiveWeight,
      40.0,
    );
    expect(
      parcel(weight: 1, length: 100, width: 50, height: 40.04).validationError,
      isNull,
    );
  });
  test(
    'paid cargo order hydrates boarding tickets but cannot cancel an active shipment',
    () async {
      final s = CargoServer();
      final flow = await oneWay(s);
      addTearDown(flow.close);
      await flow.applyDraftAction(const SetBookingCargoEnabledEvent(true));
      await flow.applyDraftAction(UpdateBookingCargoEvent(draft(101)));
      await flow.confirmPayment();
      s.paid.add(1001);
      await flow.confirmPayment();
      expect(flow.state.status, BookingFlowStatus.success);
      expect(flow.state.createdTickets.single.canShowQr, isTrue);
      expect(flow.state.createdTickets.single.canCancel, isFalse);
      expect(
        flow.state.createdTickets.single.cancellation!.reason,
        'ACTIVE_SHIPMENT',
      );
      expect(flow.state.checkoutBooking!.shipment!.code, 'WAYBILL-101');
      expect(s.posts.length, 1);
    },
  );
  test(
    'cargo state remains locked after a pending order and recheck does not create another shipment',
    () async {
      final s = CargoServer();
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      await enable(c, TripLeg.outbound, 101);
      await c.submit();
      final original = c.state.outbound.cargo;
      expect(
        c.dispatch(
          TripLeg.outbound,
          UpdateBookingCargoEvent(draft(101, items: [parcel(quantity: 2)])),
        ),
        isFalse,
      );
      await c.recheck(TripLeg.outbound);
      expect(c.state.outbound.cargo, original);
      expect(s.posts.length, 2);
      expect(s.calls.where((v) => v == 'POST /shipments'), isEmpty);
    },
  );
  test(
    'options refreshed to smaller capacity block subsequent creation',
    () async {
      final s = CargoServer();
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      await enable(c, TripLeg.outbound, 101);
      s.remaining = 0;
      await core.command(
        c,
        TripLeg.outbound,
        const RefreshBookingCargoEvent(),
        (s) => !s.cargo.loading,
      );
      expect(c.state.outbound.cargo.isValid, isFalse);
      await c.submit();
      expect(s.posts, isEmpty);
    },
  );
  test(
    'editing cargo during the load preserves latest draft and the request barrier blocks submit',
    () async {
      final s = CargoServer()..optionGates[101] = Completer();
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      c.dispatch(TripLeg.outbound, const SetBookingCargoEnabledEvent(true));
      await s.optionStarted.putIfAbsent(101, () => Completer()).future;
      c.dispatch(
        TripLeg.outbound,
        UpdateBookingCargoEvent(draft(101, items: [parcel(quantity: 2)])),
      );
      await c.submit();
      expect(s.posts, isEmpty);
      s.optionGates[101]!.complete();
      await core.until(c, (s) => !s.outbound.cargo.loading);
      expect(c.state.outbound.cargo.draft!.items.single.quantity, 2);
      await c.submit();
      expect((s.posts.first['cargoItems'] as List).single['quantity'], 2);
    },
  );
}
