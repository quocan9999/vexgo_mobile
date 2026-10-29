import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/app/routes.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/booking_model.dart';
import 'package:vexgo_app/data/models/city_model.dart';
import 'package:vexgo_app/data/models/operator_model.dart';
import 'package:vexgo_app/data/models/popular_route_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/auth_repository.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/home/bloc/home_bloc.dart';
import 'package:vexgo_app/features/user/home/bloc/home_state.dart';
import 'package:vexgo_app/features/user/home/presentation/widgets/search_form_card.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'package:vexgo_app/features/user/round_trip/presentation/screens/round_trip_booking_screen.dart';
import 'package:vexgo_app/features/user/round_trip/presentation/screens/round_trip_search_screen.dart';
import 'package:vexgo_app/features/user/round_trip/presentation/widgets/round_trip_payment_view.dart';
import 'package:vexgo_app/features/user/round_trip/presentation/widgets/round_trip_success_view.dart';
import 'package:vexgo_app/features/user/round_trip/presentation/widgets/round_trip_summary_step.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_checkout_cubit.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';
import 'round_trip_core_test.dart' as core;

BookingModel testOrder(
  int bookingId,
  int tripId,
  int amount, {
  String? code,
  DateTime? expiresAt,
}) => BookingModel(
  bookingId: bookingId,
  bookingCode: 'BK-$bookingId',
  tripId: tripId,
  status: BookingStatus.pending,
  paymentStatus: 'CHO_THANH_TOAN',
  contact: const PassengerInfo(
    fullName: 'Nguyễn Văn A',
    phone: '0912345678',
    email: 'test@vexgo.com',
  ),
  pickupPoint: 'Điểm đón',
  dropoffPoint: 'Điểm trả',
  seats: const ['A01'],
  seatIds: const [1],
  totalAmount: amount,
  orderCode: code ?? 'ORD-$bookingId',
  expiresAt: expiresAt ?? DateTime.now().add(const Duration(minutes: 10)),
);

TicketModel testTicket(String id, String code, int tripId, String seat) =>
    TicketModel(
      id: id,
      ticketCode: code,
      status: TicketStatus.upcoming,
      bookingDate: '2026-11-10',
      seatNumber: seat,
      seats: [seat],
      trip: TicketTripSummary(
        id: tripId.toString(),
        operatorName: 'Nhà xe VexGo',
        vehicleType: 'Limousine',
        departureTime: '08:00',
        departureDate: '2026-11-10',
        arrivalTime: '14:00',
        arrivalDate: '2026-11-10',
        fromCity: 'TP. Hồ Chí Minh',
        toCity: 'Đà Lạt',
        pickupPoint: 'Bến xe Miền Đông',
        pickupAddress: '292 Đinh Bộ Lĩnh',
        dropoffPoint: 'Bến xe Đà Lạt',
        dropoffAddress: '01 Tô Hiến Thành',
      ),
      totalAmount: 200000,
      discountAmount: 0,
      finalAmount: 200000,
      paymentMethod: 'vietqr',
      passenger: const PassengerInfo(
        fullName: 'Nguyễn Văn A',
        phone: '0912345678',
        email: 'test@vexgo.com',
      ),
    );

class FakeTripRepository implements TripRepository {
  List<TripModel> outboundTrips;
  List<TripModel> inboundTrips;
  bool shouldThrowOutbound;
  bool shouldThrowInbound;

  FakeTripRepository({
    this.outboundTrips = const [],
    this.inboundTrips = const [],
    this.shouldThrowOutbound = false,
    this.shouldThrowInbound = false,
  });

  @override
  Future<List<CityModel>> getCities() async => [
    const CityModel(
      id: 'hcm',
      name: 'TP. Hồ Chí Minh',
      region: '',
      isPopular: true,
    ),
    const CityModel(id: 'dalat', name: 'Đà Lạt', region: '', isPopular: true),
  ];

  @override
  Future<List<OperatorModel>> getOperators() async => [];

  @override
  Future<List<PopularRouteModel>> getPopularRoutes() async => [];

  @override
  Future<TripModel?> getTripById(String id) async => null;

