import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/network/api_config.dart';
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
import 'package:vexgo_app/features/user/booking/presentation/widgets/seat_hold_countdown_bar.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_event.dart';

const _pickup = StopPointModel(
  id: 'p1',
  name: 'Bến xe Miền Tây',
  time: '08:00',
  address: '395 Kinh Dương Vương, Bình Tân',
  isDefault: true,
);

const _dropoff = StopPointModel(
  id: 'd1',
  name: 'Bến xe Đà Lạt',
  time: '14:00',
  address: '01 Tô Hiến Thành, Đà Lạt',
  isDefault: true,
);

const _trip = TripModel(
  id: '10',
  operatorId: '3',
  operatorName: 'Phương Trang',
  vehicleType: 'Limousine 34 Phòng VIP',
  fromCityId: 'HCM',
  fromCityName: 'TP. Hồ Chí Minh',
  toCityId: 'DL',
  toCityName: 'Đà Lạt',
  departureTime: '08:00',
  arrivalTime: '14:00',
  duration: '6 giờ',
  pickupPoint: 'Bến xe Miền Tây',
  pickupAddress: '395 Kinh Dương Vương, Bình Tân',
  dropoffPoint: 'Bến xe Đà Lạt',
  dropoffAddress: '01 Tô Hiến Thành, Đà Lạt',
  originalPrice: 320000,
  discountPrice: 290000,
  availableSeats: 4,
  totalSeats: 34,
  rating: 4.8,
  reviewCount: 120,
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
  int price = 290000,
}) => SeatModel(
  id: id,
  name: '${floor == 1 ? 'A' : 'B'}$id',
  floor: floor,
  status: status,
  price: price,
  row: row,
  col: col,
);

class _FakeSeatRepository implements SeatRepository {
  DateTime Function() now;
  Duration holdDuration;
  int createHoldCalls = 0;
  int releaseHoldCalls = 0;
  String? lastReleasedToken;

  _FakeSeatRepository({
    DateTime Function()? now,
    this.holdDuration = const Duration(minutes: 10),
  }) : now = now ?? DateTime.now;

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
      expiresAt: now().add(holdDuration),
    );
  }

  @override
  Future<bool> releaseSeatHold(String token) async {
    releaseHoldCalls++;
    lastReleasedToken = token;
    return true;
  }
}

