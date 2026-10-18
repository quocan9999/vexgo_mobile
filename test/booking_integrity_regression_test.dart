import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/datasources/remote/booking_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/payment_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/seat_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/ticket_remote_data_source.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/boarding_pass_card.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/ticket_qr_modal.dart';

// HTTP fixtures mirror current controllers, not the old complete nested ticket
// shape: bookings only return summaries; /tickets/:id supplies boarding data.
class CheckoutServer {
  DateTime now = DateTime.utc(2026, 10, 18, 5);
  String paymentState = 'PENDING';
  String? mode;
  bool bookingResponseLost = false;
  bool paymentResponseLost = false;
  bool statusResponseLost = false;
  bool ticketNotFound = false;
  bool ticketResponseLost = false;
  bool omitFullDetails = false;
  bool wrongPaymentBooking = false;
  bool wrongPaymentId = false;
  bool wrongTicketBooking = false;
  bool unpaidTicket = false;
  Completer<void>? holdGate;
  int bookingPosts = 0;
  int paymentPosts = 0;
  int statusGets = 0;
  int ticketGets = 0;
  int holdPosts = 0;
  int releases = 0;
  List<int> selected = [1];
  late final ApiClient client = ApiClient(httpClient: MockClient(handle));
  late final RealBookingRepository real = RealBookingRepository(
    remoteBookingDataSource: BookingRemoteDataSourceImpl(client: client),
    remotePaymentDataSource: PaymentRemoteDataSourceImpl(client: client),
    remoteTicketDataSource: TicketRemoteDataSourceImpl(client: client),
  );
  late final HybridBookingRepository hybrid = HybridBookingRepository(
    remoteBookingDataSource: BookingRemoteDataSourceImpl(client: client),
    remotePaymentDataSource: PaymentRemoteDataSourceImpl(client: client),
    remoteTicketDataSource: TicketRemoteDataSourceImpl(client: client),
  );
  late final seats = RealSeatRepository(
    remoteDataSource: SeatRemoteDataSourceImpl(client: client),
  );

