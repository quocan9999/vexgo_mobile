import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/booking_cargo_model.dart';
import 'package:vexgo_app/data/models/booking_model.dart';
import 'package:vexgo_app/data/repositories/cargo_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/presentation/screens/booking_success_screen.dart';
import 'package:vexgo_app/features/user/booking/presentation/steps/step_4_passenger_info.dart';
import 'package:vexgo_app/features/user/booking/presentation/steps/step_5_trip_summary.dart';
import 'package:vexgo_app/features/user/booking/presentation/steps/step_6_payment.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_cargo_section_card.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_passenger_info_view.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_payment_view.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_trip_summary_view.dart';
import 'package:vexgo_app/features/user/round_trip/presentation/screens/round_trip_booking_screen.dart';
import 'package:vexgo_app/features/user/round_trip/presentation/widgets/round_trip_success_view.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_checkout_cubit.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';

import 'booking_cargo_core_test.dart' as cargo_core;
import 'round_trip_core_test.dart' as core;

CargoOptions _sampleCargoOptions({
  int tripId = 101,
  bool acceptsShipments = true,
  int parcelRemaining = 5,
  int bulkyRemaining = 2,
  int motorcycleRemaining = 1,
}) {
  return CargoOptions(
    tripId: tripId,
    categories: const [
      CargoCategory(
        id: 1,
        name: 'Xe máy số / tay ga',
        group: CargoGroup.motorcycle,
      ),
      CargoCategory(id: 2, name: 'Hàng cồng kềnh', group: CargoGroup.bulky),
      CargoCategory(
        id: 3,
        name: 'Hàng nhẹ tiêu chuẩn',
        group: CargoGroup.parcel,
      ),
    ],
    capacity: CargoCapacity(
      acceptsShipments: acceptsShipments,
      slots: {
        CargoGroup.parcel: CargoSlots(
          total: 10,
          used: 10 - parcelRemaining,
          remaining: parcelRemaining,
        ),
        CargoGroup.bulky: CargoSlots(
          total: 4,
          used: 4 - bulkyRemaining,
          remaining: bulkyRemaining,
        ),
        CargoGroup.motorcycle: CargoSlots(
          total: 2,
          used: 2 - motorcycleRemaining,
          remaining: motorcycleRemaining,
        ),
      },
    ),
    points: CargoRoutePoints(
      tripId: tripId,
      senders: [
        CargoPoint(
          id: tripId * 10,
          name: 'VP Quận 1',
          address: '272 Đề Thám, Q.1',
        ),
        CargoPoint(
          id: tripId * 10 + 2,
          name: 'BX Miền Đông',
          address: '292 Đinh Bộ Lĩnh',
        ),
      ],
      receivers: [
        CargoPoint(
          id: tripId * 10 + 1,
          name: 'BX Liên Tỉnh Đà Lạt',
          address: '01 Tô Hiến Thành',
        ),
        CargoPoint(
          id: tripId * 10,
          name: 'VP Quận 1 (Trùng điểm)',
          address: '272 Đề Thám, Q.1',
        ),
      ],
    ),
  );
}

class _FakeCargoRepository implements CargoRepository {
  final Map<int, CargoOptions> optionsByTrip;
  bool shouldFail = false;
  int loadCount = 0;

  _FakeCargoRepository({Map<int, CargoOptions>? optionsByTrip})
    : optionsByTrip =
          optionsByTrip ??
          {
            101: _sampleCargoOptions(tripId: 101),
            102: _sampleCargoOptions(tripId: 102),
          };

