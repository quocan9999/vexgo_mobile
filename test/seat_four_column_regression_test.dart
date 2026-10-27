import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/spatial_seat_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final config in [
    (264.0, 1.0),
    (264.0, 2.0),
    (380.0, 1.0),
    (380.0, 2.0),
  ]) {
    testWidgets(
      'Four staggered columns remain reachable at width ${config.$1}, text ${config.$2}',
      (tester) async {
        await (FontLoader(
          'VexGoJakarta',
        )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
        final coordinates = [
          (110.0, 1000.0),
          (310.0, 1001.0),
          (690.0, 1000.0),
          (890.0, 1001.0),
          (110.0, 2000.0),
          (310.0, 2001.0),
          (690.0, 2000.0),
          (890.0, 2001.0),
        ];
        final seats = [
          for (var i = 0; i < coordinates.length; i++)
            SeatModel(
              id: '$i',
              name: 'A$i',
              floor: 1,
              status: SeatStatus.available,
              price: 190000,
              row: 1,
              col: 1,
              x: coordinates[i].$1,
              y: coordinates[i].$2,
            ),
        ];
        // Mirrors the current backend bounds and collision rule, without HTTP.
        for (final seat in seats) {
          expect(seat.x, inInclusiveRange(110, 890));
          expect(seat.y, inInclusiveRange(1000, 30000));
          for (final other in seats.where((s) => s.id != seat.id)) {
            expect(
              (seat.x! - other.x!).abs() < 180 &&
                  (seat.y! - other.y!).abs() < 875,
              isFalse,
            );
          }
        }
        String? selected;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(config.$2)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: SizedBox(
                    width: config.$1,
                    child: SpatialSeatMap(
                      seats: seats,
                      selectedSeats: const [],
                      showPrice: true,
                      onSeatToggled: (seat) => selected = seat.id,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final height = tester
            .getSize(find.byKey(const ValueKey('spatial-seat-canvas')))
            .height;
        debugPrint('REVIEW valid four-column layout height=$height');
        expect(
          height,
          lessThan(1000),
          reason:
              'Two nearly aligned seat rows must not require tens of thousands of pixels to scroll',
        );
        final canvas = tester.getRect(
          find.byKey(const ValueKey('spatial-seat-canvas')),
        );
        final rects = [
          for (final seat in seats)
            tester.getRect(find.byKey(ValueKey('seat-${seat.id}'))),
        ];
        for (var i = 0; i < rects.length; i++) {
          expect(rects[i].width, greaterThanOrEqualTo(48));
          expect(rects[i].left, greaterThanOrEqualTo(canvas.left - 0.01));
          expect(rects[i].right, lessThanOrEqualTo(canvas.right + 0.01));
          for (var j = i + 1; j < rects.length; j++) {
            expect(
              rects[i].overlaps(rects[j]),
              isFalse,
              reason: 'Seat targets $i and $j must not overlap',
            );
          }
        }
        final first = tester.getRect(find.byKey(const ValueKey('seat-0')));
        final secondRow = tester.getRect(find.byKey(const ValueKey('seat-4')));
        expect(secondRow.top, greaterThanOrEqualTo(first.bottom + 12));
        expect(
          (first.top - tester.getRect(find.byKey(const ValueKey('seat-1'))).top)
              .abs(),
          lessThan(1),
        );
        await tester.ensureVisible(find.byKey(const ValueKey('seat-4')));
        await tester.tap(find.byKey(const ValueKey('seat-4')));
        expect(selected, '4');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