  Map<String, dynamic> ticket(int id) => {
    'ticketId': id,
    'ticketCode': 'VXG-PDV-42-A${id - 100}',
    'bookingId': wrongTicketBooking ? 43 : 42,
    'bookingCode': 'VXG-PDV-42',
    'origin': 'Ho Chi Minh',
    'destination': 'Da Lat',
    'busCompanyName': 'Nha xe',
    'vehicleType': 'Limousine',
    'departureTime': '2026-11-01T01:00:00.000Z',
    'arrivalTime': '2026-11-01T07:00:00.000Z',
    'seatNumber': 'A${id - 100}',
    'price': 200000,
    'status': 'DA_DAT',
    'bookingStatus': unpaidTicket ? 'CHO_THANH_TOAN' : 'DA_THANH_TOAN',
    'paymentStatus': unpaidTicket ? 'CHO_THANH_TOAN' : 'DA_THANH_TOAN',
    'paymentMethod': 'MOMO',
    'pickup': 'Ben xe',
    'dropoff': 'Da Lat',
    'passengerName': 'Nguyen Van An',
    'passengerPhone': '0901234567',
    'createdAt': '2026-10-18T05:00:00.000Z',
    if (!omitFullDetails)
      'cancellation': {
        'eligible': !unpaidTicket,
        'cancelFeeRate': 0.1,
        'cancelFee': 20000,
        'refundAmount': 180000,
      },
  };

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path.replaceFirst('/api/v1', '');
    final body = request.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(request.body) as Map<String, dynamic>;
    Object? data;
    if (path == '/bookings/quote') {
      final count = (body['seatIds'] as List).length;
      data = {
        'unitPrice': '200000.00',
        'seatCount': count,
        'originalTotal': '${count * 200000}.00',
        'discountAmount': '0.00',
        'finalTotal': '${count * 200000}.00',
        'currency': 'VND',
        'identityChecked': true,
        'phoneEligibilityChecked': true,
        'requiresPhoneBeforeBooking': false,
      };
    } else if (path == '/trips/101/seats') {
      data = List.generate(
        7,
        (i) => {
          'tripSeatId': i + 1,
          'seatNumber': 'A${i + 1}',
          'status': 'TRONG',
          'price': 200000,
          'floor': 1,
        },
      );
    } else if (path == '/seat-holds' && request.method == 'POST') {
      holdPosts++;
      selected = (body['seatIds'] as List).cast<int>();
      await holdGate?.future;
      data = {
        'holdToken': 'fixture-hold',
        'tripId': 101,
        'seatIds': selected,
        'expiresAt': now.add(const Duration(minutes: 10)).toIso8601String(),
      };
    } else if (path == '/seat-holds' && request.method == 'DELETE') {
      releases++;
      data = {'released': true};
    } else if (path == '/bookings' && request.method == 'POST') {
      bookingPosts++;
      selected = (body['seatIds'] as List).cast<int>();
      if (bookingResponseLost) {
        throw const SocketException('Response lost after commit');
      }
      data = {
        'bookingId': 42,
        'bookingCode': 'VXG-PDV-42',
        'tripId': 101,
        'status': 'CHO_THANH_TOAN',
        'seats': selected.map((i) => 'A$i').toList(),
        'seatIds': selected,
        'totalAmount': selected.length * 200000,
        'contact': body['contact'],
        'pickupPoint': 'Ben xe',
        'dropoffPoint': 'Da Lat',
      };
    } else if (path == '/payments' && request.method == 'POST') {
      paymentPosts++;
      if (paymentResponseLost) {
        throw const SocketException('Payment response lost');
      }
      data = {
        'paymentId': 9,
        'bookingId': 42,
        'provider': 'MOMO',
        'amount': selected.length * 200000,
        'status': 'PENDING',
        'paymentUrl': 'https://gateway.example/checkout/9',
        'deeplink': 'momo://checkout/9',
        if (mode != null) 'mode': mode,
      };
    } else if (path == '/payments/9/status') {
      statusGets++;
      if (statusResponseLost) {
        throw const SocketException('Status response lost');
      }
      data = {
        'paymentId': wrongPaymentId ? 10 : 9,
        'bookingId': wrongPaymentBooking ? 43 : 42,
        'provider': 'MOMO',
        'amount': selected.length * 200000,
        'status': paymentState,
      };
    } else if (path == '/bookings/42') {
      data = {
        'bookingId': 42,
        'bookingCode': 'VXG-PDV-42',
        'ticketCount': selected.length,
        'status': 'DA_THANH_TOAN',
        'paymentStatus': 'DA_THANH_TOAN',
        'totalAmount': selected.length * 200000,
        'tickets': selected
            .map(
              (i) => {
                'ticketId': i + 100,
                'ticketCode': 'VXG-PDV-42-A$i',
                'seatNumber': 'A$i',
                'price': 200000,
                'status': 'DA_DAT',
                'pickup': 'Ben xe',
              },
            )
            .toList(),
      };
    } else if (path.startsWith('/tickets/')) {
      ticketGets++;
      if (ticketResponseLost) {
        throw const SocketException('Ticket response lost');
      }
      if (ticketNotFound) {
        return http.Response(jsonEncode({'message': 'Ticket not found'}), 404);
      }
      data = ticket(int.parse(path.split('/').last));
    } else {
      throw StateError('Unexpected ${request.method} $path');
    }
    return http.Response(
      jsonEncode({'data': data}),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

final trip = TripModel(
  id: '101',
  operatorId: '1',
  operatorName: 'Nha xe',
  vehicleType: 'Limousine',
  fromCityId: '1',
  fromCityName: 'Ho Chi Minh',
  toCityId: '2',
  toCityName: 'Da Lat',
  departureTime: '08:00',
  arrivalTime: '14:00',
  duration: '6h',
  pickupPoint: 'Ben xe',
  pickupAddress: '',
  dropoffPoint: 'Da Lat',
  dropoffAddress: '',
  originalPrice: 200000,
  discountPrice: 200000,
  availableSeats: 7,
  totalSeats: 7,
  seatLayoutType: 'LIMOUSINE_9',
  rating: 0,
  reviewCount: 0,
  pickupPoints: const [
    StopPointModel(
      id: '1',
      name: 'Ben xe',
      time: '08:00',
      address: '',
      type: 'point',
    ),
  ],
  dropoffPoints: const [
    StopPointModel(
      id: '2',
      name: 'Da Lat',
      time: '14:00',
      address: '',
      type: 'point',
    ),
  ],
);

Future<void> dispatch(
  BookingFlowBloc bloc,
  BookingFlowEvent event,
  bool Function(BookingFlowState) predicate,
) async {
  final done = bloc.stream
      .firstWhere(predicate)
      .timeout(const Duration(seconds: 3));
  bloc.add(event);
  await done;
}

Future<BookingFlowBloc> ready(
  CheckoutServer server, {
  int seatCount = 1,
}) async {
  final bloc = BookingFlowBloc(
    seatRepository: server.seats,
    bookingRepository: server.real,
    now: () => server.now,
  );
  await dispatch(
    bloc,
    InitBookingFlowEvent(trip: trip, date: DateTime(2026, 11, 1)),
    (s) => s.status == BookingFlowStatus.loaded,
  );
  for (var i = 0; i < seatCount; i++) {
    await dispatch(
      bloc,
      ToggleSeatEvent(bloc.state.seatLayout!.lowerFloor[i]),
      (s) => s.selectedSeats.length == i + 1,
    );
  }
  await dispatch(
    bloc,
    const UpdatePassengerInfoEvent(
      name: 'Nguyen Van An',
      phone: '0901234567',
      email: 'an@example.com',
    ),
    (s) => s.isPassengerValid,
  );
  await dispatch(bloc, const NextStepEvent(), (s) => s.seatHold != null);
  await dispatch(
    bloc,
    const SelectPaymentMethodEvent('momo'),
    (s) => s.selectedPaymentMethod == 'momo',
  );
  return bloc;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(accessToken: 'fixture-token');
  });
  tearDown(() async {
    await TokenStorage.clearTokens();
    TokenStorage.resetStorageAdapter();
    ApiConfig.isDemoMode = false;
  });

