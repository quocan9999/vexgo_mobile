import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/review_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/screens/ticket_detail_screen.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/boarding_pass_card.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/cancel_ticket_sheet.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/guest_ticket_lookup_panel.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/review_bottom_sheet.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/ticket_qr_modal.dart';

class _MockTicketRepo extends MockBookingRepository {
  final Map<String, TicketModel> ticketsById = {};
  final Map<String, TicketModel> ticketsByCode = {};
  int getTicketByIdCalls = 0;
  Completer<TicketModel?>? nextGetTicketCompleter;

  void addTicket(TicketModel ticket) {
    ticketsById[ticket.id] = ticket;
    ticketsByCode[ticket.ticketCode] = ticket;
  }

  @override
  Future<List<TicketModel>> getMyTickets() async => ticketsById.values.toList();

  @override
  Future<TicketModel?> getTicketById(String id) {
    getTicketByIdCalls++;
    if (nextGetTicketCompleter != null) {
      final c = nextGetTicketCompleter!;
      nextGetTicketCompleter = null;
      return c.future;
    }
    final ticket = ticketsById[id];
    if (ticket != null) {
      return Future.value(ticket);
    }
    return Future.error(Exception('Vé không tồn tại'));
  }

  @override
  Future<TicketModel?> lookupTicket({
    required String ticketCode,
    required String phoneNumber,
  }) async {
    final ticket = ticketsByCode[ticketCode];
    if (ticket != null) {
      return ticket;
    }
    throw Exception('Không tìm thấy vé tra cứu');
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
  String arrivalTime = '14:00',
  String arrivalDate = '20/11/2030',
  String pickupPoint = 'Bến xe Miền Đông',
  String pickupAddress = '292 Đinh Bộ Lĩnh, P.26, Q.Bình Thạnh, TP.HCM',
  String dropoffPoint = 'Bến xe Liên tỉnh Đà Lạt',
  String dropoffAddress = '01 Tô Hiến Thành, P.3, TP. Đà Lạt',
  List<String> seats = const ['A01'],
  int price = 250000,
  bool isPaid = true,
  bool canCancel = true,
  String? driverPhone = '0901234567',
  String? licensePlate = '51B-123.45',
  ReviewModel? review,
  String? cancelReason,
  int? refundAmount,
  String paymentMethod = 'VexGo Pay',
  String passengerName = 'Nguyễn Văn An',
  String passengerPhone = '0901234567',
  String passengerEmail = 'an.nguyen@vexgo.vn',
}) {
  return TicketModel(
    id: id,
    ticketCode: code,
    bookingId: int.tryParse(id) ?? 999,
    bookingCode: 'BOOKING-$id',
    status: status,
    bookingStatus: isPaid ? 'DA_THANH_TOAN' : 'CHO_THANH_TOAN',
    paymentStatus: isPaid ? 'DA_THANH_TOAN' : 'CHO_THANH_TOAN',
    rawStatus: status == TicketStatus.upcoming
        ? (isPaid ? 'DA_THANH_TOAN' : 'DA_DAT')
        : (status == TicketStatus.completed ? 'HOAN_THANH' : 'DA_HUY'),
    bookingDate: '10/10/2026 10:00',
    trip: TicketTripSummary(
      id: 'TRIP-$id',
      operatorName: opName,
      vehicleType: 'Limousine 34 Phòng',
      departureTime: departureTime,
      departureDate: departureDate,
      arrivalTime: arrivalTime,
      arrivalDate: arrivalDate,
      fromCity: from,
      toCity: to,
      pickupPoint: pickupPoint,
      pickupAddress: pickupAddress,
      dropoffPoint: dropoffPoint,
      dropoffAddress: dropoffAddress,
    ),
    seats: seats,
    totalAmount: price,
    discountAmount: 0,
    finalAmount: price,
    paymentMethod: paymentMethod,
    passenger: PassengerInfo(
      fullName: passengerName,
      phone: passengerPhone,
      email: passengerEmail,
    ),
    cancellation: CancellationQuote(
      eligible: canCancel,
      cancelFeeRate: 0.1,
      cancelFee: (price * 0.1).round(),
      refundAmount: (price * 0.9).round(),
    ),
    driverPhone: driverPhone,
    licensePlate: licensePlate,
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
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    ApiConfig.isDemoMode = false;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('TicketDetailScreen & BoardingPassCard Comprehensive UI Tests', () {
    late _MockTicketRepo repo;
    late MyTicketsBloc bloc;
    late TicketModel upcomingTicket;
    late TicketModel unpaidTicket;
    late TicketModel completedTicket;
    late TicketModel cancelledTicket;

    setUp(() {
      repo = _MockTicketRepo();
      bloc = MyTicketsBloc(bookingRepository: repo, authenticated: true);
      bloc.setSession('user_session_1');

      upcomingTicket = _makeTicket(
        id: '101',
        code: 'VXG-UP01',
        status: TicketStatus.upcoming,
        opName: 'Phương Trang (FUTA Bus)',
        from: 'TP. Hồ Chí Minh',
        to: 'Đà Lạt',
        seats: ['A01', 'A02'],
        price: 580000,
        isPaid: true,
        driverPhone: '0901234567',
      );

      unpaidTicket = _makeTicket(
        id: '102',
        code: 'VXG-UNPAID',
        status: TicketStatus.upcoming,
        opName: 'Thành Bưởi Limousine',
        from: 'TP. Hồ Chí Minh',
        to: 'Cần Thơ',
        seats: ['B05'],
        price: 220000,
        isPaid: false,
        driverPhone: '0912345678',
      );

      completedTicket = _makeTicket(
        id: '103',
        code: 'VXG-DONE',
        status: TicketStatus.completed,
        opName: 'Hoa Mai Vũng Tàu',
        from: 'TP. Hồ Chí Minh',
        to: 'Vũng Tàu',
        seats: ['VIP01'],
        price: 180000,
        isPaid: true,
      );

      cancelledTicket = _makeTicket(
        id: '104',
        code: 'VXG-CANCEL',
        status: TicketStatus.cancelled,
        opName: 'Mai Linh Express',
        from: 'TP. Hồ Chí Minh',
        to: 'Nha Trang',
        seats: ['C03'],
        price: 350000,
        isPaid: true,
        cancelReason: 'Thay đổi kế hoạch cá nhân',
        refundAmount: 315000,
      );

      repo.addTicket(upcomingTicket);
      repo.addTicket(unpaidTicket);
      repo.addTicket(completedTicket);
      repo.addTicket(cancelledTicket);
    });

    tearDown(() {
      bloc.close();
    });

    testWidgets(
      'Navigation payload and fresh read lifecycle renders authoritative data without flashing initial QR',
      (tester) async {
        final completer = Completer<TicketModel?>();
        repo.nextGetTicketCompleter = completer;

        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: MaterialApp(
              home: TicketDetailScreen(initialTicket: upcomingTicket),
            ),
          ),
        );

        // While loading, BoardingPassCard and QrImageView should NOT be rendered
        expect(find.byType(BoardingPassCard), findsNothing);
        expect(find.byType(QrImageView), findsNothing);
        expect(find.text('Đang tải thông tin vé...'), findsOneWidget);

        // Complete fresh read
        completer.complete(upcomingTicket);
        await tester.pumpAndSettle();

        // Now BoardingPassCard is shown with authoritative ticket data
        expect(find.byType(BoardingPassCard), findsOneWidget);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.text('Phương Trang (FUTA Bus)'), findsOneWidget);
        expect(find.text('A01, A02'), findsOneWidget);
        expect(find.text(CurrencyFormatter.format(580000)), findsOneWidget);
        expect(find.text('Mã vé: VXG-UP01'), findsOneWidget);
      },
    );

    testWidgets('App bar refresh button triggers fresh read from backend', (
      tester,
    ) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            home: TicketDetailScreen(initialTicket: upcomingTicket),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialCalls = repo.getTicketByIdCalls;
      expect(initialCalls, greaterThanOrEqualTo(1));

      // Tap refresh on custom app bar
      await tester.tap(find.byTooltip('Cập nhật trạng thái vé'));
      await tester.pumpAndSettle();

      expect(repo.getTicketByIdCalls, initialCalls + 1);
    });

    testWidgets('Displays error view and allows retry when read fails', (
      tester,
    ) async {
      final failCompleter = Completer<TicketModel?>();
      repo.nextGetTicketCompleter = failCompleter;

      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            home: TicketDetailScreen(initialTicket: upcomingTicket),
          ),
        ),
      );

      failCompleter.completeError(Exception('Mất kết nối mạng'));
      await tester.pumpAndSettle();

      expect(find.text('Thử lại'), findsOneWidget);
      expect(find.byType(BoardingPassCard), findsNothing);

      // Now tapping retry will fetch the ticket successfully
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.byType(BoardingPassCard), findsOneWidget);
      expect(find.text('Phương Trang (FUTA Bus)'), findsOneWidget);
    });

    testWidgets('QR Code gate: Shows QR only for upcoming paid tickets', (
      tester,
    ) async {
      // 1. Upcoming + Paid ticket has QR
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            home: TicketDetailScreen(initialTicket: upcomingTicket),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Chạm để phóng to mã QR'), findsOneWidget);

      // Tap to open full screen QR modal
      await tester.tap(find.text('Chạm để phóng to mã QR'));
      await tester.pumpAndSettle();

      expect(find.byType(TicketQrModal), findsOneWidget);
      expect(find.text('Mã vé điện tử (E-Ticket)'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(TicketQrModal), findsNothing);
    });

    testWidgets(
      'QR Code gate: Hides QR for unpaid, cancelled and completed tickets',
      (tester) async {
        // 2. Unpaid ticket has NO QR
        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: MaterialApp(
              home: TicketDetailScreen(initialTicket: unpaidTicket),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(QrImageView), findsNothing);
        expect(find.text('Chưa có xác nhận thanh toán'), findsOneWidget);

        // 3. Completed ticket has NO QR
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: MaterialApp(
              home: TicketDetailScreen(
                key: ValueKey(completedTicket.id),
                initialTicket: completedTicket,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(QrImageView), findsNothing);
        expect(find.text('Chuyến đi đã hoàn thành.'), findsOneWidget);

        // 4. Cancelled ticket has NO QR and displays cancellation info
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: MaterialApp(
              home: TicketDetailScreen(
                key: ValueKey(cancelledTicket.id),
                initialTicket: cancelledTicket,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(QrImageView), findsNothing);
        expect(
          find.text('Vé đã bị hủy. Mã QR không khả dụng.'),
          findsOneWidget,
        );
        expect(find.text('Thay đổi kế hoạch cá nhân'), findsOneWidget);
        expect(find.text(CurrencyFormatter.format(315000)), findsOneWidget);
      },
    );

    testWidgets(
      'Contact phone copies to clipboard and never shows direct call action',
      (tester) async {
        String? copiedText;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copiedText = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        });

        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: MaterialApp(
              home: TicketDetailScreen(initialTicket: upcomingTicket),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sao chép số'), findsOneWidget);
        expect(find.text('Gọi ngay'), findsNothing);
        expect(find.text('Gọi điện'), findsNothing);

        await tester.ensureVisible(find.text('Sao chép số'));
        await tester.tap(find.text('Sao chép số'));
        await tester.pumpAndSettle();

        expect(copiedText, '0901234567');
        expect(find.text('Đã sao chép số liên hệ.'), findsOneWidget);
      },
    );

    testWidgets('Action buttons: Upcoming ticket offers Cancel and Search', (
      tester,
    ) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            home: TicketDetailScreen(initialTicket: upcomingTicket),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Hủy vé'));
      expect(find.text('Hủy vé'), findsOneWidget);
      expect(find.text('Tìm chuyến khác'), findsOneWidget);

      await tester.tap(find.text('Hủy vé'));
      await tester.pumpAndSettle();

      expect(find.byType(CancelTicketSheet), findsOneWidget);
    });

    testWidgets('Action buttons: Completed ticket offers Review or Rebook', (
      tester,
    ) async {
      // Unreviewed completed ticket
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            home: TicketDetailScreen(initialTicket: completedTicket),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Đánh giá chuyến đi'));
      expect(find.text('Đánh giá chuyến đi'), findsOneWidget);

      await tester.tap(find.text('Đánh giá chuyến đi'));
      await tester.pumpAndSettle();

      expect(find.byType(ReviewBottomSheet), findsOneWidget);

      // Now test reviewed completed ticket
      final reviewedTicket = completedTicket.copyWith(
        review: const ReviewModel(
          rating: 5,
          comment: 'Chuyến xe rất sạch sẽ và êm ái',
          createdAt: '2026-10-25T10:00:00Z',
        ),
      );
      repo.addTicket(reviewedTicket);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            home: TicketDetailScreen(
              key: const ValueKey('reviewed-ticket'),
              initialTicket: reviewedTicket,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Đã đánh giá'), findsOneWidget);
      expect(find.text('Đặt lại chuyến xe này'), findsOneWidget);
    });

    testWidgets('Action buttons: Cancelled ticket displays notice and rebook', (
      tester,
    ) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            home: TicketDetailScreen(initialTicket: cancelledTicket),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Vé này đã bị hủy'), findsOneWidget);
      expect(find.text('Tìm vé mới'), findsOneWidget);
    });

    testWidgets(
      'Session safety: Invalidates BoardingPassCard when account changes or logout occurs',
      (tester) async {
        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: MaterialApp(
              home: TicketDetailScreen(initialTicket: upcomingTicket),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mã vé: VXG-UP01'), findsOneWidget);

        // Account switch
        bloc.setSession('another_user_session_99');
        await tester.pumpAndSettle();

        // Previous PII and QR are hidden, invalidation warning displayed
        expect(find.byType(QrImageView), findsNothing);
        expect(
          find.text('Phiên đã thay đổi. Vui lòng mở lại thông tin vé.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Shared BoardingPassCard functions smoothly in GuestTicketLookupPanel',
      (tester) async {
        final guestBloc = MyTicketsBloc(
          bookingRepository: repo,
          authenticated: false,
        );
        guestBloc.setSession(null);
        addTearDown(guestBloc.close);

        await tester.pumpWidget(
          BlocProvider.value(
            value: guestBloc,
            child: const MaterialApp(
              home: Scaffold(body: GuestTicketLookupPanel()),
            ),
          ),
        );

        await tester.enterText(
          find.byKey(const Key('lookup-ticket-code')),
          'VXG-UP01',
        );
        await tester.enterText(
          find.byKey(const Key('lookup-phone')),
          '0901234567',
        );
        await tester.tap(find.text('Tra cứu vé'));
        await tester.pumpAndSettle();

        expect(find.byType(BoardingPassCard), findsOneWidget);
        expect(find.text('Phương Trang (FUTA Bus)'), findsOneWidget);
        expect(find.text('Mã vé: VXG-UP01'), findsOneWidget);
      },
    );

    testWidgets(
      'Responsive check: 320x740 narrow screen with 2x text scale does not overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2, 740 * 2);
        tester.view.devicePixelRatio = 2.0;
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });

        final extremeTicket = _makeTicket(
          id: '999',
          code: 'VXG-EXTREME-LONG-CODE-999',
          status: TicketStatus.upcoming,
          opName: 'Công ty Cổ phần Xe khách Phương Trang FUTA Bus Lines',
          from: 'Thành phố Hồ Chí Minh (Sài Gòn)',
          to: 'Thành phố Đà Lạt ngàn hoa',
          seats: ['A01', 'A02', 'A03', 'A04', 'A05'],
          price: 12500000,
          passengerName: 'Nguyễn Hoàng Gia Bảo Thiên Long Nguyễn Huỳnh Đức Trí',
          passengerEmail:
              'nguyen.hoang.gia.bao.thien.long.really.long@company.example.com',
          pickupPoint: 'Bến xe Miền Đông Mới - Bến xe hiện đại nhất',
          pickupAddress:
              'Số 501 Đường Hoàng Hữu Nam, Phường Long Bình, Thành phố Thủ Đức, TP. Hồ Chí Minh',
          dropoffPoint: 'Bến xe Liên tỉnh Thành phố Đà Lạt tỉnh Lâm Đồng',
          dropoffAddress:
              'Số 01 Đường Tô Hiến Thành, Phường 3, Thành phố Đà Lạt, Tỉnh Lâm Đồng',
          driverPhone: '0901234567',
        );
        repo.addTicket(extremeTicket);

        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: MaterialApp(
              home: TicketDetailScreen(initialTicket: extremeTicket),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BoardingPassCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Responsive check: 640x360 landscape screen with 2x text scale does not overflow',
      (tester) async {
        tester.view.physicalSize = const Size(640 * 2, 360 * 2);
        tester.view.devicePixelRatio = 2.0;
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });

        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: MaterialApp(
              home: TicketDetailScreen(initialTicket: upcomingTicket),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BoardingPassCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
