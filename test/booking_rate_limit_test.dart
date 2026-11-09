import 'package:vexgo_app/features/user/round_trip/round_trip_checkout_cubit.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:vexgo_app/app/routes.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:vexgo_app/core/network/api_response.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_rate_limit.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_rate_limit_view.dart';
import 'package:vexgo_app/features/user/booking/presentation/screens/booking_flow_screen.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'package:vexgo_app/data/repositories/auth_repository.dart';
import 'package:vexgo_app/features/user/round_trip/presentation/screens/round_trip_booking_screen.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';
import 'booking_integrity_regression_test.dart' as one;
import 'round_trip_core_test.dart' as two;

http.Response rejected([String code = 'TOO_MANY_UNPAID_BOOKINGS']) =>
    http.Response(
      jsonEncode({
        'statusCode': 429,
        'error': code,
        'message': 'Fixture 429 message',
      }),
      429,
      headers: {'content-type': 'application/json'},
    );

class OneRateServer extends one.CheckoutServer {
  bool holdLimited = false, createLimited = false, readLimited = false;
  String code = 'TOO_MANY_UNPAID_BOOKINGS';
  Completer<void>? gate;
  final started = Completer<void>();
  @override
  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    if (holdLimited &&
        request.method == 'POST' &&
        path.endsWith('/seat-holds')) {
      holdPosts++;
      if (!started.isCompleted) started.complete();
      if (gate != null) await gate!.future;
      return rejected(code);
    }
    if (createLimited &&
        request.method == 'POST' &&
        path.endsWith('/bookings')) {
      bookingPosts++;
      if (!started.isCompleted) started.complete();
      if (gate != null) await gate!.future;
      return rejected(code);
    }
    if (readLimited &&
        request.method == 'GET' &&
        path.endsWith('/payments/9/status')) {
      statusGets++;
      return rejected('THROTTLED');
    }
    return super.handle(request);
  }
}

