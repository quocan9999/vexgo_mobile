import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/ticket_read_cubit.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/cancel_ticket_sheet.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/guest_cancel_ticket_sheet.dart';

class _MockBookingRepo extends MockBookingRepository {
  final Map<String, TicketModel> ticketsById = {};
  final List<Map<String, dynamic>> cancelCalls = [];

  void addTicket(TicketModel ticket) {
    ticketsById[ticket.id] = ticket;
  }

  @override
  Future<List<TicketModel>> getMyTickets() async => ticketsById.values.toList();

  @override
  Future<TicketModel?> getTicketById(String id) async => ticketsById[id];

  @override
  Future<TicketModel?> lookupTicket({
    required String ticketCode,
    required String phoneNumber,
  }) async {
    final t = ticketsById.values.firstWhere(
      (t) => t.ticketCode == ticketCode,
      orElse: () => throw Exception('Không tìm thấy vé tra cứu'),
    );
    if (cancelCalls.any((c) => c['ticketCode'] == ticketCode)) {
      return t.copyWith(status: TicketStatus.cancelled, rawStatus: 'HUY');
    }
    return t;
  }

  @override
  Future<Map<String, dynamic>> cancelTicket({
    required String ticketCode,
    required String phoneNumber,
    String? reason,
    required double expectedCancelFeeRate,
  }) async {
    cancelCalls.add({
      'ticketCode': ticketCode,
      'phoneNumber': phoneNumber,
      'reason': reason,
      'expectedCancelFeeRate': expectedCancelFeeRate,
    });
    final t = ticketsById.values.firstWhere((t) => t.ticketCode == ticketCode);
    return {'ticketId': t.id, 'ticketCode': ticketCode, 'status': 'HUY'};
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
  List<String> seats = const ['A01'],
  int price = 250000,
  bool isPaid = true,
  bool canCancel = true,
  double feeRate = 0.1,
  String? ineligibleReason,
  String? driverPhone = '0901234567',
  String? licensePlate = '51B-123.45',
  String passengerName = 'Nguyễn Văn An',
  String passengerPhone = '0901234567',
}) {
  final cancelFee = (price * feeRate).round();
  final refundAmount = (price - cancelFee);

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
      pickupPoint: 'Bến xe Miền Đông',
      pickupAddress: '292 Đinh Bộ Lĩnh, P.26, Q.Bình Thạnh, TP.HCM',
      dropoffPoint: 'Bến xe Liên tỉnh Đà Lạt',
      dropoffAddress: '01 Tô Hiến Thành, P.3, TP. Đà Lạt',
    ),
    seats: seats,
    totalAmount: price,
    discountAmount: 0,
    finalAmount: price,
    paymentMethod: 'VexGo Pay',
    passenger: PassengerInfo(
      fullName: passengerName,
      phone: passengerPhone,
      email: 'an.nguyen@vexgo.vn',
    ),
    cancellation: CancellationQuote(
      eligible: canCancel,
      reason: ineligibleReason,
      cancelFeeRate: feeRate,
      cancelFee: cancelFee,
      refundAmount: refundAmount,
    ),
    driverPhone: driverPhone,
    licensePlate: licensePlate,
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

  group('CancelTicketSheet (Authenticated) Comprehensive UI Tests', () {
    late _MockBookingRepo repo;
    late MyTicketsBloc bloc;
    late TicketModel eligibleTicket;
    late TicketModel ineligibleTicket;

    setUp(() {
      repo = _MockBookingRepo();
      bloc = MyTicketsBloc(bookingRepository: repo, authenticated: true);
      bloc.setSession('session_auth_123');

      eligibleTicket = _makeTicket(
        id: '101',
        code: 'VXG-AUTH-101',
        status: TicketStatus.upcoming,
        opName: 'Phương Trang (FUTA Bus)',
        from: 'TP. Hồ Chí Minh',
        to: 'Đà Lạt',
        price: 250000,
        feeRate: 0.1,
        canCancel: true,
        driverPhone: '0901234567',
      );
      repo.addTicket(eligibleTicket);

      ineligibleTicket = _makeTicket(
        id: '102',
        code: 'VXG-AUTH-102',
        status: TicketStatus.upcoming,
        opName: 'Thành Bưởi Limousine',
        from: 'TP. Hồ Chí Minh',
        to: 'Cần Thơ',
        price: 220000,
        feeRate: 0.2,
        canCancel: false,
        ineligibleReason: 'Chuyến xe khởi hành trong vòng dưới 3 giờ.',
        driverPhone: '0912345678',
      );
      repo.addTicket(ineligibleTicket);
    });

    testWidgets(
      'Displays full ticket summary, quote fee breakdown and disclaimer',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      CancelTicketSheet.show(context, eligibleTicket, bloc),
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Header
        expect(find.text('Hủy vé xe'), findsOneWidget);
        expect(find.text('Mã vé: VXG-AUTH-101'), findsOneWidget);

        // Summary strip
        expect(
          find.text('Phương Trang (FUTA Bus) · Limousine 34 Phòng'),
          findsOneWidget,
        );
        expect(find.text('TP. Hồ Chí Minh ➔ Đà Lạt'), findsOneWidget);
        expect(find.text('08:00 · 20/11/2030'), findsOneWidget);
        expect(find.text('Chỗ ngồi: A01'), findsOneWidget);

        // Quote breakdown
        expect(find.text('Tiền vé đã thanh toán:'), findsOneWidget);
        expect(find.textContaining('250.000'), findsOneWidget);
        expect(find.text('Phí hủy theo quy định (10%):'), findsOneWidget);
        expect(find.textContaining('- 25.000'), findsOneWidget);
        expect(find.text('Số tiền dự kiến hoàn lại:'), findsOneWidget);
        expect(find.textContaining('225.000'), findsOneWidget);

        // Disclaimer
        expect(
          find.text(
            'Hủy vé không đồng nghĩa đã hoàn tiền ngay. Trạng thái hoàn tiền cần được đối soát và xử lý theo chính sách hoàn tiền.',
          ),
          findsOneWidget,
        );

        // Agreement checkbox & submit button initially disabled
        expect(find.byType(CheckboxListTile), findsOneWidget);
        final submitFinder = find.widgetWithText(
          FilledButton,
          'Xác nhận hủy vé',
        );
        expect(submitFinder, findsOneWidget);
        final FilledButton submitBtn = tester.widget(submitFinder);
        expect(submitBtn.onPressed, isNull);
      },
    );

    testWidgets(
      'Submits cancellation with selected reason after ticking policy checkbox',
      (tester) async {
        final List<MyTicketsEvent> receivedEvents = [];
        bloc.stream.listen((state) {});
        // Wrap or spy on bloc events
        final testBloc = _TestSpyMyTicketsBloc(
          repo: repo,
          onEventDispatched: (event) => receivedEvents.add(event),
        );
        testBloc.setSession('session_spy');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      CancelTicketSheet.show(context, eligibleTicket, testBloc),
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Change reason to 'Đặt nhầm ngày/giờ khởi hành'
        final altReasonFinder = find.text('Đặt nhầm ngày/giờ khởi hành');
        await tester.ensureVisible(altReasonFinder);
        await tester.tap(altReasonFinder);
        await tester.pumpAndSettle();

        // Check agreement checkbox
        final checkboxFinder = find.byType(CheckboxListTile);
        await tester.ensureVisible(checkboxFinder);
        await tester.tap(checkboxFinder);
        await tester.pumpAndSettle();

        // Submit button should now be enabled
        final submitFinder = find.widgetWithText(
          FilledButton,
          'Xác nhận hủy vé',
        );
        await tester.ensureVisible(submitFinder);
        final FilledButton submitBtn = tester.widget(submitFinder);
        expect(submitBtn.onPressed, isNotNull);

        // Tap submit
        await tester.tap(submitFinder);
        await tester.pumpAndSettle();

        // Sheet should be popped
        expect(find.byType(CancelTicketSheet), findsNothing);

        // Event should be dispatched
        final cancelEvents = receivedEvents
            .whereType<CancelTicketEvent>()
            .toList();
        expect(cancelEvents, hasLength(1));
        final event = cancelEvents.first;
        expect(event.ticketId, '101');
        expect(event.reason, 'Đặt nhầm ngày/giờ khởi hành');
        expect(event.refundAmount, 225000);
      },
    );

    testWidgets(
      'Selecting "Khác" requires typing custom text before submit is enabled',
      (tester) async {
        final List<MyTicketsEvent> receivedEvents = [];
        final testBloc = _TestSpyMyTicketsBloc(
          repo: repo,
          onEventDispatched: (event) => receivedEvents.add(event),
        );
        testBloc.setSession('session_spy');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      CancelTicketSheet.show(context, eligibleTicket, testBloc),
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Tick agreement
        final checkboxFinder = find.byType(CheckboxListTile);
        await tester.ensureVisible(checkboxFinder);
        await tester.tap(checkboxFinder);
        await tester.pumpAndSettle();

        // Now select "Khác"
        final otherFinder = find.text('Khác');
        await tester.ensureVisible(otherFinder);
        await tester.tap(otherFinder);
        await tester.pumpAndSettle();

        // TextField should appear
        final textFieldFinder = find.byType(TextField);
        await tester.ensureVisible(textFieldFinder);
        expect(textFieldFinder, findsOneWidget);
        expect(find.text('Nhập lý do cụ thể'), findsOneWidget);

        // Button should be disabled because custom text is empty
        final submitFinder = find.widgetWithText(
          FilledButton,
          'Xác nhận hủy vé',
        );
        await tester.ensureVisible(submitFinder);
        var submitBtn = tester.widget<FilledButton>(submitFinder);
        expect(submitBtn.onPressed, isNull);

        // Type custom reason
        await tester.enterText(
          textFieldFinder,
          'Bận việc đột xuất không thể đi được',
        );
        await tester.pumpAndSettle();

        // Button should now be enabled
        submitBtn = tester.widget<FilledButton>(submitFinder);
        expect(submitBtn.onPressed, isNotNull);

        // Submit
        await tester.tap(submitFinder);
        await tester.pumpAndSettle();

        // Verifications
        expect(find.byType(CancelTicketSheet), findsNothing);
        final cancelEvents = receivedEvents
            .whereType<CancelTicketEvent>()
            .toList();
        expect(cancelEvents, hasLength(1));
        final event = cancelEvents.first;
        expect(event.ticketId, '101');
        expect(event.reason, 'Bận việc đột xuất không thể đi được');
        expect(event.refundAmount, 225000);
      },
    );

    testWidgets(
      'Ineligible ticket displays real quote reason, no fake hotline/12h rules, copies phone',
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
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      CancelTicketSheet.show(context, ineligibleTicket, bloc),
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Header shows 'Không thể hủy vé'
        expect(find.text('Không thể hủy vé'), findsOneWidget);
        expect(
          find.text('Không đủ điều kiện hủy vé trực tuyến'),
          findsOneWidget,
        );

        // Real reason from quote
        expect(
          find.text('Chuyến xe khởi hành trong vòng dưới 3 giờ.'),
          findsOneWidget,
        );

        // Invariants: No technical label, no fake hotline 1900 6067
        expect(find.textContaining('sub_uc_huy_ve'), findsNothing);
        expect(find.textContaining('1900 6067'), findsNothing);

        // Driver contact row & copy button
        expect(find.text('SĐT liên hệ: 0912345678'), findsOneWidget);
        final copyBtn = find.widgetWithText(OutlinedButton, 'Sao chép');
        expect(copyBtn, findsOneWidget);

        await tester.ensureVisible(copyBtn);
        await tester.tap(copyBtn);
        await tester.pumpAndSettle();

        // Copied to clipboard & SnackBar feedback
        expect(copiedText, '0912345678');
        expect(find.text('Đã sao chép số liên hệ.'), findsOneWidget);

        // Dismiss via 'Đã hiểu và Đóng'
        final closeBtn = find.widgetWithText(OutlinedButton, 'Đã hiểu và Đóng');
        expect(closeBtn, findsOneWidget);
        await tester.ensureVisible(closeBtn);
        await tester.tap(closeBtn);
        await tester.pumpAndSettle();

        expect(find.byType(CancelTicketSheet), findsNothing);
      },
    );

    testWidgets('Double-tap guard prevents duplicate submission events', (
      tester,
    ) async {
      final List<MyTicketsEvent> receivedEvents = [];
      final testBloc = _TestSpyMyTicketsBloc(
        repo: repo,
        onEventDispatched: (event) => receivedEvents.add(event),
      );
      testBloc.setSession('session_spy');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    CancelTicketSheet.show(context, eligibleTicket, testBloc),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Check agreement checkbox
      final checkboxFinder = find.byType(CheckboxListTile);
      await tester.ensureVisible(checkboxFinder);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      final submitFinder = find.widgetWithText(FilledButton, 'Xác nhận hủy vé');
      await tester.ensureVisible(submitFinder);

      // Tap once
      await tester.tap(submitFinder);
      // Immediate second tap without pumpAndSettle
      await tester.tap(submitFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      final cancelEvents = receivedEvents
          .whereType<CancelTicketEvent>()
          .toList();
      expect(cancelEvents, hasLength(1));
    });

    testWidgets('Tapping "Giữ vé / Đóng" dismisses sheet without submit', (
      tester,
    ) async {
      final List<MyTicketsEvent> receivedEvents = [];
      final testBloc = _TestSpyMyTicketsBloc(
        repo: repo,
        onEventDispatched: (event) => receivedEvents.add(event),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    CancelTicketSheet.show(context, eligibleTicket, testBloc),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final keepBtn = find.widgetWithText(OutlinedButton, 'Giữ vé / Đóng');
      await tester.ensureVisible(keepBtn);
      await tester.tap(keepBtn);
      await tester.pumpAndSettle();

      expect(find.byType(CancelTicketSheet), findsNothing);
      expect(receivedEvents, isEmpty);
    });
  });

  group('GuestCancelTicketSheet Comprehensive UI Tests', () {
    late _MockBookingRepo repo;
    late MyTicketsBloc ownerBloc;
    late TicketReadCubit reader;
    late TicketModel guestEligibleTicket;
    late TicketModel guestIneligibleTicket;

    setUp(() {
      repo = _MockBookingRepo();
      ownerBloc = MyTicketsBloc(bookingRepository: repo, authenticated: false)
        ..setSession(null);

      guestEligibleTicket = _makeTicket(
        id: '201',
        code: 'VXG-GUEST-201',
        status: TicketStatus.upcoming,
        opName: 'Mai Linh Express',
        from: 'Hà Nội',
        to: 'Hải Phòng',
        price: 200000,
        feeRate: 0.2,
        canCancel: true,
      );
      repo.addTicket(guestEligibleTicket);

      guestIneligibleTicket = _makeTicket(
        id: '202',
        code: 'VXG-GUEST-202',
        status: TicketStatus.upcoming,
        opName: 'Hoàng Long',
        from: 'Hà Nội',
        to: 'Đà Nẵng',
        price: 450000,
        feeRate: 0.2,
        canCancel: false,
        ineligibleReason:
            'Vé đã hết hạn hủy trực tuyến theo chính sách nhà xe.',
      );
      repo.addTicket(guestIneligibleTicket);

      reader = TicketReadCubit(owner: ownerBloc);
    });

    tearDown(() {
      reader.close();
      ownerBloc.close();
    });

    testWidgets(
      'Guest cancellation shows quote fee rate, agreement enables FilledButton, submits cleanly',
      (tester) async {
        // Lookup ticket through public cubit to configure phone & public mode
        await reader.lookup(
          ticketCode: guestEligibleTicket.ticketCode,
          phoneNumber: guestEligibleTicket.passenger.phone,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => GuestCancelTicketSheet(reader: reader),
                  ),
                  child: const Text('Open Guest Sheet'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Guest Sheet'));
        await tester.pumpAndSettle();

        // Check required contract strings
        expect(find.textContaining('Phí hủy (20%)'), findsOneWidget);
        expect(find.textContaining('40.000'), findsOneWidget);
        expect(find.textContaining('Số tiền dự kiến hoàn:'), findsOneWidget);
        expect(find.textContaining('160.000'), findsOneWidget);
        expect(
          find.textContaining('Hủy vé không đồng nghĩa đã hoàn tiền.'),
          findsOneWidget,
        );

        // FilledButton('Xác nhận hủy vé') contract
        final submitFinder = find.widgetWithText(
          FilledButton,
          'Xác nhận hủy vé',
        );
        expect(submitFinder, findsOneWidget);
        expect(tester.widget<FilledButton>(submitFinder).onPressed, isNull);

        // Check agreement
        final checkboxFinder = find.byType(CheckboxListTile);
        await tester.ensureVisible(checkboxFinder);
        await tester.tap(checkboxFinder);
        await tester.pumpAndSettle();

        // Submit button is now enabled
        await tester.ensureVisible(submitFinder);
        expect(tester.widget<FilledButton>(submitFinder).onPressed, isNotNull);

        // Tap submit
        await tester.tap(submitFinder);
        await tester.pumpAndSettle();

        // Verify API was called through repository
        expect(repo.cancelCalls, hasLength(1));
        expect(repo.cancelCalls.first['ticketCode'], 'VXG-GUEST-201');
        expect(repo.cancelCalls.first['reason'], 'Thay đổi kế hoạch cá nhân');
        expect(repo.cancelCalls.first['expectedCancelFeeRate'], 0.2);

        // Sheet closed
        expect(find.byType(GuestCancelTicketSheet), findsNothing);
      },
    );

    testWidgets(
      'Guest sheet renders loading/busy indicator during cancelling',
      (tester) async {
        reader.emit(
          TicketReadState(
            TicketReadStatus.cancelling,
            ticket: guestEligibleTicket,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: GuestCancelTicketSheet(reader: reader)),
          ),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('Guest sheet renders error alert when state.error is present', (
      tester,
    ) async {
      reader.emit(
        TicketReadState(
          TicketReadStatus.failure,
          ticket: guestEligibleTicket,
          error: 'Mất kết nối mạng. Vui lòng thử lại.',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GuestCancelTicketSheet(reader: reader)),
        ),
      );
      await tester.pump();

      expect(find.text('Mất kết nối mạng. Vui lòng thử lại.'), findsOneWidget);
    });

    testWidgets(
      'Guest sheet displays ineligible reason when canCancel is false',
      (tester) async {
        reader.emit(
          TicketReadState(
            TicketReadStatus.loaded,
            ticket: guestIneligibleTicket,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: GuestCancelTicketSheet(reader: reader)),
          ),
        );
        await tester.pump();

        expect(
          find.text('Vé đã hết hạn hủy trực tuyến theo chính sách nhà xe.'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(FilledButton, 'Xác nhận hủy vé'),
          findsNothing,
        );
      },
    );
  });

  group('Responsive & Extreme Viewport Tests (No RenderFlex Overflows)', () {
    late _MockBookingRepo repo;
    late MyTicketsBloc bloc;
    late TicketModel ticket;

    setUp(() {
      repo = _MockBookingRepo();
      bloc = MyTicketsBloc(bookingRepository: repo, authenticated: true);
      bloc.setSession('session_responsive');

      ticket = _makeTicket(
        id: '301',
        code: 'VXG-RESP-301',
        status: TicketStatus.upcoming,
        opName: 'Nhà Xe Phương Trang FUTA Bus Lines VIP Express',
        from: 'Bến xe Miền Đông Mới, TP. Hồ Chí Minh',
        to: 'Bến xe Liên Tỉnh Thành Phố Đà Lạt',
        price: 350000,
        feeRate: 0.15,
        canCancel: true,
      );
      repo.addTicket(ticket);
    });

    testWidgets('Standard phone (390x844, 1.0x text scale) renders cleanly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CancelTicketSheet(ticket: ticket, bloc: bloc),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CancelTicketSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Compact phone (320x740, 2.0x text scale) wraps buttons without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              textTheme: const TextTheme(
                bodyMedium: TextStyle(fontSize: 28),
                bodySmall: TextStyle(fontSize: 24),
              ),
            ),
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(2.0),
                size: Size(320, 740),
              ),
              child: Scaffold(
                body: CancelTicketSheet(ticket: ticket, bloc: bloc),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CancelTicketSheet), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Landscape phone with open keyboard (640x360, 2.0x text scale) scrolls without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(640, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(2.0),
                size: Size(640, 360),
                viewInsets: EdgeInsets.only(bottom: 180),
              ),
              child: Scaffold(
                body: CancelTicketSheet(ticket: ticket, bloc: bloc),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CancelTicketSheet), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

class _TestSpyMyTicketsBloc extends MyTicketsBloc {
  final void Function(MyTicketsEvent event) onEventDispatched;

  _TestSpyMyTicketsBloc({
    required BookingRepository repo,
    required this.onEventDispatched,
  }) : super(bookingRepository: repo, authenticated: true);

  @override
  void add(MyTicketsEvent event) {
    onEventDispatched(event);
    super.add(event);
  }
}
