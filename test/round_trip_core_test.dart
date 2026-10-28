import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/network/vietqr_config.dart';
import 'package:vexgo_app/data/datasources/remote/booking_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/seat_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/ticket_remote_data_source.dart';
import 'package:vexgo_app/data/models/city_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/payment_display_state.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_search_cubit.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_checkout_cubit.dart';

const origin = CityModel(id: 'hcm', name: 'HCM', region: '', isPopular: false);
const destination = CityModel(
  id: 'dalat',
  name: 'Da Lat',
  region: '',
  isPopular: false,
);
RoundTripRequest request({DateTime? back}) => RoundTripRequest(
  origin: origin,
  destination: destination,
  departureDate: DateTime(2026, 11, 10),
  returnDate: back ?? DateTime(2026, 11, 11),
);
TripModel trip(int id, {String? departure, String? arrival}) =>
    TripModel.fromJson({
      'id': id.toString(),
      'operatorName': 'Fixture operator',
      'vehicleType': 'Limousine',
      'fromCityId': id == 101 ? 'hcm' : 'dalat',
      'fromCityName': id == 101 ? 'HCM' : 'Da Lat',
      'toCityId': id == 101 ? 'dalat' : 'hcm',
      'toCityName': id == 101 ? 'Da Lat' : 'HCM',
      'departureTime':
          departure ??
          (id == 101 ? '2026-11-10T01:00:00Z' : '2026-11-11T02:00:00Z'),
      'arrivalTime':
          arrival ??
          (id == 101 ? '2026-11-10T08:00:00Z' : '2026-11-11T09:00:00Z'),
      'pickupPoint': 'Pickup-$id',
      'dropoffPoint': 'Dropoff-$id',
      'originalPrice': id == 101 ? 190000 : 260000,
      'availableSeats': 8,
    });