class TwoRateServer extends two.Server {
  int? limitedTrip = 102;
  int blockedPosts = 0;
  @override
  Future<http.Response> handle(http.Request request) async {
    if (request.method == 'POST' &&
        request.url.path.endsWith('/bookings') &&
        (jsonDecode(request.body) as Map)['tripId'] == limitedTrip) {
      blockedPosts++;
      return rejected();
    }
    return super.handle(request);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(accessToken: 'fixture-rate-owner');
  });
  testWidgets(
    'one-way screen keeps draft while checking prior orders and resuming',
    (tester) async {
      final s = OneRateServer()..createLimited = true;
      late BookingFlowBloc b;
      await tester.runAsync(() async {
        b = await one.ready(s);
        await b.confirmPayment();
      });
      addTearDown(b.close);
      final auth = AuthBloc(authRepository: MockAuthRepository());
      addTearDown(auth.close);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => BookingFlowScreen(
              trip: one.trip,
              date: DateTime(2026, 11, 1),
              bloc: b,
              now: () => s.now,
            ),
          ),
          GoRoute(
            path: AppRoutes.myTickets,
            builder: (_, _) =>
                const Scaffold(body: Text('Prior orders fixture')),
          ),
          GoRoute(
            path: AppRoutes.supportChat,
            builder: (_, _) => const Scaffold(body: Text('Support fixture')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        BlocProvider.value(
          value: auth,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BookingRateLimitView), findsOneWidget);
      await tester.tap(find.text('Kiểm tra vé/đơn'));
      await tester.pumpAndSettle();
      expect(find.text('Prior orders fixture'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(BookingRateLimitView), findsOneWidget);
      await tester.tap(find.text('Quay lại đặt vé'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BookingRateLimitView), findsNothing);
      expect(b.state.passengerName, 'Nguyen Van An');
      expect(b.state.selectedSeats.length, 1);
      expect(s.bookingPosts, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'round-trip screen retains successful leg while blocked notice is visible',
    (tester) async {
      final s = TwoRateServer();
      late RoundTripCheckoutCubit c;
      await tester.runAsync(() async {
        c = s.checkout();
        await two.ready(c);
        await c.submit();
      });
      addTearDown(c.close);
      final auth = AuthBloc(authRepository: MockAuthRepository());
      addTearDown(auth.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: auth,
          child: MaterialApp(
            home: RoundTripBookingScreen(
              selection: RoundTripSelection(
                request: two.request(),
                outbound: two.trip(101),
                inbound: two.trip(102),
              ),
              cubit: c,
              now: () => s.now,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BookingRateLimitView), findsOneWidget);
      expect(
        find.textContaining('Đơn đã tạo vẫn được giữ nguyên'),
        findsOneWidget,
      );
      expect(c.state.outbound.pendingBookingId, isNotNull);
      expect(s.posts.length, 1);
      expect(s.blockedPosts, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  tearDown(TokenStorage.resetStorageAdapter);

  test('business code and generic HTTP 429 have distinct advice', () {
    final specific = BookingRateLimit.fromError(
      const ApiException(
        ApiError(
          statusCode: 429,
          errorCode: 'TOO_MANY_UNPAID_BOOKINGS',
          message: 'ignored',
        ),
      ),
      existingOrder: false,
    );
    final generic = BookingRateLimit.fromError(
      const ApiException(
        ApiError(statusCode: 429, errorCode: 'THROTTLED', message: 'ignored'),
      ),
      existingOrder: false,
    );
    expect(specific.unpaidBookings, isTrue);
    expect(specific.message, contains('30 phút'));
    expect(generic.unpaidBookings, isFalse);
    expect(generic.message, isNot(contains('30 phút')));
  });
  for (final code in ['TOO_MANY_UNPAID_BOOKINGS', 'THROTTLED']) {
    test(
      'create $code preserves draft/hold and requires explicit resume before retry',
      () async {
        final s = OneRateServer()
          ..createLimited = true
          ..code = code;
        final b = await one.ready(s);
        addTearDown(b.close);
        final before = b.state;
        await b.confirmPayment();
        expect(
          b.state.rateLimit?.unpaidBookings,
          code == 'TOO_MANY_UNPAID_BOOKINGS',
        );
        expect(b.state.bookingOutcomeUnknown, isFalse);
        expect(b.state.pendingBookingId, isNull);
        expect(b.state.seatHold, before.seatHold);
        expect(b.state.selectedSeats, before.selectedSeats);
        expect(b.state.passengerName, before.passengerName);
        expect(b.state.passengerPhone, before.passengerPhone);
        expect(b.state.passengerEmail, before.passengerEmail);
        expect(b.state.canProceed, isFalse);
        await b.confirmPayment();
        await b.confirmPayment();
        expect(s.bookingPosts, 1);
        await b.applyDraftAction(const ResumeAfterBookingRateLimitEvent());
        expect(b.state.rateLimit, isNull);
        expect(s.bookingPosts, 1);
        s.createLimited = false;
        await b.confirmPayment();
        expect(s.bookingPosts, 2);
        expect(b.state.pendingBookingId, 42);
      },
    );
  }
  test(
    'hold 429 preserves selected seats and passenger instead of clearing inventory',
    () async {
      final s = OneRateServer()..holdLimited = true;
      final b = BookingFlowBloc(
        seatRepository: s.seats,
        bookingRepository: s.real,
        now: () => s.now,
      );
      addTearDown(b.close);
      await one.dispatch(
        b,
        oneInit(),
        (st) => st.status == BookingFlowStatus.loaded,
      );
      await one.dispatch(
        b,
        ToggleSeatEvent(b.state.seatLayout!.lowerFloor.first),
        (st) => st.selectedSeats.isNotEmpty,
      );
      await one.dispatch(
        b,
        const UpdatePassengerInfoEvent(
          name: 'Fixture',
          phone: '0901234567',
          email: 'qa@example.test',
        ),
        (st) => st.passengerName == 'Fixture',
      );
      await one.dispatch(
        b,
        const NextStepEvent(),
        (st) => st.rateLimit != null,
      );
      expect(b.state.selectedSeats.length, 1);
      expect(b.state.passengerName, 'Fixture');
      b.add(const NextStepEvent());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(s.holdPosts, 1);
      expect(b.state.seatHold, isNull);
      await b.applyDraftAction(const ResumeAfterBookingRateLimitEvent());
      expect(s.holdPosts, 1);
      s.holdLimited = false;
      await one.dispatch(b, const NextStepEvent(), (st) => st.seatHold != null);
      expect(s.holdPosts, 2);
    },
  );
  test(
    'hold expires during notice, contact survives and resume does not reuse expired hold',
    () async {
      final s = OneRateServer()..createLimited = true;
      final b = await one.ready(s);
      addTearDown(b.close);
      await b.confirmPayment();
      s.now = s.now.add(const Duration(minutes: 11));
      await one.dispatch(
        b,
        const TickCountdownEvent(),
        (st) => st.seatHold == null,
      );
      expect(b.state.rateLimit, isNotNull);
      expect(b.state.passengerName, 'Nguyen Van An');
      await b.applyDraftAction(const ResumeAfterBookingRateLimitEvent());
      expect(b.state.step, BookingStep.seatSelection);
      expect(b.state.selectedSeats, isEmpty);
      await b.confirmPayment();
      expect(s.bookingPosts, 1);
    },
  );
  test(
    'repeated submit while response pending and after rejection sends one POST',
    () async {
      final s = OneRateServer()
        ..createLimited = true
        ..gate = Completer<void>();
      final b = await one.ready(s);
      addTearDown(b.close);
      final first = b.confirmPayment();
      await s.started.future;
      await b.confirmPayment();
      s.gate!.complete();
      await first;
      await b.confirmPayment();
      expect(s.bookingPosts, 1);
    },
  );
  test(
    'late 429 after session invalidation cannot restore checkout advice/draft',
    () async {
      final s = OneRateServer()
        ..createLimited = true
        ..gate = Completer<void>();
      final b = await one.ready(s);
      addTearDown(b.close);
      final first = b.confirmPayment();
      await s.started.future;
      b.invalidateSession();
      s.gate!.complete();
      await first;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(b.sessionInvalidated, isTrue);
      expect(b.state.rateLimit, isNull);
    },
  );
  test(
    '429 during existing payment check keeps IDs and cannot create another booking',
    () async {
      final s = OneRateServer()..readLimited = true;
      final b = await one.ready(s);
      addTearDown(b.close);
      await b.confirmPayment();
      expect(b.state.pendingBookingId, 42);
      expect(b.state.pendingPaymentId, 9);
      expect(b.state.rateLimit?.existingOrder, isTrue);
      await b.confirmPayment();
      expect(s.bookingPosts, 1);
      expect(s.paymentPosts, 1);
      await b.applyDraftAction(const ResumeAfterBookingRateLimitEvent());
      s.readLimited = false;
      await b.confirmPayment();
      expect(s.bookingPosts, 1);
      expect(s.paymentPosts, 1);
      expect(b.state.pendingBookingId, 42);
    },
  );
  test(
    'round trip first leg survives second-leg 429; resume reuses combo and first booking',
    () async {
      final s = TwoRateServer();
      final c = s.checkout();
      addTearDown(c.close);
      await two.ready(c);
      await c.submit();
      final id = c.state.outbound.pendingBookingId;
      expect(id, isNotNull);
      expect(c.state.inbound.pendingBookingId, isNull);
      expect(c.state.rateLimit?.unpaidBookings, isTrue);
      expect(c.state.hasUnknownOutcome, isFalse);
      expect(c.state.canDisplayCombo(s.now), isFalse);
      await c.submit();
      expect(s.blockedPosts, 1);
      expect(s.posts.length, 1);
      await c.resumeAfterRateLimit();
      expect(s.blockedPosts, 1);
      expect(s.posts.length, 1);
      s.limitedTrip = null;
      await c.submit();
      expect(c.state.outbound.pendingBookingId, id);
      expect(s.posts.length, 2);
      expect(s.posts.map((p) => p['comboCode']).toSet(), {c.comboCode});
      expect(c.state.hasBothOrders, isTrue);
      expect(c.state.canDisplayCombo(s.now), isTrue);
    },
  );
  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    testWidgets(
      'notice $size at 2x text scrolls to explicit actions without overflow',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var resumed = 0, reviewed = 0;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: BookingRateLimitView(
              notice: const BookingRateLimit(
                unpaidBookings: true,
                existingOrder: false,
              ),
              onResume: () => resumed++,
              onReviewOrders: () => reviewed++,
              onSupport: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Cần kiểm tra các đơn trước'), findsOneWidget);
        final button = find.text('Quay lại đặt vé');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
        expect(resumed, 1);
        expect(reviewed, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

InitBookingFlowEvent oneInit() =>
    InitBookingFlowEvent(trip: one.trip, date: DateTime(2026, 11, 1));
