import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/data/models/seat_hold_model.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/models/voucher_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/presentation/steps/step_1_seat_selection.dart';
import 'package:vexgo_app/features/user/booking/presentation/steps/step_2_pickup_point.dart';
import 'package:vexgo_app/features/user/booking/presentation/steps/step_3_dropoff_point.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_selection_view.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_stepper.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/stop_point_item.dart';

const pickup = StopPointModel(
  id: 'p1',
  name: 'Bến xe Miền Tây',
  time: '08:00',
  address: '395 Kinh Dương Vương, Bình Tân',
);

const pickup2 = StopPointModel(
  id: 'p2',
  name: 'Văn phòng Quận 5',
  time: '08:15',
  address: 'Địa chỉ nhà xe',
  type: 'office',
);

const dropoff = StopPointModel(
  id: 'd1',
  name: 'Bến xe Đà Lạt',
  time: '14:00',
  address: 'Đà Lạt',
);

const trip = TripModel(
  id: '10',
  operatorId: '3',
  operatorName: 'Hoa Mai',
  vehicleType: 'Giường nằm 34 chỗ',
  fromCityId: 'HCM',
  fromCityName: 'TP. Hồ Chí Minh',
  toCityId: 'DL',
  toCityName: 'Đà Lạt',
  departureTime: '13:00',
  arrivalTime: '19:00',
  duration: '6 giờ',
  pickupPoint: '',
  pickupAddress: '',
  dropoffPoint: '',
  dropoffAddress: '',
  originalPrice: 280000,
  discountPrice: 280000,
  availableSeats: 4,
  totalSeats: 5,
  rating: null,
  reviewCount: 0,
  seatLayoutType: 'test',
  pickupPoints: [pickup, pickup2],
  dropoffPoints: [dropoff],
);

SeatModel makeSeat(
  String id,
  int row,
  int col, {
  int floor = 1,
  SeatStatus status = SeatStatus.available,
  int price = 280000,
}) => SeatModel(
  id: id,
  name: '${floor == 1 ? 'A' : 'B'}$id',
  floor: floor,
  status: status,
  price: price,
  row: row,
  col: col,
);

class _TestSeatRepo implements SeatRepository {
  final items = [
    makeSeat('01', 1, 1),
    makeSeat('02', 1, 2, status: SeatStatus.booked),
    makeSeat('03', 2, 1),
    makeSeat('04', 2, 2, status: SeatStatus.held),
    makeSeat('05', 1, 1, floor: 2),
  ];
  Completer<SeatHoldModel>? hold;
  List<int>? requested;
  int calls = 0;

  @override
  Future<List<SeatModel>> getTripSeats(dynamic id) async => items;

  @override
  Future<SeatLayoutModel> getSeatLayout(String type) async =>
      throw UnimplementedError();

  @override
  Future<SeatHoldModel> createSeatHold({
    required int tripId,
    required List<int> seatIds,
  }) {
    calls++;
    requested = seatIds;
    return hold != null
        ? hold!.future
        : Future.value(
            SeatHoldModel(
              holdToken: 'test-token',
              tripId: tripId,
              seatIds: seatIds,
              expiresAt: DateTime.now().add(const Duration(minutes: 10)),
            ),
          );
  }

  @override
  Future<bool> releaseSeatHold(String token) async => true;
}

