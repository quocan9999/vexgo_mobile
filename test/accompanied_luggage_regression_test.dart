import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/luggage_policy.dart';
import 'package:vexgo_app/features/user/booking/bloc/luggage_cubit.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_luggage_section_card.dart';
import 'accompanied_luggage_core_test.dart' as fixture;

Future<LuggageCubit> mount(WidgetTester t, {int passengerCount = 1}) async {
  final s = fixture.LuggageServer();
  final c = LuggageCubit(
    tripId: 101,
    passengerCount: passengerCount,
    repository: s.luggage,
  );
  await c.load();
  await t.pumpWidget(
    MaterialApp(
      home: DiscoveryTheme(
        child: Scaffold(
          body: SingleChildScrollView(
            child: BookingLuggageSectionCard(
              editorMode: true,
              cubit: c,
              locked: false,
              onSyncBookingCargo: (_) async {},
            ),
          ),
        ),
      ),
    ),
  );
  await t.pump();
  await tap(t, 'luggage-carryon-disclosure-oneway');
  await t.pumpAndSettle();
  return c;
}

Future<void> tap(WidgetTester t, String key) async {
  final f = find.byKey(Key(key));
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pump();
}

void main() {
  setUp(() async {
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(accessToken: 'review-owner');
  });
  tearDown(TokenStorage.resetStorageAdapter);
  testWidgets('valid carry-on save closes editor', (t) async {
    final c = await mount(t);
    addTearDown(c.close);
    await tap(t, 'luggage-carryon-add-btn-oneway');
    await t.enterText(
      find.byKey(const Key('luggage-carryon-weight-input-oneway')),
      '4',
    );
    await tap(t, 'luggage-carryon-save-btn-oneway');
    expect(c.state.selection.carryOn.single.weightKg, 4);
    expect(c.validationError, isNull);
    expect(
      find.byKey(const Key('luggage-carryon-save-btn-oneway')),
      findsNothing,
    );
  });
  testWidgets('invalid quantity remains bounded', (t) async {
    final c = await mount(t);
    addTearDown(c.close);
    await tap(t, 'luggage-carryon-add-btn-oneway');
    await t.enterText(
      find.byKey(const Key('luggage-carryon-weight-input-oneway')),
      '4',
    );
    await t.enterText(
      find.byKey(const Key('luggage-carryon-qty-input-oneway')),
      '100',
    );
    await tap(t, 'luggage-carryon-save-btn-oneway');
    expect(c.state.selection.carryOn, isEmpty);
    expect(
      find.byKey(const Key('luggage-carryon-save-btn-oneway')),
      findsOneWidget,
    );
  });
  testWidgets('cancel conversion retains original bag', (t) async {
    final c = await mount(t);
    addTearDown(c.close);
    c.select(LuggageSelection(carryOn: [CarryOnBag(weightKg: 8, quantity: 1)]));
    await t.pump();
    await t.pump();
    await tap(t, 'luggage-carryon-move-checked-oneway-0');
    await tap(t, 'luggage-checked-cancel-btn-oneway');
    expect(c.state.selection.carryOn.length, 1);
  });
  testWidgets('conversion commits atomically and preserves grouped quantity', (
    t,
  ) async {
    final c = await mount(t, passengerCount: 2);
    addTearDown(c.close);
    final original = CarryOnBag(weightKg: 8, quantity: 2);
    c.select(LuggageSelection(carryOn: [original]));
    await t.pump();
    await t.pump();
    await tap(t, 'luggage-carryon-move-checked-oneway-0');
    expect(c.state.selection.carryOn.single, same(original));
    expect(c.state.selection.checked, isEmpty);
    await tap(t, 'luggage-checked-save-btn-oneway');
    expect(c.state.selection.carryOn, isEmpty);
    expect(c.state.selection.checked.single.cargo.quantity, 2);
    expect(c.state.selection.checked.single.cargo.payloadWeight, 8);
  });
  testWidgets('editing an existing bag replaces it without duplication', (
    t,
  ) async {
    final c = await mount(t);
    addTearDown(c.close);
    c.select(LuggageSelection(carryOn: [CarryOnBag(weightKg: 4, quantity: 1)]));
    await t.pump();
    await t.pump();
    await tap(t, 'luggage-carryon-edit-oneway-0');
    await t.enterText(
      find.byKey(const Key('luggage-carryon-weight-input-oneway')),
      '6',
    );
    await tap(t, 'luggage-carryon-save-btn-oneway');
    expect(c.state.selection.carryOn.single.weightKg, 6);
    expect(
      find.byKey(const Key('luggage-carryon-save-btn-oneway')),
      findsNothing,
    );
  });
}
