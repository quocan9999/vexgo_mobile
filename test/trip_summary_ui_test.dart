import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/data/models/booking_quote_model.dart';
import 'package:vexgo_app/data/models/seat_hold_model.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/models/user_model.dart';
import 'package:vexgo_app/data/models/voucher_model.dart';
import 'package:vexgo_app/data/repositories/auth_repository.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/presentation/screens/booking_flow_screen.dart';
import 'package:vexgo_app/features/user/booking/presentation/steps/step_4_passenger_info.dart';
import 'package:vexgo_app/features/user/booking/presentation/steps/step_5_trip_summary.dart';
import 'package:vexgo_app/features/user/booking/presentation/steps/step_6_payment.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_passenger_info_view.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_selection_view.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_stepper.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_trip_summary_view.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_event.dart';

const _pickup = StopPointModel(
  id: 'p1',
  name: 'Bến xe Miền Tây',
  time: '08:00',
  address: '395 Kinh Dương Vương, An Lạc, Bình Tân, TP. Hồ Chí Minh',
  isDefault: true,
);

const _dropoff = StopPointModel(
  id: 'd1',
  name: 'Bến xe Liên tỉnh Đà Lạt',
  time: '14:00',
  address: '01 Tô Hiến Thành, Phường 3, TP. Đà Lạt, Lâm Đồng',
  isDefault: true,
);

const _trip = TripModel(
  id: '769',
  operatorId: '3',
  operatorName: 'Hoa Mai Limousine',
  vehicleType: 'Limousine 34 Phòng VIP',
  fromCityId: 'HCM',
  fromCityName: 'TP. Hồ Chí Minh',
  toCityId: 'DL',
  toCityName: 'Đà Lạt',
  departureTime: '08:00',
  arrivalTime: '14:00',
  duration: '6 giờ',
  pickupPoint: 'Bến xe Miền Tây',
  pickupAddress: '395 Kinh Dương Vương, An Lạc, Bình Tân',
  dropoffPoint: 'Bến xe Liên tỉnh Đà Lạt',
  dropoffAddress: '01 Tô Hiến Thành, Phường 3, Đà Lạt',
  originalPrice: 200000,
  discountPrice: 190000,
  availableSeats: 4,
  totalSeats: 34,
  rating: 4.9,
  reviewCount: 230,
  seatLayoutType: 'SLEEPER_34',
  pickupPoints: [_pickup],
  dropoffPoints: [_dropoff],
);

SeatModel _makeSeat(
  String id,
  int row,
  int col, {
  int floor = 1,
  SeatStatus status = SeatStatus.available,
  int price = 190000,
}) => SeatModel(
  id: id,
  name: '${floor == 1 ? 'A' : 'B'}$id',
  floor: floor,
  status: status,
  price: price,
  row: row,
  col: col,
);

class _FakeSeatRepo implements SeatRepository {
  int createHoldCalls = 0;
  int releaseHoldCalls = 0;
  DateTime expiresAt = DateTime.now().add(const Duration(minutes: 10));

  final List<SeatModel> items = [
    _makeSeat('01', 1, 1),
    _makeSeat('02', 1, 2),
    _makeSeat('03', 2, 1, status: SeatStatus.booked),
    _makeSeat('04', 1, 1, floor: 2),
  ];

  @override
  Future<List<SeatModel>> getTripSeats(dynamic id) async => items;

  @override
  Future<SeatLayoutModel> getSeatLayout(String type) async =>
      throw UnimplementedError();