class _TestBookingRepo implements BookingRepository {
  @override
  Future<List<VoucherModel>> getVouchers() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<BookingFlowBloc> _createFlow(_TestSeatRepo repo) async {
  final bloc = BookingFlowBloc(
    seatRepository: repo,
    bookingRepository: _TestBookingRepo(),
  );
  final ready = bloc.stream.firstWhere(
    (s) => s.status == BookingFlowStatus.loaded,
  );
  bloc.add(InitBookingFlowEvent(trip: trip, date: DateTime(2026, 10, 24)));
  await ready;
  return bloc;
}

Widget buildSelectionView(BookingFlowBloc bloc, {VoidCallback? onDetails}) =>
    BlocBuilder<BookingFlowBloc, BookingFlowState>(
      bloc: bloc,
      builder: (context, state) {
        final step = switch (state.step) {
          BookingStep.pickupPoint => Step2PickupPoint(state: state, bloc: bloc),
          BookingStep.dropoffPoint => Step3DropoffPoint(
            state: state,
            bloc: bloc,
          ),
          _ => Step1SeatSelection(state: state, bloc: bloc),
        };
        return BookingSelectionView(
          state: state,
          onBack: () => bloc.add(const PreviousStepEvent()),
          onNext: () => bloc.add(const NextStepEvent()),
          onStep: (i) => bloc.add(GoToStepEvent(i)),
          onDetails: onDetails ?? () {},
          onRetry: () {},
          child: step,
        );
      },
    );

Future<void> pumpConfig(
  WidgetTester tester,
  Widget child,
  Size size,
  double scale,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (_, c) => MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: child,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUp(() {
    ApiConfig.isDemoMode = false;
  });

  test(
    'hold expiry refresh retains new API coordinates and authoritative floor',
    () async {
      final repo = _TestSeatRepo();
      repo.items
        ..clear()
        ..add(
          SeatModel.fromJson({
            'tripSeatId': 90,
            'seatNumber': 'B01',
            'floor': 1,
            'x': 180,
            'y': 1000,
            'status': 'TRONG',
          }),
        );
      var now = DateTime.now();
      final bloc = BookingFlowBloc(
        seatRepository: repo,
        bookingRepository: _TestBookingRepo(),
        now: () => now,
      );
      addTearDown(bloc.close);
      final loaded = bloc.stream.firstWhere(
        (s) => s.status == BookingFlowStatus.loaded,
      );
      bloc.add(InitBookingFlowEvent(trip: trip, date: DateTime(2026, 10, 24)));
      await loaded;
      expect(bloc.state.seatLayout!.lowerFloor.single.x, 180);
      final selected = bloc.stream.firstWhere(
        (s) => s.selectedSeats.isNotEmpty,
      );
      bloc.add(ToggleSeatEvent(bloc.state.seatLayout!.lowerFloor.single));
      await selected;
      final held = bloc.stream.firstWhere((s) => s.seatHold != null);
      bloc.add(const NextStepEvent());
      await held;
      repo.items[0] = repo.items[0].copyWith(
        x: 820,
        y: 3000,
        status: SeatStatus.booked,
      );
      now = bloc.state.seatHold!.expiresAt.add(const Duration(seconds: 1));
      final refreshed = bloc.stream.firstWhere(
        (s) => s.seatLayout!.lowerFloor.single.x == 820,
      );
      bloc.add(const TickCountdownEvent());
      await refreshed;
      final actual = bloc.state.seatLayout!.lowerFloor.single;
      expect(
        (actual.id, actual.floor, actual.x, actual.y),
        ('90', 1, 820, 3000),
      );
      expect(actual.status, SeatStatus.booked);
      expect(bloc.state.selectedSeats, isEmpty);
      expect(bloc.state.seatHold, isNull);
    },
  );

  group('Redesigned Header & Stepper Tests', () {
    testWidgets(
      'Compact header renders operator, route/time and inline Chi tiết xe',
      (tester) async {
        final repo = _TestSeatRepo();
        final bloc = await _createFlow(repo);
        addTearDown(bloc.close);

        var detailsTapped = false;
        await pumpConfig(
          tester,
          buildSelectionView(bloc, onDetails: () => detailsTapped = true),
          const Size(390, 844),
          1.0,
        );

        // Header info
        expect(find.text('Hoa Mai'), findsOneWidget);
        expect(find.textContaining('13:00'), findsOneWidget);
        expect(find.textContaining('TP. Hồ Chí Minh → Đà Lạt'), findsOneWidget);

        // Inline Chi tiết xe button
        final detailsBtn = find.text('Chi tiết xe');
        expect(detailsBtn, findsOneWidget);
        await tester.tap(detailsBtn);
        await tester.pumpAndSettle();
        expect(detailsTapped, isTrue);

        // Compact Stepper badges
        expect(find.byType(BookingStepperCompact), findsOneWidget);
        expect(find.text('Chọn chỗ'), findsOneWidget);
        expect(find.text('Điểm đón'), findsOneWidget);
        expect(find.text('Điểm trả'), findsOneWidget);

        // Legend: 4 statuses (no fake 'Chưa mở bán')
        expect(find.text('Trống'), findsOneWidget);
        expect(find.text('Đang chọn'), findsOneWidget);
        expect(find.text('Đang giữ'), findsOneWidget);
        expect(find.text('Đã đặt'), findsOneWidget);
        expect(find.text('Chưa mở bán'), findsNothing);
        expect(
          find.text('Chọn tối đa 5 chỗ cho mỗi lượt đặt.'),
          findsOneWidget,
        );
        expect(find.textContaining('tối đa 6 chỗ'), findsNothing);
      },
    );

    testWidgets('Stepper state transitions: active badge vs passed checkmark', (
      tester,
    ) async {
      final repo = _TestSeatRepo();
      final bloc = await _createFlow(repo);

      await pumpConfig(
        tester,
        buildSelectionView(bloc),
        const Size(390, 844),
        1.0,
      );

      // Step 0: Step 1 active
      expect(bloc.state.step, BookingStep.seatSelection);

      // Select a seat and proceed
      await tester.tap(find.byKey(const ValueKey('seat-01')));
      await tester.pumpAndSettle();
      expect(bloc.state.selectedSeats.length, 1);

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      // Step 1: Điểm đón is now active, Step 0 has checkmark
      expect(bloc.state.step, BookingStep.pickupPoint);
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Tap passed step to navigate back to seat selection
      await tester.tap(find.text('Chọn chỗ'));
      await tester.pumpAndSettle();
      expect(bloc.state.step, BookingStep.seatSelection);

      // Clean teardown for hold timer
      bloc.add(const ReleaseSeatHoldEvent());
      await tester.pumpAndSettle();
      unawaited(bloc.close());
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'Responsive check: 320dp narrow screen with text 2.0x reflows without overflow',
      (tester) async {
        final repo = _TestSeatRepo();
        final bloc = await _createFlow(repo);
        addTearDown(bloc.close);

        await pumpConfig(
          tester,
          buildSelectionView(bloc),
          const Size(320, 740),
          2.0,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Hoa Mai'), findsOneWidget);
        expect(find.text('Chi tiết xe'), findsOneWidget);
      },
    );

    testWidgets(
      'Landscape 640x360 with text 2.0x is scrollable and CTA is reachable',
      (tester) async {
        final repo = _TestSeatRepo();
        final bloc = await _createFlow(repo);
        addTearDown(bloc.close);

        await pumpConfig(
          tester,
          buildSelectionView(bloc),
          const Size(640, 360),
          2.0,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Tiếp tục'), findsOneWidget);
      },
    );

    testWidgets('Seat selection breakdown sheet shows seat names and prices', (
      tester,
    ) async {
      final repo = _TestSeatRepo();
      final bloc = await _createFlow(repo);
      addTearDown(bloc.close);

      await pumpConfig(
        tester,
        buildSelectionView(bloc),
        const Size(390, 844),
        1.0,
      );

      // Select seat A01
      await tester.tap(find.byKey(const ValueKey('seat-01')));
      await tester.pumpAndSettle();

      // Tap dock price summary to open breakdown sheet
      await tester.tap(find.textContaining('280.000'));
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết ghế đã chọn'), findsOneWidget);
      expect(find.textContaining('Ghế A01'), findsOneWidget);

      // Close breakdown sheet
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết ghế đã chọn'), findsNothing);
    });

    testWidgets('End-to-end selection flow: Seat -> Pickup -> Dropoff', (
      tester,
    ) async {
      final repo = _TestSeatRepo();
      final bloc = await _createFlow(repo);

      await pumpConfig(
        tester,
        buildSelectionView(bloc),
        const Size(390, 844),
        1.0,
      );

      // Step 1: Select seat
      await tester.tap(find.byKey(const ValueKey('seat-01')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      // Step 2: Select pickup point
      expect(bloc.state.step, BookingStep.pickupPoint);
      await tester.tap(find.widgetWithText(StopPointItem, pickup.name));
      await tester.pumpAndSettle();
      expect(bloc.state.selectedPickupPoint!.id, 'p1');

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      // Step 3: Select dropoff point
      expect(bloc.state.step, BookingStep.dropoffPoint);
      await tester.tap(find.widgetWithText(StopPointItem, dropoff.name));
      await tester.pumpAndSettle();
      expect(bloc.state.selectedDropoffPoint!.id, 'd1');

      // Can proceed to passenger info
      expect(bloc.state.canProceed, isTrue);

      // Clean teardown
      bloc.add(const ReleaseSeatHoldEvent());
      await tester.pumpAndSettle();
      unawaited(bloc.close());
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
