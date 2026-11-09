import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/features/user/booking/bloc/luggage_cubit.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_luggage_section_card.dart';
import 'accompanied_luggage_core_test.dart' as fixture;

Future<LuggageCubit> setup(WidgetTester t, {bool load = true}) async {
  final s = fixture.LuggageServer();
  final c = LuggageCubit(tripId: 101, passengerCount: 1, repository: s.luggage);
  addTearDown(c.close);
  if (load) await t.runAsync(c.load);
  return c;
}

Widget host(
  LuggageCubit c, {
  ValueNotifier<bool>? locked,
  GlobalKey? captureKey,
  double textScale = 1,
}) => RepaintBoundary(
  key: captureKey,
  child: MaterialApp(
    theme: ThemeData(
      fontFamily: 'VexGoJakarta',
      colorScheme: ColorScheme.fromSeed(seedColor: DiscoveryColors.primary),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: DiscoveryTheme(
      child: Scaffold(
        body: SingleChildScrollView(
          child: ValueListenableBuilder<bool>(
            valueListenable: locked ?? ValueNotifier(false),
            builder: (_, lock, _) =>
                BookingLuggageSectionCard(cubit: c, locked: lock),
          ),
        ),
      ),
    ),
  ),
);
Future<void> tap(WidgetTester t, String key) async {
  final f = find.byKey(Key(key));
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> capture(WidgetTester t, GlobalKey key, String name) async {
  const dir = String.fromEnvironment('LUGGAGE_REVIEW_IMAGE_DIR');
  if (dir.isEmpty) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final im = await boundary.toImage(pixelRatio: 2);
    final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
    await Directory(dir).create(recursive: true);
    await File('$dir/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    im.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final text = FontLoader('VexGoJakarta')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await text.load();
    await icons.load();
  });
  setUp(() async {
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(accessToken: 'ui-review-owner');
  });
  tearDown(TokenStorage.resetStorageAdapter);
  testWidgets(
    'booking summary hides forms; descriptions open only through info',
    (t) async {
      final c = await setup(t, load: false);
      await t.pumpWidget(host(c));
      await t.pump();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Kiện hành lý'), findsNothing);
      expect(
        find.textContaining('Các lựa chọn được quản lý riêng'),
        findsNothing,
      );
      final button = t.getSize(find.byKey(const Key('luggage-info-oneway')));
      expect(button.width, greaterThanOrEqualTo(48));
      expect(button.height, greaterThanOrEqualTo(48));
      await tap(t, 'luggage-info-oneway');
      expect(find.byType(Dialog), findsOneWidget);
      expect(
        find.textContaining('Các lựa chọn được quản lý riêng'),
        findsOneWidget,
      );
      await t.tap(find.text('Đã hiểu'));
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'separate page preserves saved estimate without changing booking payload',
    (t) async {
      final c = await setup(t);
      c.select(fixture.selected(101, code: 'M', weight: 7));
      final before = c
          .exportForBooking(expectedTripId: 101, expectedPassengerCount: 1)!
          .toJson();
      final key = GlobalKey();
      await t.pumpWidget(host(c, captureKey: key));
      await t.pumpAndSettle();
      expect(find.text('Cước phí dự tính'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await capture(t, key, 'luggage-summary');
      await tap(t, 'luggage-open-btn-oneway');
      expect(find.byKey(const Key('luggage-manager-oneway')), findsOneWidget);
      expect(
        find.byKey(const Key('luggage-carryon-add-btn-oneway')),
        findsNothing,
      );
      await capture(t, key, 'luggage-manager');
      await tap(t, 'luggage-manager-done-oneway');
      expect(
        c
            .exportForBooking(expectedTripId: 101, expectedPassengerCount: 1)!
            .toJson(),
        before,
      );
      expect(find.byKey(const Key('luggage-manager-oneway')), findsNothing);
    },
  );
  testWidgets('back confirms unsaved inputs and keeps completed declarations', (
    t,
  ) async {
    final c = await setup(t);
    c.select(fixture.selected(101));
    await t.pumpWidget(host(c));
    await t.pumpAndSettle();
    await tap(t, 'luggage-open-btn-oneway');
    await tap(t, 'luggage-add-checked-btn-oneway');
    await t.enterText(
      find.byKey(const Key('luggage-checked-name-oneway')),
      'Draft vali',
    );
    await t.pageBack();
    await t.pumpAndSettle();
    expect(find.text('Bỏ phần đang nhập?'), findsOneWidget);
    await t.tap(find.text('Nhập tiếp'));
    await t.pumpAndSettle();
    expect(find.text('Draft vali'), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();
    await t.tap(find.text('Bỏ phần đang nhập').last);
    await t.pumpAndSettle();
    expect(c.state.selection.checked.length, 1);
    expect(find.byKey(const Key('luggage-manager-oneway')), findsNothing);
  });
  testWidgets('manager follows checkout lock changes while mounted', (t) async {
    final c = await setup(t);
    final lock = ValueNotifier(false);
    addTearDown(lock.dispose);
    await t.pumpWidget(host(c, locked: lock));
    await t.pumpAndSettle();
    await tap(t, 'luggage-open-btn-oneway');
    await tap(t, 'luggage-add-checked-btn-oneway');
    lock.value = true;
    await t.pumpAndSettle();
    expect(
      find.byKey(const Key('luggage-checked-save-btn-oneway')),
      findsNothing,
    );
    await tap(t, 'luggage-manager-done-oneway');
    expect(find.byKey(const Key('luggage-manager-oneway')), findsNothing);
  });
  testWidgets('account switch removes prior declarations on open manager', (
    t,
  ) async {
    final c = await setup(t);
    c.select(fixture.selected(101));
    await t.pumpWidget(host(c));
    await t.pumpAndSettle();
    await tap(t, 'luggage-open-btn-oneway');
    await t.runAsync(() => TokenStorage.clearTokens());
    await t.pumpAndSettle();
    expect(c.state.phase, LuggagePhase.revoked);
    expect(
      find.byKey(const Key('luggage-checked-item-oneway-0')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('luggage-add-checked-btn-oneway')),
      findsNothing,
    );
  });
  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    testWidgets(
      'manager remains usable with keyboard and large text at $size',
      (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        t.view.viewInsets = const FakeViewPadding(bottom: 150);
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.view.resetViewInsets);
        final c = await setup(t);
        await t.pumpWidget(host(c, textScale: 2));
        await t.pumpAndSettle();
        await tap(t, 'luggage-open-btn-oneway');
        await tap(t, 'luggage-add-checked-btn-oneway');
        expect(t.takeException(), isNull);
        await tap(t, 'luggage-dimensions-info-oneway');
        expect(find.byType(Dialog), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
}
