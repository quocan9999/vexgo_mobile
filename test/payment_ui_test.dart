import 'package:vexgo_app/data/models/booking_cargo_model.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/booking_model.dart';
import 'package:vexgo_app/data/models/booking_quote_model.dart';
import 'package:vexgo_app/data/models/seat_hold_model.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
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
import 'package:vexgo_app/features/user/booking/presentation/steps/step_6_payment.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_payment_view.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/payment_display_state.dart';
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

class _MockBookingRepo extends MockBookingRepository {
  int quoteCalls = 0;
  int createBookingCalls = 0;

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
    final subtotal = seatIds.length * 190000;
    return BookingQuoteModel(
      unitPrice: 190000,
      seatCount: seatIds.length,
      originalTotal: subtotal,
      discountAmount: 0,
      serviceFee: 0,
      finalTotal: subtotal,
      identityChecked: true,
      phoneEligibilityChecked: true,
      requiresPhoneBeforeBooking: false,
    );
  }

  @override
  Future<TicketModel> createBooking({
    required TicketTripSummary trip,
    required List<String> seats,
    List<int>? seatIds,
    String? holdToken,
    required int totalAmount,
    required int discountAmount,
    required int finalAmount,
    required String paymentMethod,
    required PassengerInfo passenger,
    String? promotionCode,
  }) async {
    createBookingCalls++;
    return TicketModel.fromJson({
      'id': 'tk-mock-1',
      'ticketCode': 'VG-MOCK-VE-01',
      'status': 'upcoming',
    });
  }
}

