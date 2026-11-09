import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/booking_cargo_model.dart';
import 'package:vexgo_app/data/models/luggage_policy.dart';
import 'package:vexgo_app/data/repositories/luggage_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/luggage_cubit.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';
import 'booking_cargo_core_test.dart' as cargo;
import 'round_trip_core_test.dart' as core;

Map<String, dynamic> policyJson(int tripId, {double free = 7}) => {
  'tripId': tripId,
  'routeId': 10,
  'busCompanyId': 3,
  'busCompanyName': 'Hoa Mai',
  'maxFreeWeightKg': free,
  'packages': [
    for (final p in [
      ['S', 5, 40, 25, 25, 50000],
      ['M', 10, 50, 40, 25, 80000],
      ['L', 20, 60, 40, 40, 120000],
      ['XL', 35, 80, 50, 40, 180000],
    ])
      {
        'code': p[0],
        'name': 'Gói ${p[0]}',
        'weight': p[1],
        'length': p[2],
        'width': p[3],
        'height': p[4],
        'baseFee': p[5],
      },
  ],
  'vehicles': {
    'motorcycleWave': 180000,
    'motorcycleScooter': 220000,
    'motorcycleBig': 250000,
    'bicycle': 80000,
  },
  'surcharges': {'fragile': 20000, 'valuable': 50000},
};

class LuggageServer extends cargo.CargoServer {
  bool missingPolicy = false;
  int? wrongTrip;
  Completer<void>? gate;
  Map<String, dynamic> Function(Map<String, dynamic>)? mutate;
  @override
  Future<http.Response> handle(http.Request req) async {
    if (req.url.path.contains('/luggage-packages')) {
      calls.add('${req.method} ${req.url.path}');
      await gate?.future;
      if (missingPolicy) return http.Response('{"error":"NOT_FOUND"}', 404);
      final id = int.parse(req.url.path.split('/').reversed.elementAt(1));
      final json = policyJson(wrongTrip ?? id);
      return response(mutate?.call(json) ?? json);
    }
    return super.handle(req);
  }

  LuggageRepository get luggage =>
      RealLuggageRepository(client: client, cargoRepository: this.cargo);
}

LuggageSelection selected(
  int trip, {
  int quantity = 1,
  double weight = 5,
  String code = 'S',
  CargoService service = CargoService.normal,
}) => LuggageSelection(
  checked: [
    CheckedLuggageItem(
      cargo: CargoItemDraft(
        name: 'Vali',
        kind: CargoKind.parcel,
        categoryId: 3,
        weight: weight,
        quantity: quantity,
        service: service,
      ),
      packageCode: code,
    ),
  ],
  senderPointId: trip * 10,
  receiverPointId: trip * 10 + 1,
);

class DeferredRepository implements LuggageRepository {
  final List<Completer<LuggageOptions>> requests = [];
  @override
  Future<LuggageOptions> load(int tripId) {
    final c = Completer<LuggageOptions>();
    requests.add(c);
    return c.future;
  }
}

