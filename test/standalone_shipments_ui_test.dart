import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:vexgo_app/core/network/api_response.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/network/vietqr_config.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/data/models/booking_cargo_model.dart';
import 'package:vexgo_app/data/models/city_model.dart';
import 'package:vexgo_app/data/models/user_model.dart';
import 'package:vexgo_app/data/repositories/auth_repository.dart';
import 'package:vexgo_app/data/repositories/shipment_repository.dart';
import 'package:vexgo_app/features/user/main_shell/main_shell_screen.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_event.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_state.dart';
import 'package:vexgo_app/features/user/profile/presentation/screens/profile_screen.dart';
import 'package:vexgo_app/features/user/shipments/presentation/screens/shipments_host_screen.dart';
import 'package:vexgo_app/features/user/shipments/presentation/widgets/shipment_create_view.dart';
import 'package:vexgo_app/features/user/shipments/presentation/widgets/shipment_detail_view.dart';
import 'package:vexgo_app/features/user/shipments/presentation/widgets/shipment_lookup_view.dart';
import 'package:vexgo_app/features/user/shipments/presentation/widgets/shipment_status_badge.dart';
import 'package:vexgo_app/features/user/shipments/presentation/widgets/shipment_uncertain_view.dart';
import 'package:vexgo_app/features/user/shipments/shipment_flow_cubit.dart';
import 'standalone_shipments_core_test.dart' as fixture;

const _testBank = VietQrReceivingAccount(
  bankId: 'MB',
  accountNumber: '0000000001',
  accountName: 'TEST_ACCOUNT',
);

final _testTime = DateTime.utc(2026, 11, 10, 8);

ShipmentTrip _fakeTrip(int id, String code) => ShipmentTrip(
  id: id,
  code: code,
  carrier: 'Xe Test $id',
  origin: 'Hồ Chí Minh',
  destination: 'Đà Lạt',
  departure: _testTime.add(const Duration(days: 1)),
);

ShipmentOptions _fakeOptions(int routeId, {bool accepts = true}) =>
    ShipmentOptions(
      routeId: routeId,
      categories: [
        const CargoCategory(
          id: 1,
          name: 'Tài liệu / Bưu phẩm',
          group: CargoGroup.parcel,
        ),
        const CargoCategory(
          id: 2,
          name: 'Hàng khô / Đồ gia dụng',
          group: CargoGroup.bulky,
        ),
      ],
      senders: accepts
          ? [
              const CargoPoint(
                id: 10,
                name: 'VP Miền Đông',
                address: '292 Đinh Bộ Lĩnh, Bình Thạnh',
              ),
              const CargoPoint(
                id: 11,
                name: 'VP An Sương',
                address: 'QL22, Q.12',
              ),
            ]
          : [],
      receivers: accepts
          ? [
              const CargoPoint(
                id: 20,
                name: 'Bến xe Đà Lạt',
                address: '01 Tô Hiến Thành, Đà Lạt',
              ),
            ]
          : [],
    );

ShipmentRecord _fakeRecord({
  int id = 100,
  String? waybillCode,
  String? orderCode,
  ShipmentPaymentMethod method = ShipmentPaymentMethod.counter,
  ShipmentPayer payer = ShipmentPayer.sender,
  String rawStatus = 'MOI_TAO',
  String rawPayment = 'CHO_THANH_TOAN',
  DateTime? confirmedAt,
  DateTime? dropoffDeadline,
  String? expectedSendDate,
  int? estimatedFee,
  int? paidAmount,
  int? outstandingAmount,
  int? tripId = 1,
}) => ShipmentRecord(
  trip: _fakeTrip(tripId ?? 1, tripId != null ? 'TRIP-$tripId' : 'TRIP-1'),
  pickup: const CargoPoint(
    id: 10,
    name: 'VP Miền Đông',
    address: '292 Đinh Bộ Lĩnh',
  ),
  dropoff: const CargoPoint(
    id: 20,
    name: 'Bến xe Đà Lạt',
    address: '01 Tô Hiến Thành',
  ),
  items: [
    ShipmentPackage.fromJson({
      'id': 1,
      'name': 'Gói bưu phẩm',
      'category': 'Tài liệu',
      'quantity': 1,
      'weight': 2.0,
    }),
  ],
  timeline: [ShipmentTimelineEntry(rawStatus, _testTime)],
  sentAt: _testTime,
  identity: ShipmentIdentity(
    shipmentId: id,
    orderId: 200,
    waybillCode: waybillCode ?? 'WAY-$id',
    orderCode: orderCode ?? 'HMGD-$id',
  ),
  paymentId: 300,
  tripId: tripId,
  senderPointId: 10,
  receiverPointId: 20,
  totalFee: 50000,
  baseFee: 50000,
  serviceFee: 0,
  discount: 0,
  senderName: 'Nguyễn Văn Gửi',
  senderPhone: '0901234567',
  receiverName: 'Trần Thị Nhận',
  receiverPhone: '0907654321',
  rawStatus: rawStatus,
  rawPaymentStatus: rawPayment,
  paymentMethod: method,
  payer: payer,
  expiresAt: _testTime.add(const Duration(minutes: 10)),
  confirmedAt: confirmedAt,
  dropoffDeadline: dropoffDeadline,
  expectedSendDate: expectedSendDate,
  estimatedFee: estimatedFee,
  paidAmount: paidAmount,
  outstandingAmount: outstandingAmount,
);

ShipmentLookup _fakeLookup({
  String? waybillCode,
  String? orderCode,
  bool paid = false,
  bool pendingOnline = false,
  bool requiresReconciliation = false,
  String? rawPaymentStatus,
  DateTime? dropoffDeadline,
}) => ShipmentLookup(
  waybillCode: waybillCode ?? 'WAY-100',
  orderCode: orderCode ?? 'HMGD-100',
  rawStatus: 'MOI_TAO',
  rawOrderStatus: paid ? 'DA_THANH_TOAN' : 'CHO_THANH_TOAN',
  rawPaymentStatus: rawPaymentStatus ?? (paid ? 'THANH_CONG' : 'DANG_XU_LY'),
  amount: 50000,
  packageCount: 1,
  paymentMethod: pendingOnline
      ? ShipmentPaymentMethod.online
      : ShipmentPaymentMethod.counter,
  requiresReconciliation: requiresReconciliation,
  expiresAt: _testTime.add(const Duration(minutes: 10)),
  serverTime: _testTime,
  dropoffDeadline: dropoffDeadline,
  pickupName: 'VP Miền Đông',
  pickupAddress: '292 Đinh Bộ Lĩnh',
  dropoffName: 'Bến xe Đà Lạt',
  dropoffAddress: '01 Tô Hiến Thành',
  carrier: 'Xe Test 1',
  origin: 'Hồ Chí Minh',
  destination: 'Đà Lạt',
  timeline: [ShipmentTimelineEntry('MOI_TAO', _testTime)],
);

class FakeShipmentRepository implements ShipmentRepository {
  List<ShipmentRoute> routesToReturn = [
    for (final id in [1, 2])
      ShipmentRoute(
        id: id,
        carrierId: 1,
        carrier: 'Xe Test $id',
        origin: 'Hồ Chí Minh',
        destination: 'Đà Lạt',
        minimumEstimatedFee: 50000,
      ),
  ];
  ShipmentOptions? optionsToReturn;
  ShipmentRecord? recordToReturn;
  ShipmentLookup? lookupToReturn;
  ShipmentPage? pageToReturn;
  Exception? errorToThrow;

  int searchCalls = 0;
  String? lastSearchFrom;
  String? lastSearchTo;
  String? lastSearchDate;
  int optionsCalls = 0;
  int createCalls = 0;
  int retryUncertainCalls = 0;
  int lookupCalls = 0;
  int listMineCalls = 0;
  int detailCalls = 0;

