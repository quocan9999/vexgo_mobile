import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/models/voucher_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';

class FakeSeatRepository implements SeatRepository {
  @override
  Future<SeatLayoutModel> getSeatLayout(String seatLayoutType) async {
    return const SeatLayoutModel(
      vehicleType: 'Limousine 34 Phòng VIP',
      hasTwoFloors: true,
      lowerFloor: [
        SeatModel(id: 'A01', name: 'A01', floor: 1, status: SeatStatus.available, price: 290000, row: 1, col: 1),
        SeatModel(id: 'A02', name: 'A02', floor: 1, status: SeatStatus.available, price: 290000, row: 1, col: 2),
        SeatModel(id: 'A03', name: 'A03', floor: 1, status: SeatStatus.booked, price: 290000, row: 2, col: 1),
      ],
      upperFloor: [
        SeatModel(id: 'B01', name: 'B01', floor: 2, status: SeatStatus.available, price: 290000, row: 1, col: 1),
      ],
    );
  }
}

void main() {
  late BookingFlowBloc bloc;
  late MockBookingRepository bookingRepository;
  late FakeSeatRepository seatRepository;

  final testTrip = TripModel(
    id: 'TRIP_TEST',
    operatorId: 'OP_FUTA',
    operatorName: 'Phương Trang',
    vehicleType: 'Limousine 34 Phòng VIP',
    fromCityId: 'HCM',
    fromCityName: 'TP. Hồ Chí Minh',
    toCityId: 'DL',
    toCityName: 'Đà Lạt',
    departureTime: '23:00',
    arrivalTime: '06:00',
    duration: '7 tiếng',
    pickupPoint: 'Bến xe Miền Đông mới',
    pickupAddress: 'TP. Thủ Đức',
    dropoffPoint: 'Bến xe Đà Lạt',
    dropoffAddress: '01 Tô Hiến Thành',
    originalPrice: 320000,
    discountPrice: 290000,
    availableSeats: 8,
    totalSeats: 34,
    seatLayoutType: 'SLEEPER_34',
    rating: 4.8,
    reviewCount: 120,
    pickupPoints: const [
      StopPointModel(id: 'PU1', name: 'Bến xe Miền Đông mới', time: '23:00', address: 'Thủ Đức', isDefault: true),
      StopPointModel(id: 'PU2', name: 'Văn phòng Hàng Xanh', time: '23:25', address: 'Bình Thạnh'),
    ],
    dropoffPoints: const [
      StopPointModel(id: 'DO1', name: 'Bến xe Đà Lạt', time: '06:00', address: 'Tô Hiến Thành', isDefault: true),
    ],
  );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    seatRepository = FakeSeatRepository();
    bookingRepository = MockBookingRepository();
    bloc = BookingFlowBloc(
      seatRepository: seatRepository,
      bookingRepository: bookingRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('InitBookingFlowEvent initializes state and loads layout & default points', () async {
    bloc.add(InitBookingFlowEvent(trip: testTrip, date: DateTime(2026, 9, 25), ticketCount: 2));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<BookingFlowState>((s) => s.status == BookingFlowStatus.loading),
        predicate<BookingFlowState>((s) =>
            s.status == BookingFlowStatus.loaded &&
            s.seatLayout != null &&
            s.selectedPickupPoint?.id == 'PU1' &&
            s.selectedDropoffPoint?.id == 'DO1'),
      ]),
    );
  });

  test('ToggleSeatEvent adds and removes seats, respects booked status', () async {
    bloc.add(InitBookingFlowEvent(trip: testTrip, date: DateTime(2026, 9, 25)));
    await bloc.stream.firstWhere((s) => s.status == BookingFlowStatus.loaded);

    // Booked seat cannot be selected
    const bookedSeat = SeatModel(
      id: 'A03',
      name: 'A03',
      floor: 1,
      status: SeatStatus.booked,
      price: 290000,
      row: 2,
      col: 1,
    );
    bloc.add(const ToggleSeatEvent(bookedSeat));
    expect(bloc.state.selectedSeats.isEmpty, isTrue);

    // Available seat can be selected
    const seatA1 = SeatModel(
      id: 'A01',
      name: 'A01',
      floor: 1,
      status: SeatStatus.available,
      price: 290000,
      row: 1,
      col: 1,
    );
    bloc.add(const ToggleSeatEvent(seatA1));
    await expectLater(
      bloc.stream,
      emits(predicate<BookingFlowState>((s) => s.selectedSeats.length == 1 && s.seatsTotalAmount == 290000)),
    );

    // Toggle same seat removes it
    bloc.add(const ToggleSeatEvent(seatA1));
    await expectLater(
      bloc.stream,
      emits(predicate<BookingFlowState>((s) => s.selectedSeats.isEmpty && s.seatsTotalAmount == 0)),
    );
  });

  test('Step progression moves through all 6 steps smoothly', () async {
    bloc.add(InitBookingFlowEvent(trip: testTrip, date: DateTime(2026, 9, 25)));
    await bloc.stream.firstWhere((s) => s.status == BookingFlowStatus.loaded);

    // Select seat
    const seatA1 = SeatModel(
      id: 'A01',
      name: 'A01',
      floor: 1,
      status: SeatStatus.available,
      price: 290000,
      row: 1,
      col: 1,
    );
    bloc.add(const ToggleSeatEvent(seatA1));
    await bloc.stream.firstWhere((s) => s.selectedSeats.isNotEmpty);

    // Step 1 -> Step 2
    bloc.add(const NextStepEvent());
    await expectLater(
      bloc.stream,
      emits(predicate<BookingFlowState>((s) => s.step == BookingStep.pickupPoint)),
    );

    // Step 2 -> Step 3
    bloc.add(const NextStepEvent());
    await expectLater(
      bloc.stream,
      emits(predicate<BookingFlowState>((s) => s.step == BookingStep.dropoffPoint)),
    );

    // Step 3 -> Step 4
    bloc.add(const NextStepEvent());
    await expectLater(
      bloc.stream,
      emits(predicate<BookingFlowState>((s) => s.step == BookingStep.passengerInfo)),
    );

    // Step 4 -> Step 5
    bloc.add(const NextStepEvent());
    await expectLater(
      bloc.stream,
      emits(predicate<BookingFlowState>((s) => s.step == BookingStep.tripSummary)),
    );

    // Step 5 -> Step 6 (Payment)
    bloc.add(const NextStepEvent());
    await expectLater(
      bloc.stream,
      emits(predicate<BookingFlowState>((s) => s.step == BookingStep.payment)),
    );

    // Step 6 -> Step 5 (Previous)
    bloc.add(const PreviousStepEvent());
    await expectLater(
      bloc.stream,
      emits(predicate<BookingFlowState>((s) => s.step == BookingStep.tripSummary)),
    );
  });

  test('Voucher application correctly discounts the total price', () async {
    bloc.add(InitBookingFlowEvent(trip: testTrip, date: DateTime(2026, 9, 25)));
    await bloc.stream.firstWhere((s) => s.status == BookingFlowStatus.loaded);

    const seatA1 = SeatModel(
      id: 'A01',
      name: 'A01',
      floor: 1,
      status: SeatStatus.available,
      price: 290000,
      row: 1,
      col: 1,
    );
    bloc.add(const ToggleSeatEvent(seatA1));
    await bloc.stream.firstWhere((s) => s.selectedSeats.isNotEmpty);

    const testVoucher = VoucherModel(
      code: 'TEST50K',
      title: 'Giảm 50k',
      description: 'Test voucher',
      discountAmount: 50000,
      discountPercent: 0,
      minOrderAmount: 200000,
      expiryDate: '31/12/2026',
      isApplicable: true,
    );

    bloc.add(const ApplyVoucherEvent(testVoucher));
    await expectLater(
      bloc.stream,
      emits(predicate<BookingFlowState>(
          (s) => s.discountAmount == 50000 && s.finalAmount == 240000)),
    );

    bloc.add(const RemoveVoucherEvent());
    await expectLater(
      bloc.stream,
      emits(predicate<BookingFlowState>(
          (s) => s.discountAmount == 0 && s.finalAmount == 290000)),
    );
  });
}
