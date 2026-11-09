import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/network/vietqr_config.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_checkout_cubit.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';
import 'package:vexgo_app/features/user/round_trip/presentation/widgets/round_trip_payment_view.dart';
import 'round_trip_core_test.dart' as core;

const bank = VietQrReceivingAccount(
  bankId: 'MB',
  accountNumber: '0000000001',
  accountName: 'SANDBOX',
);

class ComboServer extends core.Server {
  bool dropCreateCombo = false;
  int? changedReadId;
  @override
  Future<http.Response> handle(http.Request req) async {
    final r = await super.handle(req);
    if (req.url.path.endsWith('/bookings') &&
            req.method == 'POST' &&
            dropCreateCombo ||
        req.method == 'GET' &&
            changedReadId != null &&
            req.url.path.endsWith('/bookings/$changedReadId')) {
      final json = jsonDecode(r.body) as Map<String, dynamic>;
      (json['data'] as Map<String, dynamic>)['comboCode'] = 'RT-WRONG-OWNER';
      return http.Response(jsonEncode(json), r.statusCode, headers: r.headers);
    }
    return r;
  }
}

void main() {
  setUp(() async {
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(accessToken: 'combo-fixture-owner');
  });
  tearDown(TokenStorage.resetStorageAdapter);
  test('empty optional contact email is omitted from create payload', () async {
    final s = ComboServer();
    final booking = await s.bookings.createApiBooking(
      tripId: 101,
      seatIds: [1011],
      pickupPoint: 'Pickup',
      dropoffPoint: 'Dropoff',
      holdToken: 'fixture-hold',
      comboCode: 'RT-OPTIONAL-EMAIL',
      contact: const PassengerInfo(
        fullName: 'Fixture User',
        phone: '0901234567',
        email: '',
      ),
    );
    expect((s.posts.single['contact'] as Map).containsKey('email'), isFalse);
    expect(booking.comboCode, 'RT-OPTIONAL-EMAIL');
  });
  test(
    'both POSTs share a high entropy code and authoritative combined amount',
    () async {
      final s = ComboServer();
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      await c.submit();
      expect(s.posts.length, 2);
      expect(s.posts[0]['comboCode'], c.comboCode);
      expect(s.posts[1]['comboCode'], c.comboCode);
      expect(RegExp(r'^RT[A-F0-9]{32}$').hasMatch(c.comboCode), isTrue);
      expect(c.state.confirmedComboCode, c.comboCode);
      expect(c.state.comboAmount, 450000);
      expect(c.state.canDisplayCombo(s.now), isTrue);
    },
  );
  test(
    'partial creation hides transfers and retry reuses group without recreating first order',
    () async {
      final s = ComboServer()..reject.add(102);
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      await c.submit();
      expect(c.state.phase, RoundTripPhase.partiallyCreated);
      expect(c.state.canDisplayCombo(s.now), isFalse);
      expect(c.state.canDisplayTransfer(TripLeg.outbound, s.now), isFalse);
      s.reject.clear();
      await c.submit();
      expect(s.posts.length, 3);
      expect(s.posts.where((p) => p['tripId'] == 101).length, 1);
      expect(s.posts.map((p) => p['comboCode']).toSet(), {c.comboCode});
      expect(c.state.canDisplayCombo(s.now), isTrue);
    },
  );
  test('unknown create outcome never exposes combo or replays POST', () async {
    final s = ComboServer()..lose.add(102);
    final c = s.checkout();
    addTearDown(c.close);
    await core.ready(c);
    await c.submit();
    await c.submit();
    expect(s.posts.length, 2);
    expect(c.state.hasUnknownOutcome, isTrue);
    expect(c.state.canDisplayCombo(s.now), isFalse);
  });
  test(
    'wrong group from create retains known ID and prevents second order',
    () async {
      final s = ComboServer()..dropCreateCombo = true;
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      await c.submit();
      expect(s.posts.length, 1);
      expect(c.state.outbound.pendingBookingId, 1001);
      expect(c.state.canDisplayCombo(s.now), isFalse);
      await c.submit();
      expect(s.posts.length, 1);
    },
  );
  test(
    'changed group during readback locks payment without creating replacement',
    () async {
      final s = ComboServer();
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      await c.submit();
      s.changedReadId = 1002;
      await c.recheckAll();
      expect(c.state.canDisplayCombo(s.now), isFalse);
      expect(c.state.inbound.status, BookingFlowStatus.failure);
      expect(s.posts.length, 2);
    },
  );
  test('earliest order expiry disables shared QR for both legs', () async {
    final s = ComboServer();
    final c = s.checkout();
    addTearDown(c.close);
    await core.ready(c);
    await c.submit();
    final expires = s.now.add(const Duration(minutes: 2));
    s.orders[1002]!['expiresAt'] = expires.toIso8601String();
    await c.recheckAll();
    expect(c.state.comboExpiresAt, expires);
    expect(c.state.canDisplayCombo(expires), isFalse);
    expect(
      c.state.canDisplayCombo(expires.subtract(const Duration(seconds: 1))),
      isTrue,
    );
  });
  test(
    'combined payment requires both readbacks paid and both tickets hydrated',
    () async {
      final s = ComboServer();
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      await c.submit();
      s.paid.add(1001);
      await c.recheckAll();
      expect(c.state.phase, RoundTripPhase.partiallyPaid);
      expect(c.state.canDisplayCombo(s.now), isFalse);
      s.paid.add(1002);
      await c.recheckAll();
      expect(c.state.isComplete, isTrue);
      expect(s.posts.length, 2);
    },
  );
  test(
    'checking both orders is single flight and never submits bookings',
    () async {
      final s = ComboServer();
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      await c.submit();
      final gate = Completer<void>();
      s.readGates[1001] = gate;
      final task = c.recheckAll();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.busy, isTrue);
      await c.recheckAll();
      await c.submit();
      expect(s.posts.length, 2);
      gate.complete();
      await task;
      expect(c.state.busy, isFalse);
    },
  );
  test('safe integer overflow never enables a QR', () async {
    final s = ComboServer();
    final c = s.checkout();
    addTearDown(c.close);
    await core.ready(c);
    await c.submit();
    final state = RoundTripCheckoutState(
      requestedComboCode: c.comboCode,
      outbound: c.state.outbound.copyWith(
        checkoutBooking: c.state.outbound.checkoutBooking!.copyWith(
          totalAmount: 9007199254740991,
        ),
      ),
      inbound: c.state.inbound,
    );
    expect(state.comboAmount, isNull);
    expect(state.canDisplayCombo(s.now), isFalse);
  });
  test(
    'session change clears group and prevents verification for another account',
    () async {
      final s = ComboServer();
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      await c.submit();
      await TokenStorage.clearTokens();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.invalidated, isTrue);
      expect(c.state.requestedComboCode, isNull);
      expect(c.state.canDisplayCombo(s.now), isFalse);
    },
  );
  testWidgets(
    'pending pair displays exactly one QR with summed amount and confirmed memo',
    (t) async {
      final s = ComboServer()..now = DateTime.now().toUtc();
      late RoundTripCheckoutCubit c;
      await t.runAsync(() async {
        c = s.checkout();
        await core.ready(c);
        await c.submit();
      });
      addTearDown(c.close);
      int checks = 0;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocBuilder<RoundTripCheckoutCubit, RoundTripCheckoutState>(
              bloc: c,
              builder: (_, state) => RoundTripPaymentView(
                request: core.request(),
                state: state,
                onRecheck: (_) {},
                onRecheckAll: () => checks++,
                receivingAccount: bank,
                onOpenMyTickets: () {},
                onOpenSupport: () {},
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      final image = t.widget<Image>(
        find.byKey(const ValueKey('round-trip-combo-qr')),
      );
      final uri = Uri.parse((image.image as NetworkImage).url);
      expect(uri.queryParameters['amount'], '450000');
      expect(uri.queryParameters['addInfo'], c.comboCode);
      await t.ensureVisible(
        find.byKey(const ValueKey('round-trip-combo-recheck')),
      );
      await t.tap(find.byKey(const ValueKey('round-trip-combo-recheck')));
      expect(checks, 1);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    testWidgets('combo layout with 2x text and keyboard at $size', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      t.view.viewInsets = const FakeViewPadding(bottom: 150);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetViewInsets);
      final s = ComboServer()..now = DateTime.now().toUtc();
      late RoundTripCheckoutCubit c;
      await t.runAsync(() async {
        c = s.checkout();
        await core.ready(c);
        await c.submit();
      });
      addTearDown(c.close);
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: RoundTripPaymentView(
              request: core.request(),
              state: c.state,
              onRecheck: (_) {},
              onRecheckAll: () {},
              receivingAccount: bank,
              onOpenMyTickets: () {},
              onOpenSupport: () {},
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(t.takeException(), isNull);
      final copy = find.byTooltip('Sao chép Nội dung');
      await t.ensureVisible(copy);
      expect(t.getSize(copy).width, greaterThanOrEqualTo(48));
      expect(t.getSize(copy).height, greaterThanOrEqualTo(48));
      await t.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('partial combo settlement never offers another transfer QR', (
    t,
  ) async {
    final s = ComboServer()..now = DateTime.now().toUtc();
    late RoundTripCheckoutCubit c;
    await t.runAsync(() async {
      c = s.checkout();
      await core.ready(c);
      await c.submit();
      s.paid.add(1001);
      await c.recheckAll();
    });
    addTearDown(c.close);
    expect(c.state.phase, RoundTripPhase.partiallyPaid);
    expect(c.state.canDisplayTransfer(TripLeg.inbound, s.now), isFalse);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoundTripPaymentView(
            request: core.request(),
            state: c.state,
            onRecheck: (_) {},
            onRecheckAll: () {},
            receivingAccount: bank,
            onOpenMyTickets: () {},
            onOpenSupport: () {},
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('không chuyển khoản thêm'), findsWidgets);
    expect(
      find.byKey(const ValueKey('round-trip-combo-check-all')),
      findsOneWidget,
    );
    await t.pumpWidget(const SizedBox.shrink());
  });
}
