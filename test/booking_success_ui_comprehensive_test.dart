import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/features/user/booking/presentation/screens/booking_success_screen.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';
import 'qa/qa_fixtures.dart';

class _EventTracker extends BlocObserver {
  final List<dynamic> events = [];
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    events.add(event);
  }
}

TicketModel createTicket({
  required String id,
  required String code,
  required String seat,
  bool isPaid = true,
  TicketStatus status = TicketStatus.upcoming,
  int price = 250000,
}) {
  return TicketModel(
    id: id,
    ticketCode: code,
    bookingId: 888,
    bookingCode: 'BOOKING-888',
    status: status,
    bookingStatus: isPaid ? 'DA_THANH_TOAN' : 'CHO_THANH_TOAN',
    paymentStatus: isPaid ? 'DA_THANH_TOAN' : 'CHO_THANH_TOAN',
    rawStatus: isPaid ? 'DA_THANH_TOAN' : 'CHO_THANH_TOAN',
    bookingDate: '27/10/2026 14:00',
    trip: qaSummary,
    seats: [seat],
    totalAmount: price,
    discountAmount: 0,
    finalAmount: price,
    paymentMethod: 'VEXGO_PAY',
    passenger: qaPassenger,
  );
}

void main() {
  setUpAll(() async {
    final fontFile = File('assets/fonts/PlusJakartaSans.ttf');
    if (fontFile.existsSync()) {
      final bytes = fontFile.readAsBytesSync();
      final fontLoader = FontLoader('VexGoJakarta')
        ..addFont(Future.value(ByteData.view(bytes.buffer)));
      await fontLoader.load();
    }
  });

  setUp(() {
    ApiConfig.isDemoMode = false;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('BookingSuccessScreen Comprehensive Regression Tests', () {
    testWidgets(
      'Multi-ticket (5 tickets) shows all seats, unique QRs, and no duplicate codes',
      (tester) async {
        final tickets = List.generate(5, (index) {
          final num = (index + 1).toString().padLeft(2, '0');
          return createTicket(
            id: '10$num',
            code: 'VG-20261027-TK$num',
            seat: 'A$num',
          );
        });

        final owner = MyTicketsBloc(
          authenticated: false,
          bookingRepository: MockBookingRepository(),
        )..setSession(null);
        addTearDown(owner.close);

        await tester.pumpWidget(
          BlocProvider.value(
            value: owner,
            child: MaterialApp(
              home: BookingSuccessScreen(
                ticket: tickets.first,
                tickets: tickets,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // 5 distinct QR codes
        final qrFinders = find.byType(QrImageView);
        expect(qrFinders, findsNWidgets(5));

        // Verify each ticket's distinct code and seat is displayed
        for (int i = 0; i < 5; i++) {
          expect(
            find.text(
              '${tickets[i].ticketCode} • ${tickets[i].seats.join(', ')}',
            ),
            findsOneWidget,
          );
        }

        // Summary card aggregates all seats
        expect(find.text('A01, A02, A03, A04, A05'), findsOneWidget);
        expect(find.text('5 vé'), findsOneWidget);
      },
    );

    testWidgets(
      'Ticket without QR authorization (e.g. cancelled) does NOT render QR',
      (tester) async {
        final cancelledTicket = createTicket(
          id: '99',
          code: 'VG-CANCELLED-99',
          seat: 'B01',
          status: TicketStatus.cancelled,
          isPaid: false,
        );
        expect(cancelledTicket.canShowQr, isFalse);

        final owner = MyTicketsBloc(
          authenticated: false,
          bookingRepository: MockBookingRepository(),
        )..setSession(null);
        addTearDown(owner.close);

        await tester.pumpWidget(
          BlocProvider.value(
            value: owner,
            child: MaterialApp(
              home: BookingSuccessScreen(ticket: cancelledTicket),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(QrImageView), findsNothing);
        expect(
          find.text('Chưa có xác nhận thanh toán để hiển thị mã lên xe.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Navigation callbacks: close, my-tickets, and home route correctly',
      (tester) async {
        final ticket = createTicket(id: '101', code: 'VG-NAV-101', seat: 'A01');

        String currentRoute = '/booking-success';

        final router = GoRouter(
          initialLocation: '/booking-success',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) {
                currentRoute = '/';
                return const Scaffold(body: Text('Trang chủ Mock'));
              },
            ),
            GoRoute(
              path: '/my-tickets',
              builder: (context, state) {
                currentRoute = '/my-tickets';
                return const Scaffold(body: Text('Vé của tôi Mock'));
              },
            ),
            GoRoute(
              path: '/booking-success',
              builder: (context, state) {
                currentRoute = '/booking-success';
                return BookingSuccessScreen(ticket: ticket);
              },
            ),
          ],
        );

        final owner = MyTicketsBloc(
          authenticated: false,
          bookingRepository: MockBookingRepository(),
        )..setSession(null);
        addTearDown(owner.close);

        await tester.pumpWidget(
          BlocProvider.value(
            value: owner,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // Tap close icon button in AppBar
        final closeBtn = find.byTooltip('Về trang chủ');
        expect(closeBtn, findsOneWidget);
        await tester.tap(closeBtn);
        await tester.pumpAndSettle();
        expect(currentRoute, '/');

        // Go back to success screen to test 'Xem vé của tôi'
        router.go('/booking-success');
        await tester.pumpAndSettle();
        expect(currentRoute, '/booking-success');

        final myTicketsBtn = find.text('Xem vé của tôi');
        await tester.ensureVisible(myTicketsBtn);
        await tester.tap(myTicketsBtn);
        await tester.pumpAndSettle();
        expect(currentRoute, '/my-tickets');

        // Go back to success screen to test secondary CTA 'Về trang chủ'
        router.go('/booking-success');
        await tester.pumpAndSettle();

        final homeBtn = find.text('Về trang chủ');
        await tester.ensureVisible(homeBtn);
        await tester.tap(homeBtn);
        await tester.pumpAndSettle();
        expect(currentRoute, '/');
      },
    );

    testWidgets(
      'AddNewTicketEvent is dispatched once post-frame and never on subsequent rebuilds',
      (tester) async {
        final ticket = createTicket(
          id: '55',
          code: 'VG-REBUILD-55',
          seat: 'A05',
        );

        final tracker = _EventTracker();
        Bloc.observer = tracker;

        final owner = MyTicketsBloc(
          authenticated: false,
          bookingRepository: MockBookingRepository(),
        )..setSession(null);
        addTearDown(owner.close);

        await tester.pumpWidget(
          BlocProvider.value(
            value: owner,
            child: MaterialApp(home: BookingSuccessScreen(ticket: ticket)),
          ),
        );
        await tester.pumpAndSettle();

        final initialAddEvents = tracker.events
            .whereType<AddNewTicketEvent>()
            .length;
        expect(initialAddEvents, equals(1));

        // Trigger multiple rebuilds
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Event must NOT be dispatched again
        final afterRebuildEvents = tracker.events
            .whereType<AddNewTicketEvent>()
            .length;
        expect(afterRebuildEvents, equals(1));
      },
    );

    for (final config in [
      {'size': const Size(390, 844), 'scale': 1.0, 'name': '390x844 text 1x'},
      {'size': const Size(320, 740), 'scale': 2.0, 'name': '320x740 text 2x'},
      {
        'size': const Size(640, 360),
        'scale': 2.0,
        'name': '640x360 landscape text 2x',
      },
    ]) {
      testWidgets(
        'Responsive layout (${config['name']}) has no overflow with multiple tickets',
        (tester) async {
          tester.view.physicalSize = config['size'] as Size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final tickets = [
            createTicket(id: '1', code: 'VG-RESP-01', seat: 'A01'),
            createTicket(id: '2', code: 'VG-RESP-02', seat: 'A02'),
          ];

          final owner = MyTicketsBloc(
            authenticated: false,
            bookingRepository: MockBookingRepository(),
          )..setSession(null);
          addTearDown(owner.close);

          await tester.pumpWidget(
            BlocProvider.value(
              value: owner,
              child: MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(config['scale'] as double),
                  ),
                  child: child!,
                ),
                home: BookingSuccessScreen(
                  ticket: tickets.first,
                  tickets: tickets,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(QrImageView), findsNWidgets(2));

          // Ensure bottom CTA is scrollable and visible without exception
          await tester.ensureVisible(find.text('Về trang chủ'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