  @override
  Future<List<ShipmentRoute>> searchRoutes({
    required String from,
    required String to,
    required String date,
    int page = 1,
  }) async {
    searchCalls++;
    lastSearchFrom = from;
    lastSearchTo = to;
    lastSearchDate = date;
    if (errorToThrow != null) throw errorToThrow!;
    return routesToReturn;
  }

  @override
  Future<ShipmentOptions> loadOptions(int tripId) async {
    optionsCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return optionsToReturn ?? _fakeOptions(tripId);
  }

  @override
  Future<ShipmentQuote> quote(ShipmentDraft draft) async =>
      ShipmentQuote.fromJson({
        'baseFee': 50000,
        'serviceFee': 0,
        'totalFee': 50000,
        'rates': [
          {'categoryId': 1, 'rateId': 7, 'fee': 50000, 'billableWeight': 2},
        ],
      });

  @override
  Future<ShipmentRecord> create(
    ShipmentDraft draft, {
    bool retryUncertain = false,
  }) async {
    createCalls++;
    if (retryUncertain) retryUncertainCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return recordToReturn ?? _fakeRecord();
  }

  @override
  Future<ShipmentLookup> lookup({
    required String waybillCode,
    required String phone,
  }) async {
    lookupCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return lookupToReturn ?? _fakeLookup();
  }

  @override
  Future<ShipmentPage> listMine({
    int page = 1,
    int pageSize = 10,
    String search = '',
    ShipmentStatus? status,
  }) async {
    listMineCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return pageToReturn ??
        ShipmentPage(
          records: [
            ShipmentListEntry.fromJson({
              'shipmentId': 100,
              'waybillCode': 'WAY-100',
              'orderCode': 'HMGD-100',
              'status': 'MOI_TAO',
              'paymentStatus': 'CHO_THANH_TOAN',
              'totalFee': 50000,
              'itemsCount': 1,
              'sender': {
                'fullName': 'Nguyễn Văn Gửi',
                'phoneNumber': '0901234567',
              },
              'receiver': {
                'fullName': 'Trần Thị Nhận',
                'phoneNumber': '0907654321',
              },
              'trip': {'route': 'HCM - Đà Lạt', 'busCompany': 'Xe Test 1'},
              'sentAt': _testTime.toIso8601String(),
            }),
          ],
          page: 1,
          pageSize: 10,
          totalItems: 1,
          totalPages: 1,
        );
  }

  @override
  Future<ShipmentRecord> detail(int id) async {
    detailCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return recordToReturn ?? _fakeRecord(id: id);
  }
}

class FakeAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  FakeAuthBloc({bool isAuth = false})
    : super(
        AuthState(
          status: isAuth
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
          user: isAuth
              ? const UserModel(
                  taiKhoanId: 1,
                  maKhachHang: 'KH1',
                  hoTen: 'Người Dùng',
                  soDienThoai: '0901234567',
                )
              : null,
        ),
      );

  @override
  AuthRepository get authRepository => throw UnimplementedError();
}

