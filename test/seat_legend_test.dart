import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/seat_legend.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/seat_map_view.dart';

void main() {
  group('SeatLegend and SeatMapView Tests', () {
    testWidgets(
      'SeatLegend renders without overflow on standard narrow screens',
      (WidgetTester tester) async {
        // Set screen size to a narrow 360x640 mobile screen
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SeatLegend(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Ghế trống'), findsOneWidget);
        expect(find.text('Đang chọn'), findsOneWidget);
        expect(find.text('Đang giữ'), findsOneWidget);
        expect(find.text('Đã bán'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'SeatLegend renders without overflow on ultra narrow 320px screens',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SeatLegend(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Ghế trống'), findsOneWidget);
        expect(find.text('Đang chọn'), findsOneWidget);
        expect(find.text('Đang giữ'), findsOneWidget);
        expect(find.text('Đã bán'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'SeatMapView hides floor switcher when vehicle has only 1 floor',
      (WidgetTester tester) async {
        final singleFloorLayout = SeatLayoutModel(
          vehicleType: 'Ghế ngồi 29 chỗ',
          hasTwoFloors: false,
          lowerFloor: const [
            SeatModel(
              id: '1',
              name: 'A01',
              floor: 1,
              status: SeatStatus.available,
              price: 150000,
              row: 1,
              col: 1,
            ),
            SeatModel(
              id: '2',
              name: 'A02',
              floor: 1,
              status: SeatStatus.available,
              price: 150000,
              row: 1,
              col: 2,
            ),
            SeatModel(
              id: '3',
              name: 'A03',
              floor: 1,
              status: SeatStatus.available,
              price: 150000,
              row: 1,
              col: 3,
            ),
            SeatModel(
              id: '4',
              name: 'A04',
              floor: 1,
              status: SeatStatus.available,
              price: 150000,
              row: 1,
              col: 4,
            ),
          ],
          upperFloor: const [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SeatMapView(
                  layout: singleFloorLayout,
                  selectedFloor: 1,
                  selectedSeats: const [],
                  onFloorChanged: (_) {},
                  onSeatToggled: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Floor switcher should NOT be visible
        expect(find.text('Tầng 1 (Dưới)'), findsNothing);
        expect(find.text('Tầng 2 (Trên)'), findsNothing);

        // Seats from 4-column row should all be visible
        expect(find.text('A01'), findsOneWidget);
        expect(find.text('A02'), findsOneWidget);
        expect(find.text('A03'), findsOneWidget);
        expect(find.text('A04'), findsOneWidget);
        expect(find.text('Lối đi'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