void main() {
  setUp(
    () => TokenStorage.setStorageAdapterForTesting(
      InMemorySecureStorageAdapter(),
    ),
  );
  tearDown(TokenStorage.resetStorageAdapter);
  test(
    'policy comes from public trip endpoint and shares category/capacity discovery',
    () async {
      final s = LuggageServer();
      final o = await s.luggage.load(101);
      expect(o.policy.tripId, 101);
      expect(o.policy.freeWeightPerPassengerKg, 7);
      expect(o.policy.packages.length, 4);
      expect(
        s.calls.any(
          (p) => p.contains('/bus-companies/trips/101/luggage-packages'),
        ),
        true,
      );
      expect(s.calls.any((p) => p.contains('/cargo-capacity')), true);
      expect(selected(101).validate(o.policy, o.cargo, 1), null);
    },
  );
  for (final problem in [
    'missing',
    'wrong-trip',
    'unknown-package',
    'duplicate-package',
    'bad-weight',
    'missing-fee',
    'bad-money',
  ]) {
    test('policy fail closed: $problem', () async {
      final s = LuggageServer();
      if (problem == 'missing') s.missingPolicy = true;
      if (problem == 'wrong-trip') s.wrongTrip = 102;
      s.mutate = (json) {
        final packages = json['packages'] as List;
        if (problem == 'unknown-package') packages[0]['code'] = 'XXL';
        if (problem == 'duplicate-package') packages[0]['code'] = 'M';
        if (problem == 'bad-weight') packages[1]['weight'] = 4;
        if (problem == 'missing-fee') {
          (json['surcharges'] as Map).remove('fragile');
        }
        if (problem == 'bad-money') packages[0]['baseFee'] = 0.5;
        return json;
      };
      await expectLater(s.luggage.load(101), throwsA(anything));
    });
  }
  test(
    'carry-on exactly policy limit free, overweight rejected, not cargo capacity dependent',
    () async {
      final s = LuggageServer()..accepts = false;
      final o = await s.luggage.load(101);
      final free = LuggageSelection(carryOn: [const CarryOnBag(weightKg: 7)]);
      expect(free.validate(o.policy, o.cargo, 1), null);
      expect(free.referenceFee(o.policy), 0);
      expect(free.toBookingCargo(), null);
      expect(
        LuggageSelection(
          carryOn: [const CarryOnBag(weightKg: 7.001)],
        ).validate(o.policy, o.cargo, 1),
        isNotNull,
      );
      expect(
        LuggageSelection(
          carryOn: [const CarryOnBag(weightKg: 4, quantity: 2)],
        ).validate(o.policy, o.cargo, 1),
        isNotNull,
      );
      expect(selected(101).validate(o.policy, o.cargo, 1), isNotNull);
    },
  );
  test(
    'custom allowance honored and never silently falls back to 7kg',
    () async {
      final s = LuggageServer()..mutate = (j) => {...j, 'maxFreeWeightKg': 3};
      final o = await s.luggage.load(101);
      expect(
        LuggageSelection(
          carryOn: [const CarryOnBag(weightKg: 4)],
        ).validate(o.policy, o.cargo, 1),
        isNotNull,
      );
    },
  );
  test(
    'paid baggage validates weight, package, dimensions and actual capacity/points',
    () async {
      final s = LuggageServer();
      final o = await s.luggage.load(101);
      expect(
        selected(101, weight: 6).validate(o.policy, o.cargo, 1),
        isNotNull,
      );
      expect(
        selected(101, weight: 6, code: 'M').validate(o.policy, o.cargo, 1),
        null,
      );
      expect(
        selected(101, quantity: 5).validate(o.policy, o.cargo, 1),
        isNotNull,
      );
      expect(selected(102).validate(o.policy, o.cargo, 1), isNotNull);
      final tooWide = LuggageSelection(
        checked: [
          CheckedLuggageItem(
            cargo: cargo.parcel(weight: 1, length: 41, width: 1, height: 1),
            packageCode: 'S',
          ),
        ],
        senderPointId: 1010,
        receiverPointId: 1011,
      );
      expect(tooWide.validate(o.policy, o.cargo, 1), isNotNull);
    },
  );
  test(
    'quantity/service reference estimate and safe payload omit price, package and free carry-on',
    () async {
      final o = await LuggageServer().luggage.load(101);
      final selection = LuggageSelection(
        carryOn: [const CarryOnBag(weightKg: 2)],
        checked: selected(
          101,
          quantity: 2,
          service: CargoService.fragile,
        ).checked,
        senderPointId: 1010,
        receiverPointId: 1011,
      );
      expect(selection.referenceFee(o.policy), 140000);
      final json = selection.toBookingCargo()!.toJson();
      final item = (json['cargoItems'] as List).single as Map;
      expect(item['quantity'], 2);
      expect(item['category'], 'fragile');
      expect(json['senderPointId'], 1010);
      for (final key in [
        'price',
        'fee',
        'packageCode',
        'baseFee',
        'carryOn',
        'maxFreeWeightKg',
      ]) {
        expect(json.containsKey(key), false);
        expect(item.containsKey(key), false);
      }
    },
  );
  test('reference estimate never wraps integer overflow', () {
    final policy = LuggagePolicy.fromJson(policyJson(101));
    final item = CheckedLuggageItem(
      cargo: cargo.parcel(quantity: 9007199254740991),
      packageCode: 'S',
    );
    expect(() => item.referenceFee(policy), throwsFormatException);
  });
  test(
    'cubit session, trip, passenger and absolute freshness guards',
    () async {
      var now = DateTime.utc(2026, 11, 6);
      final c = LuggageCubit(
        tripId: 101,
        passengerCount: 1,
        repository: LuggageServer().luggage,
        now: () => now,
      );
      addTearDown(c.close);
      await c.load();
      c.select(selected(101));
      expect(c.referenceFee, 50000);
      expect(c.requiresServerPricing, true);
      expect(
        c.exportForBooking(expectedTripId: 101, expectedPassengerCount: 1),
        isNotNull,
      );
      expect(
        () =>
            c.exportForBooking(expectedTripId: 102, expectedPassengerCount: 1),
        throwsStateError,
      );
      expect(
        () =>
            c.exportForBooking(expectedTripId: 101, expectedPassengerCount: 2),
        throwsStateError,
      );
      now = now.add(const Duration(minutes: 5));
      expect(c.referenceFee, null);
      expect(c.validationError, isNotNull);
      await c.load();
      expect(c.validationError, null);
      await TokenStorage.saveTokens(accessToken: 'other-session');
      expect(c.state.phase, LuggagePhase.revoked);
      expect(c.state.selection.checked, isEmpty);
      expect(
        () =>
            c.exportForBooking(expectedTripId: 101, expectedPassengerCount: 1),
        throwsStateError,
      );
    },
  );
  test(
    'late reload cannot overwrite latest, skip cancels response and disposal is safe',
    () async {
      final options = await LuggageServer().luggage.load(101);
      final repo = DeferredRepository();
      final c = LuggageCubit(tripId: 101, passengerCount: 1, repository: repo);
      final a = c.load();
      final b = c.load();
      repo.requests[1].complete(options);
      await b;
      c.select(selected(101));
      repo.requests[0].complete(options);
      await a;
      expect(c.state.selection.checked, isNotEmpty);
      final pending = c.load();
      c.skip();
      repo.requests[2].complete(options);
      await pending;
      expect(c.state.phase, LuggagePhase.idle);
      expect(
        c.exportForBooking(expectedTripId: 101, expectedPassengerCount: 1),
        null,
      );
      final disposed = c.load();
      await c.close();
      repo.requests[3].complete(options);
      await disposed;
    },
  );
  test(
    'policy error blocks baggage until explicit skip, never fabricates 0 fee',
    () async {
      final s = LuggageServer()..missingPolicy = true;
      final c = LuggageCubit(
        tripId: 101,
        passengerCount: 1,
        repository: s.luggage,
      );
      addTearDown(c.close);
      await c.load();
      expect(c.state.phase, LuggagePhase.failure);
      expect(c.referenceFee, null);
      expect(
        () =>
            c.exportForBooking(expectedTripId: 101, expectedPassengerCount: 1),
        throwsStateError,
      );
      c.skip();
      expect(c.referenceFee, 0);
      expect(
        c.exportForBooking(expectedTripId: 101, expectedPassengerCount: 1),
        null,
      );
    },
  );
  test(
    'one event hands draft to existing booking core and server amount remains authoritative',
    () async {
      final s = LuggageServer();
      final flow = await cargo.oneWay(s);
      addTearDown(flow.close);
      final c = LuggageCubit(
        tripId: 101,
        passengerCount: 1,
        repository: s.luggage,
      );
      addTearDown(c.close);
      await c.load();
      c.select(selected(101, code: 'M', weight: 6));
      final draft = c.exportForBooking(
        expectedTripId: 101,
        expectedPassengerCount: 1,
      );
      expect(c.referenceFee, 80000);
      await flow.applyDraftAction(
        SetBookingCargoEnabledEvent(true, initialDraft: draft),
      );
      expect(flow.state.cargo.draft, draft);
      expect(flow.state.cargo.isValid, true);
      await flow.confirmPayment();
      expect(s.posts.length, 1);
      expect(flow.state.checkoutBooking?.shippingFee, 50000);
    },
  );
  test(
    'round-trip legs keep separate policy/draft and accept existing coordinator command',
    () async {
      final s = LuggageServer();
      final checkout = s.checkout();
      addTearDown(checkout.close);
      await core.ready(checkout);
      final out = LuggageCubit(
        tripId: 101,
        passengerCount: 1,
        repository: s.luggage,
      );
      final back = LuggageCubit(
        tripId: 102,
        passengerCount: 1,
        repository: s.luggage,
      );
      addTearDown(out.close);
      addTearDown(back.close);
      await Future.wait([out.load(), back.load()]);
      out.select(selected(101));
      back.select(selected(102, code: 'M', weight: 8));
      final outgoing = out.exportForBooking(
        expectedTripId: 101,
        expectedPassengerCount: 1,
      );
      await core.command(
        checkout,
        TripLeg.outbound,
        SetBookingCargoEnabledEvent(true, initialDraft: outgoing),
        (state) => state.cargo.isValid,
      );
      expect(checkout.state.outbound.cargo.draft, outgoing);
      expect(checkout.state.inbound.cargo.enabled, false);
      expect(
        back
            .exportForBooking(expectedTripId: 102, expectedPassengerCount: 1)!
            .senderPointId,
        1020,
      );
    },
  );
}