  @override
  Future<SeatHoldModel> createSeatHold({
    required int tripId,
    required List<int> seatIds,
  }) async {
    createHoldCalls++;
    return SeatHoldModel(
      holdToken: 'hold-token-$createHoldCalls',
      tripId: tripId,
      seatIds: seatIds,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<bool> releaseSeatHold(String token) async {
    releaseHoldCalls++;
    return true;
  }
}

class _FakeBookingRepo implements BookingRepository {
  int quoteCalls = 0;
  String? lastCode;
  String? lastPhone;
  bool shouldFailQuote = false;
  int discountToReturn = 0;

  @override
  Future<List<VoucherModel>> getVouchers() async => const [];

  @override
  Future<BookingQuoteModel> getBookingQuote({
    required int tripId,
    required List<int> seatIds,
    String? promotionCode,
    String? contactPhone,
  }) async {
    quoteCalls++;
    lastCode = promotionCode;
    lastPhone = contactPhone;
    if (shouldFailQuote) {
      throw StateError('Mã khuyến mãi không hợp lệ hoặc đã hết lượt dùng.');
    }
    final subtotal = seatIds.length * 190000;
    final discount = (promotionCode != null && promotionCode.isNotEmpty)
        ? (discountToReturn > 0 ? discountToReturn : 30000)
        : 0;
    return BookingQuoteModel(
      unitPrice: 190000,
      seatCount: seatIds.length,
      originalTotal: subtotal,
      discountAmount: discount,
      serviceFee: 0,
      finalTotal: subtotal - discount,
      appliedPromotionCode: promotionCode,
      identityChecked: true,
      phoneEligibilityChecked: true,
      requiresPhoneBeforeBooking: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepo implements AuthRepository {
  UserModel? currentUser;
  _FakeAuthRepo({this.currentUser});

  @override
  Future<UserModel?> getCurrentUser() async => currentUser;

  @override
  Future<UserModel> updateProfile(UserModel updatedUser) async =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {
    currentUser = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<BookingFlowBloc> _createStep5Bloc(
  WidgetTester tester, {
  required _FakeSeatRepo seatRepo,
  required _FakeBookingRepo bookingRepo,
  bool prefillQuote = true,
  String promotionCode = '',
}) async {
  final bloc = BookingFlowBloc(
    seatRepository: seatRepo,
    bookingRepository: bookingRepo,
  );

  bloc.emit(
    BookingFlowState(
      status: BookingFlowStatus.loaded,
      step: BookingStep.tripSummary,
      trip: _trip,
      date: DateTime(2026, 10, 27),
      targetTicketCount: 2,
      selectedSeats: [
        _makeSeat('01', 1, 1, price: 190000),
        _makeSeat('02', 1, 2, price: 190000),
      ],
      selectedPickupPoint: _pickup,
      selectedDropoffPoint: _dropoff,
      passengerName: 'Phạm Minh Tài',
      passengerPhone: '0901234567',
      passengerEmail: 'minhtai@vexgo.vn',
      seatHold: SeatHoldModel(
        holdToken: 'valid-hold-token',
        tripId: 769,
        seatIds: const [1, 2],
        expiresAt: seatRepo.expiresAt,
      ),
      countdownSeconds: 580,
      requiresAuthoritativeQuote: true,
      requestedPromotionCode: promotionCode,
      quote: prefillQuote
          ? BookingQuoteModel(
              unitPrice: 190000,
              seatCount: 2,
              originalTotal: 380000,
              discountAmount: promotionCode.isNotEmpty ? 30000 : 0,
              serviceFee: 0,
              finalTotal: promotionCode.isNotEmpty ? 350000 : 380000,
              appliedPromotionCode: promotionCode.isNotEmpty
                  ? promotionCode
                  : null,
              identityChecked: true,
              phoneEligibilityChecked: true,
              requiresPhoneBeforeBooking: false,
            )
          : null,
      appliedVoucher: promotionCode.isNotEmpty
          ? VoucherModel(
              code: promotionCode,
              title: promotionCode,
              description: 'Giảm 30.000đ',
              discountAmount: 30000,
              discountPercent: 0,
              minOrderAmount: 0,
              expiryDate: '',
              isApplicable: true,
            )
          : null,
    ),
  );

  if (prefillQuote) {
    bloc.add(const RefreshBookingQuoteEvent());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  return bloc;
}

Widget _buildStep5Harness(BookingFlowBloc bloc) {
  return BlocProvider<BookingFlowBloc>.value(
    value: bloc,
    child: BlocBuilder<BookingFlowBloc, BookingFlowState>(
      builder: (context, state) {
        return BookingTripSummaryView(
          state: state,
          bloc: bloc,
          onBack: () => bloc.add(const PreviousStepEvent()),
          onNext: () => bloc.add(const NextStepEvent()),
          onStep: (index) => bloc.add(GoToStepEvent(index)),
          onDetails: () {},
        );
      },
    ),
  );
}

Future<void> _pumpWithViewport(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
  double textScale = 1.0,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (_, content) => MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          viewInsets: viewInsets,
        ),
        child: content!,
      ),
      home: child,
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('VexGoJakarta')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await loader.load();
  });
  testWidgets('Rejected promotion is not shown as accepted and can be edited', (
    tester,
  ) async {
    final repo = _FakeBookingRepo()..shouldFailQuote = true;
    final bloc = await _createStep5Bloc(
      tester,
      seatRepo: _FakeSeatRepo(),
      bookingRepo: repo,
      prefillQuote: false,
    );
    addTearDown(bloc.close);
    bloc.add(const ApplyPromotionCodeEvent('INVALID'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(bloc.state.quoteError, isNotNull);
    expect(bloc.state.quote, isNull);
    await _pumpWithViewport(tester, _buildStep5Harness(bloc));
    expect(find.text('Mã đã áp dụng: INVALID'), findsNothing);
    expect(find.text('Mã hợp lệ'), findsNothing);
    expect(find.text('Mã chưa được xác nhận: INVALID'), findsOneWidget);
    expect(find.text('Chọn hoặc nhập mã khuyến mãi'), findsOneWidget);
    expect(bloc.state.canProceed, isFalse);
  });
  testWidgets('Pending or invalidated quote hides prior promotion success', (
    tester,
  ) async {
    final bloc = await _createStep5Bloc(
      tester,
      seatRepo: _FakeSeatRepo(),
      bookingRepo: _FakeBookingRepo(),
      promotionCode: 'VEXGO30',
    );
    addTearDown(bloc.close);
    await _pumpWithViewport(tester, _buildStep5Harness(bloc));
    expect(find.text('Mã đã áp dụng: VEXGO30'), findsOneWidget);
    bloc.emit(bloc.state.copyWith(quoteLoading: true, clearQuote: true));
    await tester.pump();
    await tester.pump();
    expect(find.text('Mã đã áp dụng: VEXGO30'), findsNothing);
    expect(find.text('Đang kiểm tra mã: VEXGO30'), findsOneWidget);
    expect(bloc.state.canProceed, isFalse);
    bloc.emit(
      bloc.state.copyWith(
        quoteLoading: false,
        quoteError: 'Thông tin liên hệ đã thay đổi',
      ),
    );
    await tester.pump();
    expect(find.text('Mã hợp lệ'), findsNothing);
    expect(find.text('Mã chưa được xác nhận: VEXGO30'), findsOneWidget);
  });
  testWidgets('Edit buttons have Android 48dp touch targets', (tester) async {
    final bloc = await _createStep5Bloc(
      tester,
      seatRepo: _FakeSeatRepo(),
      bookingRepo: _FakeBookingRepo(),
    );
    addTearDown(bloc.close);
    await _pumpWithViewport(tester, _buildStep5Harness(bloc));
    for (final label in ['Sửa đón/trả', 'Đổi ghế', 'Sửa']) {
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byType(TextButton),
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    }
  });
  group('Step 5 Trip Summary UI & Regression Suite', () {
    testWidgets(
      '1. Step 5 embeds BookingCompactHeader on red surface with active step 5 (Xác nhận) and completed checkmarks on steps 1-4',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep5Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          prefillQuote: true,
        );

        final semantics = tester.ensureSemantics();
        await _pumpWithViewport(tester, _buildStep5Harness(bloc));

        final headerFinder = find.byKey(
          const ValueKey('booking-compact-header'),
        );
        expect(headerFinder, findsOneWidget);
        expect(
          find.descendant(
            of: headerFinder,
            matching: find.byType(BookingStepperCompact),
          ),
          findsOneWidget,
        );

        // Header shows Operator Name & Route
        expect(
          find.descendant(
            of: headerFinder,
            matching: find.text('Hoa Mai Limousine'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('TP. Hồ Chí Minh → Đà Lạt'), findsOneWidget);
        expect(find.text('Chi tiết xe'), findsOneWidget);

        // Steps 1-4 (indices 0, 1, 2, 3) show checkmarks
        expect(
          find.descendant(of: headerFinder, matching: find.byIcon(Icons.check)),
          findsNWidgets(4),
        );

        // Step 5 (index 4: Xác nhận) is active and visible
        final step5Finder = find.byKey(
          const ValueKey('booking-stepper-item-4'),
        );
        expect(step5Finder, findsOneWidget);
        final step5Rect = tester.getRect(step5Finder);
        expect(step5Rect.left, greaterThanOrEqualTo(0));
        expect(step5Rect.right, lessThanOrEqualTo(390));

        semantics.dispose();
        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '2. Displays all 5 core summary sections with functional Edit buttons navigating back to prior steps',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep5Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          prefillQuote: true,
        );

        await _pumpWithViewport(tester, _buildStep5Harness(bloc));

        // 1. Trip & Route Card
        expect(find.text('Bến xe Miền Tây'), findsOneWidget);
        expect(find.text('Bến xe Liên tỉnh Đà Lạt'), findsOneWidget);
        expect(find.text('Sửa đón/trả'), findsOneWidget);

        // 2. Seats Card
        expect(find.text('Chỗ ngồi đã chọn'), findsOneWidget);
        expect(find.text('A01'), findsOneWidget);
        expect(find.text('A02'), findsOneWidget);
        expect(find.text('Đổi ghế'), findsOneWidget);

        // 3. Passenger Info Card
        expect(find.text('Thông tin hành khách'), findsOneWidget);
        expect(find.text('Phạm Minh Tài'), findsOneWidget);
        expect(find.text('0901234567'), findsOneWidget);
        expect(find.text('minhtai@vexgo.vn'), findsOneWidget);

        // 4. Voucher Card
        expect(find.text('Mã khuyến mãi & ưu đãi'), findsOneWidget);
        expect(find.text('Chọn hoặc nhập mã khuyến mãi'), findsOneWidget);

        // 5. Price Breakdown Card
        expect(find.text('Chi tiết thanh toán'), findsOneWidget);
        expect(find.text('Giá vé (2 chỗ)'), findsOneWidget);
        expect(find.text('Phí dịch vụ'), findsOneWidget);
        expect(find.text('Miễn phí'), findsOneWidget);

        // Test Edit button to Seats (Step 0)
        await tester.tap(find.text('Đổi ghế'));
        await tester.pump();
        expect(bloc.state.step, BookingStep.seatSelection);

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '3. Quote loading, error, and retry states show appropriate indicators and control CTA state',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep5Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          prefillQuote: false,
        );

        // Set quote loading state
        bloc.emit(bloc.state.copyWith(quoteLoading: true));
        await _pumpWithViewport(tester, _buildStep5Harness(bloc));

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Đang cập nhật giá vé & ưu đãi...'), findsOneWidget);

        // CTA is disabled while quote is loading
        final ctaBtn = tester.widget<ElevatedButton>(
          find.descendant(
            of: find.byType(BookingTripSummaryDock),
            matching: find.byType(ElevatedButton),
          ),
        );
        expect(ctaBtn.onPressed, isNull);

        // Set quote error state
        bloc.emit(
          bloc.state.copyWith(
            quoteLoading: false,
            clearQuote: true,
            quoteError: 'Không thể tải báo giá vé. Vui lòng kiểm tra kết nối.',
          ),
        );
        await tester.pump();

        expect(
          find.text('Không thể tải báo giá vé. Vui lòng kiểm tra kết nối.'),
          findsOneWidget,
        );
        expect(find.text('Cập nhật giá vé'), findsOneWidget);

        // Tapping retry dispatches RefreshBookingQuoteEvent
        await tester.tap(find.text('Cập nhật giá vé'));
        await tester.pump();
        expect(bookingRepo.quoteCalls, 1);

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '4. Promotion dialog workflow: enter valid code, apply, show discount, and remove code cleanly',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep5Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          prefillQuote: false,
        );

        await _pumpWithViewport(tester, _buildStep5Harness(bloc));

        // Tap to enter code
        final voucherBtnFinder = find.text('Chọn hoặc nhập mã khuyến mãi');
        await tester.scrollUntilVisible(
          voucherBtnFinder,
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(voucherBtnFinder);
        await tester.pumpAndSettle();

        expect(find.text('Mã khuyến mãi'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.text('Kiểm tra mã'), findsOneWidget);

        await tester.enterText(find.byType(TextFormField), 'VEXGO30');
        await tester.tap(find.text('Kiểm tra mã'));
        await tester.pumpAndSettle();

        // Verify ApplyPromotionCodeEvent was handled
        expect(bookingRepo.quoteCalls, 1);
        expect(bookingRepo.lastCode, 'VEXGO30');

        // Verify applied state UI
        await _pumpWithViewport(tester, _buildStep5Harness(bloc));
        expect(find.text('Mã đã áp dụng: VEXGO30'), findsOneWidget);
        expect(find.textContaining('Tiết kiệm được'), findsOneWidget);
        expect(find.textContaining('30.000'), findsWidgets);
        expect(find.text('Bỏ mã'), findsOneWidget);

        // Tapping inline 'Bỏ mã' removes voucher
        final removeBtnFinder = find.text('Bỏ mã');
        await tester.scrollUntilVisible(
          removeBtnFinder,
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(removeBtnFinder);
        await tester.pump();
        expect(bloc.state.appliedVoucher, isNull);

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '5. Bottom dock displays accurate total, discount savings, and tapping CTA advances to Step 6',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep5Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          promotionCode: 'VEXGO30',
        );

        await _pumpWithViewport(tester, _buildStep5Harness(bloc));

        // Dock shows final amount after discount (380k - 30k = 350k)
        expect(find.text('Tổng thanh toán:'), findsOneWidget);
        expect(find.textContaining('350.000'), findsWidgets);
        expect(find.textContaining('30.000'), findsWidgets);

        // Tap CTA 'Thanh toán'
        await tester.tap(
          find.descendant(
            of: find.byType(BookingTripSummaryDock),
            matching: find.text('Thanh toán'),
          ),
        );
        await tester.pump();
        expect(bloc.state.step, BookingStep.payment);

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '6. Seat hold expiry disables CTA and reveals warning message',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep5Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          prefillQuote: true,
        );

        // Expire hold
        bloc.emit(
          bloc.state.copyWith(countdownSeconds: 0, clearSeatHold: true),
        );
        await _pumpWithViewport(tester, _buildStep5Harness(bloc));

        expect(
          find.text('Thời gian giữ ghế đã hết. Vui lòng chọn lại ghế.'),
          findsOneWidget,
        );

        final ctaBtn = tester.widget<ElevatedButton>(
          find.descendant(
            of: find.byType(BookingTripSummaryDock),
            matching: find.byType(ElevatedButton),
          ),
        );
        expect(ctaBtn.onPressed, isNull);

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '7. Responsive check: 320x740 narrow screen with 2.0x text scale renders without overflow and keeps all actions reachable',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep5Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          promotionCode: 'VEXGO30',
        );

        await _pumpWithViewport(
          tester,
          _buildStep5Harness(bloc),
          size: const Size(320, 740),
          textScale: 2.0,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(BookingCompactHeader), findsOneWidget);
        expect(find.text('Chi tiết thanh toán'), findsOneWidget);
        expect(find.byType(BookingTripSummaryDock), findsOneWidget);

        // Scroll to the bottom to verify price rows and policy banner are reachable
        await tester.scrollUntilVisible(
          find.byIcon(Icons.verified_user_rounded),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '8. Responsive check: Landscape 640x360 with 2.0x text scale and keyboard insets scrolls cleanly without overflow',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep5Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          prefillQuote: true,
        );

        await _pumpWithViewport(
          tester,
          _buildStep5Harness(bloc),
          size: const Size(640, 360),
          textScale: 2.0,
          viewInsets: const EdgeInsets.only(bottom: 120),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(BookingCompactHeader), findsOneWidget);
        expect(find.byType(BookingTripSummaryDock), findsOneWidget);

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '9. Full flow integration: Step 4 -> Step 5 -> Step 6 with BookingTripSummaryView',
      (tester) async {
        final user = UserModel(
          taiKhoanId: 101,
          maKhachHang: 'KH101',
          hoTen: 'Lê Minh Hoàng',
          soDienThoai: '0987654321',
          email: 'hoang@vexgo.vn',
        );
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final authRepo = _FakeAuthRepo(currentUser: user);
        final authBloc = AuthBloc(authRepository: authRepo)
          ..add(const CheckAuthStatusEvent());
        await tester.pump(const Duration(milliseconds: 50));

        await _pumpWithViewport(
          tester,
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<SeatRepository>.value(value: seatRepo),
              RepositoryProvider<BookingRepository>.value(value: bookingRepo),
            ],
            child: BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: BookingFlowScreen(
                trip: _trip,
                date: DateTime(2026, 10, 27),
              ),
            ),
          ),
          size: const Size(800, 900),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Step 1: Seat Selection
        expect(find.byType(BookingSelectionView), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('seat-01')));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Tiếp tục'));
        await tester.pump(const Duration(milliseconds: 100));

        // Step 2: Pickup
        expect(find.byType(BookingSelectionView), findsOneWidget);
        await tester.tap(find.text('Tiếp tục'));
        await tester.pump(const Duration(milliseconds: 100));

        // Step 3: Dropoff
        expect(find.byType(BookingSelectionView), findsOneWidget);
        await tester.tap(find.text('Tiếp tục'));
        await tester.pump(const Duration(milliseconds: 100));

        // Step 4: Passenger Info
        expect(find.byType(BookingPassengerInfoView), findsOneWidget);
        expect(find.byType(Step4PassengerInfo), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('passenger-name-input')),
          'Lê Minh Hoàng',
        );
        await tester.enterText(
          find.byKey(const ValueKey('passenger-phone-input')),
          '0987654321',
        );
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('Tiếp tục'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Step 5: BookingTripSummaryView is mounted!
        expect(find.byType(BookingTripSummaryView), findsOneWidget);
        expect(find.byType(Step5TripSummary), findsOneWidget);
        expect(find.text('Lê Minh Hoàng'), findsOneWidget);
        expect(find.text('0987654321'), findsOneWidget);

        // Advance from Step 5 to Step 6 (Step6Payment)
        await tester.tap(
          find.descendant(
            of: find.byType(BookingTripSummaryDock),
            matching: find.text('Thanh toán'),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(Step6Payment), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
        unawaited(authBloc.close());
      },
    );

    testWidgets(
      '10. Passenger card alignment: short labels (Họ tên, Số điện thoại, Email) align columns and format email without orphan .com wrap',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep5Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
        );

        // Emit state with customer details from user screenshot
        bloc.emit(
          bloc.state.copyWith(
            passengerName: 'Pham Minh Tai',
            passengerPhone: '+84582061913',
            passengerEmail: 'nguyen221205@gmail.com',
          ),
        );

        await _pumpWithViewport(
          tester,
          _buildStep5Harness(bloc),
          size: const Size(390, 844),
          textScale: 1.0,
        );

        // Verify shortened labels exist and old labels do not exist
        expect(find.text('Họ tên'), findsOneWidget);
        expect(find.text('Số điện thoại'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Họ tên hành khách:'), findsNothing);
        expect(find.text('Email nhận vé:'), findsNothing);

        // Verify values are present
        expect(find.text('Pham Minh Tai'), findsOneWidget);
        expect(find.text('+84582061913'), findsOneWidget);
        expect(find.text('nguyen221205@gmail.com'), findsOneWidget);

        // Check geometry: left coordinates of labels are equal (aligned)
        final nameLabelPos = tester.getTopLeft(find.text('Họ tên'));
        final phoneLabelPos = tester.getTopLeft(find.text('Số điện thoại'));
        final emailLabelPos = tester.getTopLeft(find.text('Email'));
        expect(nameLabelPos.dx, equals(phoneLabelPos.dx));
        expect(nameLabelPos.dx, equals(emailLabelPos.dx));

        // Check geometry: right coordinates of values are equal (aligned)
        final nameValPos = tester.getTopRight(find.text('Pham Minh Tai'));
        final phoneValPos = tester.getTopRight(find.text('+84582061913'));
        final emailValPos = tester.getTopRight(
          find.text('nguyen221205@gmail.com'),
        );
        expect(nameValPos.dx, equals(phoneValPos.dx));
        expect(nameValPos.dx, equals(emailValPos.dx));

        // Ensure email text renders on single line (height equal to 1-line text height)
        final emailSize = tester.getSize(find.text('nguyen221205@gmail.com'));
        final phoneSize = tester.getSize(find.text('+84582061913'));
        expect(emailSize.height, equals(phoneSize.height));

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '11. Passenger card: long names, long emails, and empty fallbacks render without overflow on 320dp 2.0x and 640x360 landscape',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep5Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
        );

        // Case A: Long customer info on 320dp with 2.0x text scale
        bloc.emit(
          bloc.state.copyWith(
            passengerName: 'Nguyễn Hoàng Anh Thư',
            passengerPhone: '+84901234567',
            passengerEmail: 'nguyen.hoang.anh.thu.1998@congtycophan.vn',
          ),
        );

        await _pumpWithViewport(
          tester,
          _buildStep5Harness(bloc),
          size: const Size(320, 740),
          textScale: 2.0,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Họ tên'), findsOneWidget);
        expect(find.text('Số điện thoại'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Nguyễn Hoàng Anh Thư'), findsOneWidget);
        expect(find.text('+84901234567'), findsOneWidget);
        expect(
          find.text('nguyen.hoang.anh.thu.1998@congtycophan.vn'),
          findsOneWidget,
        );

        // Case B: Fallback when email is empty on Landscape 640x360 at 2.0x
        bloc.emit(
          bloc.state.copyWith(
            passengerName: 'Trần Văn Nam',
            passengerPhone: '0988776655',
            passengerEmail: '',
          ),
        );

        await _pumpWithViewport(
          tester,
          _buildStep5Harness(bloc),
          size: const Size(640, 360),
          textScale: 2.0,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Chưa cung cấp (tùy chọn)'), findsOneWidget);
        expect(find.text('Sửa'), findsWidgets);

        await tester.runAsync(bloc.close);
      },
    );
  });
}
