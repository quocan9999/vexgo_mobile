import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/data/models/review_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_state.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/screens/my_tickets_screen.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/cancel_ticket_sheet.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/guest_ticket_lookup_panel.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/review_bottom_sheet.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/ticket_summary_card.dart';

class _MockCountingRepo extends MockBookingRepository {
  int getMyTicketsCalls = 0;
  List<TicketModel> mockTickets = [];

  @override
  Future<List<TicketModel>> getMyTickets() async {
    getMyTicketsCalls++;
    return mockTickets;
  }

  @override
  Future<TicketModel> getTicketById(String id) async {
    return mockTickets.firstWhere((t) => t.id == id);
  }

  @override
  Future<TicketModel> lookupTicket({
    required String ticketCode,
    required String phoneNumber,
  }) async {
    return mockTickets.firstWhere((t) => t.ticketCode == ticketCode);
  }

  @override
  Future<Map<String, dynamic>> cancelTicket({
    required String ticketCode,
    required String phoneNumber,
    String? reason,
    required double expectedCancelFeeRate,
  }) async {
    return {'success': true, 'refundAmount': 200000};
  }
}

TicketModel _makeTicket({
  required String id,
  required String code,
  required TicketStatus status,
  required String opName,
  required String from,
  required String to,
  String departureTime = '08:00',
  String departureDate = '20/11/2030',
  String pickupPoint = 'Bến xe Miền Đông',
  List<String> seats = const ['A01'],
  int price = 250000,
  bool isPaid = true,
  bool canCancel = true,
  ReviewModel? review,
  String? cancelReason,
  int? refundAmount,
}) {
  return TicketModel(
    id: id,
    ticketCode: code,
    bookingId: int.tryParse(id) ?? 999,
    bookingCode: 'BOOKING-$id',
    status: status,
    bookingStatus: isPaid ? 'DA_THANH_TOAN' : 'CHO_THANH_TOAN',
    paymentStatus: isPaid ? 'DA_THANH_TOAN' : 'CHO_THANH_TOAN',
    rawStatus: isPaid ? 'DA_THANH_TOAN' : 'CHO_THANH_TOAN',
    bookingDate: '10/10/2026 10:00',
    trip: TicketTripSummary(
      id: 'TRIP-$id',
      operatorName: opName,
      vehicleType: 'Limousine 34 Phòng',
      departureTime: departureTime,
      departureDate: departureDate,
      arrivalTime: '14:00',
      arrivalDate: departureDate,
      fromCity: from,
      toCity: to,
      pickupPoint: pickupPoint,
      pickupAddress: 'Quận Bình Thạnh',
      dropoffPoint: 'Bến xe $to',
      dropoffAddress: 'Trung tâm',
    ),
    seats: seats,
    totalAmount: price,
    discountAmount: 0,
    finalAmount: price,
    paymentMethod: 'VexGo Pay',
    passenger: const PassengerInfo(
      fullName: 'Nguyễn Văn An',
      phone: '0901234567',
      email: 'an@vexgo.vn',
    ),
    cancellation: CancellationQuote(
      eligible: canCancel,
      cancelFeeRate: 0.1,
      cancelFee: (price * 0.1).round(),
      refundAmount: (price * 0.9).round(),
    ),
    review: review,
    cancelReason: cancelReason,
    refundAmount: refundAmount,
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

  group('MyTicketsScreen Comprehensive UI Tests', () {
    late _MockCountingRepo repo;
    late List<TicketModel> testTickets;

    setUp(() {
      repo = _MockCountingRepo();

      testTickets = [
        _makeTicket(
          id: '101',
          code: 'VXG-UP01',
          status: TicketStatus.upcoming,
          opName: 'Phương Trang (FUTA Bus)',
          from: 'TP. Hồ Chí Minh',
          to: 'Đà Lạt',
          seats: ['A01', 'A02'],
          price: 580000,
          isPaid: true,
          canCancel: true,
        ),
        _makeTicket(
          id: '102',
          code: 'VXG-UP02',
          status: TicketStatus.upcoming,
          opName: 'Thành Bưởi Limousine',
          from: 'TP. Hồ Chí Minh',
          to: 'Cần Thơ',
          seats: ['B05'],
          price: 220000,
          isPaid: false,
          canCancel: false,
        ),
        _makeTicket(
          id: '201',
          code: 'VXG-COM01',
          status: TicketStatus.completed,
          opName: 'Phương Trang (FUTA Bus)',
          from: 'Đà Lạt',
          to: 'TP. Hồ Chí Minh',
          seats: ['A03'],
          price: 290000,
          isPaid: true,
          review: null,
        ),
        _makeTicket(
          id: '202',
          code: 'VXG-COM02',
          status: TicketStatus.completed,
          opName: 'Hoa Mai Vũng Tàu',
          from: 'Vũng Tàu',
          to: 'TP. Hồ Chí Minh',
          seats: ['C01'],
          price: 180000,
          isPaid: true,
          review: const ReviewModel(
            rating: 5,
            comment: 'Tài xế lái xe cẩn thận!',
            tags: ['Đúng giờ', 'Sạch sẽ'],
            createdAt: '25/10/2026',
          ),
        ),
        _makeTicket(
          id: '301',
          code: 'VXG-CAN01',
          status: TicketStatus.cancelled,
          opName: 'Phương Trang (FUTA Bus)',
          from: 'TP. Hồ Chí Minh',
          to: 'Nha Trang',
          seats: ['VIP01'],
          price: 350000,
          isPaid: true,
          cancelReason: 'Thay đổi lịch công tác',
          refundAmount: 315000,
        ),
      ];
      repo.mockTickets = testTickets;
    });

    testWidgets(
      '1. Tabs, counts, query filtering & clear, no redundant API calls',
      (tester) async {
        final bloc = MyTicketsBloc(
          bookingRepository: repo,
          authenticated: true,
        );
        addTearDown(bloc.close);

        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: const MaterialApp(home: MyTicketsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Check initial load: 1 call to getMyTickets
        expect(repo.getMyTicketsCalls, equals(1));

        // Check tab counts: Upcoming: 2, Completed: 2, Cancelled: 1
        expect(find.byKey(const Key('tab-upcoming')), findsOneWidget);
        expect(find.byKey(const Key('tab-completed')), findsOneWidget);
        expect(find.byKey(const Key('tab-cancelled')), findsOneWidget);
        expect(
          find.text('2'),
          findsNWidgets(2),
        ); // For Upcoming (2) and Completed (2)
        expect(find.text('1'), findsOneWidget); // For Cancelled (1)

        // Initial tab is upcoming: both upcoming tickets visible
        expect(find.text('VXG-UP01'), findsOneWidget);
        expect(find.text('VXG-UP02'), findsOneWidget);
        expect(find.text('VXG-COM01'), findsNothing);

        // Search locally for "UP02"
        await tester.enterText(find.byType(TextField), 'UP02');
        await tester.pumpAndSettle();

        expect(find.text('VXG-UP02'), findsOneWidget);
        expect(find.text('VXG-UP01'), findsNothing);
        // Verify local search did NOT trigger another API call
        expect(repo.getMyTicketsCalls, equals(1));

        // Tap clear button in search bar
        await tester.tap(find.byTooltip('Xóa tìm kiếm'));
        await tester.pumpAndSettle();

        // Both tickets return
        expect(find.text('VXG-UP01'), findsOneWidget);
        expect(find.text('VXG-UP02'), findsOneWidget);
        expect(repo.getMyTicketsCalls, equals(1));

        // Switch to "Đã đi" tab
        await tester.tap(find.byKey(const Key('tab-completed')));
        await tester.pumpAndSettle();

        expect(find.text('VXG-COM01'), findsOneWidget);
        expect(find.text('VXG-COM02'), findsOneWidget);
        expect(find.text('VXG-UP01'), findsNothing);
        expect(repo.getMyTicketsCalls, equals(1));

        // Switch to "Đã hủy" tab
        await tester.tap(find.byKey(const Key('tab-cancelled')));
        await tester.pumpAndSettle();

        expect(find.text('VXG-CAN01'), findsOneWidget);
        expect(
          find.textContaining('Lý do: Thay đổi lịch công tác'),
          findsOneWidget,
        );
        expect(find.textContaining('Hoàn: 315.000'), findsOneWidget);
        expect(repo.getMyTicketsCalls, equals(1));
      },
    );

    testWidgets(
      '2. Card tap routes to exact ticket detail; cancel/review do not trigger card tap',
      (tester) async {
        final bloc = MyTicketsBloc(
          bookingRepository: repo,
          authenticated: true,
        );
        addTearDown(bloc.close);

        TicketModel? navigatedTicket;
        final router = GoRouter(
          initialLocation: '/my-tickets',
          routes: [
            GoRoute(
              path: '/my-tickets',
              builder: (context, state) => const MyTicketsScreen(),
            ),
            GoRoute(
              path: '/ticket-detail',
              builder: (context, state) {
                navigatedTicket = state.extra as TicketModel?;
                return const Scaffold(body: Text('Ticket Detail Destination'));
              },
            ),
            GoRoute(
              path: '/search-trips',
              builder: (context, state) =>
                  const Scaffold(body: Text('Search Trips')),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) =>
                  const Scaffold(body: Text('Profile')),
            ),
          ],
        );

        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the second card's detail CTA
        final viewDetailBtns = find.widgetWithText(
          ElevatedButton,
          'Xem chi tiết',
        );
        expect(viewDetailBtns, findsWidgets);

        // Scroll down in list to bring VXG-UP02 into view, then tap it
        await tester.drag(find.byType(ListView), const Offset(0, -250));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('ticket-card-VXG-UP02')));
        await tester.pumpAndSettle();

        expect(navigatedTicket, isNotNull);
        expect(navigatedTicket!.id, equals('102'));
        expect(navigatedTicket!.ticketCode, equals('VXG-UP02'));

        // Pop back to /my-tickets
        router.pop();
        await tester.pumpAndSettle();
        navigatedTicket = null;

        // On VXG-UP01, tap "Hủy vé" button
        expect(find.text('Hủy vé'), findsOneWidget);
        await tester.tap(find.text('Hủy vé'));
        await tester.pumpAndSettle();

        // CancelTicketSheet bottom sheet should open
        expect(find.byType(CancelTicketSheet), findsOneWidget);
        // Card onTap must NOT have fired!
        expect(navigatedTicket, isNull);

        // Dismiss sheet
        Navigator.of(router.routerDelegate.navigatorKey.currentContext!).pop();
        await tester.pumpAndSettle();

        // Switch to "Đã đi" tab
        await tester.tap(find.byKey(const Key('tab-completed')));
        await tester.pumpAndSettle();

        // Tap "Đánh giá" on completed ticket without review
        expect(find.text('Đánh giá'), findsOneWidget);
        await tester.tap(find.text('Đánh giá'));
        await tester.pumpAndSettle();

        // ReviewBottomSheet should open
        expect(find.byType(ReviewBottomSheet), findsOneWidget);
        expect(navigatedTicket, isNull);
      },
    );

    testWidgets(
      '3. Loading, error + retry, search query empty vs tab empty states',
      (tester) async {
        final bloc = MyTicketsBloc(
          bookingRepository: repo,
          authenticated: true,
        );
        addTearDown(bloc.close);

        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: const MaterialApp(home: MyTicketsScreen()),
          ),
        );

        // While initial loading
        await tester.pump(const Duration(milliseconds: 10));
        await tester.pumpAndSettle();

        // Type non-matching search query
        await tester.enterText(find.byType(TextField), 'MA_VE_KHONG_TON_TAI');
        await tester.pumpAndSettle();

        // Search empty state
        expect(find.text('Không tìm thấy vé phù hợp'), findsOneWidget);
        expect(find.text('Xóa bộ lọc tìm kiếm'), findsOneWidget);

        // Tap "Xóa bộ lọc tìm kiếm"
        await tester.tap(find.text('Xóa bộ lọc tìm kiếm'));
        await tester.pumpAndSettle();
        expect(find.text('VXG-UP01'), findsOneWidget);

        // Simulate empty list by setting state
        bloc.emit(bloc.state.copyWith(tickets: []));
        await tester.pumpAndSettle();

        // Tab empty state
        expect(find.text('Chưa có chuyến xe nào sắp đi'), findsOneWidget);
        expect(find.text('Tìm chuyến ngay'), findsOneWidget);
        expect(find.text('Tải lại'), findsOneWidget);

        // Simulate error state
        bloc.emit(
          bloc.state.copyWith(
            status: MyTicketsStatus.error,
            errorMessage: 'Lỗi máy chủ kết nối 500',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Không thể tải danh sách vé'), findsOneWidget);
        expect(find.text('Lỗi máy chủ kết nối 500'), findsWidgets);
        expect(find.text('Thử lại'), findsOneWidget);

        // Tap "Thử lại" dispatches LoadMyTicketsEvent
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();

        expect(bloc.state.status, equals(MyTicketsStatus.loaded));
        expect(find.text('VXG-UP01'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Account switch / logout removes old cards, counts, PII, and restores Guest panel',
      (tester) async {
        final bloc = MyTicketsBloc(
          bookingRepository: repo,
          authenticated: true,
        );
        addTearDown(bloc.close);

        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: const MaterialApp(home: MyTicketsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('VXG-UP01'), findsOneWidget);
        expect(
          find.text('0901234567'),
          findsNothing,
        ); // PII is not leaked onto card

        // Enter search query
        await tester.enterText(find.byType(TextField), 'UP01');
        await tester.pumpAndSettle();
        expect(find.text('UP01'), findsWidgets);

        // Logout / switch account
        bloc.setSession(null);
        await tester.pumpAndSettle();

        // Verify Guest view appears
        expect(find.byType(GuestTicketLookupPanel), findsOneWidget);
        expect(find.text('Đăng nhập để xem tất cả vé'), findsOneWidget);

        // Verify old ticket cards, tab bar, and search bar are gone
        expect(find.byType(TicketSummaryCard), findsNothing);
        expect(find.text('Sắp đi'), findsNothing);
        expect(find.text('VXG-UP01'), findsNothing);
        expect(find.text('UP01'), findsNothing);
      },
    );

    final viewports = [
      (const Size(390, 844), 1.0, '390x844 (1.0x)'),
      (const Size(320, 740), 2.0, '320x740 (2.0x text scale)'),
      (const Size(640, 360), 2.0, '640x360 landscape (2.0x text scale)'),
    ];

    for (final (size, textScale, label) in viewports) {
      testWidgets(
        '5. Responsive & Accessibility without RenderFlex overflow on $label',
        (tester) async {
          tester.view.physicalSize = size * 2;
          tester.view.devicePixelRatio = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final bloc = MyTicketsBloc(
            bookingRepository: repo,
            authenticated: true,
          );
          addTearDown(bloc.close);

          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScale),
              ),
              child: BlocProvider.value(
                value: bloc,
                child: const MaterialApp(home: MyTicketsScreen()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Ensure no RenderFlex overflows
          expect(tester.takeException(), isNull);

          // Verify elements rendered within screen
          expect(find.byType(TicketSummaryCard), findsWidgets);
          expect(find.byType(TextField), findsOneWidget);

          // Switch tab in scaled layout
          await tester.ensureVisible(find.byKey(const Key('tab-cancelled')));
          await tester.tap(find.byKey(const Key('tab-cancelled')));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('VXG-CAN01'), findsOneWidget);
        },
      );
    }
  });
}