class _FakeBookingRepository implements BookingRepository {
  int quoteCalls = 0;
  String? lastQuotePhone;

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
    lastQuotePhone = contactPhone;
    final subtotal = seatIds.length * 290000;
    return BookingQuoteModel(
      unitPrice: 290000,
      seatCount: seatIds.length,
      originalTotal: subtotal,
      discountAmount: 0,
      finalTotal: subtotal,
      identityChecked: true,
      phoneEligibilityChecked: true,
      requiresPhoneBeforeBooking: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DelayedInitialSeats extends _FakeSeatRepository {
  final ready = Completer<List<SeatModel>>();

  @override
  Future<List<SeatModel>> getTripSeats(dynamic id) => ready.future;
}

class _FakeAuthRepository implements AuthRepository {
  UserModel? currentUser;
  int updateProfileCalls = 0;

  _FakeAuthRepository({this.currentUser});

  @override
  Future<UserModel?> getCurrentUser() async => currentUser;

  @override
  Future<UserModel> updateProfile(UserModel updatedUser) async {
    updateProfileCalls++;
    throw UnimplementedError('Step 4 must never mutate profile repository');
  }

  @override
  Future<void> logout() async {
    currentUser = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<BookingFlowBloc> _createStep4Bloc(
  WidgetTester tester, {
  required _FakeSeatRepository seatRepo,
  required _FakeBookingRepository bookingRepo,
  DateTime Function()? now,
  String? passengerName,
  String? passengerPhone,
  String? passengerEmail,
}) async {
  final bloc = BookingFlowBloc(
    seatRepository: seatRepo,
    bookingRepository: bookingRepo,
    now: now,
  );
  bloc.add(
    InitBookingFlowEvent(
      trip: _trip,
      date: DateTime(2026, 10, 24),
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      passengerEmail: passengerEmail,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  // Select seat A01 and advance to Step 4 (seatSelection -> pickup -> dropoff -> passengerInfo)
  bloc.add(ToggleSeatEvent(seatRepo.items.first));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  bloc.add(const NextStepEvent());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  bloc.add(const NextStepEvent());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  bloc.add(const NextStepEvent());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  return bloc;
}

Widget _buildStep4Harness(BookingFlowBloc bloc, {VoidCallback? onDetails}) {
  return BlocBuilder<BookingFlowBloc, BookingFlowState>(
    bloc: bloc,
    builder: (context, state) {
      return BookingPassengerInfoView(
        state: state,
        bloc: bloc,
        onBack: () => bloc.add(const PreviousStepEvent()),
        onNext: () => bloc.add(const NextStepEvent()),
        onDetails: onDetails ?? () {},
      );
    },
  );
}

TextField _findTextField(WidgetTester tester, Key fieldKey) {
  return tester.widget<TextField>(
    find.descendant(of: find.byKey(fieldKey), matching: find.byType(TextField)),
  );
}

final GlobalKey _screenshotBoundaryKey = GlobalKey();

Future<void> _loadRealFontsIfAvailable() async {
  final jakartaFile = File('assets/fonts/PlusJakartaSans.ttf');
  if (jakartaFile.existsSync()) {
    final bytes = jakartaFile.readAsBytesSync();
    final loader = FontLoader('VexGoJakarta')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
  final iconsFile = File(
    'D:/quantrong/LTDD/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (iconsFile.existsSync()) {
    final bytes = iconsFile.readAsBytesSync();
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}

Future<void> _captureScreenshotIfRequested(
  WidgetTester tester,
  String fileName,
) async {
  if (Platform.environment['CAPTURE_STEP4_SCREENSHOTS'] != '1') return;
  final boundaryContext = _screenshotBoundaryKey.currentContext;
  if (boundaryContext == null) return;
  final boundary = boundaryContext.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) return;
    final outDir = Directory(
      '../mobile-qa-evidence/passenger-info-implementation',
    );
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }
    final outFile = File('${outDir.path}/$fileName');
    await outFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
  });
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
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _screenshotBoundaryKey,
      child: MaterialApp(
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
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _disposeStep4Bloc(
  WidgetTester tester,
  BookingFlowBloc bloc,
) async {
  bloc.add(const ReleaseSeatHoldEvent());
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  unawaited(bloc.close());
}

void main() {
  const nameKey = ValueKey('passenger-name-input');
  const phoneKey = ValueKey('passenger-phone-input');
  const emailKey = ValueKey('passenger-email-input');

  setUpAll(() async {
    await _loadRealFontsIfAvailable();
  });

  setUp(() {
    ApiConfig.isDemoMode = false;
  });

  for (final switchAccount in [false, true]) {
    testWidgets(
      'Late init after ${switchAccount ? 'account switch' : 'logout'} cannot restore prior contact or resume checkout',
      (tester) async {
        const userA = UserModel(
          taiKhoanId: 7,
          maKhachHang: 'KH007',
          hoTen: 'Account A',
          soDienThoai: '0912345678',
          email: 'a@example.com',
        );
        const userB = UserModel(
          taiKhoanId: 8,
          maKhachHang: 'KH008',
          hoTen: 'Account B',
          soDienThoai: '0934567890',
          email: 'b@example.com',
        );
        final seats = _DelayedInitialSeats();
        final authRepo = _FakeAuthRepository(currentUser: userA);
        final auth = AuthBloc(authRepository: authRepo)
          ..add(const CheckAuthStatusEvent());
        await tester.pump(const Duration(milliseconds: 50));
        await _pumpWithViewport(
          tester,
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<SeatRepository>.value(value: seats),
              RepositoryProvider<BookingRepository>.value(
                value: _FakeBookingRepository(),
              ),
            ],
            child: BlocProvider<AuthBloc>.value(
              value: auth,
              child: BookingFlowScreen(
                trip: _trip,
                date: DateTime(2026, 10, 24),
              ),
            ),
          ),
          size: const Size(640, 360),
          textScale: 2,
          viewInsets: const EdgeInsets.only(bottom: 220),
        );
        final bloc = tester
            .element(find.byType(BookingSelectionView))
            .read<BookingFlowBloc>();
        expect(bloc.state.status, BookingFlowStatus.loading);
        if (switchAccount) {
          authRepo.currentUser = userB;
          auth.add(const CheckAuthStatusEvent());
        } else {
          auth.add(const LogoutEvent());
        }
        await tester.pump(const Duration(milliseconds: 50));
        expect(
          find.byKey(const ValueKey('booking-session-changed')),
          findsOneWidget,
        );
        seats.ready.complete(seats.items);
        await tester.pump(const Duration(milliseconds: 50));
        bloc.add(ToggleSeatEvent(seats.items.first));
        bloc.add(
          const UpdatePassengerInfoEvent(
            name: 'Old queued edit',
            phone: '0912345678',
            email: '',
          ),
        );
        bloc.add(const NextStepEvent());
        await tester.pump(const Duration(milliseconds: 50));
        expect(bloc.state.passengerName, isEmpty);
        expect(bloc.state.passengerPhone, isEmpty);
        expect(bloc.state.passengerEmail, isEmpty);
        expect(bloc.state.selectedSeats, isEmpty);
        expect(seats.createHoldCalls, 0);
        expect(find.byType(Step4PassengerInfo), findsNothing);
        expect(find.text('Account A'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        unawaited(auth.close());
      },
    );
  }

  group('Step 4 Passenger Info UI & Regression Suite', () {
    testWidgets(
      '1. Logged-in user: prefills contact info, uses neutral copy, omits note/save-checkbox, and invalidates quote on edit without mutating profile',
      (tester) async {
        final seatRepo = _FakeSeatRepository();
        final bookingRepo = _FakeBookingRepository();
        final authRepo = _FakeAuthRepository();
        final bloc = await _createStep4Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          passengerName: 'Nguyễn Quốc An',
          passengerPhone: '0912345678',
          passengerEmail: 'quocan@vexgo.vn',
        );

        var detailsTapped = false;
        await _pumpWithViewport(
          tester,
          _buildStep4Harness(bloc, onDetails: () => detailsTapped = true),
        );

        // Header & neutral copy checks
        expect(find.byType(BookingCompactHeader), findsOneWidget);
        expect(find.byType(BookingStepperCompact), findsOneWidget);
        expect(find.text('Phương Trang'), findsOneWidget);
        expect(
          find.textContaining('08:00 • 24/10 • TP. Hồ Chí Minh → Đà Lạt'),
          findsOneWidget,
        );
        expect(find.text('Thông tin'), findsOneWidget);
        expect(find.text('Thông tin liên hệ cho đơn đặt vé'), findsOneWidget);
        expect(
          find.text(
            'Dùng để xác nhận thông tin đặt chỗ và liên hệ đón trả trong chuyến đi này.',
          ),
          findsOneWidget,
        );
        expect(find.byType(SeatHoldCountdownBar), findsOneWidget);

        // Excluded non-authoritative fields are not rendered in UI
        expect(find.textContaining('Ghi chú cho nhà xe'), findsNothing);
        expect(
          find.textContaining(
            'Lưu thông tin hành khách cho lần đặt vé tiếp theo',
          ),
          findsNothing,
        );

        // Inline Chi tiết xe works
        await tester.tap(find.text('Chi tiết xe'));
        await tester.pump();
        expect(detailsTapped, isTrue);

        // Prefilled values
        expect(
          _findTextField(tester, nameKey).controller?.text,
          'Nguyễn Quốc An',
        );
        expect(_findTextField(tester, phoneKey).controller?.text, '0912345678');
        expect(
          _findTextField(tester, emailKey).controller?.text,
          'quocan@vexgo.vn',
        );
        expect(bloc.state.isPassengerValid, isTrue);
        await _captureScreenshotIfRequested(tester, 'step4-normal-390-844.png');

        // Advance to Step 5 so an authoritative quote is loaded
        await tester.tap(find.text('Tiếp tục'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(bloc.state.step, BookingStep.tripSummary);
        expect(bloc.state.quote, isNotNull);
        expect(bookingRepo.quoteCalls, 1);

        // Go back to Step 4 and edit phone -> quote must be invalidated, profile repo untouched
        bloc.add(const PreviousStepEvent());
        await tester.pump();
        expect(bloc.state.step, BookingStep.passengerInfo);

        await tester.enterText(find.byKey(phoneKey), '0987654321');
        await tester.pump();

        expect(bloc.state.passengerPhone, '0987654321');
        expect(bloc.state.quote, isNull);
        expect(authRepo.updateProfileCalls, 0);

        await _disposeStep4Bloc(tester, bloc);
      },
    );

    testWidgets(
      '2. Guest user: starts with empty form, no fake data, tapping disabled CTA reveals inline errors and focuses first invalid field',
      (tester) async {
        final seatRepo = _FakeSeatRepository();
        final bookingRepo = _FakeBookingRepository();
        final bloc = await _createStep4Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
        );

        await _pumpWithViewport(tester, _buildStep4Harness(bloc));

        expect(_findTextField(tester, nameKey).controller?.text, isEmpty);
        expect(_findTextField(tester, phoneKey).controller?.text, isEmpty);
        expect(_findTextField(tester, emailKey).controller?.text, isEmpty);
        expect(bloc.state.isPassengerValid, isFalse);

        // Before interaction, no noisy inline errors are shown
        expect(find.text('Vui lòng nhập họ và tên hành khách'), findsNothing);
        expect(find.text('Vui lòng nhập số điện thoại liên hệ'), findsNothing);

        // Tap CTA while invalid -> reveals inline errors, focuses name field, stays on Step 4
        await tester.tap(find.text('Tiếp tục'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(bloc.state.step, BookingStep.passengerInfo);
        expect(find.text('Vui lòng nhập họ và tên hành khách'), findsOneWidget);
        expect(
          find.text('Vui lòng nhập số điện thoại liên hệ'),
          findsOneWidget,
        );
        expect(
          find.text('Email không đúng định dạng (ví dụ: ten@email.com)'),
          findsNothing,
        );

        expect(_findTextField(tester, nameKey).focusNode?.hasFocus, isTrue);

        await _disposeStep4Bloc(tester, bloc);
      },
    );

    testWidgets(
      '3. Optional empty email: labeled Email (tùy chọn) and allows proceeding when name and phone are valid',
      (tester) async {
        final seatRepo = _FakeSeatRepository();
        final bookingRepo = _FakeBookingRepository();
        final bloc = await _createStep4Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
        );

        await _pumpWithViewport(tester, _buildStep4Harness(bloc));

        expect(
          find.text('Email (tùy chọn)', findRichText: true),
          findsOneWidget,
        );

        await tester.enterText(find.byKey(nameKey), 'Trần Minh Khoa');
        await tester.enterText(find.byKey(phoneKey), '0912345678');
        await tester.pump();

        expect(bloc.state.passengerEmail, isEmpty);
        expect(bloc.state.isPassengerValid, isTrue);
        expect(
          find.text('Email không đúng định dạng (ví dụ: ten@email.com)'),
          findsNothing,
        );

        await tester.tap(find.text('Tiếp tục'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(bloc.state.step, BookingStep.tripSummary);

        await _disposeStep4Bloc(tester, bloc);
      },
    );

    testWidgets(
      '4. Invalid inputs: <2 char name, invalid VN phone, and malformed email show field-specific errors and block NextStepEvent',
      (tester) async {
        final seatRepo = _FakeSeatRepository();
        final bookingRepo = _FakeBookingRepository();
        final bloc = await _createStep4Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
        );

        await _pumpWithViewport(tester, _buildStep4Harness(bloc));

        await tester.enterText(find.byKey(nameKey), 'A');
        await tester.enterText(find.byKey(phoneKey), '0123456789');
        await tester.enterText(find.byKey(emailKey), 'invalid-email@');
        await tester.pump();

        // Trigger validation via CTA tap
        await tester.tap(find.text('Tiếp tục'));
        await tester.pump();

        expect(bloc.state.step, BookingStep.passengerInfo);
        expect(find.text('Họ và tên cần ít nhất 2 ký tự'), findsOneWidget);
        expect(
          find.text(
            'Số điện thoại không hợp lệ (ví dụ: 0912345678 hoặc +84912345678)',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Email không đúng định dạng (ví dụ: ten@email.com)'),
          findsOneWidget,
        );
        await _captureScreenshotIfRequested(
          tester,
          'step4-validation-error-390-844.png',
        );

        // Fix name and phone with +84 prefix, fix email
        await tester.enterText(find.byKey(nameKey), 'Lê Hoàng');
        await tester.enterText(find.byKey(phoneKey), '+84912345678');
        await tester.enterText(find.byKey(emailKey), 'lehoang@example.com');
        await tester.pump();

        expect(find.text('Họ và tên cần ít nhất 2 ký tự'), findsNothing);
        expect(
          find.text(
            'Số điện thoại không hợp lệ (ví dụ: 0912345678 hoặc +84912345678)',
          ),
          findsNothing,
        );
        expect(
          find.text('Email không đúng định dạng (ví dụ: ten@email.com)'),
          findsNothing,
        );
        expect(bloc.state.isPassengerValid, isTrue);

        await _disposeStep4Bloc(tester, bloc);
      },
    );

    testWidgets(
      '5. Keyboard & focus traversal: Name -> Phone -> Email -> Done and preserves cursor/Vietnamese composing text',
      (tester) async {
        final seatRepo = _FakeSeatRepository();
        final bookingRepo = _FakeBookingRepository();
        final bloc = await _createStep4Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
        );

        await _pumpWithViewport(
          tester,
          _buildStep4Harness(bloc),
          viewInsets: const EdgeInsets.only(bottom: 260),
        );

        await tester.tap(find.byKey(nameKey));
        await tester.pump();
        expect(_findTextField(tester, nameKey).focusNode?.hasFocus, isTrue);

        // Simulate mid-string editing with Vietnamese diacritics and custom cursor position
        final nameController = _findTextField(tester, nameKey).controller!;
        await tester.enterText(find.byKey(nameKey), 'Nguyễn Quốc An');
        nameController.selection = const TextSelection.collapsed(offset: 6);
        await tester.pump();
        await _captureScreenshotIfRequested(
          tester,
          'step4-keyboard-390-844.png',
        );

        // Cursor position at index 6 must not be reset to end of string on state rebuild
        expect(nameController.selection.baseOffset, 6);
        expect(bloc.state.passengerName, 'Nguyễn Quốc An');

        // Next action moves focus from Name -> Phone
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pump();
        expect(_findTextField(tester, phoneKey).focusNode?.hasFocus, isTrue);

        // Next action moves focus from Phone -> Email
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pump();
        expect(_findTextField(tester, emailKey).focusNode?.hasFocus, isTrue);

        // Done action unfocuses Email
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(_findTextField(tester, emailKey).focusNode?.hasFocus, isFalse);

        await _disposeStep4Bloc(tester, bloc);
      },
    );

    testWidgets(
      '6. Back / Forward navigation preserves draft passenger info, selected seats, pickup/dropoff, and active seatHold without re-creating hold',
      (tester) async {
        final seatRepo = _FakeSeatRepository();
        final bookingRepo = _FakeBookingRepository();
        final bloc = await _createStep4Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
        );

        await _pumpWithViewport(tester, _buildStep4Harness(bloc));

        await tester.enterText(find.byKey(nameKey), 'Phạm Thu Hà');
        await tester.enterText(find.byKey(phoneKey), '0934567890');
        await tester.enterText(find.byKey(emailKey), 'thuha@vexgo.vn');
        await tester.pump();

        final originalHoldToken = bloc.state.holdToken;
        expect(seatRepo.createHoldCalls, 1);

        // Press Quay lại -> goes back to Step 3 (dropoffPoint)
        await tester.tap(find.text('Quay lại'));
        await tester.pump();
        expect(bloc.state.step, BookingStep.dropoffPoint);

        // Advance back to Step 4 -> draft contact info & hold token are preserved
        bloc.add(const NextStepEvent());
        await tester.pump();
        expect(bloc.state.step, BookingStep.passengerInfo);
        expect(bloc.state.passengerName, 'Phạm Thu Hà');
        expect(bloc.state.passengerPhone, '0934567890');
        expect(bloc.state.passengerEmail, 'thuha@vexgo.vn');
        expect(bloc.state.selectedSeats.map((s) => s.name).toList(), ['A01']);
        expect(bloc.state.selectedPickupPoint?.id, 'p1');
        expect(bloc.state.selectedDropoffPoint?.id, 'd1');
        expect(bloc.state.holdToken, originalHoldToken);
        expect(seatRepo.createHoldCalls, 1);

        await _disposeStep4Bloc(tester, bloc);
      },
    );

    testWidgets(
      '7. Seat hold expiry on Step 4 blocks NextStepEvent even when passenger info is valid, releases hold, and returns to seatSelection',
      (tester) async {
        var currentTime = DateTime(2026, 10, 24, 8, 0, 0);
        final seatRepo = _FakeSeatRepository(
          now: () => currentTime,
          holdDuration: const Duration(minutes: 5),
        );
        final bookingRepo = _FakeBookingRepository();
        final bloc = await _createStep4Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          now: () => currentTime,
          passengerName: 'Võ Hoàng Nam',
          passengerPhone: '0978123456',
        );

        await _pumpWithViewport(tester, _buildStep4Harness(bloc));
        expect(bloc.state.isPassengerValid, isTrue);
        expect(bloc.state.step, BookingStep.passengerInfo);

        // Advance clock past hold expiration before NextStepEvent is dispatched
        currentTime = currentTime.add(const Duration(minutes: 6));
        bloc.add(const NextStepEvent());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Must NOT advance to tripSummary; must reset to seatSelection and release hold
        expect(bloc.state.step, BookingStep.seatSelection);
        expect(bloc.state.seatHold, isNull);
        expect(bloc.state.selectedSeats, isEmpty);
        expect(bloc.state.errorMessage, contains('Hết thời gian giữ ghế'));
        expect(seatRepo.releaseHoldCalls, 1);

        await _disposeStep4Bloc(tester, bloc);
      },
    );

    testWidgets(
      '8. Loading / submitting / checkout lock disables inputs and actions to prevent double submit or draft mutation',
      (tester) async {
        final seatRepo = _FakeSeatRepository();
        final bookingRepo = _FakeBookingRepository();
        final bloc = await _createStep4Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          passengerName: 'Đặng Quốc Bảo',
          passengerPhone: '0911223344',
        );

        // Simulate checkout lock state on Step 4
        bloc.emit(
          bloc.state.copyWith(
            bookingOutcomeUnknown: true,
            status: BookingFlowStatus.submitting,
          ),
        );

        await _pumpWithViewport(tester, _buildStep4Harness(bloc));

        expect(_findTextField(tester, nameKey).enabled, isFalse);
        expect(_findTextField(tester, phoneKey).enabled, isFalse);
        expect(_findTextField(tester, emailKey).enabled, isFalse);

        // Attempt to mutate passenger info or advance step while locked
        bloc.add(
          const UpdatePassengerInfoEvent(
            name: 'Hacker',
            phone: '0999999999',
            email: 'hack@example.com',
          ),
        );
        bloc.add(const NextStepEvent());
        await tester.pump();

        expect(bloc.state.passengerName, 'Đặng Quốc Bảo');
        expect(bloc.state.step, BookingStep.passengerInfo);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        unawaited(bloc.close());
      },
    );

    testWidgets(
      '9. Responsive 320x740 with text scale 2.0x renders without overflow and keeps fields + CTA reachable',
      (tester) async {
        final seatRepo = _FakeSeatRepository();
        final bookingRepo = _FakeBookingRepository();
        final bloc = await _createStep4Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          passengerName: 'Nguyễn Quốc An',
          passengerPhone: '0912345678',
          passengerEmail: 'quocan@vexgo.vn',
        );

        await _pumpWithViewport(
          tester,
          _buildStep4Harness(bloc),
          size: const Size(320, 740),
          textScale: 2.0,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(BookingCompactHeader), findsOneWidget);
        expect(find.byType(BookingStepperCompact), findsOneWidget);
        expect(find.text('Thông tin'), findsOneWidget);
        expect(find.byKey(nameKey), findsOneWidget);
        expect(find.text('Tiếp tục'), findsOneWidget);
        await _captureScreenshotIfRequested(tester, 'step4-320-740-text2.png');

        await tester.scrollUntilVisible(
          find.byKey(emailKey),
          120,
          scrollable: find
              .descendant(
                of: find.byType(Step4PassengerInfo),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await _captureScreenshotIfRequested(
          tester,
          'step4-320-740-text2-scrolled.png',
        );

        await _disposeStep4Bloc(tester, bloc);
      },
    );

    testWidgets(
      '10. Landscape 640x360 with text scale 2.0x and simulated keyboard viewInsets renders without overflow and scrolls cleanly',
      (tester) async {
        final seatRepo = _FakeSeatRepository();
        final bookingRepo = _FakeBookingRepository();
        final bloc = await _createStep4Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          passengerName: 'Nguyễn Quốc An',
          passengerPhone: '0912345678',
        );

        await _pumpWithViewport(
          tester,
          _buildStep4Harness(bloc),
          size: const Size(640, 360),
          textScale: 2.0,
          viewInsets: const EdgeInsets.only(bottom: 140),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Tiếp tục'), findsOneWidget);
        await _captureScreenshotIfRequested(tester, 'step4-640-360-text2.png');

        await tester.scrollUntilVisible(
          find.byKey(phoneKey),
          100,
          scrollable: find
              .descendant(
                of: find.byType(Step4PassengerInfo),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await _captureScreenshotIfRequested(
          tester,
          'step4-640-360-text2-scrolled.png',
        );

        await _disposeStep4Bloc(tester, bloc);
      },
    );

    testWidgets(
      '11. Session change: AuthBloc logout clears old user contact info on Step 4',
      (tester) async {
        final seatRepo = _FakeSeatRepository();
        final bookingRepo = _FakeBookingRepository();
        final authRepo = _FakeAuthRepository(
          currentUser: const UserModel(
            taiKhoanId: 7,
            maKhachHang: 'KH007',
            hoTen: 'Trần Quốc Tuấn',
            soDienThoai: '0912345678',
            email: 'tuan@vexgo.vn',
          ),
        );
        final authBloc = AuthBloc(authRepository: authRepo)
          ..add(const CheckAuthStatusEvent());
        await tester.pump();
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
                date: DateTime(2026, 10, 24),
              ),
            ),
          ),
          size: const Size(800, 900),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Advance from Step 1 -> Step 2 -> Step 3 -> Step 4
        await tester.tap(find.byKey(const ValueKey('seat-01')));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Tiếp tục'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Tiếp tục'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Tiếp tục'));
        await tester.pump(const Duration(milliseconds: 100));

        // Verify User A's info is prefilled on Step 4
        expect(
          _findTextField(tester, nameKey).controller?.text,
          'Trần Quốc Tuấn',
        );
        expect(_findTextField(tester, phoneKey).controller?.text, '0912345678');

        // Dispatch LogoutEvent on AuthBloc while Step 4 is mounted
        authBloc.add(const LogoutEvent());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Hide the prior form and retire the account-bound hold, rather than
        // letting the next account continue as a guest with the same token.
        expect(
          find.byKey(const ValueKey('booking-session-changed')),
          findsOneWidget,
        );
        expect(find.byType(Step4PassengerInfo), findsNothing);
        expect(find.text('Trần Quốc Tuấn'), findsNothing);
        expect(seatRepo.releaseHoldCalls, 1);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
        unawaited(authBloc.close());
      },
    );

    testWidgets(
      '12. Full flow regression check: Steps 1-3 (BookingSelectionView) -> Step 4 (BookingPassengerInfoView) -> Steps 5-6 (Step5TripSummary & Step6Payment)',
      (tester) async {
        final seatRepo = _FakeSeatRepository();
        final bookingRepo = _FakeBookingRepository();
        final authRepo = _FakeAuthRepository();
        final authBloc = AuthBloc(authRepository: authRepo);

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
                date: DateTime(2026, 10, 24),
              ),
            ),
          ),
          size: const Size(800, 900),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Steps 1-3 use BookingSelectionView
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

        // Step 4: BookingPassengerInfoView
        expect(find.byType(BookingPassengerInfoView), findsOneWidget);
        expect(find.byType(Step4PassengerInfo), findsOneWidget);

        await tester.enterText(find.byKey(nameKey), 'Nguyễn Văn Bình');
        await tester.enterText(find.byKey(phoneKey), '0912345678');
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('Tiếp tục'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Step 5: Step5TripSummary
        expect(find.byType(Step5TripSummary), findsOneWidget);
        expect(find.text('Nguyễn Văn Bình'), findsOneWidget);

        // Advance to Step 6: Step6Payment
        await tester.tap(find.text('Thanh toán'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(Step6Payment), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
        unawaited(authBloc.close());
      },
    );

    testWidgets(
      '13. Header Step 4 embeds BookingStepperCompact on red header surface, auto-scrolls step 4 (Thông tin) into visible viewport, and exposes semantics & >=48dp touch targets',
      (tester) async {
        final seatRepo = _FakeSeatRepository();
        final bookingRepo = _FakeBookingRepository();
        final bloc = await _createStep4Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          passengerName: 'Nguyễn Quốc An',
          passengerPhone: '0912345678',
        );

        final semanticsHandle = tester.ensureSemantics();
        await _pumpWithViewport(
          tester,
          _buildStep4Harness(bloc),
          size: const Size(390, 844),
        );

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

        // Compact header height target (90-110dp on 390x844 at 1.0x text scale)
        final headerSize = tester.getSize(headerFinder);
        expect(headerSize.height, inInclusiveRange(90, 112));

        // Steps 1-3 show completed checkmarks, Step 4 (Thông tin) is active and visible inside 0..390 viewport
        expect(
          find.descendant(of: headerFinder, matching: find.byIcon(Icons.check)),
          findsNWidgets(3),
        );
        final step4ItemFinder = find.byKey(
          const ValueKey('booking-stepper-item-3'),
        );
        final step4Rect = tester.getRect(step4ItemFinder);
        expect(step4Rect.left, greaterThanOrEqualTo(0));
        expect(step4Rect.right, lessThanOrEqualTo(390));

        // Touch target >= 48dp checks on 390x844
        final backBtnSize = tester.getSize(find.byTooltip('Quay lại'));
        expect(backBtnSize.width, greaterThanOrEqualTo(48));
        expect(backBtnSize.height, greaterThanOrEqualTo(48));
        final detailsBtnSize = tester.getSize(
          find.widgetWithText(TextButton, 'Chi tiết xe'),
        );
        expect(detailsBtnSize.width, greaterThanOrEqualTo(48));
        expect(detailsBtnSize.height, greaterThanOrEqualTo(48));
        expect(step4Rect.width, greaterThanOrEqualTo(48));
        expect(step4Rect.height, greaterThanOrEqualTo(48));

        // Semantics verification for passed, current, and future steps
        final step1Semantics = tester.getSemantics(
          find.byKey(const ValueKey('booking-stepper-item-0')),
        );
        expect(
          step1Semantics.label,
          contains('Bước 1/6: Chọn chỗ, đã hoàn thành'),
        );
        expect(
          step1Semantics.getSemanticsData().flagsCollection.isButton,
          isTrue,
        );

        final step4Semantics = tester.getSemantics(step4ItemFinder);
        expect(
          step4Semantics.label,
          contains('Bước 4/6: Thông tin, đang chọn'),
        );
        expect(
          step4Semantics.getSemanticsData().flagsCollection.isSelected,
          ui.Tristate.isTrue,
        );

        final step5Semantics = tester.getSemantics(
          find.byKey(const ValueKey('booking-stepper-item-4')),
        );
        expect(step5Semantics.label, contains('Bước 5/6: Xác nhận, chưa tới'));
        expect(
          step5Semantics.getSemanticsData().hasAction(ui.SemanticsAction.tap),
          isFalse,
        );

        semanticsHandle.dispose();
        await _disposeStep4Bloc(tester, bloc);
      },
    );

    testWidgets(
      '14. Tapping completed steps in BookingStepperCompact from Step 4 navigates backward while preserving contact draft, seatHold, and selections without re-creating hold',
      (tester) async {
        final seatRepo = _FakeSeatRepository();
        final bookingRepo = _FakeBookingRepository();
        final authRepo = _FakeAuthRepository();
        final authBloc = AuthBloc(authRepository: authRepo);

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
                date: DateTime(2026, 10, 24),
              ),
            ),
          ),
          size: const Size(390, 844),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Advance Step 1 -> Step 2 -> Step 3 -> Step 4
        await tester.tap(find.byKey(const ValueKey('seat-01')));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Tiếp tục'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Tiếp tục'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Tiếp tục'));
        await tester.pump(const Duration(milliseconds: 100));

        final bloc = tester
            .element(find.byType(BookingPassengerInfoView))
            .read<BookingFlowBloc>();
        expect(bloc.state.step, BookingStep.passengerInfo);
        final holdToken = bloc.state.holdToken;
        expect(seatRepo.createHoldCalls, 1);

        // Enter draft contact info on Step 4
        await tester.enterText(find.byKey(nameKey), 'Lê Minh Tuấn');
        await tester.enterText(find.byKey(phoneKey), '0912345678');
        await tester.enterText(find.byKey(emailKey), 'tuan@vexgo.vn');
        await tester.pump();

        // Tap completed step 3 (Điểm trả, index 2) in header stepper
        final step3Item = find.byKey(const ValueKey('booking-stepper-item-2'));
        await tester.ensureVisible(step3Item);
        await tester.pump();
        await tester.tap(step3Item);
        await tester.pump(const Duration(milliseconds: 100));
        expect(bloc.state.step, BookingStep.dropoffPoint);

        // Tap completed step 1 (Chọn chỗ, index 0) in header stepper
        final step1Item = find.byKey(const ValueKey('booking-stepper-item-0'));
        await tester.ensureVisible(step1Item);
        await tester.pump();
        await tester.tap(step1Item);
        await tester.pump(const Duration(milliseconds: 100));
        expect(bloc.state.step, BookingStep.seatSelection);

        // Advance back to Step 4: hold was NOT recreated, and contact draft + selections remain intact
        await tester.tap(find.text('Tiếp tục'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Tiếp tục'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Tiếp tục'));
        await tester.pump(const Duration(milliseconds: 100));

        expect(bloc.state.step, BookingStep.passengerInfo);
        expect(bloc.state.passengerName, 'Lê Minh Tuấn');
        expect(bloc.state.passengerPhone, '0912345678');
        expect(bloc.state.passengerEmail, 'tuan@vexgo.vn');
        expect(bloc.state.holdToken, holdToken);
        expect(bloc.state.selectedSeats.map((s) => s.name).toList(), ['A01']);
        expect(bloc.state.selectedPickupPoint?.id, 'p1');
        expect(bloc.state.selectedDropoffPoint?.id, 'd1');
        expect(seatRepo.createHoldCalls, 1);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
        unawaited(authBloc.close());
      },
    );

    testWidgets(
      '15. Future steps in BookingStepperCompact cannot be tapped to bypass validation/quote, and busy/locked states block stepper navigation',
      (tester) async {
        final seatRepo = _FakeSeatRepository();
        final bookingRepo = _FakeBookingRepository();
        final bloc = await _createStep4Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
        );

        await _pumpWithViewport(tester, _buildStep4Harness(bloc));
        expect(bloc.state.step, BookingStep.passengerInfo);
        expect(bloc.state.isPassengerValid, isFalse);

        // Attempt to tap future Step 5 (Xác nhận) and Step 6 (Thanh toán)
        final step5Item = find.byKey(const ValueKey('booking-stepper-item-4'));
        await tester.ensureVisible(step5Item);
        await tester.pump();
        await tester.tap(step5Item, warnIfMissed: false);
        await tester.pump();
        expect(bloc.state.step, BookingStep.passengerInfo);
        expect(bookingRepo.quoteCalls, 0);

        final step6Item = find.byKey(const ValueKey('booking-stepper-item-5'));
        await tester.ensureVisible(step6Item);
        await tester.pump();
        await tester.tap(step6Item, warnIfMissed: false);
        await tester.pump();
        expect(bloc.state.step, BookingStep.passengerInfo);

        // Even if GoToStepEvent(4) is dispatched directly, bloc blocks forward jumps
        bloc.add(const GoToStepEvent(4));
        await tester.pump();
        expect(bloc.state.step, BookingStep.passengerInfo);

        // When loading/submitting/locked, backward stepper taps and GoToStepEvent are also blocked
        bloc.emit(bloc.state.copyWith(status: BookingFlowStatus.loading));
        await tester.pump();
        final step3Item = find.byKey(const ValueKey('booking-stepper-item-2'));
        await tester.ensureVisible(step3Item);
        await tester.pump();
        await tester.tap(step3Item, warnIfMissed: false);
        bloc.add(const GoToStepEvent(0));
        await tester.pump();
        expect(bloc.state.step, BookingStep.passengerInfo);

        await _disposeStep4Bloc(tester, bloc);
      },
    );

    testWidgets(
      '16. Countdown ticks do not reset Stepper scroll offset, lose input focus, or reset draft; keyboard inset 220dp renders without overflow',
      (tester) async {
        var currentTime = DateTime(2026, 10, 24, 8, 0, 0);
        final seatRepo = _FakeSeatRepository(now: () => currentTime);
        final bookingRepo = _FakeBookingRepository();
        final bloc = await _createStep4Bloc(
          tester,
          seatRepo: seatRepo,
          bookingRepo: bookingRepo,
          now: () => currentTime,
        );

        await _pumpWithViewport(
          tester,
          _buildStep4Harness(bloc),
          size: const Size(390, 844),
          viewInsets: const EdgeInsets.only(bottom: 220),
        );
        expect(tester.takeException(), isNull);

        // Step 4 item was auto-scrolled into view (> 0 offset on 390dp width)
        final stepperState = tester.state<BookingStepperCompactState>(
          find.byType(BookingStepperCompact),
        );
        final autoScrolledOffset = stepperState.scrollController.offset;
        expect(autoScrolledOffset, greaterThan(0));

        // Manually scroll stepper horizontally to a custom position and focus + edit name field
        stepperState.scrollController.jumpTo(42.0);
        await tester.pump();
        expect(stepperState.scrollController.offset, 42.0);

        await tester.tap(find.byKey(nameKey));
        await tester.pump();
        await tester.enterText(find.byKey(nameKey), 'Trần Quốc Bảo');
        final nameController = _findTextField(tester, nameKey).controller!;
        nameController.selection = const TextSelection.collapsed(offset: 4);
        await tester.pump();

        // Dispatch multiple 1-second countdown ticks
        for (var tick = 1; tick <= 3; tick++) {
          currentTime = currentTime.add(const Duration(seconds: 1));
          bloc.add(const TickCountdownEvent());
          await tester.pump();
        }

        // Scroll offset, focus, text, and cursor offset must remain untouched
        expect(stepperState.scrollController.offset, 42.0);
        expect(_findTextField(tester, nameKey).focusNode?.hasFocus, isTrue);
        expect(nameController.text, 'Trần Quốc Bảo');
        expect(nameController.selection.baseOffset, 4);
        expect(tester.takeException(), isNull);

        // Also verify 320x740 at 2.0x text scale with keyboard inset 220dp has zero overflow
        await _pumpWithViewport(
          tester,
          _buildStep4Harness(bloc),
          size: const Size(320, 740),
          textScale: 2.0,
          viewInsets: const EdgeInsets.only(bottom: 220),
        );
        expect(tester.takeException(), isNull);

        await _disposeStep4Bloc(tester, bloc);
      },
    );

    testWidgets(
      '17. Mounted stepper keeps current step visible across width, font and compact changes',
      (tester) async {
        BookingStepperCompactState? initialStepper;
        for (final viewport in [
          (size: const Size(390, 844), scale: 1.0, compact: false),
          (size: const Size(320, 740), scale: 2.0, compact: false),
          (size: const Size(640, 360), scale: 2.0, compact: true),
          (size: const Size(390, 844), scale: 1.0, compact: false),
        ]) {
          await _pumpWithViewport(
            tester,
            Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: BookingCompactHeader(
                  state: BookingFlowState(
                    trip: _trip,
                    date: DateTime(2026, 10, 24),
                    step: BookingStep.passengerInfo,
                  ),
                  compact: viewport.compact,
                  onBack: () {},
                  onDetails: () {},
                  onStep: (_) {},
                ),
              ),
            ),
            size: viewport.size,
            textScale: viewport.scale,
          );
          await tester.pump();
          final stepper = tester.state<BookingStepperCompactState>(
            find.byType(BookingStepperCompact),
          );
          initialStepper ??= stepper;
          expect(identical(initialStepper, stepper), isTrue);
          final currentRect = tester.getRect(
            find.byKey(const ValueKey('booking-stepper-item-3')),
          );
          final viewportRect = tester.getRect(
            find.byKey(const ValueKey('booking-stepper-scroll')),
          );
          expect(
            currentRect.left,
            greaterThanOrEqualTo(viewportRect.left - 0.01),
          );
          expect(
            currentRect.right,
            lessThanOrEqualTo(viewportRect.right + 0.01),
          );
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      '18. Landscape keyboard opening and closing retain controller, focus, selection and composing',
      (tester) async {
        final bloc = await _createStep4Bloc(
          tester,
          seatRepo: _FakeSeatRepository(),
          bookingRepo: _FakeBookingRepository(),
          passengerName: 'Nguyễn Quốc An',
          passengerPhone: '0912345678',
        );
        await _pumpWithViewport(
          tester,
          _buildStep4Harness(bloc),
          size: const Size(640, 360),
        );
        await tester.ensureVisible(find.byKey(nameKey));
        await tester.pump();
        await tester.tap(find.byKey(nameKey));
        await tester.pump();
        final original = _findTextField(tester, nameKey);
        final controller = original.controller!;
        const editing = TextEditingValue(
          text: 'Nguyễn Quốc An',
          selection: TextSelection.collapsed(offset: 4),
          composing: TextRange(start: 0, end: 6),
        );
        controller.value = editing;
        expect(original.focusNode!.hasFocus, isTrue);

        for (final inset in [220.0, 0.0, 220.0]) {
          await _pumpWithViewport(
            tester,
            _buildStep4Harness(bloc),
            size: const Size(640, 360),
            viewInsets: EdgeInsets.only(bottom: inset),
          );
          await tester.pump(const Duration(milliseconds: 100));
          final current = _findTextField(tester, nameKey);
          expect(identical(current.controller, controller), isTrue);
          expect(identical(current.focusNode, original.focusNode), isTrue);
          expect(current.focusNode!.hasFocus, isTrue);
          expect(controller.value, editing);
          expect(bloc.state.passengerName, editing.text);
          expect(tester.takeException(), isNull);
        }
        await _disposeStep4Bloc(tester, bloc);
      },
    );
  });
}