Widget _wrap(
  Widget child, {
  FakeAuthBloc? authBloc,
  double width = 400,
  double height = 800,
  double textScale = 1.0,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, height),
        textScaler: TextScaler.linear(textScale),
      ),
      child: authBloc != null
          ? BlocProvider<AuthBloc>.value(value: authBloc, child: child)
          : child,
    ),
  );
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _selectCitiesAndSearch(
  WidgetTester tester, {
  String fromCityName = 'TP. Hồ Chí Minh',
  String toCityName = 'Đà Lạt',
}) async {
  await tester.ensureVisible(
    find.byKey(const Key('shipment_from_city_selector')),
  );
  await tester.tap(find.byKey(const Key('shipment_from_city_selector')));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ChoiceChip, fromCityName));
  await tester.pumpAndSettle();

  await tester.ensureVisible(
    find.byKey(const Key('shipment_to_city_selector')),
  );
  await tester.tap(find.byKey(const Key('shipment_to_city_selector')));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ChoiceChip, toCityName));
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('Tìm tuyến gửi hàng'));
  await tester.tap(find.text('Tìm tuyến gửi hàng'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => TokenStorage.setStorageAdapterForTesting(
      InMemorySecureStorageAdapter(),
    ),
  );
  tearDown(TokenStorage.resetStorageAdapter);

  group('Standalone Shipments UI Tests', () {
    testWidgets(
      '1. Nhập sai/Backend 4xx: hiển thị lỗi inline và giữ focus/input',
      (tester) async {
        _setPhoneViewport(tester);
        final fakeRepo = FakeShipmentRepository();
        final cubit = ShipmentFlowCubit(
          repository: fakeRepo,
          account: _testBank,
          now: () => _testTime,
        );

        await tester.pumpWidget(
          _wrap(ShipmentsHostScreen(repository: fakeRepo, cubit: cubit)),
        );
        await tester.pumpAndSettle();

        // Select from and to cities via SelectCitySheet, then search trips
        await _selectCitiesAndSearch(tester);

        expect(fakeRepo.searchCalls, 1);
        expect(fakeRepo.lastSearchFrom, 'TP.HCM');
        expect(fakeRepo.lastSearchTo, 'Đà Lạt');
        expect(find.text('Xe Test 1'), findsOneWidget);

        // Select first trip
        await tester.ensureVisible(find.text('Xe Test 1'));
        await tester.tap(find.text('Xe Test 1'));
        await tester.pumpAndSettle();
        expect(fakeRepo.optionsCalls, 1);

        // An invalid draft cannot obtain a quote or expose the create action.
        await tester.ensureVisible(find.text('Báo cước'));
        await tester.tap(find.text('Báo cước'));
        await tester.pumpAndSettle();
        expect(find.text('Tạo đơn gửi hàng'), findsNothing);

        // Client-side validation inline errors appear
        expect(find.text('Chọn điểm gửi.'), findsOneWidget);
        expect(find.text('Chọn điểm nhận.'), findsOneWidget);
        expect(find.text('Nhập họ tên người gửi.'), findsOneWidget);
        expect(find.text('Nhập họ tên người nhận.'), findsOneWidget);

        // Select sender point from dropdown
        await tester.ensureVisible(find.text('Chọn văn phòng/bến gửi hàng'));
        await tester.tap(
          find.text('Chọn văn phòng/bến gửi hàng'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.textContaining('VP Miền Đông').last,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Select receiver point from dropdown
        await tester.ensureVisible(find.text('Chọn văn phòng/bến nhận hàng'));
        await tester.tap(
          find.text('Chọn văn phòng/bến nhận hàng'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.textContaining('Bến xe Đà Lạt').last,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Enter names and phones
        final senderNameField = find.widgetWithText(
          TextField,
          'Nhập đầy đủ họ tên',
        );
        final senderPhoneField = find.widgetWithText(
          TextField,
          'VD: 0901234567',
        );
        final receiverNameField = find.widgetWithText(
          TextField,
          'Nhập đầy đủ họ tên người nhận',
        );
        final receiverPhoneField = find.widgetWithText(
          TextField,
          'VD: 0907654321',
        );

        await tester.ensureVisible(senderNameField);
        await tester.enterText(senderNameField, 'Người Gửi');
        await tester.enterText(senderPhoneField, '0901234567');
        await tester.ensureVisible(receiverNameField);
        await tester.enterText(receiverNameField, 'Người Nhận');
        await tester.enterText(receiverPhoneField, '0907654321');

        // Fill Item #1
        final itemNameField = find.widgetWithText(
          TextField,
          'VD: Thùng trái cây, Tài liệu...',
        );
        final itemWeightField = find.widgetWithText(TextField, 'VD: 5');
        await tester.ensureVisible(itemNameField);
        await tester.enterText(itemNameField, 'Bưu kiện');
        await tester.enterText(itemWeightField, '2.5');

        // Select item category
        await tester.ensureVisible(find.text('Chọn loại hàng'));
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Chọn loại hàng'));
        await tester.tap(
          find.ancestor(
            of: find.text('Chọn loại hàng'),
            matching: find.byWidgetPredicate(
              (w) => w is DropdownButtonFormField<int>,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('Tài liệu / Bưu phẩm').last,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Simulate Backend 400 error on create
        fakeRepo.errorToThrow = const ApiException(
          ApiError(
            statusCode: 400,
            errorCode: 'VALIDATION_ERROR',
            message: 'Số điện thoại người gửi không nhận mã OTP',
            details: [
              ApiValidationErrorDetail(
                field: 'sender.phoneNumber',
                message: 'Số điện thoại người gửi bị chặn',
              ),
            ],
          ),
        );

        await tester.ensureVisible(find.text('Báo cước'));
        await tester.tap(find.text('Báo cước'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Tạo đơn gửi hàng'));
        await tester.tap(find.text('Tạo đơn gửi hàng'));
        await tester.pumpAndSettle();

        // Check that field error is mapped to sender.phoneNumber
        expect(find.text('Số điện thoại người gửi bị chặn'), findsOneWidget);
        // User input is preserved!
        expect(find.text('Người Gửi'), findsOneWidget);
        expect(find.text('0901234567'), findsOneWidget);
      },
    );

    testWidgets('2. Chuyển chuyến xóa điểm cũ', (tester) async {
      _setPhoneViewport(tester);

      final fakeRepo = FakeShipmentRepository();
      final cubit = ShipmentFlowCubit(
        repository: fakeRepo,
        account: _testBank,
        now: () => _testTime,
      );

      await tester.pumpWidget(
        _wrap(ShipmentsHostScreen(repository: fakeRepo, cubit: cubit)),
      );
      await tester.pumpAndSettle();

      // Search trips via city selector
      await _selectCitiesAndSearch(tester);

      // Select trip 1
      await tester.ensureVisible(find.text('Xe Test 1'));
      await tester.tap(find.text('Xe Test 1'));
      await tester.pumpAndSettle();

      // Select sender point
      await tester.ensureVisible(find.text('Chọn văn phòng/bến gửi hàng'));
      await tester.tap(
        find.text('Chọn văn phòng/bến gửi hàng'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.textContaining('VP Miền Đông').last,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('VP Miền Đông'), findsOneWidget);

      // Now switch to trip 2
      await tester.ensureVisible(find.text('Xe Test 2'));
      await tester.tap(find.text('Xe Test 2'));
      await tester.pumpAndSettle();

      // Previously selected point must be cleared and require re-selection
      expect(find.text('Chọn văn phòng/bến gửi hàng'), findsOneWidget);
    });

    testWidgets('3. Tạo xong không POST lại & không double POST', (
      tester,
    ) async {
      _setPhoneViewport(tester);
      final fakeRepo = FakeShipmentRepository();
      final cubit = ShipmentFlowCubit(
        repository: fakeRepo,
        account: _testBank,
        now: () => _testTime,
      );

      await tester.pumpWidget(
        _wrap(ShipmentsHostScreen(repository: fakeRepo, cubit: cubit)),
      );
      await tester.pumpAndSettle();

      // Setup valid form
      await _selectCitiesAndSearch(tester);

      await tester.ensureVisible(find.text('Xe Test 1'));
      await tester.tap(find.text('Xe Test 1'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Chọn văn phòng/bến gửi hàng'));
      await tester.tap(
        find.text('Chọn văn phòng/bến gửi hàng'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.textContaining('VP Miền Đông').last,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Chọn văn phòng/bến nhận hàng'));
      await tester.tap(
        find.text('Chọn văn phòng/bến nhận hàng'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.textContaining('Bến xe Đà Lạt').last,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      final senderNameField = find.widgetWithText(
        TextField,
        'Nhập đầy đủ họ tên',
      );
      final senderPhoneField = find.widgetWithText(TextField, 'VD: 0901234567');
      final receiverNameField = find.widgetWithText(
        TextField,
        'Nhập đầy đủ họ tên người nhận',
      );
      final receiverPhoneField = find.widgetWithText(
        TextField,
        'VD: 0907654321',
      );

      await tester.ensureVisible(senderNameField);
      await tester.enterText(senderNameField, 'Nguyễn Văn Gửi');
      await tester.enterText(senderPhoneField, '0901234567');
      await tester.ensureVisible(receiverNameField);
      await tester.enterText(receiverNameField, 'Trần Thị Nhận');
      await tester.enterText(receiverPhoneField, '0907654321');

      final itemNameField = find.widgetWithText(
        TextField,
        'VD: Thùng trái cây, Tài liệu...',
      );
      final itemWeightField = find.widgetWithText(TextField, 'VD: 5');
      await tester.ensureVisible(itemNameField);
      await tester.enterText(itemNameField, 'Gói bưu phẩm');
      await tester.enterText(itemWeightField, '2.0');
      await tester.ensureVisible(find.text('Chọn loại hàng'));
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Chọn loại hàng'));
      await tester.tap(
        find.ancestor(
          of: find.text('Chọn loại hàng'),
          matching: find.byWidgetPredicate(
            (w) => w is DropdownButtonFormField<int>,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Tài liệu / Bưu phẩm').last,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Submit once
      await tester.ensureVisible(find.text('Báo cước'));
      await tester.tap(find.text('Báo cước'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tạo đơn gửi hàng'));
      await tester.tap(find.text('Tạo đơn gửi hàng'));
      await tester.pumpAndSettle();

      expect(fakeRepo.createCalls, 1);
      // Once created, we are on Detail view!
      expect(find.text('Chi tiết vận đơn'), findsOneWidget);
      expect(find.text('WAY-100'), findsOneWidget);
      // "Tạo đơn gửi hàng" submit button is no longer present, preventing repost
      expect(find.text('Tạo đơn gửi hàng'), findsNothing);
    });

    testWidgets('4. Tại bến không hiển thị VietQR thanh toán & không nút giả', (
      tester,
    ) async {
      final fakeRepo = FakeShipmentRepository();
      final record = _fakeRecord(
        method: ShipmentPaymentMethod.counter,
        payer: ShipmentPayer.sender,
      );
      final cubit = ShipmentFlowCubit(
        repository: fakeRepo,
        account: _testBank,
        now: () => _testTime,
      );

      await tester.pumpWidget(
        _wrap(
          ShipmentDetailView(
            cubit: cubit,
            state: ShipmentFlowState(
              phase: ShipmentCreationPhase.created,
              record: record,
            ),
            onNewShipment: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Displays counter explanation
      expect(find.text('Thanh toán tại bến xe'), findsOneWidget);
      expect(
        find.textContaining('thanh toán trực tiếp tại quầy bến xe'),
        findsOneWidget,
      );

      // Has QrImageView for waybill code
      expect(find.byType(QrImageView), findsOneWidget);
      expect(
        find.textContaining('Mã QR nhận diện vận đơn tại bến'),
        findsOneWidget,
      );

      // NO VietQR payment QR or fake "Tôi đã chuyển khoản" button
      expect(find.text('Quét mã VietQR để thanh toán'), findsNothing);
      expect(find.text('Tôi đã chuyển khoản'), findsNothing);
    });

    testWidgets('5. Unknown payment status không hiển thị đã thanh toán', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Scaffold(
            body: ShipmentPaymentBadge(
              paid: false,
              rawStatus: 'UNKNOWN_STATUS',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã thanh toán'), findsNothing);
      expect(find.text('UNKNOWN_STATUS'), findsOneWidget);
    });

    testWidgets('6. Lỗi refresh ẩn QR chuyển khoản ngay lập tức', (
      tester,
    ) async {
      _setPhoneViewport(tester);
      final fakeRepo = FakeShipmentRepository();
      final record = _fakeRecord(
        method: ShipmentPaymentMethod.online,
        payer: ShipmentPayer.sender,
      );
      fakeRepo.recordToReturn = record;
      fakeRepo.lookupToReturn = _fakeLookup(pendingOnline: true);

      var currentTime = _testTime;
      final cubit = ShipmentFlowCubit(
        repository: fakeRepo,
        account: _testBank,
        now: () => currentTime,
      );

      await cubit.openDetail(100);

      await tester.pumpWidget(
        _wrap(
          BlocBuilder<ShipmentFlowCubit, ShipmentFlowState>(
            bloc: cubit,
            builder: (context, state) => ShipmentDetailView(
              cubit: cubit,
              state: state,
              onNewShipment: () {},
              enablePollingTimer: false,
              qrImageBuilder: (context, url) => Container(
                key: const Key('vietqr_image'),
                child: Text('QR_URL: $url'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await cubit.refreshPayment();
      await tester.pumpAndSettle();

      // Shows QR
      expect(find.text('Quét mã VietQR để thanh toán'), findsNothing);
      expect(find.byKey(const Key('vietqr_image')), findsNothing);

      currentTime = currentTime.add(const Duration(seconds: 20));

      fakeRepo.errorToThrow = const ApiException(
        ApiError(
          statusCode: 500,
          errorCode: 'SERVER_ERROR',
          message: 'Lỗi máy chủ',
        ),
      );

      await cubit.refreshPayment();
      await tester.pumpAndSettle();

      // QR is hidden immediately; error is displayed
      expect(find.text('Lỗi máy chủ'), findsOneWidget);
      expect(find.text('Mã QR đã hết hạn\nhoặc đang làm mới'), findsNothing);
      expect(find.byKey(const Key('vietqr_image')), findsNothing);
    });

    testWidgets('7. Invalidation/Logout xóa form & dismiss view', (
      tester,
    ) async {
      final fakeRepo = FakeShipmentRepository();
      final cubit = ShipmentFlowCubit(
        repository: fakeRepo,
        account: _testBank,
        now: () => _testTime,
      );

      await tester.pumpWidget(
        _wrap(ShipmentsHostScreen(repository: fakeRepo, cubit: cubit)),
      );
      await tester.pumpAndSettle();

      // Select departure city in from selector
      await tester.tap(find.byKey(const Key('shipment_from_city_selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'TP. Hồ Chí Minh'));
      await tester.pumpAndSettle();
      expect(find.text('TP. Hồ Chí Minh'), findsOneWidget);

      // Trigger session invalidation
      cubit.invalidate();
      await tester.pumpAndSettle();

      // City selection is cleared and warning snackbar is shown
      expect(
        find.text('Phiên làm việc đã thay đổi. Dữ liệu đã được làm mới.'),
        findsOneWidget,
      );
      expect(find.text('TP. Hồ Chí Minh'), findsNothing);
    });

    testWidgets(
      '8. Responsiveness: 320dp, landscape, 2x text scaler, keyboard',
      (tester) async {
        final fakeRepo = FakeShipmentRepository();
        final cubit = ShipmentFlowCubit(
          repository: fakeRepo,
          account: _testBank,
          now: () => _testTime,
        );

        // Test A: 320dp width
        await tester.pumpWidget(
          _wrap(
            ShipmentsHostScreen(repository: fakeRepo, cubit: cubit),
            width: 320,
            height: 600,
          ),
        );
        await tester.pumpAndSettle();
        final err = tester.takeException();
        if (err is FlutterError) {
          for (final d in err.diagnostics) {
            // ignore: avoid_print
            print('DIAGNOSTIC: $d');
          }
        }
        expect(err, isNull);

        // Test B: Landscape (800x360)
        await tester.pumpWidget(
          _wrap(
            ShipmentsHostScreen(repository: fakeRepo, cubit: cubit),
            width: 800,
            height: 360,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Test C: 2.0x Text Scaler
        await tester.pumpWidget(
          _wrap(
            ShipmentsHostScreen(repository: fakeRepo, cubit: cubit),
            width: 360,
            height: 700,
            textScale: 2.0,
          ),
        );
        await tester.pumpAndSettle();
        final errC = tester.takeException();
        if (errC is FlutterError) {
          for (final d in errC.diagnostics) {
            // ignore: avoid_print
            print('PROP: ${d.name} -> ${d.toDescription()}');
          }
        }
        expect(errC, isNull);

        // Test D: Keyboard insets (bottom inset 300)
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 640),
                viewInsets: EdgeInsets.only(bottom: 300),
              ),
              child: ShipmentsHostScreen(repository: fakeRepo, cubit: cubit),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '9. Tra cứu vận đơn guest: gửi body POST & hiển thị trạng thái',
      (tester) async {
        final fakeRepo = FakeShipmentRepository();
        final cubit = ShipmentFlowCubit(
          repository: fakeRepo,
          account: _testBank,
          now: () => _testTime,
        );

        await tester.pumpWidget(
          _wrap(ShipmentsHostScreen(repository: fakeRepo, cubit: cubit)),
        );
        await tester.pumpAndSettle();

        // Switch to Tra cứu tab
        await tester.tap(find.text('Tra cứu'));
        await tester.pumpAndSettle();

        expect(find.text('Tra cứu trạng thái vận đơn'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextField, 'VD: WAY-123456'),
          'WAY-100',
        );
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Số điện thoại người gửi hoặc người nhận',
          ),
          '0901234567',
        );

        await tester.tap(find.text('Tra cứu vận đơn'));
        await tester.pumpAndSettle();

        expect(fakeRepo.lookupCalls, 1);
        expect(find.text('WAY-100'), findsAtLeast(1));
        expect(find.textContaining('Xe Test 1'), findsOneWidget);
        expect(find.text('Thanh toán tại bến'), findsOneWidget);
      },
    );

    testWidgets('10. Đơn của tôi hiển thị khi đã đăng nhập', (tester) async {
      final fakeRepo = FakeShipmentRepository();
      final cubit = ShipmentFlowCubit(
        repository: fakeRepo,
        account: _testBank,
        now: () => _testTime,
      );
      final authBloc = FakeAuthBloc(isAuth: true);

      await tester.pumpWidget(
        _wrap(
          ShipmentsHostScreen(repository: fakeRepo, cubit: cubit),
          authBloc: authBloc,
        ),
      );
      await tester.pumpAndSettle();

      // "Đơn của tôi" tab is visible
      expect(find.text('Đơn của tôi'), findsOneWidget);

      // Tap "Đơn của tôi"
      await tester.tap(find.text('Đơn của tôi'));
      await tester.pumpAndSettle();

      expect(fakeRepo.listMineCalls, 1);
      expect(find.text('WAY-100'), findsOneWidget);

      // Tap the shipment card to open detail
      await tester.tap(find.text('WAY-100'));
      await tester.pumpAndSettle();

      expect(fakeRepo.detailCalls, 1);
      expect(find.text('Chi tiết vận đơn'), findsOneWidget);
    });

    testWidgets(
      '11. [UI-01] Điều hướng từ chi tiết đơn: Tạo đơn khác, Xem danh sách & Back',
      (tester) async {
        final fakeRepo = FakeShipmentRepository();
        final cubit = ShipmentFlowCubit(
          repository: fakeRepo,
          account: _testBank,
          now: () => _testTime,
        );
        final authBloc = FakeAuthBloc(isAuth: true);

        await cubit.openDetail(100);

        await tester.pumpWidget(
          _wrap(
            ShipmentsHostScreen(repository: fakeRepo, cubit: cubit),
            authBloc: authBloc,
          ),
        );
        await tester.pumpAndSettle();

        // Initially viewing detail
        expect(find.text('Chi tiết vận đơn'), findsOneWidget);
        expect(find.text('Tạo đơn gửi hàng khác'), findsOneWidget);

        // Tap "Xem danh sách đơn gửi hàng"
        await tester.ensureVisible(find.text('Xem danh sách đơn gửi hàng'));
        await tester.tap(find.text('Xem danh sách đơn gửi hàng'));
        await tester.pumpAndSettle();

        // Switches to "Đơn của tôi" tab and stays there
        expect(find.text('Chi tiết vận đơn'), findsNothing);
        expect(find.text('Tìm kiếm theo mã vận đơn...'), findsOneWidget);
        expect(find.text('WAY-100'), findsOneWidget);

        // Open detail from list
        await tester.tap(find.text('WAY-100'));
        await tester.pumpAndSettle();
        expect(find.text('Chi tiết vận đơn'), findsOneWidget);

        // Tap Back button in header to return to list
        final backButton = find.byType(BackButton);
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Back returns to My List
        expect(find.text('Chi tiết vận đơn'), findsNothing);
        expect(find.text('Tìm kiếm theo mã vận đơn...'), findsOneWidget);

        // Open detail again and tap "Tạo đơn gửi hàng khác"
        await tester.tap(find.text('WAY-100'));
        await tester.pumpAndSettle();
        expect(find.text('Chi tiết vận đơn'), findsOneWidget);

        await tester.ensureVisible(find.text('Tạo đơn gửi hàng khác'));
        await tester.tap(find.text('Tạo đơn gửi hàng khác'));
        await tester.pumpAndSettle();

        // Now on Create form with a fresh session
        expect(find.text('Chi tiết vận đơn'), findsNothing);
        expect(
          find.byKey(const Key('shipment_from_city_selector')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '12. [UI-02] Uncertain view: tra cứu có mã điền sẵn, Back giữ uncertain & retry',
      (tester) async {
        final fakeRepo = FakeShipmentRepository();
        final cubit = ShipmentFlowCubit(
          repository: fakeRepo,
          account: _testBank,
          now: () => _testTime,
        );
        const identity = ShipmentIdentity(
          shipmentId: 101,
          orderId: 201,
          waybillCode: 'WAY-UNCERTAIN-101',
          orderCode: 'HMGD-UNCERTAIN-101',
        );

        cubit.emit(
          ShipmentFlowState(
            phase: ShipmentCreationPhase.uncertain,
            recovery: identity,
            draft: ShipmentDraft(
              routeId: 1,
              sendDate: '11-11-2026',
              senderPointId: 10,
              receiverPointId: 20,
              senderName: 'Nguyễn Văn Gửi',
              senderPhone: '0901234567',
              receiverName: 'Trần Thị Nhận',
              receiverPhone: '0907654321',
              items: [
                const ShipmentItem(
                  name: 'Kiện thử',
                  categoryId: 1,
                  quantity: 1,
                  weight: 2.0,
                ),
              ],
              payer: ShipmentPayer.sender,
              paymentMethod: ShipmentPaymentMethod.counter,
            ),
          ),
        );

        await tester.pumpWidget(
          _wrap(ShipmentsHostScreen(repository: fakeRepo, cubit: cubit)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Kết quả tạo đơn'), findsOneWidget);
        expect(find.text('Chưa thể xác minh kết quả tạo đơn'), findsOneWidget);
        expect(find.text('WAY-UNCERTAIN-101'), findsOneWidget);
        expect(find.text('Kiểm tra lại kết quả tạo đơn'), findsOneWidget);

        // Tap "Tra cứu vận đơn này"
        await tester.ensureVisible(find.text('Tra cứu vận đơn này'));
        await tester.tap(find.text('Tra cứu vận đơn này'));
        await tester.pumpAndSettle();

        // Lookup view is rendered with the prefilled code
        expect(find.byType(ShipmentLookupView), findsOneWidget);
        expect(find.text('Tra cứu trạng thái vận đơn'), findsOneWidget);
        expect(find.text('WAY-UNCERTAIN-101'), findsOneWidget);
        expect(cubit.state.phase, ShipmentCreationPhase.uncertain);

        // Tap Back returns to uncertain view without creating new shipment
        final backButton = find.byType(BackButton);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(find.text('Kết quả tạo đơn'), findsOneWidget);
        expect(find.text('Chưa thể xác minh kết quả tạo đơn'), findsOneWidget);
        expect(cubit.state.phase, ShipmentCreationPhase.uncertain);

        // Tap retry uncertain creation
        await tester.ensureVisible(find.text('Kiểm tra lại kết quả tạo đơn'));
        await tester.tap(find.text('Kiểm tra lại kết quả tạo đơn'));
        await tester.pumpAndSettle();

        expect(fakeRepo.retryUncertainCalls, 1);
        expect(fakeRepo.createCalls, 1);
        // Upon successful retry, record is confirmed and detail view is shown
        expect(find.text('Chi tiết vận đơn'), findsOneWidget);
      },
    );

    testWidgets(
      '13. [UI-03] UUID 32 ký tự trên 320dp & 2.0x text scale không overflow, copy button >= 48dp',
      (tester) async {
        const longWaybill = 'a123456789abcdef0123456789abcdef';
        const longOrderCode = 'b123456789abcdef0123456789abcdef';
        final fakeRepo = FakeShipmentRepository();
        final cubit = ShipmentFlowCubit(
          repository: fakeRepo,
          account: _testBank,
          now: () => _testTime,
        );

        final longRecord = _fakeRecord(
          id: 100,
          waybillCode: longWaybill,
          orderCode: longOrderCode,
        );

        // 1. Detail View with 32-char UUIDs at 320dp and 2.0x text
        await tester.pumpWidget(
          _wrap(
            Scaffold(
              body: ShipmentDetailView(
                cubit: cubit,
                state: ShipmentFlowState(
                  phase: ShipmentCreationPhase.created,
                  record: longRecord,
                ),
                onNewShipment: () {},
                enablePollingTimer: false,
              ),
            ),
            width: 320,
            height: 700,
            textScale: 2.0,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Verify copy button size >= 48dp
        final copyButtons = find.byTooltip('Sao chép mã đơn');
        expect(copyButtons, findsOneWidget);
        final renderBox = tester.renderObject<RenderBox>(copyButtons);
        expect(renderBox.size.width, greaterThanOrEqualTo(48.0));
        expect(renderBox.size.height, greaterThanOrEqualTo(48.0));

        // 2. Lookup View with 32-char UUIDs
        final longLookup = _fakeLookup(
          waybillCode: longWaybill,
          orderCode: longOrderCode,
        );
        await tester.pumpWidget(
          _wrap(
            Scaffold(
              body: ShipmentLookupView(
                cubit: cubit,
                state: ShipmentFlowState(lookup: longLookup),
              ),
            ),
            width: 320,
            height: 700,
            textScale: 2.0,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // 3. Uncertain View with 32-char UUIDs
        await tester.pumpWidget(
          _wrap(
            Scaffold(
              body: ShipmentUncertainView(
                cubit: cubit,
                state: const ShipmentFlowState(
                  phase: ShipmentCreationPhase.uncertain,
                  recovery: ShipmentIdentity(
                    shipmentId: 100,
                    orderId: 200,
                    waybillCode: longWaybill,
                    orderCode: longOrderCode,
                  ),
                ),
                isAuthenticated: false,
              ),
            ),
            width: 320,
            height: 700,
            textScale: 2.0,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '14. [UI-04] Phân biệt cước dự tính vs xác nhận, paidAmount/outstandingAmount & dropoffDeadline',
      (tester) async {
        final fakeRepo = FakeShipmentRepository();
        final cubit = ShipmentFlowCubit(
          repository: fakeRepo,
          account: _testBank,
          now: () => _testTime,
        );

        final deadline = _testTime.add(const Duration(hours: 72));

        // Case A: confirmedAt == null -> "Cước dự tính" + note
        final unconfirmedRecord = _fakeRecord(
          confirmedAt: null,
          dropoffDeadline: deadline,
          paidAmount: 20000,
          outstandingAmount: 30000,
          expectedSendDate: '15-11-2026',
        );

        await tester.pumpWidget(
          _wrap(
            Scaffold(
              body: ShipmentDetailView(
                cubit: cubit,
                state: ShipmentFlowState(
                  phase: ShipmentCreationPhase.created,
                  record: unconfirmedRecord,
                ),
                onNewShipment: () {},
                enablePollingTimer: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Cước dự tính'), findsOneWidget);
        expect(
          find.text('Cước phí thực tế sẽ được cân đo và xác nhận tại bến.'),
          findsOneWidget,
        );
        expect(find.text('Hạn mang hàng ra bến:'), findsOneWidget);
        expect(find.text('Ngày dự kiến gửi: 15-11-2026'), findsOneWidget);
        expect(find.text('Đã thanh toán'), findsOneWidget);
        expect(find.text('Còn phải thanh toán'), findsOneWidget);

        // Case B: confirmedAt != null -> "Cước phí xác nhận"
        final confirmedRecord = _fakeRecord(
          confirmedAt: _testTime,
          dropoffDeadline: deadline,
        );

        await tester.pumpWidget(
          _wrap(
            Scaffold(
              body: ShipmentDetailView(
                cubit: cubit,
                state: ShipmentFlowState(
                  phase: ShipmentCreationPhase.created,
                  record: confirmedRecord,
                ),
                onNewShipment: () {},
                enablePollingTimer: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Cước phí xác nhận'), findsOneWidget);
        expect(find.textContaining('Đã xác nhận:'), findsOneWidget);
      },
    );

    testWidgets(
      '15. [UI-05] Quy trình hai bước Báo cước -> Tạo đơn: tóm tắt cước sát CTA & vô hiệu hóa khi sửa input',
      (tester) async {
        _setPhoneViewport(tester);

        final fakeRepo = FakeShipmentRepository();
        final cubit = ShipmentFlowCubit(
          repository: fakeRepo,
          account: _testBank,
          now: () => _testTime,
        );

        await tester.pumpWidget(
          _wrap(ShipmentsHostScreen(repository: fakeRepo, cubit: cubit)),
        );
        await tester.pumpAndSettle();

        // Search routes
        await _selectCitiesAndSearch(tester);

        // Select route
        await tester.ensureVisible(find.text('Xe Test 1'));
        await tester.tap(find.text('Xe Test 1'));
        await tester.pumpAndSettle();

        // Select points and fill parties
        await tester.ensureVisible(find.text('Chọn văn phòng/bến gửi hàng'));
        await tester.tap(
          find.text('Chọn văn phòng/bến gửi hàng'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.textContaining('VP Miền Đông').last,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Chọn văn phòng/bến nhận hàng'));
        await tester.tap(
          find.text('Chọn văn phòng/bến nhận hàng'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.textContaining('Bến xe Đà Lạt').last,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        final senderName = find.widgetWithText(TextField, 'Nhập đầy đủ họ tên');
        await tester.ensureVisible(senderName);
        await tester.enterText(senderName, 'Nguyễn Văn Gửi');
        final senderPhone = find.widgetWithText(TextField, 'VD: 0901234567');
        await tester.ensureVisible(senderPhone);
        await tester.enterText(senderPhone, '0901234567');

        final receiverName = find.widgetWithText(
          TextField,
          'Nhập đầy đủ họ tên người nhận',
        );
        await tester.ensureVisible(receiverName);
        await tester.enterText(receiverName, 'Trần Thị Nhận');
        final receiverPhone = find.widgetWithText(TextField, 'VD: 0907654321');
        await tester.ensureVisible(receiverPhone);
        await tester.enterText(receiverPhone, '0907654321');

        final pkgName = find.widgetWithText(
          TextField,
          'VD: Thùng trái cây, Tài liệu...',
        );
        await tester.ensureVisible(pkgName);
        await tester.enterText(pkgName, 'Hàng mẫu');
        final pkgWeight = find.widgetWithText(TextField, 'VD: 5');
        await tester.ensureVisible(pkgWeight);
        await tester.enterText(pkgWeight, '3.5');

        await tester.ensureVisible(find.text('Chọn loại hàng'));
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Chọn loại hàng'));
        await tester.tap(
          find.ancestor(
            of: find.text('Chọn loại hàng'),
            matching: find.byWidgetPredicate(
              (w) => w is DropdownButtonFormField<int>,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('Tài liệu / Bưu phẩm').last,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Step 1: Initial state has "Báo cước", no "Tạo đơn gửi hàng"
        await tester.ensureVisible(find.text('Báo cước'));
        expect(find.text('Tạo đơn gửi hàng'), findsNothing);

        // Tap "Báo cước"
        await tester.tap(find.text('Báo cước'));
        await tester.pumpAndSettle();

        // Quote card appears right above the CTA button
        expect(find.text('CƯỚC DỰ TÍNH'), findsOneWidget);
        expect(find.textContaining('50.000'), findsWidgets);
        expect(find.text('Tạo đơn gửi hàng'), findsOneWidget);

        // Changing note invalidates quote and hides "Tạo đơn gửi hàng"
        final noteField = find.widgetWithText(
          TextField,
          'Nhập ghi chú hoặc yêu cầu bàn giao cho nhà xe...',
        );
        await tester.ensureVisible(noteField);
        await tester.enterText(noteField, 'Giao giờ hành chính');
        await tester.pumpAndSettle();

        expect(find.text('CƯỚC DỰ TÍNH'), findsNothing);
        expect(find.text('Tạo đơn gửi hàng'), findsNothing);
        expect(find.text('Báo cước'), findsOneWidget);
      },
    );

    testWidgets(
      '16. [UI-06] Đồng bộ bộ lọc Đơn của tôi khi đổi tab và quay lại',
      (tester) async {
        final fakeRepo = FakeShipmentRepository();
        final cubit = ShipmentFlowCubit(
          repository: fakeRepo,
          account: _testBank,
          now: () => _testTime,
        );
        final authBloc = FakeAuthBloc(isAuth: true);

        await tester.pumpWidget(
          _wrap(
            ShipmentsHostScreen(repository: fakeRepo, cubit: cubit),
            authBloc: authBloc,
          ),
        );
        await tester.pumpAndSettle();

        // Go to "Đơn của tôi"
        await tester.tap(find.text('Đơn của tôi'));
        await tester.pumpAndSettle();

        // Select filter "Đã giao"
        await tester.tap(find.text('Đã giao'));
        await tester.pumpAndSettle();

        // Verify "Đã giao" filter is selected
        final deliveredChip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'Đã giao'),
        );
        expect(deliveredChip.selected, isTrue);

        // Switch to "Tạo đơn"
        await tester.tap(find.text('Tạo đơn'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('shipment_from_city_selector')),
          findsOneWidget,
        );

        // Switch back to "Đơn của tôi"
        await tester.tap(find.text('Đơn của tôi'));
        await tester.pumpAndSettle();

        // "Đã giao" chip is STILL selected, keeping UI in sync with query
        final returnedChip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'Đã giao'),
        );
        expect(returnedChip.selected, isTrue);
      },
    );

    testWidgets(
      '17. [P1-01] Tạo đơn mới có cùng nội dung dùng khóa idempotency mới',
      (tester) async {
        _setPhoneViewport(tester);
        final server = fixture.Server();
        final first = ShipmentFlowCubit(repository: server.repository);
        addTearDown(first.close);

        await fixture.prepare(first);
        await first.create();
        expect(first.state.phase, ShipmentCreationPhase.created);

        await tester.pumpWidget(
          MaterialApp(
            home: ShipmentsHostScreen(
              repository: server.repository,
              cubit: first,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Tạo đơn gửi hàng khác'));
        await tester.tap(find.text('Tạo đơn gửi hàng khác'));
        await tester.pumpAndSettle();

        final next = tester
            .widget<ShipmentCreateView>(find.byType(ShipmentCreateView))
            .cubit;
        await fixture.prepare(next);
        await next.create();
        await tester.pumpAndSettle();

        final posts = server.requests
            .where(
              (r) => r.method == 'POST' && r.url.path.endsWith('/shipments'),
            )
            .toList();
        expect(posts.length, 2);
        expect(
          posts.last.headers['Idempotency-Key'],
          isNot(posts.first.headers['Idempotency-Key']),
        );

        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );

    testWidgets(
      '18. [P1-02] Đổi tài khoản xóa sạch PII/form cũ và gắn listener vào cubit mới',
      (tester) async {
        _setPhoneViewport(tester);
        final server = fixture.Server();

        await tester.pumpWidget(
          MaterialApp(home: ShipmentsHostScreen(repository: server.repository)),
        );
        await tester.pumpAndSettle();

        final first = tester
            .widget<ShipmentCreateView>(find.byType(ShipmentCreateView))
            .cubit;
        await fixture.prepare(first);
        await tester.pumpAndSettle();

        final field = find.widgetWithText(TextField, 'Nhập đầy đủ họ tên');
        await tester.ensureVisible(field);
        await tester.enterText(field, 'Previous account private name');

        await TokenStorage.saveTokens(accessToken: 'next-account');
        await tester.pumpAndSettle();

        final next = tester
            .widget<ShipmentCreateView>(find.byType(ShipmentCreateView))
            .cubit;
        expect(identical(first, next), false);

        await fixture.prepare(next);
        await tester.pumpAndSettle();

        expect(find.text('Previous account private name'), findsNothing);

        // Verify quote invalidation listener is attached to the new cubit
        expect(next.state.quote, isNotNull);
        final newField = find.widgetWithText(TextField, 'Nhập đầy đủ họ tên');
        await tester.enterText(newField, 'New User Name');
        await tester.pumpAndSettle();
        expect(next.state.quote, isNull);

        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );

    testWidgets(
      '19. [NAV-01] Bottom navigation 5 tabs chuẩn thứ tự, giữ state Gửi hàng khi chuyển tab/re-tap, ẩn Back ở root & xóa mục trùng ở Profile',
      (tester) async {
        final fakeRepo = FakeShipmentRepository();
        final authBloc = FakeAuthBloc(isAuth: false);
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) =>
                  MainShellScreen(navigationShell: navigationShell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/',
                      builder: (_, _) => const Scaffold(body: Text('HOME_TAB')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/my-tickets',
                      builder: (_, _) =>
                          const Scaffold(body: Text('TICKETS_TAB')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/shipments',
                      builder: (_, _) =>
                          ShipmentsHostScreen(repository: fakeRepo),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/notifications',
                      builder: (_, _) =>
                          const Scaffold(body: Text('NOTIFICATIONS_TAB')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/profile',
                      builder: (_, _) => const ProfileScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 700),
                textScaler: TextScaler.linear(2.0),
              ),
              child: MaterialApp.router(routerConfig: router),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final bottomNav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNav.items.map((e) => e.label).toList(), [
          'Trang chủ',
          'Vé của tôi',
          'Gửi hàng',
          'Thông báo',
          'Tài khoản',
        ]);

        // Tap Gửi hàng tab (index 2)
        await tester.tap(find.text('Gửi hàng'));
        await tester.pumpAndSettle();

        expect(find.byType(ShipmentsHostScreen), findsOneWidget);
        // Root of Gửi hàng tab has no meaningless BackButton
        expect(find.byType(BackButton), findsNothing);

        // Select departure city on Gửi hàng tab
        await tester.tap(find.byKey(const Key('shipment_from_city_selector')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ChoiceChip, 'TP. Hồ Chí Minh'));
        await tester.pumpAndSettle();
        expect(find.text('TP. Hồ Chí Minh'), findsOneWidget);

        // Switch to Tài khoản tab (index 4) and verify duplicate "Gửi hàng" menu item was removed
        await tester.tap(find.text('Tài khoản'));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsOneWidget);
        // Only the bottom nav bar has 'Gửi hàng', not the ProfileScreen menu list
        expect(find.text('Gửi hàng'), findsOneWidget);

        // Return to Gửi hàng tab and re-tap it; state is preserved
        await tester.tap(find.text('Gửi hàng'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Gửi hàng').last);
        await tester.pumpAndSettle();
        expect(find.text('TP. Hồ Chí Minh'), findsOneWidget);
      },
    );

    testWidgets(
      '20. [SEARCH-01] Chọn điểm đi/đến qua SelectCitySheet, đổi chiều (Swap >= 48dp + tooltip/semantics), xóa tuyến/điểm/báo giá cũ & chặn thiếu/trùng tỉnh',
      (tester) async {
        _setPhoneViewport(tester);
        final fakeRepo = FakeShipmentRepository();
        final cubit = ShipmentFlowCubit(
          repository: fakeRepo,
          account: _testBank,
          now: () => _testTime,
        );

        await tester.pumpWidget(
          _wrap(ShipmentsHostScreen(repository: fakeRepo, cubit: cubit)),
        );
        await tester.pumpAndSettle();

        // Tapping search before selecting cities shows inline validation message
        await tester.tap(find.text('Tìm tuyến gửi hàng'));
        await tester.pumpAndSettle();
        expect(
          find.text('Vui lòng chọn điểm đi và điểm đến.'),
          findsAtLeastNWidgets(1),
        );
        expect(fakeRepo.searchCalls, 0);

        // Select identical cities -> blocked with inline message
        await tester.tap(find.byKey(const Key('shipment_from_city_selector')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ChoiceChip, 'Đà Lạt'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('shipment_to_city_selector')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ChoiceChip, 'Đà Lạt'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Tìm tuyến gửi hàng'));
        await tester.pumpAndSettle();
        expect(
          find.text('Điểm đi và điểm đến không được trùng nhau.'),
          findsAtLeastNWidgets(1),
        );
        expect(fakeRepo.searchCalls, 0);

        // Select TP. Hồ Chí Minh -> Đà Lạt and search
        await _selectCitiesAndSearch(tester);
        expect(fakeRepo.searchCalls, 1);
        expect(fakeRepo.lastSearchFrom, 'TP.HCM');
        expect(fakeRepo.lastSearchTo, 'Đà Lạt');

        // Select route 1 and sender point
        await tester.ensureVisible(find.text('Xe Test 1'));
        await tester.tap(find.text('Xe Test 1'));
        await tester.pumpAndSettle();
        expect(cubit.state.selectedRouteId, 1);

        // Verify Swap button size >= 48x48dp and tooltip
        final swapFinder = find.byKey(const Key('shipment_swap_cities_button'));
        expect(find.byTooltip('Đổi chiều điểm đi và điểm đến'), findsOneWidget);
        final swapSize = tester.getSize(swapFinder);
        expect(swapSize.width, greaterThanOrEqualTo(48.0));
        expect(swapSize.height, greaterThanOrEqualTo(48.0));

        // Tap Swap button -> swaps cities and clears selected route/options
        await tester.ensureVisible(swapFinder);
        await tester.tap(swapFinder);
        await tester.pumpAndSettle();

        expect(cubit.state.selectedRouteId, isNull);
        expect(cubit.state.routes, isEmpty);

        // Search again after swap -> sends Đà Lạt to TP.HCM
        await tester.tap(find.text('Tìm tuyến gửi hàng'));
        await tester.pumpAndSettle();
        expect(fakeRepo.searchCalls, 2);
        expect(fakeRepo.lastSearchFrom, 'Đà Lạt');
        expect(fakeRepo.lastSearchTo, 'TP.HCM');
      },
    );

    testWidgets(
      '21. [SEARCH-02] Trạng thái danh mục tỉnh/thành phố: lỗi + Thử lại và danh sách rỗng + Tải lại',
      (tester) async {
        final fakeRepo = FakeShipmentRepository();
        var shouldFail = true;
        var returnEmpty = false;

        Future<List<CityModel>> customLoader() async {
          if (shouldFail) {
            throw Exception('Network error');
          }
          if (returnEmpty) {
            return const [];
          }
          return const [
            CityModel(
              id: 'HCM',
              name: 'TP. Hồ Chí Minh',
              region: 'Miền Nam',
              isPopular: true,
            ),
            CityModel(
              id: 'DL',
              name: 'Đà Lạt',
              region: 'Tây Nguyên',
              isPopular: true,
            ),
          ];
        }

        await tester.pumpWidget(
          _wrap(
            ShipmentsHostScreen(
              repository: fakeRepo,
              citiesLoader: customLoader,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Shows error banner and Retry button
        expect(
          find.text('Không thể tải danh sách tỉnh/thành phố.'),
          findsOneWidget,
        );
        expect(find.text('Thử lại'), findsOneWidget);

        // Switch to empty list on retry
        shouldFail = false;
        returnEmpty = true;
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();

        expect(
          find.text('Chưa có danh sách tỉnh/thành phố khả dụng.'),
          findsOneWidget,
        );
        expect(find.text('Tải lại'), findsOneWidget);

        // Switch to valid catalog on reload
        returnEmpty = false;
        await tester.tap(find.text('Tải lại'));
        await tester.pumpAndSettle();

        expect(
          find.text('Chưa có danh sách tỉnh/thành phố khả dụng.'),
          findsNothing,
        );
        await tester.tap(find.byKey(const Key('shipment_from_city_selector')));
        await tester.pumpAndSettle();
        expect(find.text('TP. Hồ Chí Minh'), findsWidgets);
      },
    );

    testWidgets(
      '22. [D01] Back từ chi tiết sau khi tạo đơn mở lại form tạo mới (phase == editing & khóa idempotency mới); Back từ chi tiết mở ở Đơn của tôi quay về Đơn của tôi',
      (tester) async {
        _setPhoneViewport(tester);
        final server = fixture.Server();
        final authBloc = FakeAuthBloc(isAuth: true);

        await tester.pumpWidget(
          _wrap(
            ShipmentsHostScreen(repository: server.repository),
            authBloc: authBloc,
          ),
        );
        await tester.pumpAndSettle();

        final firstCubit = tester
            .widget<ShipmentCreateView>(find.byType(ShipmentCreateView))
            .cubit;
        await fixture.prepare(firstCubit);
        await firstCubit.create();
        await tester.pumpAndSettle();

        // Detail view is shown after creation
        expect(find.text('Chi tiết vận đơn'), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);

        // Press BackButton from created detail
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Returns to ShipmentCreateView with a fresh editing cubit and new idempotency key
        final createFinder = find.byType(ShipmentCreateView);
        expect(createFinder, findsOneWidget);
        final secondCubit = tester
            .widget<ShipmentCreateView>(createFinder)
            .cubit;
        expect(secondCubit.state.phase, ShipmentCreationPhase.editing);
        expect(identical(firstCubit, secondCubit), isFalse);

        await fixture.prepare(secondCubit);
        await secondCubit.create();
        await tester.pumpAndSettle();

        final posts = server.requests
            .where(
              (r) => r.method == 'POST' && r.url.path.endsWith('/shipments'),
            )
            .toList();
        expect(posts.length, 2);
        expect(
          posts.last.headers['Idempotency-Key'],
          isNot(posts.first.headers['Idempotency-Key']),
        );

        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );

    testWidgets(
      '24. Date picker ignores its result after session replaces the host owner',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ShipmentsHostScreen(repository: FakeShipmentRepository()),
          ),
        );
        await tester.pumpAndSettle();
        final first = tester
            .widget<ShipmentCreateView>(find.byType(ShipmentCreateView))
            .cubit;
        final selector = find.byKey(const Key('shipment_send_date_selector'));
        await tester.ensureVisible(selector);
        await tester.tap(selector);
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsOneWidget);

        // Replace the session and invalidate its owner without depending on
        // credential-write futures shared across widget-test fake async zones.
        TokenStorage.setStorageAdapterForTesting(
          InMemorySecureStorageAdapter(),
        );
        first.invalidate();
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final next = tester
            .widget<ShipmentCreateView>(find.byType(ShipmentCreateView))
            .cubit;
        expect(identical(first, next), isFalse);
        expect(next.state.phase, ShipmentCreationPhase.editing);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      '25. Date picker from an old owner cannot clear the new owners quote',
      (tester) async {
        final server = fixture.Server();
        final first = ShipmentFlowCubit(repository: server.repository);
        final next = ShipmentFlowCubit(repository: server.repository);
        final owner = ValueNotifier(first);
        addTearDown(first.close);
        addTearDown(next.close);
        addTearDown(owner.dispose);
        await fixture.prepare(next);
        final quote = next.state.quote;
        expect(quote, isNotNull);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<ShipmentFlowCubit>(
                valueListenable: owner,
                builder: (_, cubit, _) =>
                    ShipmentCreateView(cubit: cubit, state: cubit.state),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final selector = find.byKey(const Key('shipment_send_date_selector'));
        await tester.ensureVisible(selector);
        await tester.tap(selector);
        await tester.pumpAndSettle();
        owner.value = next;
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(next.state.quote, same(quote));
        expect(next.state.selectedRouteId, 1);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      '23. [D02] Hiển thị hạn mang hàng ra bến (dropoffDeadline) và thời điểm xác nhận (confirmedAt) kèm HH:mm theo giờ địa phương ở Detail & Lookup',
      (tester) async {
        final fakeRepo = FakeShipmentRepository();
        final cubit = ShipmentFlowCubit(
          repository: fakeRepo,
          account: _testBank,
          now: () => _testTime,
        );
        final deadlineUtc = DateTime.utc(2026, 11, 8, 16, 45);
        final confirmedUtc = DateTime.utc(2026, 11, 8, 9, 30);

        final deadlineLocal = deadlineUtc.toLocal();
        final deadlineHhMm =
            '${deadlineLocal.hour.toString().padLeft(2, '0')}:${deadlineLocal.minute.toString().padLeft(2, '0')}';
        final expectedDeadlineText =
            '$deadlineHhMm - ${DateFormatter.formatFullDate(deadlineLocal)}';

        final confirmedLocal = confirmedUtc.toLocal();
        final confirmedHhMm =
            '${confirmedLocal.hour.toString().padLeft(2, '0')}:${confirmedLocal.minute.toString().padLeft(2, '0')}';
        final expectedConfirmedText =
            'Đã xác nhận: $confirmedHhMm - ${DateFormatter.formatFullDate(confirmedLocal)}';

        final record = _fakeRecord(
          dropoffDeadline: deadlineUtc,
          confirmedAt: confirmedUtc,
        );

        await tester.pumpWidget(
          _wrap(
            Scaffold(
              body: ShipmentDetailView(
                cubit: cubit,
                state: ShipmentFlowState(
                  phase: ShipmentCreationPhase.created,
                  record: record,
                ),
                onNewShipment: () {},
                enablePollingTimer: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(expectedDeadlineText), findsOneWidget);
        expect(find.text(expectedConfirmedText), findsOneWidget);

        // Also check Lookup view
        final lookup = _fakeLookup(dropoffDeadline: deadlineUtc);
        await tester.pumpWidget(
          _wrap(
            Scaffold(
              body: ShipmentLookupView(
                cubit: cubit,
                state: ShipmentFlowState(lookup: lookup),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Hạn mang hàng ra bến: $expectedDeadlineText'),
          findsOneWidget,
        );
      },
    );
  });
}
