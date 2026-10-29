import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_checkout_cubit.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';
import 'package:vexgo_app/features/user/round_trip/presentation/screens/round_trip_booking_screen.dart';
import 'package:vexgo_app/features/user/round_trip/presentation/widgets/round_trip_passenger_step.dart';
import 'round_trip_core_test.dart' as core;
import 'round_trip_ui_comprehensive_test.dart' as ui;

void main() {
  setUpAll(() async {
    final bytes = await File('assets/fonts/PlusJakartaSans.ttf').readAsBytes();
    await (FontLoader(
      'VexGoJakarta',
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  });
  setUp(() async {
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(accessToken: 'fixture-owner');
  });
  tearDown(TokenStorage.resetStorageAdapter);

  testWidgets(
    'partial create locks shared identity while return seats remain editable',
    (tester) async {
      final server = core.Server()..reject.add(102);
      late RoundTripCheckoutCubit cubit;
      await tester.runAsync(() async {
        cubit = server.checkout();
        await core.ready(cubit);
        await cubit.submit();
      });
      addTearDown(cubit.close);
      await tester.pumpWidget(
        ui.buildTestApp(
          child: RoundTripBookingScreen(
            selection: RoundTripSelection(
              request: core.request(),
              outbound: core.trip(101),
              inbound: core.trip(102),
            ),
            cubit: cubit,
          ),
        ),
      );
      await ui.pumpBounded(tester);
      final edit = find.byKey(const ValueKey('edit-missing-inbound-btn'));
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await ui.pumpBounded(tester);
      expect(cubit.state.inbound.step, BookingStep.seatSelection);

      // Actual seat UI remains usable after the identity is locked by the first order.
      await tester.ensureVisible(find.text('A02').last);
      await tester.tap(find.text('A02').last);
      await ui.pumpUntil(
        tester,
        () =>
            !cubit.state.busy && cubit.state.inbound.selectedSeats.length == 2,
      );
      expect(cubit.state.inbound.selectedSeats.map((s) => s.name), [
        'A01',
        'A02',
      ]);
      for (var i = 0; i < 3; i++) {
        final next = find.byKey(const ValueKey('round-trip-step-next-btn'));
        await tester.ensureVisible(next);
        await tester.tap(next);
        await ui.pumpUntil(
          tester,
          () => !cubit.state.busy && cubit.state.inbound.step.index == i + 1,
        );
        expect(cubit.state.inbound.step.index, i + 1);
      }

      expect(find.byType(RoundTripPassengerStep), findsOneWidget);
      for (final key in ['name', 'phone', 'email', 'note']) {
        final field = tester.widget<TextField>(
          find.byKey(ValueKey('passenger-$key-field')),
        );
        expect(
          field.readOnly,
          isTrue,
          reason: '$key must show the committed contact',
        );
        expect(field.onChanged, isNull);
      }
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('passenger-name-field')),
            )
            .controller!
            .text,
        'Fixture User',
      );
      expect(
        find.textContaining('Thông tin hành khách được giữ theo đơn đã tạo'),
        findsOneWidget,
      );
      final next = find.byKey(const ValueKey('passenger-continue-btn'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      await ui.pumpUntil(
        tester,
        () =>
            !cubit.state.busy &&
            cubit.state.inbound.step == BookingStep.tripSummary,
      );
      server.reject.clear();
      final pay = find.byKey(const ValueKey('confirm-and-pay-btn'));
      await tester.ensureVisible(pay);
      await tester.tap(pay);
      await ui.pumpUntil(
        tester,
        () => cubit.state.inbound.pendingBookingId != null && !cubit.state.busy,
      );
      expect(cubit.state.hasBothOrders, isTrue);
      expect(server.posts.map((p) => p['tripId']), [101, 102, 102]);
      expect(server.posts.last['contact'], server.posts.first['contact']);
      expect(server.posts.last['seatIds'], [1021, 1022]);
    },
  );

  testWidgets(
    'switching an editable passenger form to locked restores authoritative fields',
    (tester) async {
      final updates = <UpdatePassengerInfoEvent>[];
      Widget form(bool locked) => ui.buildTestApp(
        child: Scaffold(
          body: RoundTripPassengerStep(
            initialName: 'Fixture User',
            initialPhone: '0901234567',
            initialEmail: 'fixture@example.com',
            initialNote: 'Original note',
            isValid: true,
            busy: false,
            readOnly: locked,
            onUpdate: updates.add,
            onNext: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpWidget(form(false));
      for (final entry in {
        'name': 'Unaccepted User',
        'phone': '0909999999',
        'email': 'unaccepted@example.com',
        'note': 'Unsaved note',
      }.entries) {
        final field = find.byKey(ValueKey('passenger-${entry.key}-field'));
        await tester.ensureVisible(field);
        await tester.enterText(field, entry.value);
      }
      expect(updates.last.name, 'Unaccepted User');
      await tester.pumpWidget(form(true));
      await ui.pumpBounded(tester);
      for (final entry in {
        'name': 'Fixture User',
        'phone': '0901234567',
        'email': 'fixture@example.com',
        'note': 'Original note',
      }.entries) {
        final field = tester.widget<TextField>(
          find.byKey(ValueKey('passenger-${entry.key}-field')),
        );
        expect(field.readOnly, isTrue);
        expect(field.controller!.text, entry.value);
        expect(field.onChanged, isNull);
      }
    },
  );
}
