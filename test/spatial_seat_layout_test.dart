import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/data/models/seat_layout_resolver.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/seat_legend.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/seat_map_view.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/seat_vector.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/spatial_seat_map.dart';

SeatModel apiSeat(
  int id,
  String name, {
  int floor = 1,
  num? x,
  num? y,
  String status = 'TRONG',
  int price = 260000,
}) => SeatModel.fromJson({
  'tripSeatId': id,
  'seatNumber': name,
  'floor': floor,
  'x': x,
  'y': y,
  'status': status,
  'price': price,
});

Future<void> mount(
  WidgetTester tester,
  List<SeatModel> seats, {
  Size size = const Size(390, 844),
  double scale = 1,
  int floor = 1,
  List<SeatModel> selected = const [],
  ValueChanged<SeatModel>? onTap,
  ValueChanged<int>? onFloor,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: RepaintBoundary(
            key: const ValueKey('seat-map-render'),
            child: SeatMapView(
              layout: resolveSeatLayout(
                vehicleType: 'Cùng loại xe',
                seats: seats,
              ),
              selectedFloor: floor,
              selectedSeats: selected,
              onFloorChanged: onFloor ?? (_) {},
              onSeatToggled: onTap ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder seat(int id) => find.byKey(ValueKey('seat-$id'));

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_SEAT_COORDINATE_SCREENSHOTS')) {
      return;
    }
    for (final font in [
      ('VexGoJakarta', 'assets/fonts/PlusJakartaSans.ttf'),
      (
        'MaterialIcons',
        'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
      ),
    ]) {
      final loader = FontLoader(font.$1)
        ..addFont(
          Future.value(ByteData.sublistView(File(font.$2).readAsBytesSync())),
        );
      await loader.load();
    }
  });
  test(
    'Customer API floor and exact coordinates survive copy and roundtrip',
    () {
      final model = apiSeat(
        910,
        'B01',
        floor: 1,
        x: 820,
        y: 3500,
        status: 'DANG_GIU',
      );
      expect(model.id, '910');
      expect(model.floor, 1); // B prefix must not override authoritative floor.
      expect((model.x, model.y), (820, 3500));
      expect(model.status, SeatStatus.held);
      expect(model.copyWith(price: 270000).x, 820);
      expect(SeatModel.fromJson(model.toJson()), model);
      expect(model.copyWith(x: 180), isNot(model));
    },
  );

  test(
    'one/two floor geometry is independent of vehicle type and seat codes',
    () {
      final first = resolveSeatLayout(
        vehicleType: 'Giường nằm',
        seats: [
          apiSeat(1, 'Z9', x: 820, y: 1000),
          apiSeat(2, 'A1', x: 180, y: 1000),
        ],
      );
      final second = resolveSeatLayout(
        vehicleType: 'Giường nằm',
        seats: [
          apiSeat(1, 'Z9', floor: 2, x: 500, y: 2500),
          apiSeat(2, 'A1', x: 110, y: 1000),
        ],
      );
      expect(first.hasTwoFloors, isFalse);
      expect(second.hasTwoFloors, isTrue);
      expect(first.lowerFloor.singleWhere((s) => s.id == '1').x, 820);
      expect(second.upperFloor.single.x, 500);
      expect(second.upperFloor.single.y, 2500);
    },
  );

  test(
    'mixed null coordinates use Web fallback without moving configured seats',
    () {
      final real = apiSeat(1, 'A1', x: 180, y: 1000, status: 'DA_DAT');
      final missing = apiSeat(2, 'A2');
      final partial = apiSeat(3, 'A3', x: 180);
      final layout = resolveSeatLayout(
        vehicleType: 'Any',
        seats: [partial, real, missing],
      );
      final byId = {for (final s in layout.lowerFloor) s.id: s};
      expect(byId['1'], real);
      expect((byId['2']!.x, byId['2']!.y), (360, 1000));
      expect((byId['3']!.x, byId['3']!.y), (640, 1000));
      expect(byId.values.map((s) => (s.x, s.y)).toSet(), hasLength(3));
      expect(missing.x, isNull); // No mutation or persistence of fallback.
      expect(partial.y, isNull);
      expect(byId['1']!.status, SeatStatus.booked);
    },
  );

  test(
    'null-coordinate two-floor legacy inventory matches Web fallback on each floor',
    () {
      final layout = resolveSeatLayout(
        vehicleType: 'Ghế ngồi',
        seats: [
          for (var i = 1; i <= 5; i++) apiSeat(i, 'A$i'),
          apiSeat(6, 'A6', floor: 2),
        ],
      );
      expect(layout.lowerFloor.map((s) => (s.x, s.y)), [
        (160, 1000),
        (360, 1000),
        (640, 1000),
        (840, 1000),
        (160, 2000),
      ]);
      expect(
        (layout.upperFloor.single.x, layout.upperFloor.single.y),
        (160, 1000),
      );
      expect(layout.upperFloor.single.floor, 2);
    },
  );

  testWidgets(
    'coordinate map preserves alignment and unequal gaps, not name sorting',
    (tester) async {
      await mount(tester, [
        apiSeat(1, 'Z9', x: 110, y: 1000),
        apiSeat(2, 'A1', x: 310, y: 1000),
        apiSeat(3, 'A2', x: 890, y: 1000),
        apiSeat(4, 'D1', x: 110, y: 3000),
      ]);
      final a = tester.getCenter(seat(1));
      final b = tester.getCenter(seat(2));
      final c = tester.getCenter(seat(3));
      final d = tester.getCenter(seat(4));
      expect(a.dy, b.dy);
      expect(b.dy, c.dy);
      expect(a.dx, d.dx);
      expect((c.dx - b.dx) / (b.dx - a.dx), closeTo(580 / 200, .001));
      expect(find.text('Tầng trên'), findsNothing);
      expect(find.text('Dãy trái'), findsNothing);
      expect(find.text('Dãy phải'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'floor switch uses independent columns and retains selected seat IDs',
    (tester) async {
      final items = [
        apiSeat(1, 'A1', x: 180, y: 1000),
        apiSeat(2, 'A2', x: 820, y: 1000),
        apiSeat(3, 'B1', floor: 2, x: 180, y: 1000),
        apiSeat(4, 'B2', floor: 2, x: 500, y: 1000),
        apiSeat(5, 'B3', floor: 2, x: 820, y: 1000),
      ];
      var requestedFloor = 0;
      await mount(
        tester,
        items,
        selected: [items.first],
        onFloor: (f) => requestedFloor = f,
      );
      expect(seat(1), findsOneWidget);
      expect(seat(3), findsNothing);
      await tester.tap(find.text('Tầng trên'));
      expect(requestedFloor, 2);
      await mount(tester, items, floor: 2, selected: [items.first]);
      expect(seat(1), findsNothing);
      for (final id in [3, 4, 5]) {
        expect(seat(id), findsOneWidget);
      }
      expect(tester.getCenter(seat(3)).dy, tester.getCenter(seat(5)).dy);
      expect(find.text('(1)'), findsOneWidget);
      await mount(tester, items, selected: [items.first]);
      expect(
        tester.getSemantics(seat(1)).getSemanticsData().label,
        contains('Đang chọn'),
      );
    },
  );

  testWidgets(
    'vehicle head layout places steering wheel on left, Đầu xe in center, door on right',
    (tester) async {
      final items = [
        apiSeat(1, 'A01', x: 160, y: 1000),
        apiSeat(2, 'A02', x: 360, y: 1000),
      ];
      await mount(tester, items, size: const Size(360, 640));

      expect(find.byType(SteeringWheelVector), findsOneWidget);
      expect(find.text('Đầu xe'), findsOneWidget);
      expect(find.byType(BusDoorVector), findsOneWidget);

      final wheelCenter = tester.getCenter(find.byType(SteeringWheelVector));
      final headCenter = tester.getCenter(find.text('Đầu xe'));
      final doorCenter = tester.getCenter(find.byType(BusDoorVector));

      expect(wheelCenter.dx, lessThan(headCenter.dx));
      expect(headCenter.dx, lessThan(doorCenter.dx));

      final cardRect = tester.getRect(find.byType(SeatMapView));
      expect(headCenter.dx, closeTo(cardRect.center.dx, 2.0));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'eliminates excessive vertical gap from y=1000 by normalizing with minY',
    (tester) async {
      final items = [
        apiSeat(1, 'A01', x: 160, y: 1000),
        apiSeat(2, 'A02', x: 360, y: 1000),
      ];
      await mount(tester, items, size: const Size(360, 640));

      final dividerRect = tester.getRect(find.byType(Divider).first);
      final seat1Rect = tester.getRect(seat(1));
      // Distance from divider to first seat should be tight (< 20px), not 64+ px
      expect(seat1Rect.top - dividerRect.bottom, lessThanOrEqualTo(20.0));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SpatialSeatMap has no horizontal scrollable and fits all 2+2 columns within 320dp',
    (tester) async {
      // 2+2 layout with 4 columns on row 1
      final items = [
        apiSeat(1, 'A01', x: 160, y: 1000),
        apiSeat(2, 'A02', x: 360, y: 1000),
        apiSeat(3, 'A03', x: 640, y: 1000),
        apiSeat(4, 'A04', x: 840, y: 1000),
      ];
      await mount(tester, items, size: const Size(320, 640), scale: 1.0);

      // Verify no horizontal Scrollable exists inside SpatialSeatMap
      final spatialMap = find.byType(SpatialSeatMap);
      expect(spatialMap, findsOneWidget);
      expect(
        find.descendant(
          of: spatialMap,
          matching: find.byWidgetPredicate(
            (w) =>
                w is SingleChildScrollView &&
                w.scrollDirection == Axis.horizontal,
          ),
        ),
        findsNothing,
      );

      // Verify all seat bounding boxes are fully within the 320dp viewport
      for (final id in [1, 2, 3, 4]) {
        final rect = tester.getRect(seat(id));
        expect(rect.left, greaterThanOrEqualTo(0.0));
        expect(rect.right, lessThanOrEqualTo(320.0));
        expect(rect.width, greaterThanOrEqualTo(48.0));
        expect(rect.height, greaterThanOrEqualTo(58.0));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SeatLegend renders all 4 statuses on ultra-narrow 320dp with 2.0x text without horizontal scroll',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2.0)),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(child: SeatLegend()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trống'), findsOneWidget);
      expect(find.text('Đang chọn'), findsOneWidget);
      expect(find.text('Đang giữ'), findsOneWidget);
      expect(find.text('Đã đặt'), findsOneWidget);

      // Verify no horizontal scrollable inside SeatLegend
      expect(
        find.descendant(
          of: find.byType(SeatLegend),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );

      // All texts are within screen bounds
      for (final label in ['Trống', 'Đang chọn', 'Đang giữ', 'Đã đặt']) {
        final rect = tester.getRect(find.text(label));
        expect(rect.left, greaterThanOrEqualTo(0.0));
        expect(rect.right, lessThanOrEqualTo(320.0));
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final config in [
    (const Size(390, 844), 1.0),
    (const Size(320, 740), 2.0),
    (const Size(640, 360), 2.0),
  ]) {
    testWidgets(
      'coordinate seats remain accessible at ${config.$1} text ${config.$2}',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final items = [
          apiSeat(1, 'A01', x: 160, y: 1000),
          apiSeat(2, 'A02', x: 360, y: 1000, status: 'DANG_GIU'),
          apiSeat(3, 'A03', x: 640, y: 1000, status: 'DA_DAT'),
          apiSeat(4, 'LONG-04', x: 840, y: 1000, price: 300000),
          apiSeat(5, 'A05', x: 160, y: 2000, status: 'UNKNOWN'),
        ];
        final tapped = <String>[];
        await mount(
          tester,
          items,
          size: config.$1,
          scale: config.$2,
          onTap: (s) => tapped.add(s.id),
        );
        final rects = [
          for (final id in [1, 2, 3, 4, 5]) tester.getRect(seat(id)),
        ];
        for (var i = 0; i < rects.length; i++) {
          expect(rects[i].width, greaterThanOrEqualTo(48));
          expect(rects[i].height, greaterThanOrEqualTo(58));
          for (var j = i + 1; j < rects.length; j++) {
            expect(rects[i].overlaps(rects[j]), isFalse);
          }
        }
        expect(
          tester.getSemantics(seat(2)).getSemanticsData().label,
          contains('Đang giữ'),
        );
        await tester.tap(seat(1));
        for (final id in [2, 3, 5]) {
          await tester.ensureVisible(seat(id));
          await tester.pumpAndSettle();
          await tester.tap(seat(id));
        }
        expect(tapped, ['1']);
        await tester.ensureVisible(seat(4));
        await tester.pumpAndSettle();
        await tester.tap(seat(4));
        expect(tapped, ['1', '4']);
        expect(tester.takeException(), isNull);
        semantics.dispose();
        if (const bool.fromEnvironment('CAPTURE_SEAT_COORDINATE_SCREENSHOTS')) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('seat-map-render')),
          );
          await tester.runAsync(() async {
            final picture = await boundary.toImage(pixelRatio: 1);
            final bytes = await picture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '../mobile-qa-evidence/backend-sync-20261026/seat-${config.$1.width.toInt()}-${config.$2}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            picture.dispose();
          });
        }
      },
    );
  }
}
