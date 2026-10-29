import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/data/models/seat_layout_resolver.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/seat_map_view.dart';

SeatModel apiSeat(
  int id,
  String name, {
  String position = '',
  String status = 'TRONG',
}) => SeatModel.fromJson({
  'tripSeatId': id,
  'seatNumber': name,
  'position': position,
  'status': status,
  'price': 260000,
});

List<SeatModel> allSeats(SeatLayoutModel layout) => [
  ...layout.lowerFloor,
  ...layout.upperFloor,
];

void main() {
  test(
    'seated API payload uses 2+2 rather than the old three-column fallback',
    () {
      final seats = [
        for (final i in [4, 2, 8, 1, 3, 7, 6, 5]) apiSeat(100 + i, 'A$i'),
      ];
      final layout = resolveSeatLayout(
        vehicleType: 'Ghế ngồi 29 chỗ',
        seats: seats,
      );
      expect(layout.columnCount, 4);
      expect(layout.aisleAfterColumn, 2);
      expect(layout.upperFloor, isEmpty);
      for (var i = 1; i <= 8; i++) {
        final seat = layout.lowerFloor.singleWhere((s) => s.name == 'A$i');
        expect((seat.row, seat.col), ((i - 1) ~/ 4 + 1, (i - 1) % 4 + 1));
        expect(seat.id, '${100 + i}');
        expect(seat.price, 260000);
      }
    },
  );

  test(
    'left/right position labels take priority over sequential seat numbers',
    () {
      final seats = [
        apiSeat(1, 'A1', position: 'Dãy phải'),
        apiSeat(2, 'A2', position: 'Dãy trái', status: 'DA_DAT'),
        apiSeat(3, 'A3', position: 'Dãy phải', status: 'DANG_GIU'),
        apiSeat(4, 'A4', position: 'Dãy trái'),
      ];
      final layout = resolveSeatLayout(vehicleType: 'Ghế ngồi', seats: seats);
      final byId = {for (final s in layout.lowerFloor) s.id: s};
      expect(byId['2']!.col, 1);
      expect(byId['4']!.col, 2);
      expect(byId['1']!.col, 3);
      expect(byId['3']!.col, 4);
      expect(byId['2']!.status, SeatStatus.booked);
      expect(byId['3']!.status, SeatStatus.held);
    },
  );

  test(
    'a B seat prefix alone does not create a second floor on a seated bus',
    () {
      final layout = resolveSeatLayout(
        vehicleType: 'Ghế ngồi 16 chỗ',
        seats: [
          apiSeat(1, 'A1'),
          apiSeat(2, 'A2'),
          apiSeat(3, 'B1'),
          apiSeat(4, 'B2'),
        ],
      );
      expect(layout.hasTwoFloors, isFalse);
      expect(layout.upperFloor, isEmpty);
      expect(layout.lowerFloor, hasLength(4));
    },
  );

  test(
    'sleeper API payload is sorted numerically into three columns per floor',
    () {
      final layout = resolveSeatLayout(
        vehicleType: 'Giường nằm 34 chỗ',
        seats: [
          apiSeat(1, 'A10', position: 'Tầng dưới'),
          apiSeat(2, 'A2', position: 'Tầng dưới'),
          apiSeat(3, 'A1', position: 'Tầng dưới'),
          apiSeat(4, 'A3', position: 'Tầng dưới'),
          apiSeat(5, 'B2', position: 'Tầng trên'),
          apiSeat(6, 'B1', position: 'Tầng trên'),
        ],
      );
      expect(layout.columnCount, 3);
      expect(layout.aisleAfterColumn, isNull);
      expect(layout.hasTwoFloors, isTrue);
      expect(layout.lowerFloor.map((s) => s.name), ['A1', 'A2', 'A3', 'A10']);
      expect(layout.lowerFloor.last.row, 2);
      expect(layout.upperFloor.map((s) => s.name), ['B1', 'B2']);
      expect(allSeats(layout).map((s) => s.id).toSet(), {
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
      });
    },
  );

  test('explicit API coordinates are preserved including empty cells', () {
    final seats = [
      SeatModel.fromJson({
        'tripSeatId': 1,
        'seatNumber': 'A1',
        'status': 'TRONG',
        'floor': 1,
        'row': 1,
        'col': 1,
      }),
      SeatModel.fromJson({
        'tripSeatId': 2,
        'seatNumber': 'A2',
        'status': 'TRONG',
        'floor': 1,
        'row': 1,
        'col': 5,
      }),
    ];
    final layout = resolveSeatLayout(vehicleType: 'Ghế ngồi', seats: seats);
    expect(layout.lowerFloor, seats);
    expect(layout.lowerFloor.last.col, 5);
  });

  test('mixed explicit and inferred coordinates do not hide a real seat', () {
    final explicit = SeatModel.fromJson({
      'tripSeatId': 1,
      'seatNumber': 'A1',
      'status': 'TRONG',
      'floor': 1,
      'row': 1,
      'col': 2,
    });
    final layout = resolveSeatLayout(
      vehicleType: 'Ghế ngồi',
      seats: [explicit, apiSeat(2, 'A2'), apiSeat(3, 'A3'), apiSeat(4, 'A4')],
    );
    final seats = allSeats(layout);
    expect(seats, hasLength(4));
    expect(seats.singleWhere((s) => s.id == '1'), explicit);
    expect(seats.map((s) => (s.floor, s.row, s.col)).toSet(), hasLength(4));
  });

  test('serialization retains API position and coordinate provenance', () {
    final seat = apiSeat(1, 'A1', position: 'Dãy trái');
    expect(seat.hasExplicitCoordinates, isFalse);
    expect(SeatModel.fromJson(seat.toJson()), seat);
  });

  test('empty inventory creates no synthetic seats', () {
    final layout = resolveSeatLayout(vehicleType: 'Ghế ngồi', seats: []);
    expect(allSeats(layout), isEmpty);
  });

  for (final config in [
    (const Size(390, 844), 1.0),
    (const Size(320, 740), 2.0),
    (const Size(640, 360), 2.0),
  ]) {
    testWidgets(
      'seated map preserves aisle and seat callbacks at ${config.$1}, text ${config.$2}',
      (tester) async {
        tester.view.physicalSize = config.$1;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final layout = resolveSeatLayout(
          vehicleType: 'Ghế ngồi',
          seats: [
            apiSeat(11, 'A1'),
            apiSeat(12, 'A2', status: 'DA_DAT'),
            apiSeat(13, 'A3'),
            apiSeat(14, 'A4'),
            apiSeat(15, 'A5'),
          ],
        );
        final selected = <String>[];
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(config.$2)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: SeatMapView(
                  layout: layout,
                  selectedFloor: 1,
                  selectedSeats: const [],
                  onFloorChanged: (_) {},
                  onSeatToggled: (seat) => selected.add(seat.id),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final first = find.byKey(const ValueKey('seat-11'));
        final second = find.byKey(const ValueKey('seat-12'));
        final third = find.byKey(const ValueKey('seat-13'));
        expect(tester.getTopLeft(first).dy, tester.getTopLeft(third).dy);
        expect(tester.getTopLeft(third).dx - tester.getTopRight(second).dx, 24);
        await tester.tap(find.text('A1'));
        await tester.tap(find.text('A2'));
        expect(selected, ['11']);
        expect(find.text('Tầng trên'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