class _FakeBookingRepo implements BookingRepository {
  int quoteCalls = 0;
  int createApiBookingCalls = 0;
  int getBookingByIdCalls = 0;
  BookingModel? bookingToReturn;

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
    final subtotal = seatIds.length * 190000;
    return BookingQuoteModel(
      unitPrice: 190000,
      seatCount: seatIds.length,
      originalTotal: subtotal,
      discountAmount: 0,
      serviceFee: 0,
      finalTotal: subtotal,
      identityChecked: true,
      phoneEligibilityChecked: true,
      requiresPhoneBeforeBooking: false,
    );
  }

  @override
  Future<BookingModel> createApiBooking({
    required int tripId,
    required List<int> seatIds,
    required String pickupPoint,
    required String dropoffPoint,
    required PassengerInfo contact,
    String? holdToken,
    String? promotionCode,
    BookingQuoteModel? expectedPromotionQuote,
    BookingCargoDraft? cargo,
  }) async {
    createApiBookingCalls++;
    return bookingToReturn ??
        BookingModel(
          bookingId: 777,
          bookingCode: 'VG-777-TEST',
          tripId: tripId,
          status: BookingStatus.pending,
          contact: contact,
          pickupPoint: pickupPoint,
          dropoffPoint: dropoffPoint,
          seats: const ['A01', 'A02'],
          seatIds: seatIds,
          totalAmount: 380000,
          originalAmount: 380000,
          discountAmount: 0,
          orderCode: 'VG777TEST',
          paymentStatus: 'CHO_THANH_TOAN',
          paymentMethod: 'vietqr',
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        );
  }

  @override
  Future<BookingModel?> getBookingById(dynamic bookingId) async {
    getBookingByIdCalls++;
    return bookingToReturn ??
        BookingModel(
          bookingId: 777,
          bookingCode: 'VG-777-TEST',
          tripId: 769,
          status: BookingStatus.pending,
          contact: const PassengerInfo(
            fullName: 'Nguyen Van A',
            phone: '0901234567',
            email: 'nguyenvana@gmail.com',
          ),
          pickupPoint: _pickup.name,
          dropoffPoint: _dropoff.name,
          seats: const ['A01', 'A02'],
          seatIds: const [1, 2],
          totalAmount: 380000,
          originalAmount: 380000,
          discountAmount: 0,
          orderCode: 'VG777TEST',
          paymentStatus: 'CHO_THANH_TOAN',
          paymentMethod: 'vietqr',
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<BookingFlowBloc> _createStep6Bloc(
  WidgetTester tester, {
  required _FakeSeatRepo seatRepo,
  required BookingRepository bookingRepo,
  bool prefillQuote = true,
  bool hasPendingOrder = false,
  DateTime? customExpiry,
}) async {
  final bloc = BookingFlowBloc(
    seatRepository: seatRepo,
    bookingRepository: bookingRepo,
  );

  final seats = [
    _makeSeat('01', 1, 1, price: 190000),
    _makeSeat('02', 1, 2, price: 190000),
  ];

  final hold = SeatHoldModel(
    holdToken: 'hold-token-valid',
    tripId: 769,
    seatIds: const [1, 2],
    expiresAt: DateTime.now().add(const Duration(minutes: 10)),
  );

  BookingModel? checkoutBooking;
  if (hasPendingOrder) {
    checkoutBooking = BookingModel(
      bookingId: 777,
      bookingCode: 'VG-777-TEST',
      tripId: 769,
      status: BookingStatus.pending,
      contact: const PassengerInfo(
        fullName: 'Nguyen Van A',
        phone: '0901234567',
        email: 'nguyenvana@gmail.com',
      ),
      pickupPoint: _pickup.name,
      dropoffPoint: _dropoff.name,
      seats: const ['A01', 'A02'],
      seatIds: const [1, 2],
      totalAmount: 380000,
      originalAmount: 380000,
      discountAmount: 0,
      orderCode: 'VG777TEST',
      paymentStatus: 'CHO_THANH_TOAN',
      paymentMethod: 'vietqr',
      expiresAt:
          customExpiry ?? DateTime.now().add(const Duration(minutes: 10)),
      tickets: [
        TicketModel.fromJson({
          'id': 'tk-1',
          'ticketCode': 'VG-777-TEST-VE-01',
          'status': 'upcoming',
        }),
        TicketModel.fromJson({
          'id': 'tk-2',
          'ticketCode': 'VG-777-TEST-VE-02',
          'status': 'upcoming',
        }),
      ],
    );
  }

  bloc.emit(
    BookingFlowState(
      step: BookingStep.payment,
      trip: _trip,
      date: DateTime(2026, 10, 28),
      selectedSeats: seats,
      selectedPickupPoint: _pickup,
      selectedDropoffPoint: _dropoff,
      passengerName: 'Nguyen Van A',
      passengerPhone: '0901234567',
      passengerEmail: 'nguyenvana@gmail.com',
      selectedPaymentMethod: 'vietqr',
      seatHold: hasPendingOrder ? null : hold,
      countdownSeconds: 600,
      requiresAuthoritativeQuote: false,
      quote: prefillQuote
          ? const BookingQuoteModel(
              unitPrice: 190000,
              seatCount: 2,
              originalTotal: 380000,
              discountAmount: 0,
              serviceFee: 0,
              finalTotal: 380000,
              identityChecked: true,
              phoneEligibilityChecked: true,
              requiresPhoneBeforeBooking: false,
            )
          : null,
      pendingBookingId: hasPendingOrder ? 777 : null,
      checkoutBooking: checkoutBooking,
      pendingPaymentAmount: hasPendingOrder ? 380000 : null,
      status: hasPendingOrder
          ? BookingFlowStatus.paymentPending
          : BookingFlowStatus.loaded,
      pendingQrCodeUrl: hasPendingOrder
          ? 'https://img.vietqr.io/image/MB-0000000001-compact2.png?amount=380000&addInfo=VG777TEST'
          : null,
    ),
  );

  return bloc;
}

Widget _buildStep6Harness(BookingFlowBloc bloc) {
  return BlocProvider<BookingFlowBloc>.value(
    value: bloc,
    child: BlocBuilder<BookingFlowBloc, BookingFlowState>(
      builder: (context, state) {
        return BookingPaymentView(
          state: state,
          bloc: bloc,
          onBack: () => bloc.add(const PreviousStepEvent()),
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
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          viewInsets: viewInsets,
        ),
        child: child,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
  });

  testWidgets(
    'Rejected inconsistent payment evidence never shows a paid banner',
    (tester) async {
      final repo = _FakeBookingRepo();
      final bloc = await _createStep6Bloc(
        tester,
        seatRepo: _FakeSeatRepo(),
        bookingRepo: repo,
        hasPendingOrder: true,
      );
      addTearDown(bloc.close);
      repo.bookingToReturn = bloc.state.checkoutBooking!.copyWith(
        status: BookingStatus.paid,
        paymentStatus: 'CHO_THANH_TOAN',
      );
      bloc.add(const ConfirmPaymentEvent());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(bloc.state.status, BookingFlowStatus.failure);
      expect(bloc.state.paymentConfirmed, isFalse);
      await _pumpWithViewport(tester, _buildStep6Harness(bloc));
      expect(find.text('Đã xác nhận thanh toán'), findsNothing);
      expect(
        find.text('Đã xác nhận thanh toán. Nhấn kiểm tra để nhận vé.'),
        findsNothing,
      );
      expect(
        find.textContaining('1. Mở ứng dụng ngân hàng và chuyển khoản'),
        findsNothing,
      );
      expect(
        find.textContaining('Vui lòng không chuyển thêm tiền'),
        findsOneWidget,
      );
      expect(repo.createApiBookingCalls, 0);
    },
  );

  testWidgets(
    'Cancelled order hides transfer guidance and retains existing-order recheck',
    (tester) async {
      final repo = _FakeBookingRepo();
      final bloc = await _createStep6Bloc(
        tester,
        seatRepo: _FakeSeatRepo(),
        bookingRepo: repo,
        hasPendingOrder: true,
      );
      addTearDown(bloc.close);
      repo.bookingToReturn = bloc.state.checkoutBooking!.copyWith(
        status: BookingStatus.cancelled,
        paymentStatus: 'DA_HUY',
      );
      bloc.add(const ConfirmPaymentEvent());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(bloc.state.checkoutBooking!.status, BookingStatus.cancelled);
      await _pumpWithViewport(tester, _buildStep6Harness(bloc));
      expect(find.text('Thông tin chuyển khoản VietQR'), findsNothing);
      expect(
        find.textContaining('1. Mở ứng dụng ngân hàng và chuyển khoản'),
        findsNothing,
      );
      expect(
        find.textContaining('Vui lòng không chuyển thêm tiền'),
        findsOneWidget,
      );
      final check = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Kiểm tra kết quả thanh toán'),
      );
      expect(check.onPressed, isNotNull);
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Kiểm tra kết quả thanh toán'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.getBookingByIdCalls, 2);
      expect(repo.createApiBookingCalls, 0);
    },
  );

  testWidgets(
    'Confirmation is scoped to current order and not inferred from status fields',
    (tester) async {
      final bloc = await _createStep6Bloc(
        tester,
        seatRepo: _FakeSeatRepo(),
        bookingRepo: _FakeBookingRepo(),
        hasPendingOrder: true,
      );
      addTearDown(bloc.close);
      final paidFieldsOnly = bloc.state.copyWith(
        checkoutBooking: bloc.state.checkoutBooking!.copyWith(
          status: BookingStatus.paid,
          paymentStatus: 'DA_THANH_TOAN',
        ),
      );
      expect(paidFieldsOnly.hasConfirmedPayment, isFalse);
      final confirmed = paidFieldsOnly.copyWith(paymentConfirmed: true);
      expect(confirmed.hasConfirmedPayment, isTrue);
      expect(
        confirmed.copyWith(pendingBookingId: 888).hasConfirmedPayment,
        isFalse,
      );
      expect(
        confirmed.copyWith(bookingOutcomeUnknown: true).hasConfirmedPayment,
        isFalse,
      );
      expect(confirmed.canDisplayBankTransfer(DateTime.now()), isFalse);
    },
  );

  testWidgets(
    'Transfer instructions require a current payable order and valid deadline',
    (tester) async {
      final bloc = await _createStep6Bloc(
        tester,
        seatRepo: _FakeSeatRepo(),
        bookingRepo: _FakeBookingRepo(),
        hasPendingOrder: true,
      );
      addTearDown(bloc.close);
      final state = bloc.state;
      expect(state.canDisplayBankTransfer(DateTime.now()), isTrue);
      expect(
        state.canDisplayBankTransfer(state.checkoutBooking!.expiresAt!),
        isFalse,
      );
      expect(
        state.paymentDeadlineExpired(state.checkoutBooking!.expiresAt!),
        isTrue,
      );
      expect(
        state
            .copyWith(status: BookingFlowStatus.failure)
            .canDisplayBankTransfer(DateTime.now()),
        isFalse,
      );
      expect(
        state
            .copyWith(pendingBookingId: 888)
            .canDisplayBankTransfer(DateTime.now()),
        isFalse,
      );
      expect(
        state
            .copyWith(pendingPaymentAmount: 1)
            .canDisplayBankTransfer(DateTime.now()),
        isFalse,
      );
    },
  );

  group('Step 6 Payment UI & Regression Suite', () {
    testWidgets(
      '1. BookingPaymentView renders unified BookingCompactHeader & 6-step BookingStepperCompact with Step 6 active',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep6Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
        );

        await _pumpWithViewport(tester, _buildStep6Harness(bloc));

        // Header and Stepper checks
        expect(find.byType(BookingCompactHeader), findsOneWidget);
        expect(find.byType(BookingStepperCompact), findsOneWidget);
        expect(find.text('Hoa Mai Limousine'), findsOneWidget);
        expect(find.text('Chi tiết xe'), findsOneWidget);

        // Step 6 should be the active step (Thanh toán vé)
        final step6Item = find.byKey(const ValueKey('booking-stepper-item-5'));
        expect(step6Item, findsOneWidget);

        // Prior steps should be completed with checkmarks
        expect(
          find.byIcon(Icons.check),
          findsNWidgets(5),
        ); // Steps 0, 1, 2, 3, 4

        // Tapping prior step 4 (Xác nhận) should dispatch GoToStepEvent(4)
        final step4Item = find.byKey(const ValueKey('booking-stepper-item-4'));
        await tester.ensureVisible(step4Item);
        await tester.tap(step4Item);
        await tester.pump();

        expect(bloc.state.step, BookingStep.tripSummary);

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '2. Pre-order screen displays quoted total, route recap, seat chips, VietQR tile, instructions, and CTA',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep6Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
        );

        await _pumpWithViewport(tester, _buildStep6Harness(bloc));

        // Quoted amount
        expect(find.text('Số tiền thanh toán'), findsOneWidget);
        expect(find.textContaining('380.000'), findsAtLeastNWidgets(1));
        expect(find.text('2 Vé'), findsOneWidget);

        // Trip & Seats Recap
        expect(find.text('Ghế A01'), findsOneWidget);
        expect(find.text('Ghế A02'), findsOneWidget);
        expect(find.textContaining('Bến xe Miền Tây'), findsAtLeastNWidgets(1));
        expect(
          find.textContaining('Bến xe Liên tỉnh Đà Lạt'),
          findsAtLeastNWidgets(1),
        );

        // Payment Method Tile (Real Mode VietQR only)
        expect(find.text('Chuyển khoản VietQR'), findsOneWidget);
        expect(find.text('Khuyên dùng'), findsOneWidget);
        expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);

        // Bottom Dock CTA
        expect(find.byType(BookingPaymentDock), findsOneWidget);
        expect(find.textContaining('Thanh toán 380.000'), findsOneWidget);

        // Mutation isolation: createApiBooking has not been called yet
        expect(bookingRepo.createApiBookingCalls, 0);

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '3. Double-tap protection: tapping CTA dispatches ConfirmPaymentEvent without duplicating calls',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _MockBookingRepo();
        final bloc = await _createStep6Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
        );

        await _pumpWithViewport(tester, _buildStep6Harness(bloc));

        final cta = find.widgetWithText(
          ElevatedButton,
          'Thanh toán 380.000\u00A0đ',
        );
        final targetButton = cta.evaluate().isNotEmpty
            ? cta
            : find.widgetWithText(ElevatedButton, 'Thanh toán 380.000 đ');

        // Tap once
        await tester.tap(targetButton.first);
        await tester.pump();

        // While submitting, double tap should be blocked
        await tester.tap(targetButton.first, warnIfMissed: false);
        await tester.pump();

        expect(bookingRepo.createBookingCalls, 1);

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '4. Post-order pending state renders booking code, order code, tickets, account details, and copy buttons',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep6Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          hasPendingOrder: true,
        );

        await _pumpWithViewport(tester, _buildStep6Harness(bloc));

        // Booking information
        expect(find.text('Đơn đặt chỗ: #777'), findsOneWidget);
        expect(find.text('Mã đặt vé: VG-777-TEST'), findsOneWidget);
        expect(find.text('Mã vé: VG-777-TEST-VE-01'), findsOneWidget);
        expect(find.text('Mã vé: VG-777-TEST-VE-02'), findsOneWidget);
        expect(
          find.textContaining('tra cứu bằng số điện thoại'),
          findsOneWidget,
        );

        // Transfer details
        expect(find.text('Thông tin chuyển khoản VietQR'), findsOneWidget);
        expect(
          find.textContaining('Nội dung chuyển khoản: VG777TEST'),
          findsOneWidget,
        );
        expect(find.textContaining('Ngân hàng:'), findsOneWidget);
        expect(find.textContaining('Số tài khoản:'), findsOneWidget);
        expect(find.textContaining('Chủ tài khoản:'), findsOneWidget);

        // Copy buttons are present
        expect(find.byIcon(Icons.copy_rounded), findsAtLeastNWidgets(3));

        // Dock CTA changes to 'Kiểm tra kết quả thanh toán'
        expect(find.text('Kiểm tra kết quả thanh toán'), findsOneWidget);

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '5. Copy button copies text to clipboard and reveals feedback SnackBar',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep6Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          hasPendingOrder: true,
        );

        await _pumpWithViewport(tester, _buildStep6Harness(bloc));

        // Tap copy button for booking code
        final copyButtons = find.byIcon(Icons.copy_rounded);
        await tester.tap(copyButtons.first);
        await tester.pump();

        // Verify SnackBar feedback
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Đã sao chép'), findsOneWidget);

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '6. Authoritative deadline handling: expired order stops rendering QR and displays expiration alert',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final pastExpiry = DateTime.now().subtract(const Duration(minutes: 5));
        final bloc = await _createStep6Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          hasPendingOrder: true,
          customExpiry: pastExpiry,
        );

        await _pumpWithViewport(tester, _buildStep6Harness(bloc));

        // When expired, the expiration warning should appear
        expect(find.text('Đơn đặt vé đã hết hạn thanh toán'), findsOneWidget);
        expect(
          find.textContaining(
            'Thời gian giữ chỗ và thanh toán của đơn đã kết thúc',
          ),
          findsOneWidget,
        );

        // QR image and transfer info should NOT be rendered when expired
        expect(find.text('Thông tin chuyển khoản VietQR'), findsNothing);
        expect(find.byType(Image), findsNothing);

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '7. Re-check action calls getBookingById for existing pending order without creating new booking',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep6Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          hasPendingOrder: true,
        );

        await _pumpWithViewport(tester, _buildStep6Harness(bloc));

        final checkBtn = find.widgetWithText(
          ElevatedButton,
          'Kiểm tra kết quả thanh toán',
        );
        await tester.tap(checkBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should call getBookingById, but NOT createApiBooking
        expect(bookingRepo.getBookingByIdCalls, 1);
        expect(bookingRepo.createApiBookingCalls, 0);

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets('8. Unknown outcome and error states render clear guidance', (
      tester,
    ) async {
      final seatRepo = _FakeSeatRepo();
      final bookingRepo = _FakeBookingRepo();
      final bloc = await _createStep6Bloc(
        tester,
        seatRepo: seatRepo,
        bookingRepo: bookingRepo,
      );

      // Set unknown outcome
      bloc.emit(bloc.state.copyWith(bookingOutcomeUnknown: true));

      await _pumpWithViewport(tester, _buildStep6Harness(bloc));

      expect(find.text('Kết quả tạo đơn chưa xác định'), findsOneWidget);
      expect(
        find.textContaining(
          'Không gửi lại yêu cầu để tránh trừ tiền nhiều lần',
        ),
        findsOneWidget,
      );

      // CTA should be disabled when outcome is unknown
      final ctaBtn = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).last,
      );
      expect(ctaBtn.onPressed, isNull);

      await tester.runAsync(bloc.close);
    });

    testWidgets(
      '9. Responsive check: 320x740 narrow screen with 2.0x text scale renders without overflow and keeps actions reachable',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep6Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          hasPendingOrder: true,
        );

        await _pumpWithViewport(
          tester,
          _buildStep6Harness(bloc),
          size: const Size(320, 740),
          textScale: 2.0,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(BookingCompactHeader), findsOneWidget);
        expect(find.byType(BookingPaymentDock), findsOneWidget);
        expect(find.text('Kiểm tra kết quả thanh toán'), findsOneWidget);

        // Scroll down to verify instructions card is reachable
        await tester.scrollUntilVisible(
          find.text('Hướng dẫn sau khi chuyển tiền'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Hướng dẫn sau khi chuyển tiền'), findsOneWidget);

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '10. Responsive check: Landscape 640x360 with 2.0x text scale and keyboard insets scrolls cleanly without overflow',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final bloc = await _createStep6Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
        );

        await _pumpWithViewport(
          tester,
          _buildStep6Harness(bloc),
          size: const Size(640, 360),
          textScale: 2.0,
          viewInsets: const EdgeInsets.only(bottom: 120),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(BookingPaymentDock), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Chuyển khoản VietQR'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Chuyển khoản VietQR'), findsOneWidget);

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '11. Full flow integration: Step 4 -> Step 5 -> Step 6 with BookingPaymentView',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final authRepo = _FakeAuthRepo(
          currentUser: const UserModel(
            taiKhoanId: 101,
            maKhachHang: 'KH001',
            hoTen: 'Lê Minh Hoàng',
            soDienThoai: '0987654321',
            email: 'hoang@gmail.com',
          ),
        );

        final authBloc = AuthBloc(authRepository: authRepo);
        authBloc.add(const CheckAuthStatusEvent());
        await tester.pump();

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<SeatRepository>.value(value: seatRepo),
              RepositoryProvider<BookingRepository>.value(value: bookingRepo),
              RepositoryProvider<AuthRepository>.value(value: authRepo),
            ],
            child: MultiBlocProvider(
              providers: [BlocProvider<AuthBloc>.value(value: authBloc)],
              child: MaterialApp(
                home: BookingFlowScreen(
                  trip: _trip,
                  date: DateTime(2026, 10, 28),
                  ticketCount: 1,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Step 1: select seat A01
        await tester.tap(find.byKey(const ValueKey('seat-01')));
        await tester.pumpAndSettle();

        // Step 2: continue to pickup
        await tester.tap(find.text('Tiếp tục'));
        await tester.pumpAndSettle();

        // Step 3: continue to dropoff
        await tester.tap(find.text('Tiếp tục'));
        await tester.pumpAndSettle();

        // Step 4: continue to passenger info
        await tester.tap(find.text('Tiếp tục'));
        await tester.pumpAndSettle();

        // Enter contact info
        await tester.enterText(
          find.byKey(const ValueKey('passenger-name-input')),
          'Lê Minh Hoàng',
        );
        await tester.enterText(
          find.byKey(const ValueKey('passenger-phone-input')),
          '0987654321',
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Advance to Step 5
        await tester.tap(find.text('Tiếp tục'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(BookingTripSummaryView), findsOneWidget);

        // Advance from Step 5 to Step 6
        await tester.tap(
          find.descendant(
            of: find.byType(BookingTripSummaryDock),
            matching: find.text('Thanh toán'),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Step 6: BookingPaymentView and Step6Payment are mounted!
        expect(find.byType(BookingPaymentView), findsOneWidget);
        expect(find.byType(Step6Payment), findsOneWidget);
        expect(find.text('Chuyển khoản VietQR'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
        unawaited(authBloc.close());
      },
    );

    testWidgets(
      '12. R1 regression: paid order with ticket-sync failure displays payment confirmation and is not labelled expired',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final pastExpiry = DateTime.now().subtract(const Duration(minutes: 5));
        final bloc = await _createStep6Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          hasPendingOrder: true,
          customExpiry: pastExpiry,
        );

        // Simulate paid booking where ticket sync failed
        bookingRepo.bookingToReturn = bloc.state.checkoutBooking!.copyWith(
          status: BookingStatus.paid,
          paymentStatus: 'DA_THANH_TOAN',
        );
        bloc.add(const ConfirmPaymentEvent());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(bloc.state.paymentConfirmed, isTrue);
        expect(bloc.state.status, BookingFlowStatus.failure);
        expect(bloc.state.checkoutBooking!.isPaid, isTrue);

        await _pumpWithViewport(tester, _buildStep6Harness(bloc));

        // Must NOT show expired banner
        expect(find.text('Đơn đặt vé đã hết hạn thanh toán'), findsNothing);
        // Must show payment confirmation banner
        expect(find.text('Đã xác nhận thanh toán'), findsOneWidget);
        // Must show ticket note instead of bank transfer instructions
        expect(find.text('Lưu ý về vé điện tử'), findsOneWidget);
        expect(
          find.textContaining('1. Mở ứng dụng ngân hàng và chuyển khoản'),
          findsNothing,
        );

        await tester.runAsync(bloc.close);
      },
    );

    testWidgets(
      '13. R2 regression: expired order hides transfer instructions and displays stop-transfer warning',
      (tester) async {
        final seatRepo = _FakeSeatRepo();
        final bookingRepo = _FakeBookingRepo();
        final pastExpiry = DateTime.now().subtract(const Duration(minutes: 5));
        final bloc = await _createStep6Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          hasPendingOrder: true,
          customExpiry: pastExpiry,
        );

        await _pumpWithViewport(tester, _buildStep6Harness(bloc));

        // Must show expired warning
        expect(find.text('Đơn đặt vé đã hết hạn thanh toán'), findsOneWidget);
        // Must hide QR details
        expect(find.text('Thông tin chuyển khoản VietQR'), findsNothing);
        // Must NOT tell customer to transfer money
        expect(
          find.textContaining('1. Mở ứng dụng ngân hàng và chuyển khoản'),
          findsNothing,
        );
        // Must show stop-transfer notice
        expect(find.text('Lưu ý khi đơn hàng hết hạn'), findsOneWidget);
        expect(
          find.textContaining(
            '1. Vui lòng không thực hiện chuyển khoản cho đơn hàng này.',
          ),
          findsOneWidget,
        );

        await tester.runAsync(bloc.close);
      },
    );
  });
}