  test(
    'real checkout PENDING retains create URLs, polls without duplicate POST, hydrates every full ticket',
    () async {
      final server = CheckoutServer();
      final bloc = await ready(server, seatCount: 2);
      addTearDown(bloc.close);
      await dispatch(
        bloc,
        const ConfirmPaymentEvent(),
        (s) => s.status == BookingFlowStatus.paymentPending,
      );
      expect(
        bloc.state.pendingPaymentUrl,
        'https://gateway.example/checkout/9',
      );
      expect(bloc.state.pendingDeeplink, 'momo://checkout/9');
      expect(bloc.state.pendingBookingId, 42);
      expect(bloc.state.seatHold, isNull);
      await dispatch(
        bloc,
        const ConfirmPaymentEvent(),
        (s) => s.status == BookingFlowStatus.paymentPending,
      );
      server.now = server.now.add(const Duration(hours: 1));
      bloc.add(const TickCountdownEvent());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, BookingFlowStatus.paymentPending);
      server.paymentState = 'SUCCESS';
      await dispatch(
        bloc,
        const ConfirmPaymentEvent(),
        (s) => s.status == BookingFlowStatus.success,
      );
      expect(server.bookingPosts, 1);
      expect(server.paymentPosts, 1);
      expect(server.statusGets, 3);
      expect(server.ticketGets, 2);
      expect(bloc.state.createdTickets.map((t) => t.ticketCode), [
        'VXG-PDV-42-A1',
        'VXG-PDV-42-A2',
      ]);
      expect(
        bloc.state.createdTickets.every((t) => t.hasFullDetails && t.canShowQr),
        isTrue,
      );
      expect(bloc.state.createdTicket!.trip.fromCity, 'Ho Chi Minh');
    },
  );

  for (final failure in [
    '404',
    'timeout',
    'incomplete',
    'unpaid',
    'wrong booking',
  ]) {
    test(
      'SUCCESS + ticket $failure never fabricates success; retry hydrates same transaction',
      () async {
        final server = CheckoutServer()..paymentState = 'SUCCESS';
        server.ticketNotFound = failure == '404';
        server.ticketResponseLost = failure == 'timeout';
        server.omitFullDetails = failure == 'incomplete';
        server.unpaidTicket = failure == 'unpaid';
        server.wrongTicketBooking = failure == 'wrong booking';
        final bloc = await ready(server);
        addTearDown(bloc.close);
        await dispatch(
          bloc,
          const ConfirmPaymentEvent(),
          (s) => s.status == BookingFlowStatus.failure,
        );
        expect(bloc.state.createdTicket, isNull);
        expect(bloc.state.createdTickets, isEmpty);
        expect(bloc.state.pendingPaymentId, 9);
        expect(bloc.state.paymentConfirmed, isTrue);
        server.ticketNotFound = server.ticketResponseLost =
            server.omitFullDetails = server.unpaidTicket =
                server.wrongTicketBooking = false;
        await dispatch(
          bloc,
          const ConfirmPaymentEvent(),
          (s) => s.status == BookingFlowStatus.success,
        );
        expect(server.bookingPosts, 1);
        expect(server.paymentPosts, 1);
        expect(
          server.statusGets,
          1,
          reason: 'SUCCESS already verified, only ticket fetch retries',
        );
      },
    );
  }

  test(
    'status timeout retains both IDs; retry polls instead of creating',
    () async {
      final server = CheckoutServer()..statusResponseLost = true;
      final bloc = await ready(server);
      addTearDown(bloc.close);
      await dispatch(
        bloc,
        const ConfirmPaymentEvent(),
        (s) => s.status == BookingFlowStatus.failure,
      );
      expect(bloc.state.pendingPaymentId, 9);
      server.statusResponseLost = false;
      await dispatch(
        bloc,
        const ConfirmPaymentEvent(),
        (s) => s.status == BookingFlowStatus.paymentPending,
      );
      expect(server.bookingPosts, 1);
      expect(server.paymentPosts, 1);
    },
  );

  test('payment POST timeout resumes payment on same booking', () async {
    final server = CheckoutServer()..paymentResponseLost = true;
    final bloc = await ready(server);
    addTearDown(bloc.close);
    await dispatch(
      bloc,
      const ConfirmPaymentEvent(),
      (s) => s.status == BookingFlowStatus.failure,
    );
    expect(bloc.state.pendingBookingId, 42);
    server.paymentResponseLost = false;
    await dispatch(
      bloc,
      const ConfirmPaymentEvent(),
      (s) => s.status == BookingFlowStatus.paymentPending,
    );
    expect(server.bookingPosts, 1);
    expect(
      server.paymentPosts,
      2,
      reason: 'Backend reuses active attempt for same booking/provider',
    );
  });

  test('unknown booking POST outcome blocks blind retry', () async {
    final server = CheckoutServer()..bookingResponseLost = true;
    final bloc = await ready(server);
    addTearDown(bloc.close);
    await dispatch(
      bloc,
      const ConfirmPaymentEvent(),
      (s) => s.status == BookingFlowStatus.failure,
    );
    expect(bloc.state.bookingOutcomeUnknown, isTrue);
    bloc.add(const ConfirmPaymentEvent());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(server.bookingPosts, 1);
    expect(server.paymentPosts, 0);
    expect(bloc.state.createdTicket, isNull);
  });

  test(
    'real mode rejects backend DEMO even if status could be SUCCESS',
    () async {
      final server = CheckoutServer()
        ..mode = 'DEMO'
        ..paymentState = 'SUCCESS';
      final bloc = await ready(server);
      addTearDown(bloc.close);
      await dispatch(
        bloc,
        const ConfirmPaymentEvent(),
        (s) => s.status == BookingFlowStatus.blockedByBackend,
      );
      expect(bloc.state.pendingBookingId, 42);
      expect(bloc.state.pendingPaymentId, 9);
      expect(server.statusGets, 0);
      expect(server.ticketGets, 0);
      bloc.add(const ConfirmPaymentEvent());
      await Future<void>.delayed(Duration.zero);
      expect(server.bookingPosts, 1);
      expect(bloc.state.createdTicket, isNull);
    },
  );

  for (final mismatchedId in [false, true]) {
    test(
      'mismatched payment ${mismatchedId ? 'ID' : 'booking'} fails closed',
      () async {
        final server = CheckoutServer()..paymentState = 'SUCCESS';
        server.wrongPaymentId = mismatchedId;
        server.wrongPaymentBooking = !mismatchedId;
        final bloc = await ready(server);
        addTearDown(bloc.close);
        await dispatch(
          bloc,
          const ConfirmPaymentEvent(),
          (s) => s.status == BookingFlowStatus.failure,
        );
        expect(server.ticketGets, 0);
        expect(bloc.state.createdTicket, isNull);
      },
    );
  }

  test(
    'guest creates booking without Authorization on latest develop',
    () async {
      final server = CheckoutServer();
      await TokenStorage.clearTokens();
      final booking = await server.real.createApiBooking(
        tripId: 101,
        seatIds: [1],
        pickupPoint: 'Ben xe',
        dropoffPoint: 'Da Lat',
        holdToken: 'fixture-hold',
        contact: const PassengerInfo(
          fullName: 'Guest',
          phone: '0901234567',
          email: '',
        ),
      );
      expect(server.bookingPosts, 1);
      expect(booking.bookingId, 42);
    },
  );

  test(
    'wall clock jump expires hold once and clears stale selection',
    () async {
      final server = CheckoutServer();
      final bloc = await ready(server);
      addTearDown(bloc.close);
      server.now = server.now.add(const Duration(minutes: 11));
      await dispatch(
        bloc,
        const TickCountdownEvent(),
        (s) => s.seatHold == null,
      );
      expect(bloc.state.countdownSeconds, 0);
      expect(bloc.state.selectedSeats, isEmpty);
      expect(bloc.state.step, BookingStep.seatSelection);
      bloc.add(const TickCountdownEvent());
      await Future<void>.delayed(Duration.zero);
      expect(server.releases, 1);
      expect(server.bookingPosts, 0);
    },
  );

  test('rejected seventh seat keeps valid hold and deadline', () async {
    final server = CheckoutServer();
    final bloc = await ready(server, seatCount: 6);
    addTearDown(bloc.close);
    await dispatch(
      bloc,
      const PreviousStepEvent(),
      (s) => s.step == BookingStep.seatSelection,
    );
    await dispatch(
      bloc,
      ToggleSeatEvent(bloc.state.seatLayout!.lowerFloor[6]),
      (s) => s.errorMessage != null,
    );
    expect(server.releases, 0);
    expect(bloc.state.seatHold, isNotNull);
    server.now = server.now.add(const Duration(minutes: 2));
    await dispatch(
      bloc,
      const TickCountdownEvent(),
      (s) => s.countdownSeconds == 480,
    );
  });

  test(
    'concurrent hold requests only create once; late close response is released',
    () async {
      final server = CheckoutServer()..holdGate = Completer<void>();
      final bloc = BookingFlowBloc(
        seatRepository: server.seats,
        bookingRepository: server.real,
        now: () => server.now,
      );
      await dispatch(
        bloc,
        InitBookingFlowEvent(trip: trip, date: DateTime(2026, 11, 1)),
        (s) => s.status == BookingFlowStatus.loaded,
      );
      await dispatch(
        bloc,
        ToggleSeatEvent(bloc.state.seatLayout!.lowerFloor.first),
        (s) => s.selectedSeats.isNotEmpty,
      );
      bloc.add(const NextStepEvent());
      bloc.add(const NextStepEvent());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(server.holdPosts, 1);
      final closing = bloc.close();
      server.holdGate!.complete();
      await closing;
      expect(server.releases, 1);
    },
  );

  test('concurrent Confirm events only create one booking/payment', () async {
    final server = CheckoutServer();
    final bloc = await ready(server);
    addTearDown(bloc.close);
    final done = bloc.stream.firstWhere(
      (s) => s.status == BookingFlowStatus.paymentPending,
    );
    bloc.add(const ConfirmPaymentEvent());
    bloc.add(const ConfirmPaymentEvent());
    await done;
    expect(server.bookingPosts, 1);
    expect(server.paymentPosts, 1);
  });

  test(
    'Hybrid repository immediate SUCCESS resolves real full ticket via HTTP',
    () async {
      final server = CheckoutServer()..paymentState = 'SUCCESS';
      final ticket = await server.hybrid.createBooking(
        trip: TicketTripSummary(
          id: trip.id,
          operatorName: trip.operatorName,
          vehicleType: trip.vehicleType,
          departureTime: trip.departureTime,
          departureDate: '01/11/2026',
          arrivalTime: trip.arrivalTime,
          arrivalDate: '01/11/2026',
          fromCity: trip.fromCityName,
          toCity: trip.toCityName,
          pickupPoint: trip.pickupPoint,
          pickupAddress: '',
          dropoffPoint: trip.dropoffPoint,
          dropoffAddress: '',
        ),
        seats: ['A1'],
        seatIds: [1],
        holdToken: 'fixture-hold',
        totalAmount: 1,
        discountAmount: 0,
        finalAmount: 1,
        paymentMethod: 'momo',
        passenger: const PassengerInfo(
          fullName: 'Nguyen Van An',
          phone: '0901234567',
          email: 'an@example.com',
        ),
      );
      expect(ticket.id, '101');
      expect(ticket.ticketCode, 'VXG-PDV-42-A1');
      expect(ticket.canShowQr, isTrue);
      expect(server.ticketGets, 1);
    },
  );

  test('unknown seat status is unavailable, never selectable inventory', () {
    expect(
      SeatModel.fromJson({
        'tripSeatId': 1,
        'seatNumber': 'A1',
        'status': 'BAO_TRI',
      }).status,
      SeatStatus.unavailable,
    );
    expect(
      SeatModel.fromJson({'tripSeatId': 1, 'seatNumber': 'A1'}).isAvailable,
      isFalse,
    );
  });

  testWidgets(
    'DA_DAT before payment cannot render QR even via direct modal construction',
    (tester) async {
      final server = CheckoutServer()..unpaidTicket = true;
      final ticket = TicketModel.fromJson(server.ticket(101));
      expect(ticket.isPaid, isFalse);
      expect(ticket.canShowQr, isFalse);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BoardingPassCard(ticket: ticket),
            ),
          ),
        ),
      );
      expect(find.byType(QrImageView), findsNothing);
      await tester.pumpWidget(MaterialApp(home: TicketQrModal(ticket: ticket)));
      expect(find.byType(QrImageView), findsNothing);
    },
  );

  test(
    'unknown, cancelled and used ticket states never authorize a boarding QR',
    () {
      final server = CheckoutServer();
      for (final status in [
        'UNKNOWN',
        'HUY',
        'DA_HUY',
        'HET_HAN',
        'DA_SU_DUNG',
      ]) {
        final ticket = TicketModel.fromJson({
          ...server.ticket(101),
          'status': status,
        });
        expect(ticket.canShowQr, isFalse, reason: status);
      }
      expect(TicketModel.fromJson(server.ticket(101)).canShowQr, isTrue);
    },
  );
}
