import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/seat_item.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/seat_map_view.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/spatial_seat_map.dart';

SeatModel seat(String id, double x, int floor) => SeatModel(
  id: id,
  name: id,
  floor: floor,
  status: SeatStatus.available,
  row: 1,
  col: 1,
  x: x,
  y: 1000,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('VexGoJakarta')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await loader.load();
  });
  testWidgets(
    'Same x has identical centre and cell width across floor densities',
    (tester) async {
      final lower = [
        for (final x in [110.0, 305.0, 500.0, 695.0, 890.0]) seat('A$x', x, 1),
      ];
      final upper = [seat('B305', 305, 2), seat('B695', 695, 2)];
      Future<void> pump(List<SeatModel> seats) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 288,
                child: SpatialSeatMap(
                  seats: seats,
                  allSeats: [...lower, ...upper],
                  selectedSeats: const [],
                  showPrice: false,
                  onSeatToggled: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      Finder item(String id) =>
          find.byWidgetPredicate((w) => w is SeatItem && w.seat.id == id);
      await pump(lower);
      final a = tester.getRect(item('A305.0'));
      await pump(upper);
      final b = tester.getRect(item('B305'));
      expect(b.center.dx, closeTo(a.center.dx, 0.001));
      expect(b.width, closeTo(a.width, 0.001));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Front label fits its intrinsic height at 2x text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SeatMapView(
                layout: SeatLayoutModel(
                  vehicleType: 'test',
                  hasTwoFloors: false,
                  lowerFloor: [seat('A01', 500, 1)],
                  upperFloor: const [],
                ),
                selectedFloor: 1,
                selectedSeats: const [],
                onFloorChanged: (_) {},
                onSeatToggled: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(find.text('Đầu xe'));
    expect(
      paragraph.size.height,
      greaterThanOrEqualTo(
        paragraph.getMaxIntrinsicHeight(paragraph.size.width) - 0.01,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