/// Native repositories/parsers/BLoCs, with an HTTP fixture, never live E2E.
class Server {
  DateTime now = DateTime.utc(2026, 11, 1);
  final posts = <Map<String, dynamic>>[];
  final started = <int, Completer<void>>{};
  final headers = <String?>[];
  final releases = <String>[];
  final paid = <int>{};
  final orders = <int, Map<String, dynamic>>{};
  final reject = <int>{};
  final lose = <int>{};
  final quoteErrors = <int>{};
  final quoteGates = <int, Completer<void>>{};
  final readErrors = <int>{};
  final ticketErrors = <int>{};
  final gates = <int, Completer<void>>{};
  final holdGates = <int, Completer<void>>{};
  final readGates = <int, Completer<void>>{};
  bool wrongReadAmount = false;
  bool duplicateOrderCode = false;
  late final transport = MockClient(handle);
  late final client = ApiClient(httpClient: transport);
  late final bookings = RealBookingRepository(
    remoteBookingDataSource: BookingRemoteDataSourceImpl(client: client),
    remoteTicketDataSource: TicketRemoteDataSourceImpl(client: client),
  );
  late final seats = RealSeatRepository(
    remoteDataSource: SeatRemoteDataSourceImpl(client: client),
  );
  int price(int id) => id == 101 ? 190000 : 260000;
  http.Response response(Object data, [int code = 200]) => http.Response(
    jsonEncode({'data': data}),
    code,
    headers: {'content-type': 'application/json'},
  );
  Future<http.Response> handle(http.Request req) async {
    final path = req.url.path.replaceFirst('/api/v1', '');
    final body = req.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(req.body) as Map<String, dynamic>;
    if (RegExp(r'^/trips/\d+/seats$').hasMatch(path)) {
      final id = int.parse(path.split('/')[2]);
      return response(
        List.generate(
          6,
          (i) => {
            'tripSeatId': id * 10 + i + 1,
            'seatNumber': 'A0${i + 1}',
            'status': 'TRONG',
            'price': price(id),
            'floor': 1,
          },
        ),
      );
    }
    if (path == '/seat-holds' && req.method == 'POST') {
      final id = body['tripId'] as int;
      await holdGates[id]?.future;
      return response({
        'holdToken': 'hold-$id',
        'tripId': id,
        'seatIds': body['seatIds'],
        'expiresAt': now.add(const Duration(minutes: 10)).toIso8601String(),
      });
    }
    if (path == '/seat-holds' && req.method == 'DELETE') {
      releases.add(body['holdToken'] as String);
      return response({'released': true});
    }
    if (path == '/bookings/quote') {
      final id = body['tripId'] as int;
      await quoteGates[id]?.future;
      if (quoteErrors.contains(id)) return response({}, 409);
      final count = (body['seatIds'] as List).length;
      final discount = body['promotionCode'] == 'SAVE10' ? 10000 : 0;
      return response({
        'unitPrice': '${price(id)}.00',
        'seatCount': count,
        'originalTotal': '${price(id) * count}.00',
        'discountAmount': '$discount.00',
        'finalTotal': '${price(id) * count - discount}.00',
        'currency': 'VND',
        'identityChecked': true,
        'phoneEligibilityChecked': true,
        if (discount > 0) 'appliedPromotionCode': 'SAVE10',
      });
    }
    if (path == '/bookings' && req.method == 'POST') {
      posts.add(body);
      headers.add(req.headers['authorization']);
      final id = body['tripId'] as int;
      final signal = started.putIfAbsent(id, () => Completer<void>());
      if (!signal.isCompleted) signal.complete();
      await gates[id]?.future;
      if (reject.contains(id)) return response({}, 409);
      final bookingId = id + 900;
      final count = (body['seatIds'] as List).length;
      orders[bookingId] = {
        'bookingId': bookingId,
        'bookingCode': 'B-$bookingId',
        'tripId': id,
        'status': 'CHO_THANH_TOAN',
        'paymentStatus': 'CHO_THANH_TOAN',
        'contact': body['contact'],
        'pickupPoint': body['pickupPoint'],
        'dropoffPoint': body['dropoffPoint'],
        'seatIds': body['seatIds'],
        'seats': ['A01'],
        'totalAmount':
            price(id) * count - (body['promotionCode'] == 'SAVE10' ? 10000 : 0),
        'orderCode': duplicateOrderCode ? 'ORDER-1001' : 'ORDER-$bookingId',
        'ticketCount': count,
        'expiresAt': now.add(const Duration(minutes: 10)).toIso8601String(),
      };
      if (lose.contains(id)) {
        throw const SocketException('Lost POST response after commit');
      }
      return response(orders[bookingId]!);
    }
    if (path.startsWith('/bookings/')) {
      final id = int.parse(path.split('/')[2]);
      await readGates[id]?.future;
      if (readErrors.contains(id)) {
        throw const SocketException('read unavailable');
      }
      final order = {...orders[id]!};
      if (wrongReadAmount) order['totalAmount'] = 1;
      if (paid.contains(id)) {
        order['status'] = 'DA_THANH_TOAN';
        order['paymentStatus'] = 'DA_THANH_TOAN';
        order['tickets'] = [
          {'ticketId': id + 1000, 'ticketCode': 'T-$id'},
        ];
      }
      return response(order);
    }
    if (path.startsWith('/tickets/')) {
      final ticketId = int.parse(path.split('/')[2]);
      final id = ticketId - 1000;
      if (ticketErrors.contains(id)) return response({}, 404);
      return response({
        'ticketId': ticketId,
        'ticketCode': 'T-$id',
        'bookingId': id,
        'bookingCode': 'B-$id',
        'origin': 'Origin',
        'destination': 'Destination',
        'busCompanyName': 'Fixture operator',
        'vehicleType': 'Limousine',
        'departureTime': '2026-11-10T01:00:00Z',
        'arrivalTime': '2026-11-10T08:00:00Z',
        'seatNumber': 'A01',
        'price': price(id - 900),
        'status': 'DA_DAT',
        'bookingStatus': 'DA_THANH_TOAN',
        'paymentStatus': 'DA_THANH_TOAN',
        'passengerName': 'Fixture User',
        'passengerPhone': '0901234567',
        'pickup': 'Pickup',
        'dropoff': 'Dropoff',
        'cancellation': {
          'eligible': true,
          'cancelFeeRate': 0.2,
          'cancelFee': 38000,
          'refundAmount': 152000,
        },
      });
    }
    throw StateError('Unexpected fixture request ${req.method} $path');
  }

