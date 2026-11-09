import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/booking_cargo_model.dart';
import 'package:vexgo_app/data/models/luggage_policy.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/cargo_repository.dart';
import 'package:vexgo_app/data/repositories/luggage_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/bloc/luggage_cubit.dart';
import 'package:vexgo_app/features/user/booking/presentation/screens/booking_flow_screen.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_luggage_section_card.dart';
import 'package:vexgo_app/features/user/round_trip/presentation/screens/round_trip_booking_screen.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_checkout_cubit.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';

import 'accompanied_luggage_core_test.dart' as lug_core;
import 'booking_cargo_core_test.dart' as cargo_core;
import 'round_trip_core_test.dart' as rt_core;

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

Future<BookingFlowBloc> _prepareOneWayBloc({
  required lug_core.LuggageServer server,
  int seatCount = 1,
  BookingStep targetStep = BookingStep.passengerInfo,
}) async {
  final bloc = BookingFlowBloc(
    seatRepository: server.seats,
    bookingRepository: server.bookings,
    cargoRepository: server.cargo,
    now: () => server.now,
    receivingAccount: cargo_core.bank,
  );
  bloc.add(
    InitBookingFlowEvent(
      trip: rt_core.trip(101),
      date: rt_core.request().departureDate,
      ticketCount: seatCount,
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
  for (var i = 0; i < seatCount; i++) {
    await bloc.applyDraftAction(
      ToggleSeatEvent(bloc.state.seatLayout!.lowerFloor[i]),
    );
  }
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
    await TokenStorage.saveTokens(accessToken: 'accompanied-luggage-ui-owner');
  });

  tearDown(TokenStorage.resetStorageAdapter);

  group('Accompanied Luggage UI - Packages, Carry-On, Error/Stale/Skip', () {
    testWidgets(
      '1. Free carry-on uses dynamic API freeWeightPerPassengerKg (not hardcoded 7kg), rejects overweight or excess bags with clear guidance, and never sends carryOn in cargoItems',
      (tester) async {
        final server = lug_core.LuggageServer()
          ..mutate = (json) => {...json, 'maxFreeWeightKg': 4.5};
        final cubit = LuggageCubit(
          tripId: 101,
          passengerCount: 1,
          repository: server.luggage,
        );
        addTearDown(cubit.close);

        BookingCargoDraft? syncedDraft;
        int syncCalls = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: DiscoveryTheme(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: BookingLuggageSectionCard(
                    editorMode: true,
                    cubit: cubit,
                    locked: false,
                    scopeKey: 'oneway',
                    onSyncBookingCargo: (draft) async {
                      syncCalls++;
                      syncedDraft = draft;
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Initially idle ("Không thêm hành lý ký gửi")
        expect(find.byKey(const Key('luggage-idle-oneway')), findsOneWidget);

        // Open luggage declaration -> loads policy with maxFreeWeightKg = 4.5
        await tester.tap(find.byKey(const Key('luggage-open-btn-oneway')));
        await _pumpUntil(tester, () => cubit.state.phase == LuggagePhase.ready);
        await tester.pump();

        await tester.tap(
          find.byKey(const Key('luggage-carryon-disclosure-oneway')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('luggage-free-allowance-badge-oneway')),
          findsOneWidget,
        );
        expect(find.textContaining('4.5 kg/kiện'), findsWidgets);

        // Open carry-on editor and enter 6 kg (> 4.5 kg limit, even though < 7 kg!)
        await tester.ensureVisible(
          find.byKey(const Key('luggage-carryon-add-btn-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-carryon-add-btn-oneway')),
        );
        await tester.pump();

        await tester.enterText(
          find.byKey(const Key('luggage-carryon-weight-input-oneway')),
          '6',
        );
        await tester.pump();

        // Immediate inline error and "Chuyển sang hành lý ký gửi" button
        expect(
          find.byKey(const Key('luggage-carryon-error-oneway')),
          findsOneWidget,
        );
        expect(find.textContaining('vượt hạn mức miễn phí'), findsWidgets);
        expect(
          find.byKey(const Key('luggage-carryon-convert-btn-oneway')),
          findsOneWidget,
        );

        // Invalid input remains editable; never mutate the saved selection.
        await tester.tap(
          find.byKey(const Key('luggage-carryon-save-btn-oneway')),
        );
        await tester.pump();
        expect(cubit.state.selection.carryOn, isEmpty);
        expect(find.textContaining('vượt hạn mức miễn phí'), findsWidgets);

        await tester.enterText(
          find.byKey(const Key('luggage-carryon-weight-input-oneway')),
          '4',
        );
        await tester.enterText(
          find.byKey(const Key('luggage-carryon-qty-input-oneway')),
          '2',
        );
        await tester.tap(
          find.byKey(const Key('luggage-carryon-save-btn-oneway')),
        );
        await tester.pump();
        expect(cubit.state.selection.carryOn, isEmpty);
        expect(
          find.textContaining('Mỗi hành khách được khai báo tối đa'),
          findsWidgets,
        );

        // Correct the same draft and save one valid bag.
        await tester.enterText(
          find.byKey(const Key('luggage-carryon-weight-input-oneway')),
          '4.5',
        );
        await tester.enterText(
          find.byKey(const Key('luggage-carryon-qty-input-oneway')),
          '1',
        );
        await tester.tap(
          find.byKey(const Key('luggage-carryon-save-btn-oneway')),
        );
        await tester.pump();

        expect(cubit.validationError, isNull);
        expect(cubit.referenceFee, 0);
        expect(
          cubit.exportForBooking(
            expectedTripId: 101,
            expectedPassengerCount: 1,
          ),
          isNull,
        );
        expect(syncCalls, greaterThan(0));
        expect(syncedDraft, isNull);
      },
    );

    testWidgets(
      '2. Select, change, and delete S/M/L/XL packages and special vehicles; immediate validation on overweight/oversize without auto-switching packages',
      (tester) async {
        final server = lug_core.LuggageServer();
        final cubit = LuggageCubit(
          tripId: 101,
          passengerCount: 2,
          repository: server.luggage,
        );
        addTearDown(cubit.close);

        BookingCargoDraft? syncedDraft;

        await tester.pumpWidget(
          MaterialApp(
            home: DiscoveryTheme(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: BookingLuggageSectionCard(
                    editorMode: true,
                    cubit: cubit,
                    locked: false,
                    scopeKey: 'oneway',
                    onSyncBookingCargo: (draft) async {
                      syncedDraft = draft;
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('luggage-open-btn-oneway')));
        await _pumpUntil(tester, () => cubit.state.phase == LuggagePhase.ready);
        await tester.pump();

        // Select distinct sender (1010) and receiver (1011) points from options.cargo.points
        await tester.ensureVisible(
          find.byKey(const Key('luggage-sender-point-oneway')),
        );
        await tester.tap(find.byKey(const Key('luggage-sender-point-oneway')));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Sender').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('luggage-receiver-point-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-receiver-point-oneway')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Receiver').last);
        await tester.pumpAndSettle();

        // Open package item editor (default package S: max 5kg, 40x25x25cm)
        await tester.ensureVisible(
          find.byKey(const Key('luggage-add-checked-btn-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-add-checked-btn-oneway')),
        );
        await tester.pump();

        await tester.enterText(
          find.byKey(const Key('luggage-checked-name-oneway')),
          'Vali du lịch',
        );
        // Enter 8 kg while package S is selected -> immediate validation error, never auto-switches from S
        await tester.enterText(
          find.byKey(const Key('luggage-checked-weight-oneway')),
          '8',
        );
        await tester.pump();

        expect(
          find.byKey(const Key('luggage-checked-editor-error-oneway')),
          findsOneWidget,
        );
        expect(
          find.text('Khối lượng hiệu dụng vượt hạn mức gói đã chọn.'),
          findsOneWidget,
        );

        // Switch to package M (max 10kg, 50x40x25cm, 80.000đ) -> weight 8kg is valid, now test oversize length 55cm
        await tester.ensureVisible(
          find.byKey(const Key('luggage-pack-chip-M-oneway')),
        );
        await tester.tap(find.byKey(const Key('luggage-pack-chip-M-oneway')));
        await tester.pump();
        expect(
          find.byKey(const Key('luggage-checked-editor-error-oneway')),
          findsNothing,
        );

        await tester.ensureVisible(
          find.byKey(const Key('luggage-dimensions-disclosure-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-dimensions-disclosure-oneway')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('luggage-checked-length-oneway')),
          '55',
        );
        await tester.enterText(
          find.byKey(const Key('luggage-checked-width-oneway')),
          '30',
        );
        await tester.enterText(
          find.byKey(const Key('luggage-checked-height-oneway')),
          '20',
        );
        await tester.pump();
        expect(
          find.text('Kích thước kiện vượt hạn mức gói đã chọn.'),
          findsOneWidget,
        );

        // Fix length to 45cm, select fragile service (+20.000đ), and save
        await tester.enterText(
          find.byKey(const Key('luggage-checked-length-oneway')),
          '45',
        );
        await tester.ensureVisible(
          find.byKey(const Key('luggage-options-disclosure-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-options-disclosure-oneway')),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const Key('luggage-checked-service-fragile-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-checked-service-fragile-oneway')),
        );
        await tester.pump();

        await tester.ensureVisible(
          find.byKey(const Key('luggage-checked-save-btn-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-checked-save-btn-oneway')),
        );
        await tester.pump();

        expect(cubit.state.selection.checked.length, 1);
        expect(cubit.state.selection.checked.first.packageCode, 'M');
        // Reference fee: M (80.000) + fragile (20.000) = 100.000
        expect(cubit.referenceFee, 100000);
        expect(syncedDraft, isNotNull);
        expect(syncedDraft!.items.length, 1);

        // Editing opens the same package picker; invalid edits do not replace saved data.
        await tester.ensureVisible(
          find.byKey(const Key('luggage-checked-edit-oneway-0')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-checked-edit-oneway-0')),
        );
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(const Key('luggage-pack-chip-S-oneway')),
        );
        await tester.tap(find.byKey(const Key('luggage-pack-chip-S-oneway')));
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(const Key('luggage-checked-save-btn-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-checked-save-btn-oneway')),
        );
        await tester.pump();
        expect(cubit.state.selection.checked.first.packageCode, 'M');
        expect(cubit.state.selection.checked.first.cargo.weight, 8);
        expect(
          find.byKey(const Key('luggage-checked-editor-error-oneway')),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.byKey(const Key('luggage-pack-chip-L-oneway')),
        );
        await tester.tap(find.byKey(const Key('luggage-pack-chip-L-oneway')));
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(const Key('luggage-checked-save-btn-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-checked-save-btn-oneway')),
        );
        await tester.pump();
        expect(cubit.validationError, isNull);
        expect(cubit.referenceFee, 140000);

        // Add Special Vehicle (Motorcycle Scooter: 220.000đ)
        await tester.ensureVisible(
          find.byKey(const Key('luggage-add-vehicle-btn-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-add-vehicle-btn-oneway')),
        );
        await tester.pump();

        await tester.ensureVisible(
          find.byKey(const Key('luggage-vehicle-kind-motorcycle-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-vehicle-kind-motorcycle-oneway')),
        );
        await tester.pump();

        await tester.ensureVisible(
          find.byKey(const Key('luggage-motorcycle-tariff-scooter-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-motorcycle-tariff-scooter-oneway')),
        );
        await tester.pump();

        await tester.enterText(
          find.byKey(const Key('luggage-checked-name-oneway')),
          'Honda Lead',
        );
        await tester.enterText(
          find.byKey(const Key('luggage-vehicle-model-oneway')),
          'Lead 125',
        );
        await tester.enterText(
          find.byKey(const Key('luggage-license-plate-oneway')),
          '59G2-888.99',
        );
        await tester.ensureVisible(
          find.byKey(const Key('luggage-checked-save-btn-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-checked-save-btn-oneway')),
        );
        await tester.pump();

        expect(cubit.state.selection.checked.length, 2);
        expect(cubit.validationError, isNull);
        // 140.000 + 220.000 = 360.000 reference fee
        expect(cubit.referenceFee, 360000);

        // Delete first item -> only motorcycle remains (220.000)
        await tester.ensureVisible(
          find.byKey(const Key('luggage-checked-delete-oneway-0')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-checked-delete-oneway-0')),
        );
        await tester.pump();
        expect(cubit.state.selection.checked.length, 1);
        expect(cubit.referenceFee, 220000);
      },
    );

    testWidgets(
      '3. Policy load error, stale policy (> 5 min), and Retry vs Skip ("Không thêm hành lý ký gửi") without auto-dropping selected items on API error',
      (tester) async {
        var now = DateTime.utc(2026, 11, 6, 9, 0);
        final server = lug_core.LuggageServer()..missingPolicy = true;
        final cubit = LuggageCubit(
          tripId: 101,
          passengerCount: 1,
          repository: server.luggage,
          now: () => now,
        );
        addTearDown(cubit.close);

        await tester.pumpWidget(
          MaterialApp(
            home: DiscoveryTheme(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: BookingLuggageSectionCard(
                    editorMode: true,
                    cubit: cubit,
                    locked: false,
                    scopeKey: 'oneway',
                  ),
                ),
              ),
            ),
          ),
        );

        // Attempt to open luggage while API fails
        await tester.tap(find.byKey(const Key('luggage-open-btn-oneway')));
        await _pumpUntil(
          tester,
          () => cubit.state.phase == LuggagePhase.failure,
        );
        await tester.pump();

        expect(find.byKey(const Key('luggage-error-oneway')), findsOneWidget);
        expect(
          find.byKey(const Key('luggage-retry-btn-oneway')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('luggage-skip-btn-oneway')),
          findsOneWidget,
        );

        // Fix server and tap Retry
        server.missingPolicy = false;
        await tester.tap(find.byKey(const Key('luggage-retry-btn-oneway')));
        await _pumpUntil(tester, () => cubit.state.phase == LuggagePhase.ready);
        await tester.pump();

        // Select an item on cubit
        cubit.select(lug_core.selected(101, code: 'S', weight: 4));
        await tester.pump();
        expect(cubit.state.selection.checked.length, 1);
        expect(cubit.validationError, isNull);

        // Advance clock by 6 minutes -> stale policy banner (> 5 minutes)
        now = now.add(const Duration(minutes: 6));
        await tester.pumpWidget(
          MaterialApp(
            home: DiscoveryTheme(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: BookingLuggageSectionCard(
                    editorMode: true,
                    cubit: cubit,
                    locked: false,
                    scopeKey: 'oneway',
                  ),
                ),
              ),
            ),
          ),
        );
        expect(
          find.byKey(const Key('luggage-stale-banner-oneway')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('luggage-reload-policy-btn-oneway')),
          findsOneWidget,
        );

        // Make server fail on reload -> existing checked item is NOT auto-dropped!
        server.missingPolicy = true;
        await tester.tap(
          find.byKey(const Key('luggage-reload-policy-btn-oneway')),
        );
        await _pumpUntil(
          tester,
          () => cubit.state.phase == LuggagePhase.failure,
        );
        await tester.pump();

        expect(cubit.state.selection.checked.length, 1);
        expect(
          find.byKey(const Key('luggage-preserved-items-notice-oneway')),
          findsOneWidget,
        );

        // User explicitly chooses "Không thêm hành lý ký gửi" -> returns to idle and clears selection
        await tester.tap(find.byKey(const Key('luggage-skip-btn-oneway')));
        await tester.pump();
        expect(cubit.state.phase, LuggagePhase.idle);
        expect(cubit.state.selection.checked, isEmpty);
      },
    );
  });

  group('One-Way & Round-Trip Lifecycle, Seat Changes, Locked State, and Pricing', () {
    testWidgets(
      '4. One-way BookingFlowScreen preserves luggage draft across Step 4 -> Step 5 -> Back, resets with notice when seat count changes, and reconciles server shippingFee on POST',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final server = lug_core.LuggageServer();
        final bloc = await tester.runAsync(
          () => _prepareOneWayBloc(
            server: server,
            seatCount: 1,
            targetStep: BookingStep.passengerInfo,
          ),
        );
        addTearDown(bloc!.close);

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<SeatRepository>.value(value: server.seats),
              RepositoryProvider<BookingRepository>.value(
                value: server.bookings,
              ),
              RepositoryProvider<CargoRepository>.value(value: server.cargo),
              RepositoryProvider<LuggageRepository>.value(
                value: server.luggage,
              ),
            ],
            child: MaterialApp(
              home: BookingFlowScreen(
                trip: rt_core.trip(101),
                date: rt_core.request().departureDate,
                bloc: bloc,
                luggageRepository: server.luggage,
                now: () => server.now,
              ),
            ),
          ),
        );
        await tester.pump();

        // In Step 4: open accompanied luggage
        await tester.ensureVisible(
          find.byKey(const Key('luggage-open-btn-oneway')),
        );
        await tester.tap(find.byKey(const Key('luggage-open-btn-oneway')));
        await _pumpUntil(
          tester,
          () => find
              .byKey(const Key('luggage-carryon-disclosure-oneway'))
              .evaluate()
              .isNotEmpty,
        );

        // Select sender (1010) and receiver (1011)
        await tester.ensureVisible(
          find.byKey(const Key('luggage-sender-point-oneway')),
        );
        await tester.tap(find.byKey(const Key('luggage-sender-point-oneway')));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Sender').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('luggage-receiver-point-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-receiver-point-oneway')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Receiver').last);
        await tester.pumpAndSettle();

        // Add checked item in Package M (80.000đ reference fee)
        await tester.ensureVisible(
          find.byKey(const Key('luggage-add-checked-btn-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-add-checked-btn-oneway')),
        );
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(const Key('luggage-pack-chip-M-oneway')),
        );
        await tester.tap(find.byKey(const Key('luggage-pack-chip-M-oneway')));
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('luggage-checked-name-oneway')),
          'Thùng đặc sản',
        );
        await tester.enterText(
          find.byKey(const Key('luggage-checked-weight-oneway')),
          '7',
        );
        await tester.ensureVisible(
          find.byKey(const Key('luggage-checked-save-btn-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-checked-save-btn-oneway')),
        );
        await _pumpUntil(
          tester,
          () => bloc.state.cargo.enabled && bloc.state.cargo.isValid,
        );

        await tester.tap(find.byKey(const Key('luggage-manager-done-oneway')));
        await tester.pumpAndSettle();

        // Move Step 4 -> Step 5 (Trip Summary)
        final nextBtnStep4 = find.widgetWithText(DiscoveryButton, 'Tiếp tục');
        await tester.tap(nextBtnStep4);
        await _pumpUntil(
          tester,
          () =>
              bloc.state.step == BookingStep.tripSummary &&
              bloc.state.hasUsableQuote &&
              !bloc.state.cargo.loading &&
              !bloc.state.quoteLoading,
        );
        await tester.pump();

        // Verify Step 5 preserves the exact same luggage item AND displays reference fee 80.000đ as estimate
        expect(find.textContaining('Thùng đặc sản × 1'), findsOneWidget);
        expect(find.textContaining('Cước phí dự tính'), findsWidgets);
        expect(find.textContaining('80.000'), findsWidgets);

        // Go Back Step 5 -> Step 4: verify draft is still preserved
        final backBtnStep5 = find.byTooltip('Quay lại');
        await tester.tap(backBtnStep5);
        await _pumpUntil(
          tester,
          () => bloc.state.step == BookingStep.passengerInfo,
        );
        await tester.pump();
        expect(bloc.state.step, BookingStep.passengerInfo);
        expect(find.textContaining('Thùng đặc sản × 1'), findsOneWidget);

        // Now simulate changing selected seat count (1 -> 2 seats)
        await tester.runAsync(() async {
          await bloc.applyDraftAction(
            ToggleSeatEvent(bloc.state.seatLayout!.lowerFloor[1]),
          );
        });
        await tester.pump();

        // Notice is displayed that seat count changed (1 -> 2 hành khách) and old cargo is reset for re-verification
        expect(
          find.byKey(const Key('luggage-seat-change-notice-oneway')),
          findsOneWidget,
        );
        expect(
          find.textContaining('Số ghế đã thay đổi (1 → 2 hành khách)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '5. Round-trip owns two independent LuggageCubits (outbound & inbound), preserves drafts across steps, and locks when order is created',
      (tester) async {
        final server = lug_core.LuggageServer();
        final selection = RoundTripSelection(
          request: rt_core.request(),
          outbound: rt_core.trip(101),
          inbound: rt_core.trip(102),
        );

        late RoundTripCheckoutCubit checkoutCubit;
        await tester.runAsync(() async {
          checkoutCubit = server.checkout();
          await rt_core.ready(checkoutCubit);
          // Move both legs back to passengerInfo to test Step 4 -> Step 5 -> Back
          checkoutCubit.dispatch(
            TripLeg.outbound,
            GoToStepEvent(BookingStep.passengerInfo.index),
          );
          checkoutCubit.dispatch(
            TripLeg.inbound,
            GoToStepEvent(BookingStep.passengerInfo.index),
          );
          while (checkoutCubit.state.busy) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });
        addTearDown(checkoutCubit.close);

        await tester.pumpWidget(
          MaterialApp(
            home: RoundTripBookingScreen(
              selection: selection,
              cubit: checkoutCubit,
              luggageRepository: server.luggage,
              now: () => server.now,
            ),
          ),
        );
        await tester.pump();

        // Both outbound and inbound luggage cards are present
        expect(
          find.byKey(const Key('luggage-section-card-outbound')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('luggage-section-card-inbound')),
          findsOneWidget,
        );

        // Open outbound luggage only, leaving inbound idle
        await tester.ensureVisible(
          find.byKey(const Key('luggage-open-btn-outbound')),
        );
        await tester.tap(find.byKey(const Key('luggage-open-btn-outbound')));
        await _pumpUntil(
          tester,
          () => find
              .byKey(const Key('luggage-carryon-disclosure-outbound'))
              .evaluate()
              .isNotEmpty,
        );

        // Inbound is still in idle state
        expect(checkoutCubit.state.inbound.cargo.enabled, isFalse);

        await tester.tap(
          find.byKey(const Key('luggage-carryon-disclosure-outbound')),
        );
        await tester.pumpAndSettle();

        // Add a free carry-on bag to outbound
        await tester.ensureVisible(
          find.byKey(const Key('luggage-carryon-add-btn-outbound')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-carryon-add-btn-outbound')),
        );
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('luggage-carryon-weight-input-outbound')),
          '5',
        );
        await tester.tap(
          find.byKey(const Key('luggage-carryon-save-btn-outbound')),
        );
        await tester.pump();

        expect(
          find.byKey(const Key('luggage-carryon-item-outbound-0')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('luggage-manager-done-outbound')),
        );
        await tester.pumpAndSettle();

        // Proceed from RoundTripPassengerStep -> RoundTripSummaryStep
        await tester.ensureVisible(
          find.byKey(const ValueKey('passenger-continue-btn')),
        );
        await tester.tap(find.byKey(const ValueKey('passenger-continue-btn')));
        await _pumpUntil(
          tester,
          () =>
              checkoutCubit.state.outbound.step == BookingStep.tripSummary &&
              checkoutCubit.state.inbound.step == BookingStep.tripSummary,
        );
        await tester.pump();

        // The compact summary preserves outbound carry-on without expanding forms.
        expect(
          find.textContaining('Xách tay · 1 kiện · 5 kg/kiện'),
          findsOneWidget,
        );
        expect(checkoutCubit.state.inbound.cargo.enabled, isFalse);
      },
    );

    testWidgets(
      '6. Locked mode disables all edits/buttons, and responsive 320dp at 2.0x text scale + 640x360 landscape with keyboard open has 0 overflow',
      (tester) async {
        final server = lug_core.LuggageServer();
        final cubit = LuggageCubit(
          tripId: 101,
          passengerCount: 1,
          repository: server.luggage,
        );
        addTearDown(cubit.close);
        await tester.runAsync(() => cubit.load());
        cubit.select(
          LuggageSelection(
            carryOn: const [CarryOnBag(weightKg: 4, quantity: 1)],
            checked: lug_core.selected(101, code: 'L', weight: 15).checked,
            senderPointId: 1010,
            receiverPointId: 1011,
          ),
        );

        // 1) Locked state verification
        await tester.pumpWidget(
          MaterialApp(
            home: DiscoveryTheme(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: BookingLuggageSectionCard(
                    editorMode: true,
                    cubit: cubit,
                    locked: true,
                    scopeKey: 'oneway',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.byKey(const Key('luggage-locked-banner-oneway')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('luggage-carryon-add-btn-oneway')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('luggage-add-checked-btn-oneway')),
          findsNothing,
        );
        expect(find.byKey(const Key('luggage-skip-btn-oneway')), findsNothing);

        // 2) 320x640 portrait at 2.0x text scale (unlocked with open editors)
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
            home: DiscoveryTheme(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: BookingLuggageSectionCard(
                    editorMode: true,
                    cubit: cubit,
                    locked: false,
                    scopeKey: 'oneway',
                    seatChangeNotice:
                        'Số ghế đã thay đổi. Vui lòng kiểm tra lại hành lý.',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        // Open checked item editor at 320dp 2.0x text scale
        await tester.ensureVisible(
          find.byKey(const Key('luggage-add-checked-btn-oneway')),
        );
        await tester.tap(
          find.byKey(const Key('luggage-add-checked-btn-oneway')),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        // 3) 640x360 landscape with keyboard open
        tester.view.physicalSize = const Size(640, 360);
        tester.view.viewInsets = FakeViewPadding(bottom: 160);
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '7. Trip with acceptsShipments == false blocks checked luggage while allowing carry-on, and POST /bookings reconciles server shippingFee without sending referenceFee',
      (tester) async {
        // Part A: acceptsShipments == false
        final noShipServer = lug_core.LuggageServer()..accepts = false;
        final noShipCubit = LuggageCubit(
          tripId: 101,
          passengerCount: 1,
          repository: noShipServer.luggage,
        );
        addTearDown(noShipCubit.close);
        await tester.runAsync(() => noShipCubit.load());

        await tester.pumpWidget(
          MaterialApp(
            home: DiscoveryTheme(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: BookingLuggageSectionCard(
                    editorMode: true,
                    cubit: noShipCubit,
                    locked: false,
                    scopeKey: 'oneway',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.byKey(const Key('luggage-checked-not-accepted-oneway')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const Key('luggage-carryon-disclosure-oneway')),
        );
        await tester.pumpAndSettle();
        // Carry-on is still allowed even when acceptsShipments == false
        expect(
          find.byKey(const Key('luggage-carryon-add-btn-oneway')),
          findsOneWidget,
        );
        // Checked luggage add button is hidden when acceptsShipments == false
        expect(
          find.byKey(const Key('luggage-add-checked-btn-oneway')),
          findsNothing,
        );

        // Part B: POST /bookings reconciliation (referenceFee = 80.000đ vs server shippingFee = 50.000đ)
        final server = lug_core.LuggageServer();
        final bloc = await tester.runAsync(
          () => _prepareOneWayBloc(
            server: server,
            seatCount: 1,
            targetStep: BookingStep.tripSummary,
          ),
        );
        addTearDown(bloc!.close);

        final cubit = LuggageCubit(
          tripId: 101,
          passengerCount: 1,
          repository: server.luggage,
          now: () => server.now,
        );
        addTearDown(cubit.close);
        await tester.runAsync(() => cubit.load());
        cubit.select(lug_core.selected(101, code: 'M', weight: 7));
        expect(cubit.referenceFee, 80000);

        final draft = cubit.exportForBooking(
          expectedTripId: 101,
          expectedPassengerCount: 1,
        );
        expect(draft, isNotNull);
        expect(draft!.toJson().containsKey('referenceFee'), isFalse);

        await tester.runAsync(() async {
          await bloc.applyDraftAction(
            SetBookingCargoEnabledEvent(true, initialDraft: draft),
          );
          await bloc.applyDraftAction(const NextStepEvent());
          await bloc.confirmPayment();
        });

        // POST body never contains referenceFee, and server returns shippingFee = 50.000đ (not 80.000đ referenceFee)
        expect(server.posts.single.containsKey('referenceFee'), isFalse);
        expect(bloc.state.checkoutBooking?.shippingFee, 50000);
        expect(bloc.state.pendingPaymentAmount, 190000);
        expect(bloc.state.finalAmount, 190000);
      },
    );
  });
}
