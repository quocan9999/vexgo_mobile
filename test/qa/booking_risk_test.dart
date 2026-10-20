import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:vexgo_app/data/models/booking_model.dart';
import 'package:vexgo_app/data/models/payment_transaction_model.dart';
import 'package:vexgo_app/data/models/seat_hold_model.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'qa_fixtures.dart';

class RiskSeatRepository implements SeatRepository {
  int releases = 0;
  @override
  Future<bool> releaseSeatHold(String holdToken) async {
    releases++;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RiskBookingRepository implements BookingRepository {
  int bookings = 0;
  int payments = 0;
  int polls = 0;
  int ticketFetches = 0;
  bool loseBookingResponse = false;
  bool failTicketFetch = false;
  bool failPoll = false;
  PaymentStatus paymentStatus = PaymentStatus.pending;
  final Completer<void> bookingStarted = Completer<void>();
  Completer<void>? bookingGate;

  @override
  Future<BookingModel> createApiBooking({
    required int tripId,
    required List<int> seatIds,
    required String pickupPoint,
    required String dropoffPoint,
    required PassengerInfo contact,
    String? promotionCode,
    String? holdToken,
  }) async {
    bookings++;
    if (!bookingStarted.isCompleted) bookingStarted.complete();
    if (bookingGate != null) await bookingGate!.future;
    if (loseBookingResponse) {
      throw const NetworkException(message: 'QA lost POST response');
    }
    return BookingModel.fromJson(qaBookingJson(status: 'CHO_THANH_TOAN'));
  }

  @override
  Future<TicketModel> createBooking({
    required TicketTripSummary trip,
    required List<String> seats,
    required int totalAmount,
    required int discountAmount,
    required int finalAmount,
    required String paymentMethod,
    required PassengerInfo passenger,
    List<int>? seatIds,
    String? holdToken,
    String? promotionCode,
  }) async {
    // Compatibility probe for the pre-integration one-shot checkout path.
    await createApiBooking(
      tripId: 101,
      seatIds: seatIds ?? [1],
      pickupPoint: trip.pickupPoint,
      dropoffPoint: trip.dropoffPoint,
      contact: passenger,
    );
    payments++;
    throw const PaymentPendingException(
      message: 'QA pending',
      paymentId: 71,
      bookingId: 888,
    );
  }

  @override
  Future<PaymentTransactionModel> createPayment({
    required int bookingId,
    required String provider,
  }) async {
    payments++;
    return const PaymentTransactionModel(
      paymentId: 71,
      bookingId: 888,
      provider: PaymentProvider.momo,
      amount: 250000,
      status: PaymentStatus.pending,
    );
  }

  @override
  Future<PaymentTransactionModel> getPaymentStatus(dynamic paymentId) async {
    polls++;
    if (failPoll) throw const NetworkException(message: 'QA poll disconnected');
    return PaymentTransactionModel(
      paymentId: 71,
      bookingId: 888,
      provider: PaymentProvider.momo,
      amount: 250000,
      status: paymentStatus,
    );
  }

  @override
  Future<BookingModel?> getBookingById(dynamic id) async =>
      BookingModel.fromJson(qaBookingJson());
  @override
  Future<TicketModel?> getTicketById(String id) async {
    ticketFetches++;
    if (failTicketFetch) {
      throw const NetworkException(message: 'QA ticket unavailable');
    }
    return TicketModel.fromJson(qaTicketJson());
  }

  @override
  Future<List<TicketModel>> getMyTickets() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SeededBookingBloc extends BookingFlowBloc {
  SeededBookingBloc(
    BookingFlowState seed,
    RiskBookingRepository bookings,
    RiskSeatRepository seats,
  ) : super(bookingRepository: bookings, seatRepository: seats) {
    emit(seed);
  }
}

BookingFlowState draft({
  bool expired = false,
  int? bookingId,
  int? paymentId,
}) => BookingFlowState(
  status: BookingFlowStatus.loaded,
  step: BookingStep.payment,
  trip: qaTrip,
  date: DateTime(2030, 10, 20),
  selectedSeats: const [
    SeatModel(
      id: '1',
      name: 'A01',
      floor: 1,
      status: SeatStatus.available,
      price: 250000,
      row: 1,
      col: 1,
    ),
  ],
  selectedPickupPoint: const StopPointModel(
    id: '1',
    name: 'QA Pickup',
    time: '23:00',
    address: 'QA',
  ),
  selectedDropoffPoint: const StopPointModel(
    id: '2',
    name: 'QA Dropoff',
    time: '06:00',
    address: 'QA',
  ),
  passengerName: qaPassenger.fullName,
  passengerPhone: qaPassenger.phone,
  passengerEmail: qaPassenger.email,
  pendingBookingId: bookingId,
  pendingPaymentId: paymentId,
  seatHold: SeatHoldModel(
    holdToken: 'qa-hold',
    tripId: 101,
    seatIds: const [1],
    expiresAt: DateTime.now().add(
      expired ? const Duration(seconds: -10) : const Duration(minutes: 10),
    ),
  ),
);

Future<void> confirm(BookingFlowBloc bloc) async {
  final completed = bloc.stream.firstWhere(
    (s) =>
        s.status != BookingFlowStatus.submitting &&
        s.status != BookingFlowStatus.loaded &&
        s.status != BookingFlowStatus.loading,
  );
  bloc.add(const ConfirmPaymentEvent());
  await completed.timeout(const Duration(seconds: 6));
}

void main() {
  late RiskBookingRepository bookings;
  late RiskSeatRepository seats;
  BookingFlowBloc? active;
  setUp(() {
    bookings = RiskBookingRepository();
    seats = RiskSeatRepository();
  });
  tearDown(() async {
    await active?.close();
    active = null;
  });
  BookingFlowBloc start(BookingFlowState seed) =>
      active = SeededBookingBloc(seed, bookings, seats);

  test(
    'QA-BKG-01 PENDING remains pending on repeat status check, no duplicate create',
    () async {
      final bloc = start(draft());
      await confirm(bloc);
      expect(bloc.state.status, BookingFlowStatus.paymentPending);
      await confirm(bloc);
      expect(bloc.state.status, BookingFlowStatus.paymentPending);
      expect(bloc.state.createdTicket, isNull);
      expect(bookings.bookings, 1);
      expect(bookings.payments, 1);
    },
  );

  test(
    'QA-BKG-02 FAILED retry preserves IDs and never creates a second booking/payment',
    () async {
      final bloc = start(draft());
      await confirm(bloc);
      bookings.paymentStatus = PaymentStatus.failed;
      await confirm(bloc);
      expect(bloc.state.status, BookingFlowStatus.failure);
      expect(bloc.state.createdTicket, isNull);
      expect(bloc.state.pendingBookingId, 888);
      expect(bloc.state.pendingPaymentId, 71);
      await confirm(bloc);
      expect(bookings.bookings, 1);
      expect(bookings.payments, 1);
      expect(bloc.state.createdTicket, isNull);
    },
  );

  test(
    'QA-BKG-03 double confirm while booking is in flight creates exactly one order',
    () async {
      bookings.bookingGate = Completer<void>();
      final bloc = start(draft());
      final done = bloc.stream.firstWhere(
        (s) => s.status == BookingFlowStatus.paymentPending,
      );
      bloc.add(const ConfirmPaymentEvent());
      await bookings.bookingStarted.future.timeout(const Duration(seconds: 5));
      bloc.add(const ConfirmPaymentEvent());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      bookings.bookingGate!.complete();
      await done.timeout(const Duration(seconds: 5));
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      expect(bookings.bookings, 1);
      expect(bookings.payments, 1);
    },
  );

  test(
    'QA-BKG-04 lost booking POST response cannot be blindly retried',
    () async {
      bookings.loseBookingResponse = true;
      final bloc = start(draft());
      await confirm(bloc);
      await confirm(bloc);
      expect(bookings.bookings, 1);
      expect(bookings.payments, 0);
      expect(bloc.state.createdTicket, isNull);
    },
  );

  test(
    'QA-BKG-05 paid status with unavailable authoritative ticket never emits success',
    () async {
      final bloc = start(draft());
      await confirm(bloc);
      bookings.paymentStatus = PaymentStatus.success;
      bookings.failTicketFetch = true;
      await confirm(bloc);
      expect(bloc.state.status, isNot(BookingFlowStatus.success));
      expect(bloc.state.createdTicket, isNull);
      expect(bloc.state.pendingBookingId, 888);
      expect(bloc.state.pendingPaymentId, 71);
    },
  );

  test(
    'QA-BKG-06 poll network error keeps IDs so retry does not create payment',
    () async {
      final bloc = start(draft());
      await confirm(bloc);
      bookings.failPoll = true;
      await confirm(bloc);
      expect(bloc.state.createdTicket, isNull);
      expect(bloc.state.pendingPaymentId, 71);
      bookings.failPoll = false;
      await confirm(bloc);
      expect(bloc.state.status, BookingFlowStatus.paymentPending);
      expect(bookings.bookings, 1);
      expect(bookings.payments, 1);
    },
  );

  test(
    'QA-HOLD-01 one tick after elapsed wall clock expires the hold immediately',
    () async {
      final bloc = start(draft(expired: true));
      bloc.add(const TickCountdownEvent());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(bloc.state.countdownSeconds, 0);
      expect(bloc.state.seatHold, isNull);
      expect(bloc.state.selectedSeats, isEmpty);
    },
  );

  test(
    'QA-HOLD-02 expired hold cannot create a booking even if cached countdown says 600',
    () async {
      final bloc = start(draft(expired: true));
      await confirm(bloc);
      expect(bookings.bookings, 0);
      expect(bookings.payments, 0);
      expect(bloc.state.createdTicket, isNull);
    },
  );

  test(
    'QA-HOLD-03 checkout owns booking; stale hold tick must retain payment recovery',
    () async {
      final bloc = start(draft());
      await confirm(bloc);
      for (var i = 0; i < 601; i++) {
        bloc.add(const TickCountdownEvent());
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(bloc.state.pendingBookingId, 888);
      expect(bloc.state.pendingPaymentId, 71);
      expect(bloc.state.status, BookingFlowStatus.paymentPending);
    },
  );

  for (final phone in ['0|12345678', '090123456', '09012345678', '']) {
    test(
      'QA-FORM-01 invalid local phone "$phone" cannot pass passenger validation',
      () {
        expect(
          draft().copyWith(passengerPhone: phone).isPassengerValid,
          isFalse,
        );
      },
    );
  }
  test('Backend-supported E164 phone is accepted', () {
    expect(
      draft().copyWith(passengerPhone: '+84901234567').isPassengerValid,
      isTrue,
    );
  });
}