  RoundTripCheckoutCubit checkout() => RoundTripCheckoutCubit(
    receivingAccount: const VietQrReceivingAccount(
      bankId: 'MB',
      accountNumber: '0000000001',
      accountName: 'SANDBOX',
    ),
    request: request(),
    outbound: trip(101),
    inbound: trip(102),
    seatRepository: seats,
    bookingRepository: bookings,
    now: () => now,
  );
}

Future<void> until(
  RoundTripCheckoutCubit c,
  bool Function(RoundTripCheckoutState) predicate,
) async {
  if (predicate(c.state) && !c.state.busy) return;
  await c.stream
      .firstWhere((s) => predicate(s) && !s.busy)
      .timeout(const Duration(seconds: 3));
}

Future<void> command(
  RoundTripCheckoutCubit c,
  TripLeg leg,
  BookingFlowEvent event,
  bool Function(BookingFlowState) predicate,
) async {
  expect(c.dispatch(leg, event), isTrue);
  await until(c, (s) => predicate(s.leg(leg)));
}

Future<void> ready(RoundTripCheckoutCubit c) async {
  await until(
    c,
    (s) =>
        s.outbound.status == BookingFlowStatus.loaded &&
        s.inbound.status == BookingFlowStatus.loaded,
  );
  expect(
    c.updatePassenger(
      const UpdatePassengerInfoEvent(
        name: 'Fixture User',
        phone: '0901234567',
        email: 'fixture@example.com',
      ),
    ),
    isTrue,
  );
  await until(
    c,
    (s) => s.outbound.isPassengerValid && s.inbound.isPassengerValid,
  );
  for (final leg in TripLeg.values) {
    await command(
      c,
      leg,
      ToggleSeatEvent(c.state.leg(leg).seatLayout!.lowerFloor.first),
      (s) => s.selectedSeats.length == 1,
    );
    await command(
      c,
      leg,
      const NextStepEvent(),
      (s) => s.step == BookingStep.pickupPoint,
    );
    await command(
      c,
      leg,
      const NextStepEvent(),
      (s) => s.step == BookingStep.dropoffPoint,
    );
    await command(
      c,
      leg,
      const NextStepEvent(),
      (s) => s.step == BookingStep.passengerInfo,
    );
    await command(
      c,
      leg,
      const NextStepEvent(),
      (s) =>
          s.step == BookingStep.tripSummary &&
          s.quote != null &&
          !s.quoteLoading,
    );
    await command(
      c,
      leg,
      const NextStepEvent(),
      (s) => s.step == BookingStep.payment,
    );
  }
}