  @override
  Future<CargoOptions> loadOptions(int tripId) async {
    loadCount++;
    if (shouldFail) {
      throw StateError('Network failure loading cargo');
    }
    return optionsByTrip[tripId] ?? _sampleCargoOptions(tripId: tripId);
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  int maxIterations = 80,
}) async {
  for (var i = 0; i < maxIterations && !predicate(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<BookingFlowBloc> _prepareOneWayBlocAtStep({
  required cargo_core.CargoServer server,
  CargoRepository? cargoRepo,
  BookingStep targetStep = BookingStep.passengerInfo,
}) async {
  final bloc = BookingFlowBloc(
    seatRepository: server.seats,
    bookingRepository: server.bookings,
    cargoRepository: cargoRepo ?? server.cargo,
    now: () => server.now,
    receivingAccount: cargo_core.bank,
  );
  bloc.add(
    InitBookingFlowEvent(
      trip: core.trip(101),
      date: core.request().departureDate,
    ),
  );
  await bloc.stream.firstWhere((s) => s.status == BookingFlowStatus.loaded);
  await bloc.applyDraftAction(
    const UpdatePassengerInfoEvent(
      name: 'Nguyễn Văn An',
      phone: '0901234567',
      email: 'an@example.com',
    ),
  );
  await bloc.applyDraftAction(
    ToggleSeatEvent(bloc.state.seatLayout!.lowerFloor.first),
  );
  await bloc.applyDraftAction(const NextStepEvent()); // -> pickupPoint
  await bloc.applyDraftAction(const NextStepEvent()); // -> dropoffPoint
  await bloc.applyDraftAction(const NextStepEvent()); // -> passengerInfo
  if (targetStep.index >= BookingStep.tripSummary.index) {
    await bloc.applyDraftAction(const NextStepEvent()); // -> tripSummary
  }
  if (targetStep.index >= BookingStep.payment.index) {
    await bloc.applyDraftAction(const NextStepEvent()); // -> payment
  }
  return bloc;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(accessToken: 'cargo-ui-owner');
  });

  tearDown(TokenStorage.resetStorageAdapter);

  group('BookingCargoSectionCard & One-Way Cargo UI', () {
    testWidgets(
      '1. Default cargo off keeps normal ticket flow; enabling shows loading, error, retry, and disable without auto-turning off',
      (tester) async {
        final server = cargo_core.CargoServer();
        final cargoRepo = _FakeCargoRepository()..shouldFail = true;

        final bloc = await tester.runAsync(
          () => _prepareOneWayBlocAtStep(
            server: server,
            cargoRepo: cargoRepo,
            targetStep: BookingStep.passengerInfo,
          ),
        );
        addTearDown(bloc!.close);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocBuilder<BookingFlowBloc, BookingFlowState>(
              bloc: bloc,
              builder: (context, state) => BookingPassengerInfoView(
                state: state,
                bloc: bloc,
                onBack: () {},
                onNext: () => bloc.add(const NextStepEvent()),
              ),
            ),
          ),
        );
        await tester.pump();

        // Default off
        expect(bloc.state.cargo.enabled, isFalse);
        expect(find.byKey(const Key('cargo-toggle-oneway')), findsOneWidget);

        // Toggle cargo ON while cargoRepo fails
        await tester.ensureVisible(
          find.byKey(const Key('cargo-toggle-oneway')),
        );
        await tester.tap(find.byKey(const Key('cargo-toggle-oneway')));
        await _pumpUntil(tester, () => bloc.state.cargo.error != null);

        // Cargo stays enabled with explicit error, retry and disable buttons
        expect(bloc.state.cargo.enabled, isTrue);
        expect(find.byKey(const Key('cargo-error-oneway')), findsOneWidget);
        expect(find.byKey(const Key('cargo-retry-btn-oneway')), findsOneWidget);
        expect(
          find.byKey(const Key('cargo-disable-btn-oneway')),
          findsOneWidget,
        );

        // Continue button in BookingPassengerDock is disabled while cargo has error
        final nextBtn = tester.widget<DiscoveryButton>(
          find.widgetWithText(DiscoveryButton, 'Tiếp tục'),
        );
        expect(nextBtn.onPressed, isNull);

        // Fix cargoRepo and tap Retry
        cargoRepo.shouldFail = false;
        await tester.ensureVisible(
          find.byKey(const Key('cargo-retry-btn-oneway')),
        );
        await tester.tap(find.byKey(const Key('cargo-retry-btn-oneway')));
        await _pumpUntil(tester, () => bloc.state.cargo.options != null);

        expect(bloc.state.cargo.error, isNull);
        expect(find.byKey(const Key('cargo-capacity-oneway')), findsOneWidget);

        // Turn cargo OFF via toggle
        await tester.ensureVisible(
          find.byKey(const Key('cargo-toggle-oneway')),
        );
        await tester.tap(find.byKey(const Key('cargo-toggle-oneway')));
        await _pumpUntil(tester, () => !bloc.state.cargo.enabled);
        expect(bloc.state.cargo.enabled, isFalse);
      },
    );

    testWidgets(
      '2. Trip with acceptsShipments == false blocks cargo and lets user disable cargo to proceed',
      (tester) async {
        final server = cargo_core.CargoServer()..accepts = false;

        final bloc = await tester.runAsync(
          () => _prepareOneWayBlocAtStep(
            server: server,
            targetStep: BookingStep.tripSummary,
          ),
        );
        addTearDown(bloc!.close);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocBuilder<BookingFlowBloc, BookingFlowState>(
              bloc: bloc,
              builder: (context, state) => BookingTripSummaryView(
                state: state,
                bloc: bloc,
                onBack: () {},
                onNext: () => bloc.add(const NextStepEvent()),
              ),
            ),
          ),
        );
        await tester.pump();

        // Enable cargo
        bloc.add(const SetBookingCargoEnabledEvent(true));
        await _pumpUntil(tester, () => bloc.state.cargo.options != null);

        expect(
          find.byKey(const Key('cargo-not-accepted-oneway')),
          findsOneWidget,
        );
        expect(find.text('Chuyến xe không nhận gửi hàng.'), findsWidgets);
        expect(bloc.state.canProceed, isFalse);

        // Tap "Bỏ gửi hàng"
        final disableBtn = tester.widget<OutlinedButton>(
          find.byKey(const Key('cargo-disable-btn-oneway')),
        );
        disableBtn.onPressed!();
        await _pumpUntil(tester, () => !bloc.state.cargo.enabled);

        expect(bloc.state.canProceed, isTrue);
      },
    );

    testWidgets(
      '3. Add, edit, delete multiple cargo items (parcel with dimensions & motorcycle 100kg) and validate route points',
      (tester) async {
        BookingCargoState cargoState = BookingCargoState(
          enabled: true,
          options: _sampleCargoOptions(tripId: 101),
          draft: BookingCargoDraft(items: const []),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return SingleChildScrollView(
                    child: BookingCargoSectionCard(
                      cargo: cargoState,
                      locked: false,
                      scopeKey: 'oneway',
                      onToggleEnabled: (enabled) {
                        setState(() {
                          cargoState = BookingCargoState(enabled: enabled);
                        });
                      },
                      onRefresh: () {},
                      onUpdateDraft: (draft) {
                        setState(() {
                          cargoState = BookingCargoState(
                            enabled: true,
                            options: cargoState.options,
                            draft: draft,
                          );
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pump();

        // Select sender point (id: 1010) and same receiver point (id: 1010) -> validation error
        await tester.tap(find.byKey(const Key('cargo-sender-point-oneway')));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('VP Quận 1').last);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('cargo-receiver-point-oneway')));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('VP Quận 1 (Trùng điểm)').last);
        await tester.pumpAndSettle();

        // Now select valid distinct receiver point (id: 1011)
        await tester.tap(find.byKey(const Key('cargo-receiver-point-oneway')));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('BX Liên Tỉnh Đà Lạt').last);
        await tester.pumpAndSettle();

        expect(cargoState.draft?.senderPointId, 1010);
        expect(cargoState.draft?.receiverPointId, 1011);

        // Open item editor to add Item 1 (Parcel with dimensions)
        await tester.tap(find.byKey(const Key('cargo-add-item-btn-oneway')));
        await tester.pump();

        await tester.enterText(
          find.byKey(const Key('cargo-item-name-oneway')),
          'Thùng dâu tây',
        );
        await tester.enterText(
          find.byKey(const Key('cargo-item-quantity-oneway')),
          '2',
        );
        // Enter overweight 45kg -> should show editor error
        await tester.enterText(
          find.byKey(const Key('cargo-item-weight-oneway')),
          '45',
        );
        await tester.ensureVisible(
          find.byKey(const Key('cargo-save-item-btn-oneway')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('cargo-save-item-btn-oneway')));
        await tester.pump();
        expect(
          find.byKey(const Key('cargo-editor-error-oneway')),
          findsOneWidget,
        );

        // Fix weight to 6kg and enter dimensions 60 x 40 x 30 cm (volumetric = 12 kg)
        await tester.enterText(
          find.byKey(const Key('cargo-item-weight-oneway')),
          '6',
        );
        await tester.enterText(
          find.byKey(const Key('cargo-item-length-oneway')),
          '60',
        );
        await tester.enterText(
          find.byKey(const Key('cargo-item-width-oneway')),
          '40',
        );
        await tester.enterText(
          find.byKey(const Key('cargo-item-height-oneway')),
          '30',
        );
        await tester.ensureVisible(
          find.byKey(const Key('cargo-service-fragile-oneway')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('cargo-service-fragile-oneway')));
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(const Key('cargo-save-item-btn-oneway')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('cargo-save-item-btn-oneway')));
        await tester.pumpAndSettle();

        expect(cargoState.draft?.items.length, 1);
        expect(cargoState.draft?.items.first.name, 'Thùng dâu tây');
        expect(cargoState.draft?.items.first.effectiveWeight, 14.4);
        expect(cargoState.isValid, isTrue);

        // Add Item 2 (Motorcycle -> fixed 100kg, vehicleModel + licensePlate)
        await tester.ensureVisible(
          find.byKey(const Key('cargo-add-item-btn-oneway')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('cargo-add-item-btn-oneway')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const Key('cargo-kind-motorcycle-oneway')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('cargo-kind-motorcycle-oneway')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('cargo-item-name-oneway')),
          'Honda Vision',
        );
        await tester.enterText(
          find.byKey(const Key('cargo-item-vehicle-model-oneway')),
          'Vision 2024',
        );
        await tester.enterText(
          find.byKey(const Key('cargo-item-license-plate-oneway')),
          '59X1-123.45',
        );
        await tester.ensureVisible(
          find.byKey(const Key('cargo-save-item-btn-oneway')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('cargo-save-item-btn-oneway')));
        await tester.pumpAndSettle();

        expect(cargoState.draft?.items.length, 2);
        expect(cargoState.draft?.items[1].kind, CargoKind.motorcycle);
        expect(cargoState.draft?.items[1].payloadWeight, 100);
        expect(cargoState.draft?.items[1].vehicleModel, 'Vision 2024');
        expect(cargoState.draft?.items[1].licensePlate, '59X1-123.45');
        expect(cargoState.isValid, isTrue);

        // Edit Item 1 quantity from 2 to 1
        await tester.ensureVisible(
          find.byKey(const Key('cargo-edit-item-oneway-0')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('cargo-edit-item-oneway-0')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('cargo-item-quantity-oneway')),
          '1',
        );
        await tester.ensureVisible(
          find.byKey(const Key('cargo-save-item-btn-oneway')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('cargo-save-item-btn-oneway')));
        await tester.pumpAndSettle();
        expect(cargoState.draft?.items[0].quantity, 1);

        // Delete Item 2
        await tester.ensureVisible(
          find.byKey(const Key('cargo-delete-item-oneway-1')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('cargo-delete-item-oneway-1')));
        await tester.pumpAndSettle();
        expect(cargoState.draft?.items.length, 1);
      },
    );

    testWidgets(
      '4. Pre-order unknown cargo fee still allows valid order creation, then displays server shippingFee, waybill code, and locks cargo',
      (tester) async {
        final server = cargo_core.CargoServer();

        final bloc = await tester.runAsync(
          () => _prepareOneWayBlocAtStep(
            server: server,
            targetStep: BookingStep.payment,
          ),
        );
        addTearDown(bloc!.close);

        await tester.runAsync(() async {
          await bloc.applyDraftAction(const SetBookingCargoEnabledEvent(true));
          await bloc.applyDraftAction(
            UpdateBookingCargoEvent(
              cargo_core.draft(
                101,
                items: [
                  const CargoItemDraft(
                    name: 'Thùng quà Đà Lạt',
                    kind: CargoKind.parcel,
                    categoryId: 3,
                    quantity: 2,
                    weight: 5,
                  ),
                ],
              ),
            ),
          );
        });

        // Before creating order: finalAmount is null, ticketFinalAmount is 190000
        expect(bloc.state.finalAmount, isNull);
        expect(bloc.state.ticketFinalAmount, 190000);
        expect(bloc.state.canSubmitDraft, isTrue);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocBuilder<BookingFlowBloc, BookingFlowState>(
              bloc: bloc,
              builder: (context, state) =>
                  BookingPaymentView(state: state, bloc: bloc, onBack: () {}),
            ),
          ),
        );
        await tester.pump();

        // Pre-order view shows "Xác định khi tạo đơn" and "Phí gửi hàng được xác định khi tạo đơn", never "0 đ"
        expect(find.text('Xác định khi tạo đơn'), findsWidgets);
        expect(
          find.textContaining('Phí gửi hàng được xác định khi tạo đơn'),
          findsWidgets,
        );
        expect(
          find.byKey(const Key('cargo-summary-box-oneway-preorder')),
          findsOneWidget,
        );

        // Tap CTA "Tạo đơn & Thanh toán"
        final createBtn = find.widgetWithText(
          DiscoveryButton,
          'Tạo đơn & Thanh toán',
        );
        expect(createBtn, findsOneWidget);
        await tester.tap(createBtn);
        await _pumpUntil(tester, () => bloc.state.pendingBookingId != null);

        // Verify order created with server shippingFee (50.000 đ) and total (240.000 đ)
        expect(bloc.state.checkoutBooking?.shippingFee, 50000);
        expect(bloc.state.checkoutBooking?.totalAmount, 240000);
        expect(bloc.state.checkoutBooking?.shipment?.code, 'WAYBILL-101');
        expect(bloc.state.isCheckoutLocked, isTrue);

        // Post-order view displays server shipping fee, total amount, and waybill code
        expect(
          find.byKey(const Key('cargo-summary-box-oneway-postorder')),
          findsOneWidget,
        );
        expect(find.text('WAYBILL-101'), findsOneWidget);
        expect(find.textContaining('50.000'), findsWidgets);
        expect(find.textContaining('240.000'), findsWidgets);

        // Mark paid on server and confirm payment -> BookingSuccessScreen
        server.paid.add(101 + 900);
        await tester.runAsync(() => bloc.confirmPayment());
        await tester.pump();
        expect(bloc.state.status, BookingFlowStatus.success);

        await tester.pumpWidget(
          MaterialApp(
            home: BookingSuccessScreen(
              ticket: bloc.state.createdTicket!,
              tickets: bloc.state.createdTickets,
              booking: bloc.state.checkoutBooking,
            ),
          ),
        );
        await tester.pump();

        expect(
          find.byKey(const Key('cargo-summary-box-oneway-success')),
          findsOneWidget,
        );
        expect(find.textContaining('Thùng quà Đà Lạt × 2'), findsOneWidget);
        // The order total includes cargo; a boarding ticket still costs190000.
        expect(find.textContaining('240.000'), findsOneWidget);
      },
    );
  });

  group('Round-Trip Independent Cargo UI', () {
    testWidgets(
      '5. Round-trip supports independent cargo per leg, allows submit when cargo fee is pending, and locks created leg on partial failure',
      (tester) async {
        final server = cargo_core.CargoServer()..reject.add(102);
        final selection = RoundTripSelection(
          request: core.request(),
          outbound: core.trip(101),
          inbound: core.trip(102),
        );

        late RoundTripCheckoutCubit cubit;
        await tester.runAsync(() async {
          cubit = server.checkout();
          await core.ready(cubit);
          await cargo_core.enable(
            cubit,
            TripLeg.outbound,
            101,
            value: cargo_core.draft(
              101,
              items: [
                const CargoItemDraft(
                  name: 'Vali hành lý ký gửi',
                  kind: CargoKind.parcel,
                  categoryId: 3,
                  quantity: 1,
                  weight: 8,
                ),
              ],
            ),
          );
        });
        addTearDown(cubit.close);

        // Outbound has cargo enabled -> cubit.state.totalAmount is null before creation
        expect(cubit.state.outbound.cargo.enabled, isTrue);
        expect(cubit.state.inbound.cargo.enabled, isFalse);
        expect(cubit.state.totalAmount, isNull);

        await tester.pumpWidget(
          MaterialApp(
            home: RoundTripBookingScreen(selection: selection, cubit: cubit),
          ),
        );
        await tester.pump();

        // Confirm button is enabled on RoundTripSummaryStep despite totalAmount == null
        final confirmBtn = tester.widget<ElevatedButton>(
          find.byKey(const ValueKey('confirm-and-pay-btn')),
        );
        expect(confirmBtn.onPressed, isNotNull);
        expect(find.text('Xác định khi tạo đơn'), findsWidgets);

        // Tap confirm -> outbound created (with cargo), inbound fails -> partiallyCreated
        await tester.ensureVisible(
          find.byKey(const ValueKey('confirm-and-pay-btn')),
        );
        await tester.tap(find.byKey(const ValueKey('confirm-and-pay-btn')));
        await _pumpUntil(
          tester,
          () => cubit.state.phase == RoundTripPhase.partiallyCreated,
        );

        expect(cubit.state.outbound.pendingBookingId, 1001);
        expect(cubit.state.outbound.checkoutBooking?.shippingFee, 50000);
        expect(cubit.state.outbound.checkoutBooking?.totalAmount, 240000);
        expect(cubit.state.outbound.isCheckoutLocked, isTrue);
        expect(cubit.state.inbound.pendingBookingId, isNull);

        // Payment view shows outbound cargo waybill code WAYBILL-101
        expect(
          find.byKey(const Key('cargo-summary-box-payment-outbound')),
          findsOneWidget,
        );
        expect(find.text('WAYBILL-101'), findsOneWidget);

        // Fix inbound and retry missing leg
        server.reject.remove(102);
        await tester.runAsync(() => cubit.submit());
        await tester.pump();
        expect(cubit.state.phase, RoundTripPhase.paymentPending);
        expect(cubit.state.inbound.pendingBookingId, 1002);
        expect(cubit.state.inbound.checkoutBooking?.shippingFee, isNull);

        // Mark both paid and verify RoundTripSuccessView shows outbound cargo summary
        server.paid.addAll([1001, 1002]);
        await tester.runAsync(() async {
          await cubit.recheck(TripLeg.outbound);
          await cubit.recheck(TripLeg.inbound);
        });
        await tester.pump();

        expect(cubit.state.isComplete, isTrue);
        expect(find.byType(RoundTripSuccessView), findsOneWidget);
        expect(
          find.byKey(const Key('cargo-summary-box-outbound-success')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('cargo-summary-box-inbound-success')),
          findsNothing,
        );
      },
    );
  });

  group('Responsive & Accessibility Verification (320dp 2x & Landscape Keyboard)', () {
    testWidgets(
      '6. No overflow on 320x640 portrait at 2.0x text scale and 640x360 landscape with keyboard insets',
      (tester) async {
        final server = cargo_core.CargoServer();

        final bloc = await tester.runAsync(
          () => _prepareOneWayBlocAtStep(
            server: server,
            targetStep: BookingStep.tripSummary,
          ),
        );
        addTearDown(bloc!.close);

        await tester.runAsync(() async {
          await bloc.applyDraftAction(const SetBookingCargoEnabledEvent(true));
          await bloc.applyDraftAction(
            UpdateBookingCargoEvent(
              cargo_core.draft(
                101,
                items: [
                  const CargoItemDraft(
                    name: 'Kiện hàng mẫu kiểm thử responsive',
                    kind: CargoKind.bulky,
                    categoryId: 2,
                    quantity: 1,
                    weight: 18,
                    length: 80,
                    width: 50,
                    height: 40,
                  ),
                ],
              ),
            ),
          );
        });

        // 1) 320x640 at 2.0x text scale
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetViewInsets();
        });

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: Scaffold(
              body: Step4PassengerInfo(state: bloc.state, bloc: bloc),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: Scaffold(
              body: Step5TripSummary(state: bloc.state, bloc: bloc),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        // 2) 640x360 landscape with keyboard open
        tester.view.physicalSize = const Size(640, 360);
        tester.view.viewInsets = FakeViewPadding(bottom: 160);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Step6Payment(state: bloc.state, bloc: bloc),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        // 3) Post-order Step 6 at 320x640 with 2.0x text scale and production VexGoJakarta font (F04)
        final font = FontLoader('VexGoJakarta')
          ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
        await font.load();

        await tester.runAsync(() => bloc.confirmPayment());
        tester.view.resetViewInsets();
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: DiscoveryTheme(
              child: Scaffold(
                body: Step6Payment(state: bloc.state, bloc: bloc),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      '7. F01 & F02 regression: editing preserves exact decimal weight/dimensions and rejects non-empty invalid dimensions',
      (tester) async {
        final opts = _sampleCargoOptions();
        var draft = cargo_core.draft(
          101,
          items: [cargo_core.parcel(weight: 19.96)],
        );
        var updateCount = 0;
        late StateSetter rebuild;

        await tester.pumpWidget(
          MaterialApp(
            home: DiscoveryTheme(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      rebuild = setState;
                      return BookingCargoSectionCard(
                        cargo: BookingCargoState(
                          enabled: true,
                          options: opts,
                          draft: draft,
                        ),
                        locked: false,
                        onToggleEnabled: (_) {},
                        onRefresh: () {},
                        onUpdateDraft: (val) {
                          updateCount++;
                          rebuild(() => draft = val);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        // F01: open edit and immediately save -> weight 19.96 and parcel group preserved
        final editBtn = find.byKey(const Key('cargo-edit-item-oneway-0'));
        await tester.ensureVisible(editBtn);
        await tester.tap(editBtn);
        await tester.pump();

        final saveBtn = find.byKey(const Key('cargo-save-item-btn-oneway'));
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pump();

        expect(updateCount, 1);
        expect(draft.items.single.weight, 19.96);
        expect(draft.items.single.group, CargoGroup.parcel);

        // F02: open edit, enter invalid non-empty dimensions ('abc'), attempt save -> blocked
        await tester.ensureVisible(editBtn);
        await tester.tap(editBtn);
        await tester.pump();

        for (final dim in ['length', 'width', 'height']) {
          await tester.enterText(
            find.byKey(Key('cargo-item-$dim-oneway')),
            'abc',
          );
        }
        await tester.pump();
        expect(
          find.byKey(const Key('cargo-dimension-error-oneway')),
          findsOneWidget,
        );

        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pump();

        expect(updateCount, 1);
        expect(
          find.byKey(const Key('cargo-editor-error-oneway')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '8. F03 regression: ticket-only Backend payload with shippingFee=0 and empty cargoItems does not render cargo summary',
      (tester) async {
        final ticketOnlyBooking = BookingModel.fromJson({
          'bookingId': 1001,
          'tripId': 101,
          'totalAmount': 190000,
          'originalTicketSubtotal': 190000,
          'ticketSubtotal': 190000,
          'discountAmount': 0,
          'shippingFee': 0,
          'shipment': null,
          'cargoItems': [],
          'status': 'CHO_THANH_TOAN',
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCargoSummaryBox(booking: ticketOnlyBooking),
            ),
          ),
        );
        expect(find.byKey(const Key('cargo-summary-box-oneway')), findsNothing);

        // Free shipment with actual shipment/cargoItems still renders
        final freeCargoBooking = BookingModel.fromJson({
          'bookingId': 1002,
          'tripId': 101,
          'totalAmount': 190000,
          'originalTicketSubtotal': 190000,
          'ticketSubtotal': 190000,
          'discountAmount': 0,
          'shippingFee': 0,
          'shipment': {
            'shipmentId': 501,
            'shipmentCode': 'VD1002',
            'shippingFee': 0,
            'itemCount': 1,
          },
          'cargoItems': [
            {'name': 'Tài liệu miễn phí', 'quantity': 1},
          ],
          'status': 'CHO_THANH_TOAN',
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingCargoSummaryBox(booking: freeCargoBooking),
            ),
          ),
        );
        expect(
          find.byKey(const Key('cargo-summary-box-oneway')),
          findsOneWidget,
        );
        expect(find.text('VD1002'), findsOneWidget);
      },
    );
  });
}