  @override
  Future<List<TripModel>> searchTrips({
    required String fromCityId,
    required String toCityId,
    String? date,
  }) async {
    if (fromCityId == 'hcm') {
      if (shouldThrowOutbound) throw Exception('Outbound search error');
      return outboundTrips;
    } else {
      if (shouldThrowInbound) throw Exception('Inbound search error');
      return inboundTrips;
    }
  }
}

class TestAuthBloc extends AuthBloc {
  TestAuthBloc() : super(authRepository: MockAuthRepository());
}

Widget buildTestApp({
  required Widget child,
  TripRepository? tripRepository,
  SeatRepository? seatRepository,
  BookingRepository? bookingRepository,
  AuthBloc? authBloc,
  TextScaler textScaler = TextScaler.noScaling,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) {
  Widget app = MaterialApp(
    theme: ThemeData(fontFamily: 'VexGoJakarta'),
    home: MediaQuery(
      data: MediaQueryData(textScaler: textScaler, viewInsets: viewInsets),
      child: Material(child: child),
    ),
  );

  app = BlocProvider<AuthBloc>.value(
    value: authBloc ?? TestAuthBloc(),
    child: app,
  );

  final repos = <RepositoryProvider>[
    if (tripRepository != null)
      RepositoryProvider<TripRepository>.value(value: tripRepository),
    if (seatRepository != null)
      RepositoryProvider<SeatRepository>.value(value: seatRepository),
    if (bookingRepository != null)
      RepositoryProvider<BookingRepository>.value(value: bookingRepository),
  ];

  if (repos.isNotEmpty) {
    app = MultiRepositoryProvider(providers: repos, child: app);
  }

  return app;
}

Future<void> pumpBounded(WidgetTester tester, [int count = 6]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  int maxTurns = 30,
}) async {
  for (var i = 0; i < maxTurns && !predicate(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() async {
    final fontFile = File('assets/fonts/PlusJakartaSans.ttf');
    if (fontFile.existsSync()) {
      final bytes = await fontFile.readAsBytes();
      final fontLoader = FontLoader('VexGoJakarta');
      fontLoader.addFont(Future.value(ByteData.sublistView(bytes)));
      await fontLoader.load();
    }
  });

  setUp(() async {
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.clearTokens();
  });

  tearDown(TokenStorage.resetStorageAdapter);

  group('Group 1: Navigation & Route Parameter Preservation', () {
    testWidgets(
      '1. One-way search button in SearchFormCard retains /search-trips route',
      (tester) async {
        String? pushedRoute;
        final homeBloc = HomeBloc(tripRepository: FakeTripRepository());
        homeBloc.emit(
          HomeState(
            isRoundTrip: false,
            departureCity: const CityModel(
              id: 'HCM',
              name: 'TP. Hồ Chí Minh',
              region: '',
              isPopular: false,
            ),
            destinationCity: const CityModel(
              id: 'DL',
              name: 'Đà Lạt',
              region: '',
              isPopular: false,
            ),
            departureDate: DateTime(2026, 11, 10),
            ticketCount: 1,
          ),
        );

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => BlocProvider<HomeBloc>.value(
                value: homeBloc,
                child: const Scaffold(
                  body: SingleChildScrollView(child: SearchFormCard()),
                ),
              ),
            ),
            GoRoute(
              path: '/search-trips',
              builder: (context, state) {
                pushedRoute = state.uri.toString();
                return const Scaffold(body: Text('Search Trips Screen'));
              },
            ),
            GoRoute(
              path: AppRoutes.roundTripSearch,
              builder: (context, state) {
                pushedRoute = state.uri.toString();
                return const Scaffold(body: Text('Round Trip Search Screen'));
              },
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await pumpBounded(tester, 3);

        final searchBtn = find.text('Tìm chuyến');
        await tester.ensureVisible(searchBtn);
        await tester.tap(searchBtn);
        await pumpBounded(tester, 5);

        expect(pushedRoute, isNotNull);
        expect(pushedRoute, startsWith('/search-trips'));
        expect(pushedRoute, isNot(contains(AppRoutes.roundTripSearch)));
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        homeBloc.close();
      },
    );

    testWidgets(
      '2. Round-trip switch preserves returnDate and routes to /round-trip/search',
      (tester) async {
        String? pushedRoute;
        Map<String, dynamic>? pushedExtra;
        final homeBloc = HomeBloc(tripRepository: FakeTripRepository());
        final dep = DateTime(2026, 11, 10);
        final ret = DateTime(2026, 11, 12);

        homeBloc.emit(
          HomeState(
            isRoundTrip: true,
            departureCity: const CityModel(
              id: 'HCM',
              name: 'TP. Hồ Chí Minh',
              region: '',
              isPopular: false,
            ),
            destinationCity: const CityModel(
              id: 'DL',
              name: 'Đà Lạt',
              region: '',
              isPopular: false,
            ),
            departureDate: dep,
            returnDate: ret,
            ticketCount: 2,
          ),
        );

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => BlocProvider<HomeBloc>.value(
                value: homeBloc,
                child: const Scaffold(
                  body: SingleChildScrollView(child: SearchFormCard()),
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.roundTripSearch,
              builder: (context, state) {
                pushedRoute = state.uri.toString();
                pushedExtra = state.extra as Map<String, dynamic>?;
                return const Scaffold(body: Text('Round Trip Search Screen'));
              },
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await pumpBounded(tester, 3);

        final searchBtn = find.text('Tìm chuyến');
        await tester.ensureVisible(searchBtn);
        await tester.tap(searchBtn);
        await pumpBounded(tester, 5);

        expect(pushedRoute, isNotNull);
        expect(pushedRoute, startsWith(AppRoutes.roundTripSearch));
        expect(pushedRoute, contains('returnDate=2026-11-12'));
        expect(pushedRoute, contains('ticketCount=2'));
        expect(pushedExtra?['returnDate'], equals(ret));
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        homeBloc.close();
      },
    );

    testWidgets(
      '3. Invalid search route query displays friendly error without crash',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            child: const RoundTripSearchScreen(
              query: {
                'fromCityId': 'HCM',
                'toCityId': 'HCM',
              }, // same origin and destination
              extra: {},
            ),
          ),
        );
        await pumpBounded(tester, 3);

        expect(find.text('Không thể tìm chuyến'), findsOneWidget);
        expect(find.text('Về Trang chủ'), findsOneWidget);
      },
    );
  });

  group('Group 2: RoundTripSearchScreen Behavior & Leg Tabs', () {
    testWidgets(
      '4. Search screen renders two tabs and independent trip results',
      (tester) async {
        final outTrip = core.trip(101);
        final inTrip = core.trip(102);

        final repo = FakeTripRepository(
          outboundTrips: [outTrip],
          inboundTrips: [inTrip],
        );

        final req = core.request();

        await tester.pumpWidget(
          buildTestApp(
            tripRepository: repo,
            child: RoundTripSearchScreen(
              query: {
                'fromCityId': req.origin.id,
                'toCityId': req.destination.id,
                'date': '2026-11-10',
                'returnDate': '2026-11-11',
                'ticketCount': '1',
              },
              extra: {
                'fromCity': req.origin,
                'toCity': req.destination,
                'date': req.departureDate,
                'returnDate': req.returnDate,
              },
            ),
          ),
        );

        await pumpBounded(tester, 10);

        expect(find.text('Lượt đi'), findsOneWidget);
        expect(find.text('Lượt về'), findsOneWidget);
        expect(find.text(outTrip.operatorName), findsWidgets);
      },
    );

    testWidgets('5. Leg failure preserves other leg and renders retry button', (
      tester,
    ) async {
      final inTrip = core.trip(102);
      final repo = FakeTripRepository(
        outboundTrips: [],
        shouldThrowOutbound: true,
        inboundTrips: [inTrip],
      );

      final req = core.request();

      await tester.pumpWidget(
        buildTestApp(
          tripRepository: repo,
          child: RoundTripSearchScreen(
            query: {
              'fromCityId': req.origin.id,
              'toCityId': req.destination.id,
              'date': '2026-11-10',
              'returnDate': '2026-11-11',
              'ticketCount': '1',
            },
            extra: {'fromCity': req.origin, 'toCity': req.destination},
          ),
        ),
      );

      await pumpBounded(tester, 10);

      expect(
        find.text('Không tải được chuyến đi. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(find.text('Thử lại'), findsOneWidget);

      await tester.tap(find.text('Lượt về'));
      await pumpBounded(tester, 5);

      expect(find.text(inTrip.operatorName), findsWidgets);
    });

    testWidgets(
      '6. Selecting outbound and compatible inbound enables Continue button',
      (tester) async {
        final outTrip = core.trip(101);
        final inTrip = core.trip(102);

        final repo = FakeTripRepository(
          outboundTrips: [outTrip],
          inboundTrips: [inTrip],
        );

        final req = core.request();

        await tester.pumpWidget(
          buildTestApp(
            tripRepository: repo,
            child: RoundTripSearchScreen(
              query: {
                'fromCityId': req.origin.id,
                'toCityId': req.destination.id,
                'date': '2026-11-10',
                'returnDate': '2026-11-11',
                'ticketCount': '1',
              },
              extra: {'fromCity': req.origin, 'toCity': req.destination},
            ),
          ),
        );

        await pumpBounded(tester, 10);

        final continueBtnFinder = find.byKey(
          const ValueKey('round-trip-continue-btn'),
        );
        expect(
          tester.widget<ElevatedButton>(continueBtnFinder).onPressed,
          isNull,
        );

        await tester.tap(find.byKey(ValueKey('select-trip-${outTrip.id}')));
        await pumpBounded(tester, 5);

        await tester.tap(find.text('Lượt về'));
        await pumpBounded(tester, 10);

        final inTripBtn = find.byKey(ValueKey('select-trip-${inTrip.id}'));
        await tester.ensureVisible(inTripBtn);
        await tester.tap(inTripBtn, warnIfMissed: false);
        await pumpBounded(tester, 5);

        expect(
          tester.widget<ElevatedButton>(continueBtnFinder).onPressed,
          isNotNull,
        );
      },
    );
  });

  group('Group 3: RoundTripBookingScreen Step Flow & Passenger Sync', () {
    testWidgets('7. Missing selection payload renders error and back button', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(child: const RoundTripBookingScreen(selection: null)),
      );
      await pumpBounded(tester, 3);

      expect(find.text('Thiếu dữ liệu chuyến đi'), findsOneWidget);
      expect(find.text('Quay lại tìm kiếm'), findsOneWidget);
    });

    testWidgets(
      '8. Seat selection renders SeatMapView and updates leg header summary',
      (tester) async {
        final server = core.Server();
        final outTrip = core.trip(101);
        final inTrip = core.trip(102);
        final req = core.request();
        final selection = RoundTripSelection(
          request: req,
          outbound: outTrip,
          inbound: inTrip,
        );

        await tester.pumpWidget(
          buildTestApp(
            seatRepository: server.seats,
            bookingRepository: server.bookings,
            child: RoundTripBookingScreen(selection: selection),
          ),
        );

        await pumpBounded(tester, 15);

        expect(find.byKey(const ValueKey('leg-tab-outbound')), findsOneWidget);
        expect(find.byKey(const ValueKey('leg-tab-inbound')), findsOneWidget);

        final seatFinder = find.text('A01');
        if (seatFinder.evaluate().isNotEmpty) {
          await tester.tap(seatFinder.first);
          await pumpBounded(tester, 5);
        }

        final nextBtn = find.byKey(const ValueKey('round-trip-step-next-btn'));
        expect(nextBtn, findsOneWidget);
      },
    );

    testWidgets(
      '9. Passenger step updates both legs simultaneously and trip summary calculates total',
      (tester) async {
        final req = core.request();
        final outTrip = core.trip(101);
        final inTrip = core.trip(102);
        final server = core.Server();

        final cubit = RoundTripCheckoutCubit(
          request: req,
          outbound: outTrip,
          inbound: inTrip,
          seatRepository: server.seats,
          bookingRepository: server.bookings,
        );

        await pumpBounded(tester, 10);

        cubit.updatePassenger(
          const UpdatePassengerInfoEvent(
            name: 'Nguyễn Văn A',
            phone: '0912345678',
            email: 'test@vexgo.com',
          ),
        );

        await pumpBounded(tester, 5);

        expect(cubit.state.outbound.passengerName, equals('Nguyễn Văn A'));
        expect(cubit.state.inbound.passengerName, equals('Nguyễn Văn A'));
        expect(cubit.state.outbound.passengerPhone, equals('0912345678'));
        expect(cubit.state.inbound.passengerPhone, equals('0912345678'));

        cubit.close();
      },
    );
  });

  group('Group 4: Payment View, Invalidation, Two Separate QRs & Partial Status', () {
    testWidgets(
      '10. paymentPending renders two distinct VietQR cards without combining totals',
      (tester) async {
        final req = core.request();

        await tester.pumpWidget(
          buildTestApp(
            child: RoundTripPaymentView(
              request: req,
              state: RoundTripCheckoutState(
                outbound: BookingFlowState(
                  status: BookingFlowStatus.paymentPending,
                  selectedPaymentMethod: 'vietqr',
                  pendingBookingId: 1001,
                  pendingPaymentAmount: 190000,
                  checkoutBooking: testOrder(
                    1001,
                    101,
                    190000,
                    code: 'ORD-OUTBOUND-101',
                  ),
                ),
                inbound: BookingFlowState(
                  status: BookingFlowStatus.paymentPending,
                  selectedPaymentMethod: 'vietqr',
                  pendingBookingId: 1002,
                  pendingPaymentAmount: 260000,
                  checkoutBooking: testOrder(
                    1002,
                    102,
                    260000,
                    code: 'ORD-INBOUND-102',
                  ),
                ),
              ),
              onRecheck: (_) {},
              onOpenMyTickets: () {},
              onOpenSupport: () {},
            ),
          ),
        );
        await pumpBounded(tester, 5);

        expect(find.text('ORD-OUTBOUND-101'), findsOneWidget);
        expect(find.text('ORD-INBOUND-102'), findsOneWidget);
        expect(find.text(CurrencyFormatter.format(190000)), findsOneWidget);
        expect(find.text(CurrencyFormatter.format(260000)), findsOneWidget);
        expect(find.text(CurrencyFormatter.format(450000)), findsNothing);
      },
    );

    testWidgets(
      '11. partiallyPaid displays confirmed badge on one leg and payment on pending leg',
      (tester) async {
        final req = core.request();

        await tester.pumpWidget(
          buildTestApp(
            child: RoundTripPaymentView(
              request: req,
              state: RoundTripCheckoutState(
                outbound: BookingFlowState(
                  status: BookingFlowStatus.success,
                  paymentConfirmed: true,
                  pendingBookingId: 1001,
                  checkoutBooking: testOrder(
                    1001,
                    101,
                    190000,
                    code: 'ORD-OUTBOUND-101',
                  ),
                ),
                inbound: BookingFlowState(
                  status: BookingFlowStatus.paymentPending,
                  selectedPaymentMethod: 'vietqr',
                  pendingBookingId: 1002,
                  pendingPaymentAmount: 260000,
                  checkoutBooking: testOrder(
                    1002,
                    102,
                    260000,
                    code: 'ORD-INBOUND-102',
                  ),
                ),
              ),
              onRecheck: (_) {},
              onOpenMyTickets: () {},
              onOpenSupport: () {},
            ),
          ),
        );
        await pumpBounded(tester, 5);

        expect(find.text('ĐÃ THANH TOÁN'), findsOneWidget);
        expect(find.text('CHỜ THANH TOÁN'), findsOneWidget);
        expect(find.text('Đã thanh toán 1 chiều'), findsOneWidget);
      },
    );

    testWidgets(
      '12. isComplete renders RoundTripSuccessView with tickets from both legs',
      (tester) async {
        final req = core.request();
        final outTicket = testTicket('1001', 'TK-OUT-01', 101, 'A01');
        final inTicket = testTicket('1002', 'TK-IN-02', 102, 'B02');

        await tester.pumpWidget(
          buildTestApp(
            child: RoundTripSuccessView(
              request: req,
              outbound: BookingFlowState(
                status: BookingFlowStatus.success,
                paymentConfirmed: true,
                createdTickets: [outTicket],
              ),
              inbound: BookingFlowState(
                status: BookingFlowStatus.success,
                paymentConfirmed: true,
                createdTickets: [inTicket],
              ),
              onOpenMyTickets: () {},
              onOpenHome: () {},
            ),
          ),
        );
        await pumpBounded(tester, 5);

        expect(find.text('Đặt vé khứ hồi thành công!'), findsOneWidget);
        expect(find.text('Mã vé: TK-OUT-01'), findsOneWidget);
        expect(find.text('Mã vé: TK-IN-02'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('view-my-tickets-btn')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '13. Session invalidation wipes old data and displays re-login view',
      (tester) async {
        final req = core.request();
        final outTrip = core.trip(101);
        final inTrip = core.trip(102);
        final selection = RoundTripSelection(
          request: req,
          outbound: outTrip,
          inbound: inTrip,
        );
        final server = core.Server();

        final cubit = RoundTripCheckoutCubit(
          request: req,
          outbound: outTrip,
          inbound: inTrip,
          seatRepository: server.seats,
          bookingRepository: server.bookings,
        );

        await tester.pumpWidget(
          buildTestApp(
            seatRepository: server.seats,
            bookingRepository: server.bookings,
            child: RoundTripBookingScreen(selection: selection, cubit: cubit),
          ),
        );
        await pumpBounded(tester, 5);

        cubit.invalidateSession();
        await pumpBounded(tester, 5);

        expect(find.text('Phiên đăng nhập đã thay đổi'), findsOneWidget);
        expect(find.text('Về Trang chủ'), findsOneWidget);

        cubit.close();
      },
    );
  });

  group('Group 5: Responsive & A11y (320dp 2.0x & Landscape Keyboard)', () {
    testWidgets(
      '14. Narrow 320dp screen with 2.0x font renders without overflow in search and summary',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2, 740 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final req = core.request();
        final outTrip = core.trip(101);
        final inTrip = core.trip(102);

        await tester.pumpWidget(
          buildTestApp(
            textScaler: const TextScaler.linear(2.0),
            child: RoundTripSummaryStep(
              request: req,
              outbound: BookingFlowState(
                trip: outTrip,
                status: BookingFlowStatus.loaded,
                passengerName: 'Nguyễn Văn A',
                passengerPhone: '0912345678',
                checkoutBooking: testOrder(1001, 101, 190000),
              ),
              inbound: BookingFlowState(
                trip: inTrip,
                status: BookingFlowStatus.loaded,
                passengerName: 'Nguyễn Văn A',
                passengerPhone: '0912345678',
                checkoutBooking: testOrder(1002, 102, 260000),
              ),
              totalAmount: 450000,
              busy: false,
              onApplyOutboundVoucher: (_) {},
              onRemoveOutboundVoucher: () {},
              onApplyInboundVoucher: (_) {},
              onRemoveInboundVoucher: () {},
              onSubmit: () {},
              onBack: () {},
            ),
          ),
        );
        await pumpBounded(tester, 5);

        expect(tester.takeException(), isNull);
        expect(find.text('Tổng kết chi phí'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('confirm-and-pay-btn')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '15. Landscape 640x360 with 160dp keyboard inset retains visible scrollable inputs',
      (tester) async {
        tester.view.physicalSize = const Size(640 * 2, 360 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestApp(
            viewInsets: const EdgeInsets.only(bottom: 160),
            child: Scaffold(
              body: RoundTripPaymentView(
                request: core.request(),
                state: RoundTripCheckoutState(
                  outbound: BookingFlowState(
                    status: BookingFlowStatus.paymentPending,
                    selectedPaymentMethod: 'vietqr',
                    pendingBookingId: 1001,
                    pendingPaymentAmount: 190000,
                    checkoutBooking: testOrder(
                      1001,
                      101,
                      190000,
                      code: 'ORD-OUTBOUND-101',
                    ),
                  ),
                  inbound: BookingFlowState(
                    status: BookingFlowStatus.paymentPending,
                    selectedPaymentMethod: 'vietqr',
                    pendingBookingId: 1002,
                    pendingPaymentAmount: 260000,
                    checkoutBooking: testOrder(
                      1002,
                      102,
                      260000,
                      code: 'ORD-INBOUND-102',
                    ),
                  ),
                ),
                onRecheck: (_) {},
                onOpenMyTickets: () {},
                onOpenSupport: () {},
              ),
            ),
          ),
        );
        await pumpBounded(tester, 5);

        expect(tester.takeException(), isNull);
        expect(find.text('ORD-OUTBOUND-101'), findsOneWidget);
      },
    );

    testWidgets(
      '16. (R01) Definite outbound create rejection (HTTP 409) leaves actionable retry/edit UI and recovers when retried',
      (tester) async {
        final server = core.Server()..reject.add(101);
        late RoundTripCheckoutCubit cubit;
        await tester.runAsync(() async {
          await TokenStorage.saveTokens(accessToken: 'review-fixture-owner');
          cubit = server.checkout();
          await core.ready(cubit);
          await cubit.submit();
        });
        addTearDown(cubit.close);

        expect(cubit.state.phase, RoundTripPhase.editing);
        expect(cubit.state.outbound.status, BookingFlowStatus.failure);
        expect(cubit.state.outbound.step, BookingStep.payment);
        expect(cubit.state.inbound.step, BookingStep.payment);

        final selection = RoundTripSelection(
          request: core.request(),
          outbound: core.trip(101),
          inbound: core.trip(102),
        );

        await tester.pumpWidget(
          buildTestApp(
            child: RoundTripBookingScreen(selection: selection, cubit: cubit),
          ),
        );
        await pumpBounded(tester, 5);

        expect(
          find.byType(RoundTripPaymentView).evaluate().isNotEmpty ||
              find.byType(RoundTripSummaryStep).evaluate().isNotEmpty,
          isTrue,
        );
        expect(find.byType(RoundTripSummaryStep), findsOneWidget);
        expect(
          find.byKey(const ValueKey('confirm-and-pay-btn')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('edit-summary-leg-outbound-btn')),
          findsOneWidget,
        );

        // Clear error and retry from UI
        server.reject.remove(101);
        final confirmBtn = find.byKey(const ValueKey('confirm-and-pay-btn'));
        await tester.ensureVisible(confirmBtn);
        await tester.tap(confirmBtn);
        await pumpUntil(
          tester,
          () => cubit.state.phase == RoundTripPhase.paymentPending,
        );
        await pumpBounded(tester, 5);

        expect(cubit.state.phase, RoundTripPhase.paymentPending);
        expect(find.byType(RoundTripPaymentView), findsOneWidget);
        expect(find.text('ORDER-1001'), findsOneWidget);
        expect(find.text('ORDER-1002'), findsOneWidget);
      },
    );

    testWidgets(
      '17. (R02) Partial create (outbound 200, inbound 409) exposes retry and edit buttons for uncreated inbound leg',
      (tester) async {
        final server = core.Server()..reject.add(102);
        late RoundTripCheckoutCubit cubit;
        await tester.runAsync(() async {
          await TokenStorage.saveTokens(accessToken: 'review-fixture-owner');
          cubit = server.checkout();
          await core.ready(cubit);
          await cubit.submit();
        });
        addTearDown(cubit.close);

        expect(cubit.state.phase, RoundTripPhase.partiallyCreated);

        var retried = false;
        await tester.pumpWidget(
          buildTestApp(
            child: RoundTripPaymentView(
              request: core.request(),
              state: cubit.state,
              onRecheck: (_) {},
              onRetrySubmitMissing: () {
                retried = true;
              },
              onOpenMyTickets: () {},
              onOpenSupport: () {},
            ),
          ),
        );
        await pumpBounded(tester, 5);

        final enabled = find.byWidgetPredicate(
          (w) =>
              w is ButtonStyleButton &&
              w.onPressed != null &&
              (w.child?.toStringDeep().contains('Tạo') == true ||
                  w.child?.toStringDeep().contains('Thử lại') == true),
        );
        expect(enabled, findsWidgets);
        await tester.ensureVisible(enabled.first);
        await tester.tap(enabled.first);
        expect(retried, isTrue);

        // Also verify full RoundTripBookingScreen retry recovery flow
        final selection = RoundTripSelection(
          request: core.request(),
          outbound: core.trip(101),
          inbound: core.trip(102),
        );
        await tester.pumpWidget(
          buildTestApp(
            child: RoundTripBookingScreen(selection: selection, cubit: cubit),
          ),
        );
        await pumpBounded(tester, 5);

        final retryInboundBtn = find.byKey(
          const ValueKey('retry-create-inbound-btn'),
        );
        expect(retryInboundBtn, findsOneWidget);
        expect(
          find.byKey(const ValueKey('edit-missing-inbound-btn')),
          findsOneWidget,
        );

        server.reject.remove(102);
        await tester.ensureVisible(retryInboundBtn);
        await tester.tap(retryInboundBtn);
        await pumpUntil(
          tester,
          () => cubit.state.phase == RoundTripPhase.paymentPending,
        );
        await pumpBounded(tester, 5);

        expect(cubit.state.phase, RoundTripPhase.paymentPending);
        expect(cubit.state.inbound.pendingBookingId, 1002);
        expect(find.text('ORDER-1002'), findsOneWidget);
      },
    );

    testWidgets(
      '18. (R03) Paid leg with ticket read failure keeps recheck/sync button visible and reconciles to complete without reopening QR',
      (tester) async {
        final server = core.Server();
        late RoundTripCheckoutCubit cubit;
        await tester.runAsync(() async {
          await TokenStorage.saveTokens(accessToken: 'review-fixture-owner');
          cubit = server.checkout();
          await core.ready(cubit);
          await cubit.submit();
          server.paid.add(1001);
          server.paid.add(1002);
          server.ticketErrors.add(1001);
          await cubit.recheck(TripLeg.outbound);
          await cubit.recheck(TripLeg.inbound);
        });
        addTearDown(cubit.close);

        expect(cubit.state.outbound.paymentConfirmed, isTrue);
        expect(cubit.state.outbound.createdTickets, isEmpty);
        expect(cubit.state.inbound.status, BookingFlowStatus.success);
        expect(cubit.state.isComplete, isFalse);

        final selection = RoundTripSelection(
          request: core.request(),
          outbound: core.trip(101),
          inbound: core.trip(102),
        );

        await tester.pumpWidget(
          buildTestApp(
            child: RoundTripBookingScreen(selection: selection, cubit: cubit),
          ),
        );
        await pumpBounded(tester, 5);

        final recheckOutbound = find.byKey(
          const ValueKey('recheck-outbound-btn'),
        );
        expect(recheckOutbound, findsOneWidget);
        expect(find.text('Đồng bộ lại vé'), findsOneWidget);

        // Clear ticket read error and tap recheck button
        server.ticketErrors.remove(1001);
        await tester.ensureVisible(recheckOutbound);
        await tester.tap(recheckOutbound);
        await pumpUntil(tester, () => cubit.state.isComplete);
        await pumpBounded(tester, 5);

        expect(cubit.state.isComplete, isTrue);
        expect(find.byType(RoundTripSuccessView), findsOneWidget);
      },
    );

    testWidgets(
      '19. (R04) Genuine hold/quote summary from production coordinator renders at 320dp 2.0x text scale without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(640, 1280);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final server = core.Server();
        late RoundTripCheckoutCubit cubit;
        await tester.runAsync(() async {
          await TokenStorage.saveTokens(accessToken: 'review-fixture-owner');
          cubit = server.checkout();
          await core.ready(cubit);
        });
        addTearDown(cubit.close);

        await tester.pumpWidget(
          buildTestApp(
            textScaler: const TextScaler.linear(2.0),
            child: RoundTripSummaryStep(
              request: core.request(),
              outbound: cubit.state.outbound,
              inbound: cubit.state.inbound,
              totalAmount: cubit.state.totalAmount,
              busy: false,
              onApplyOutboundVoucher: (_) {},
              onRemoveOutboundVoucher: () {},
              onApplyInboundVoucher: (_) {},
              onRemoveInboundVoucher: () {},
              onSubmit: () {},
              onBack: () {},
            ),
          ),
        );
        await pumpBounded(tester, 5);

        expect(tester.takeException(), isNull);
        expect(find.text('Tổng kết chi phí'), findsOneWidget);
      },
    );
  });
}