class SearchRepository extends MockTripRepository {
  final calls = <String>[];
  Completer<List<TripModel>>? first;
  bool failReturn = false;
  @override
  Future<List<TripModel>> searchTrips({
    required String fromCityId,
    required String toCityId,
    String? date,
  }) async {
    calls.add('$fromCityId/$toCityId/$date');
    if (first != null && calls.length == 1) return first!.future;
    if (failReturn && fromCityId == 'dalat') {
      throw const SocketException('offline');
    }
    return [trip(fromCityId == 'hcm' ? 101 : 102)];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(accessToken: 'fixture-owner');
  });
  tearDown(() async {
    await TokenStorage.clearTokens();
    TokenStorage.resetStorageAdapter();
  });

  test('route preserves return date and rejects invalid calendar/count', () {
    final r = RoundTripRequest.fromRoute(
      query: {
        'fromCityId': 'hcm',
        'toCityId': 'dalat',
        'date': '2026-11-10',
        'returnDate': '2026-11-11',
        'ticketCount': '5',
      },
    );
    expect(r.ticketCount, 5);
    expect(r.returnDate.day, 11);
    expect(
      () => RoundTripRequest.fromRoute(
        query: {
          'fromCityId': 'hcm',
          'toCityId': 'dalat',
          'date': '2026-02-30',
          'returnDate': '2026-11-11',
        },
      ),
      throwsArgumentError,
    );
    expect(() => request(back: DateTime(2026, 11, 9)), throwsArgumentError);
    expect(
      () => RoundTripRequest(
        origin: origin,
        destination: destination,
        departureDate: DateTime(2026, 11, 10),
        returnDate: DateTime(2026, 11, 11),
        ticketCount: 6,
      ),
      throwsArgumentError,
    );
  });
  test(
    'pair rejects same-day overlap and accepts sufficient time after overnight arrival',
    () {
      final sameDay = request(back: DateTime(2026, 11, 10));
      expect(
        sameDay.acceptsPair(
          trip(101),
          trip(102, departure: '2026-11-10T07:00:00Z'),
        ),
        isFalse,
      );
      expect(
        sameDay.acceptsPair(
          trip(101),
          trip(102, departure: '2026-11-10T09:00:00Z'),
        ),
        isTrue,
      );
      expect(
        request().acceptsPair(
          trip(101, arrival: '2026-11-11T03:00:00Z'),
          trip(102),
        ),
        isFalse,
      );
      expect(request().accepts(TripLeg.inbound, trip(101)), isFalse);
    },
  );
  test(
    'search calls reverse route/date and keeps successful leg when the other fails',
    () async {
      final repo = SearchRepository()..failReturn = true;
      final c = RoundTripSearchCubit(repo);
      addTearDown(c.close);
      await c.search(request());
      expect(repo.calls, ['hcm/dalat/2026-11-10', 'dalat/hcm/2026-11-11']);
      expect(c.state.outboundTrips.length, 1);
      expect(c.state.inboundError, isNotNull);
      expect(c.state.canContinue, isFalse);
    },
  );
  test('old search response cannot replace a newer request', () async {
    final repo = SearchRepository()..first = Completer();
    final c = RoundTripSearchCubit(repo);
    addTearDown(c.close);
    final old = c.search(request());
    await Future<void>.delayed(Duration.zero);
    await c.search(request(back: DateTime(2026, 11, 12)));
    repo.first!.complete([trip(101)]);
    await old;
    expect(c.state.request!.returnDate.day, 12);
    expect(c.state.inboundTrips, isEmpty);
    expect(c.state.outboundLoading, isFalse);
  });
  test(
    'selection accepts only result members and requires both valid trips',
    () async {
      final c = RoundTripSearchCubit(SearchRepository());
      addTearDown(c.close);
      await c.search(request());
      expect(c.select(TripLeg.inbound, trip(101)), isFalse);
      expect(c.select(TripLeg.outbound, c.state.outboundTrips.first), isTrue);
      expect(c.state.canContinue, isFalse);
      expect(c.select(TripLeg.inbound, c.state.inboundTrips.first), isTrue);
      expect(c.state.canContinue, isTrue);
    },
  );

  test(
    'two distinct holds/orders/prices, authenticated payload and no duplicate submit',
    () async {
      final s = Server();
      final c = s.checkout();
      addTearDown(c.close);
      await ready(c);
      await c.submit();
      await c.submit();
      expect(s.posts.length, 2);
      expect(s.headers, everyElement('Bearer fixture-owner'));
      expect(s.posts[0]['holdToken'], 'hold-101');
      expect(s.posts[1]['holdToken'], 'hold-102');
      expect(s.posts[0]['seatIds'], [1011]);
      expect(s.posts[1]['seatIds'], [1021]);
      expect(c.state.totalAmount, 450000);
      expect(c.state.phase, RoundTripPhase.paymentPending);
      expect(c.state.outbound.checkoutBooking!.orderCode, 'ORDER-1001');
      expect(c.state.inbound.checkoutBooking!.orderCode, 'ORDER-1002');
      expect(c.state.outbound.canDisplayBankTransfer(s.now), isTrue);
      expect(c.state.inbound.canDisplayBankTransfer(s.now), isTrue);
      expect(
        c.state.outbound.pendingQrCodeUrl,
        isNot(c.state.inbound.pendingQrCodeUrl),
      );
      expect(
        c.dispatch(TripLeg.outbound, const ConfirmPaymentEvent()),
        isFalse,
      );
    },
  );
  test('double tap and recheck during submit produce only two POSTs', () async {
    final s = Server()..gates[101] = Completer();
    final c = s.checkout();
    addTearDown(c.close);
    await ready(c);
    final first = c.submit();
    await s.started
        .putIfAbsent(101, () => Completer<void>())
        .future
        .timeout(const Duration(seconds: 3));
    await c.submit();
    await c.recheck(TripLeg.inbound);
    expect(
      c.updatePassenger(
        const UpdatePassengerInfoEvent(
          name: 'Other',
          phone: '0901234567',
          email: '',
        ),
      ),
      isFalse,
    );
    s.gates[101]!.complete();
    await first;
    expect(s.posts.length, 2);
  });
  test(
    'return rejection retains outbound; explicit retry creates only return',
    () async {
      final s = Server()..reject.add(102);
      final c = s.checkout();
      addTearDown(c.close);
      await ready(c);
      await c.submit();
      expect(c.state.phase, RoundTripPhase.partiallyCreated);
      expect(c.state.outbound.pendingBookingId, 1001);
      expect(c.state.inbound.pendingBookingId, isNull);
      expect(c.state.hasUnknownOutcome, isFalse);
      await c.recheck(TripLeg.inbound);
      expect(s.posts.length, 2);
      s.reject.clear();
      // A definite rejection is editable; re-enter payment after reviewing the quote.
      await command(
        c,
        TripLeg.inbound,
        const PreviousStepEvent(),
        (state) => state.step == BookingStep.tripSummary,
      );
      await command(
        c,
        TripLeg.inbound,
        const NextStepEvent(),
        (state) => state.step == BookingStep.payment,
      );
      await c.submit();
      expect(s.posts.map((p) => p['tripId']), [101, 102, 102]);
      expect(c.state.hasBothOrders, isTrue);
    },
  );
  for (final lostTrip in [101, 102]) {
    test('lost POST response for $lostTrip is never replayed', () async {
      final s = Server()..lose.add(lostTrip);
      final c = s.checkout();
      addTearDown(c.close);
      await ready(c);
      await c.submit();
      expect(c.state.phase, RoundTripPhase.verificationRequired);
      final count = s.posts.length;
      await c.submit();
      await c.recheck(lostTrip == 101 ? TripLeg.outbound : TripLeg.inbound);
      expect(s.posts.length, count);
      expect(
        s.orders.length,
        count,
      ); // server committed despite missing response
      if (lostTrip == 102) {
        await c.recheck(TripLeg.outbound);
        expect(c.state.outbound.pendingBookingId, 1001);
      }
    });
  }
  test(
    'one paid leg does not complete round trip; recheck never recreates orders',
    () async {
      final s = Server();
      final c = s.checkout();
      addTearDown(c.close);
      await ready(c);
      await c.submit();
      s.paid.add(1001);
      await c.recheck(TripLeg.outbound);
      expect(c.state.outbound.createdTickets.length, 1);
      expect(c.state.phase, RoundTripPhase.partiallyPaid);
      expect(c.state.isComplete, isFalse);
      s.paid.add(1002);
      await c.recheck(TripLeg.inbound);
      expect(c.state.isComplete, isTrue);
      expect(c.state.phase, RoundTripPhase.success);
      expect(s.posts.length, 2);
    },
  );
  test(
    'paid but ticket hydration failed remains recoverable without duplicate create',
    () async {
      final s = Server();
      final c = s.checkout();
      addTearDown(c.close);
      await ready(c);
      await c.submit();
      s.paid.add(1001);
      s.ticketErrors.add(1001);
      await c.recheck(TripLeg.outbound);
      expect(c.state.outbound.paymentConfirmed, isTrue);
      expect(c.state.outbound.createdTickets, isEmpty);
      expect(c.state.isComplete, isFalse);
      s.ticketErrors.clear();
      await c.recheck(TripLeg.outbound);
      expect(c.state.outbound.createdTickets.length, 1);
      expect(s.posts.length, 2);
    },
  );
  test(
    'expired second hold while first POST runs stops second create',
    () async {
      final s = Server()..gates[101] = Completer();
      final c = s.checkout();
      addTearDown(c.close);
      await ready(c);
      final first = c.submit();
      await s.started
          .putIfAbsent(101, () => Completer<void>())
          .future
          .timeout(const Duration(seconds: 3));
      s.now = s.now.add(const Duration(minutes: 11));
      s.gates[101]!.complete();
      await first;
      expect(s.posts.length, 1);
      expect(c.state.outbound.pendingBookingId, 1001);
      expect(c.state.inbound.pendingBookingId, isNull);
    },
  );
  test(
    'session switch during POST hides state and prevents return creation',
    () async {
      final s = Server()..gates[101] = Completer();
      final c = s.checkout();
      addTearDown(c.close);
      await ready(c);
      final first = c.submit();
      await s.started
          .putIfAbsent(101, () => Completer<void>())
          .future
          .timeout(const Duration(seconds: 3));
      await TokenStorage.saveTokens(accessToken: 'other-owner');
      expect(c.state.phase, RoundTripPhase.invalidated);
      expect(c.state.outbound.passengerPhone, isEmpty);
      s.gates[101]!.complete();
      await first;
      expect(s.posts.length, 1);
      expect(c.state.outbound.pendingBookingId, isNull);
      expect(c.dispatch(TripLeg.inbound, const NextStepEvent()), isFalse);
    },
  );
  test(
    'each accepted promotion sends its own expected quote to create API',
    () async {
      final s = Server();
      final c = s.checkout();
      addTearDown(c.close);
      await ready(c);
      for (final leg in TripLeg.values) {
        await command(
          c,
          leg,
          const ApplyPromotionCodeEvent('SAVE10'),
          (state) =>
              state.quote?.discountAmount == 10000 && !state.quoteLoading,
        );
      }
      await c.submit();
      expect(s.posts[0]['expectedPromotionQuote'], {
        'originalTotal': '190000',
        'discountAmount': '10000',
        'finalTotal': '180000',
      });
      expect(s.posts[1]['expectedPromotionQuote'], {
        'originalTotal': '260000',
        'discountAmount': '10000',
        'finalTotal': '250000',
      });
      expect(c.state.totalAmount, 430000);
    },
  );
  test('unusable quote on either leg blocks both create requests', () async {
    final s = Server();
    final c = s.checkout();
    addTearDown(c.close);
    await ready(c);
    s.quoteErrors.add(102);
    await command(
      c,
      TripLeg.inbound,
      const RefreshBookingQuoteEvent(),
      (state) => state.quoteError != null && !state.quoteLoading,
    );
    await c.submit();
    expect(s.posts, isEmpty);
    expect(c.state.totalAmount, isNull);
  });
  test('tampered payment amount never enables QR or reports success', () async {
    final s = Server()..wrongReadAmount = true;
    final c = s.checkout();
    addTearDown(c.close);
    await ready(c);
    await c.submit();
    expect(c.state.outbound.pendingBookingId, 1001);
    expect(c.state.outbound.paymentConfirmed, isFalse);
    expect(c.state.outbound.canDisplayBankTransfer(s.now), isFalse);
    expect(s.posts.length, 1);
    expect(c.state.isComplete, isFalse);
  });
  test(
    'closing an unsubmitted flow releases both holds without creating bookings',
    () async {
      final s = Server();
      final c = s.checkout();
      await ready(c);
      await c.close();
      expect(s.releases, containsAll(['hold-101', 'hold-102']));
      expect(s.posts, isEmpty);
    },
  );
  test('initial total is unknown and not a fabricated free order', () async {
    final s = Server();
    final c = s.checkout();
    addTearDown(c.close);
    expect(c.state.totalAmount, isNull);
    await until(
      c,
      (s) =>
          s.outbound.status == BookingFlowStatus.loaded &&
          s.inbound.status == BookingFlowStatus.loaded,
    );
    expect(c.state.totalAmount, isNull);
  });
  test(
    'both legs enforce five seats and reject cross-leg stop selection',
    () async {
      final s = Server();
      final c = s.checkout();
      addTearDown(c.close);
      await until(
        c,
        (s) =>
            s.outbound.status == BookingFlowStatus.loaded &&
            s.inbound.status == BookingFlowStatus.loaded,
      );
      for (final leg in TripLeg.values) {
        final inventory = c.state.leg(leg).seatLayout!.lowerFloor;
        for (var i = 0; i < 5; i++) {
          await command(
            c,
            leg,
            ToggleSeatEvent(inventory[i]),
            (s) => s.selectedSeats.length == i + 1,
          );
        }
        await command(
          c,
          leg,
          ToggleSeatEvent(inventory[5]),
          (s) => s.errorMessage != null,
        );
        expect(c.state.leg(leg).selectedSeats.length, 5);
      }
      expect(
        c.dispatch(
          TripLeg.outbound,
          SelectPickupPointEvent(c.state.inbound.availablePickupPoints.first),
        ),
        isFalse,
      );
      expect(s.posts, isEmpty);
    },
  );
  test(
    'known order read failure must reconcile before creating remaining leg',
    () async {
      final s = Server()..readErrors.add(1001);
      final c = s.checkout();
      addTearDown(c.close);
      await ready(c);
      await c.submit();
      await c.submit();
      expect(s.posts.length, 1);
      expect(c.state.phase, RoundTripPhase.verificationRequired);
      s.readErrors.clear();
      await c.recheck(TripLeg.outbound);
      await c.submit();
      expect(s.posts.map((p) => p['tripId']), [101, 102]);
    },
  );
  test(
    'duplicate order codes fail closed for both transfer instructions',
    () async {
      final s = Server()..duplicateOrderCode = true;
      final c = s.checkout();
      addTearDown(c.close);
      await ready(c);
      await c.submit();
      expect(c.state.ordersConflict, isTrue);
      expect(c.state.isComplete, isFalse);
      expect(c.state.phase, RoundTripPhase.verificationRequired);
      expect(c.state.canDisplayTransfer(TripLeg.outbound, s.now), isFalse);
      expect(c.state.canDisplayTransfer(TripLeg.inbound, s.now), isFalse);
      expect(c.state.totalAmount, isNull);
    },
  );
  test(
    'payment expiry hides QR on wall clock without a POST or timer tick',
    () async {
      final s = Server();
      final c = s.checkout();
      addTearDown(c.close);
      await ready(c);
      await c.submit();
      expect(c.state.canDisplayTransfer(TripLeg.outbound, s.now), isTrue);
      s.now = s.now.add(const Duration(minutes: 11));
      expect(c.state.canDisplayTransfer(TripLeg.outbound, s.now), isFalse);
      await c.recheck(TripLeg.outbound);
      expect(s.posts.length, 2);
    },
  );
  test(
    'session replacement during read cannot hydrate tickets or leak prior payload',
    () async {
      final s = Server();
      final c = s.checkout();
      addTearDown(c.close);
      await ready(c);
      await c.submit();
      s.paid.add(1001);
      s.readGates[1001] = Completer();
      final reading = c.recheck(TripLeg.outbound);
      await Future<void>.delayed(Duration.zero);
      await TokenStorage.saveTokens(accessToken: 'replacement');
      s.readGates[1001]!.complete();
      await reading;
      expect(c.state.invalidated, isTrue);
      expect(c.state.outbound.createdTickets, isEmpty);
      expect(c.state.outbound.checkoutBooking, isNull);
      expect(s.posts.length, 2);
    },
  );
  test('leaving while a hold is in flight releases that late hold', () async {
    final s = Server()..holdGates[101] = Completer();
    final c = s.checkout();
    await until(
      c,
      (s) =>
          s.outbound.status == BookingFlowStatus.loaded &&
          s.inbound.status == BookingFlowStatus.loaded,
    );
    await command(
      c,
      TripLeg.outbound,
      ToggleSeatEvent(c.state.outbound.seatLayout!.lowerFloor.first),
      (s) => s.selectedSeats.length == 1,
    );
    c.dispatch(TripLeg.outbound, const NextStepEvent());
    await c.stream.firstWhere(
      (s) => s.outbound.status == BookingFlowStatus.loading,
    );
    final closing = c.close();
    await Future<void>.delayed(Duration.zero);
    s.holdGates[101]!.complete();
    await closing;
    expect(s.releases, contains('hold-101'));
    expect(s.posts, isEmpty);
  });
  test(
    'changing selected outbound can clear old inbound without refetching',
    () async {
      final c = RoundTripSearchCubit(SearchRepository());
      addTearDown(c.close);
      await c.search(request());
      c.select(TripLeg.outbound, c.state.outboundTrips.first);
      c.select(TripLeg.inbound, c.state.inboundTrips.first);
      expect(c.state.canContinue, isTrue);
      c.clearSelection(TripLeg.inbound);
      expect(c.state.canContinue, isFalse);
      expect(c.state.outbound, isNotNull);
      expect(c.state.inboundTrips.length, 1);
    },
  );
  test(
    'queued promotion edit blocks immediate submit until quote completes',
    () async {
      final s = Server();
      final c = s.checkout();
      addTearDown(c.close);
      await ready(c);
      s.quoteGates[101] = Completer();
      expect(
        c.dispatch(TripLeg.outbound, const ApplyPromotionCodeEvent('SAVE10')),
        isTrue,
      );
      expect(c.state.busy, isTrue);
      await c.submit();
      expect(s.posts, isEmpty);
      await c.stream.firstWhere((state) => state.outbound.quoteLoading);
      s.quoteGates[101]!.complete();
      await until(c, (state) => state.outbound.quote?.discountAmount == 10000);
      await c.submit();
      expect(s.posts.length, 2);
      expect(s.posts.first['expectedPromotionQuote'], {
        'originalTotal': '190000',
        'discountAmount': '10000',
        'finalTotal': '180000',
      });
    },
  );
  test('missing receiving config fails before any booking POST', () async {
    final s = Server();
    final c = RoundTripCheckoutCubit(
      request: request(),
      outbound: trip(101),
      inbound: trip(102),
      seatRepository: s.seats,
      bookingRepository: s.bookings,
      receivingAccount: const VietQrReceivingAccount(
        bankId: '',
        accountNumber: '',
        accountName: '',
      ),
      now: () => s.now,
    );
    addTearDown(c.close);
    await ready(c);
    await c.submit();
    expect(s.posts, isEmpty);
    expect(c.state.outbound.status, BookingFlowStatus.failure);
    expect(c.state.hasUnknownOutcome, isFalse);
  });
  test('local city codes match canonical Backend route names', () {
    final r = RoundTripRequest(
      origin: const CityModel(
        id: 'HCM',
        name: 'TP. Hồ Chí Minh',
        region: '',
        isPopular: false,
      ),
      destination: const CityModel(
        id: 'DL',
        name: 'Đà Lạt',
        region: '',
        isPopular: false,
      ),
      departureDate: DateTime(2026, 11, 10),
      returnDate: DateTime(2026, 11, 11),
    );
    final t = TripModel.fromJson({
      'id': '101',
      'origin': 'TP.HCM',
      'route': {'origin': 'TP.HCM', 'destination': 'Đà Lạt'},
      'departureTime': '2026-11-10T01:00:00Z',
      'availableSeats': 10,
    });
    expect(r.accepts(TripLeg.outbound, t), isTrue);
    expect(
      () => RoundTripRequest(
        origin: const CityModel(
          id: 'HCM',
          name: 'TP.HCM',
          region: '',
          isPopular: false,
        ),
        destination: const CityModel(
          id: 'SG',
          name: 'Sài Gòn',
          region: '',
          isPopular: false,
        ),
        departureDate: DateTime(2026, 11, 10),
        returnDate: DateTime(2026, 11, 11),
      ),
      throwsArgumentError,
    );
    final selected = RoundTripSelection(
      request: request(),
      outbound: trip(101),
      inbound: trip(102),
    );
    expect(selected.inbound.numericTripId, 102);
  });
}
