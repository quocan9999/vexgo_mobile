import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/datasources/remote/booking_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/review_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/ticket_remote_data_source.dart';
import 'package:vexgo_app/data/models/review_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_state.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/review_bottom_sheet.dart';

// Contract fixtures from TicketsService/BookingsService at vexgo develop@045ba69.
// These are HTTP fixtures, not device E2E or real customer reviews.
Map<String, dynamic> flatTicket({int? tripId = 902}) => {
  'ticketId': 501,
  'ticketCode': 'TEST-TICKET-501',
  'bookingId': 101,
  'bookingCode': 'TEST-BOOKING-101',
  'tripId': tripId,
  'status': 'HOAN_TAT',
  'bookingStatus': 'HOAN_TAT',
  'paymentStatus': 'DA_THANH_TOAN',
  'busCompanyName': 'Contract fixture operator',
  'route': 'TP.HCM - Đà Lạt',
  'origin': 'TP.HCM',
  'destination': 'Đà Lạt',
  'departureTime': '2026-10-01T01:00:00.000Z',
  'seatNumber': 'A05',
  'price': 260000,
  'createdAt': '2026-09-29T01:00:00.000Z',
};

const submittedReview = ReviewModel(
  rating: 4,
  comment: '  Chuyến đi tốt  ',
  tags: ['Xe sạch sẽ'],
  createdAt: 'client-time-is-not-server-time',
);

class ReviewHarness {
  static const jsonHeaders = {
    'content-type': 'application/json; charset=utf-8',
  };
  Map<String, dynamic> ticket = flatTicket();
  Map<String, dynamic> booking = {
    'bookingId': 101,
    'bookingCode': 'TEST-BOOKING-101',
    'tripId': 902,
    'status': 'HOAN_TAT',
    'totalAmount': 260000,
  };
  Map<String, dynamic>? receiptOverride;
  int reviewStatus = 201;
  int bookingReads = 0;
  final posts = <Map<String, dynamic>>[];
  final reviewStarted = Completer<void>();
  Completer<void>? responseGate;
  late final ApiClient client = ApiClient(httpClient: MockClient(handle));
  late final repository = RealBookingRepository(
    remoteTicketDataSource: TicketRemoteDataSourceImpl(client: client),
    remoteBookingDataSource: BookingRemoteDataSourceImpl(client: client),
  );
  late final bloc = MyTicketsBloc(
    bookingRepository: repository,
    reviewRemoteDataSource: ReviewRemoteDataSourceImpl(client: client),
  );

  Future<http.Response> handle(http.Request request) async {
    expect(request.headers['Authorization'], 'Bearer fixture-access');
    if (request.method == 'GET' && request.url.path.endsWith('/tickets')) {
      return http.Response(
        jsonEncode({
          'data': [ticket],
          'meta': {'totalPages': 1},
        }),
        200,
        headers: jsonHeaders,
      );
    }
    if (request.method == 'GET' && request.url.path.endsWith('/bookings/101')) {
      bookingReads++;
      return http.Response(
        jsonEncode({'data': booking}),
        200,
        headers: jsonHeaders,
      );
    }
    if (request.method == 'POST' && request.url.path.endsWith('/reviews')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      posts.add(body);
      if (!reviewStarted.isCompleted) reviewStarted.complete();
      if (responseGate != null) await responseGate!.future;
      if (reviewStatus != 201) {
        return http.Response(
          jsonEncode({'message': 'Review rejected'}),
          reviewStatus,
          headers: jsonHeaders,
        );
      }
      return http.Response(
        jsonEncode({
          'data':
              receiptOverride ??
              {
                'reviewId': 71,
                'tripId': body['tripId'],
                'rating': body['rating'],
                'comment': (body['comment'] as String?)?.trim(),
                'createdAt': '2026-10-20T08:00:00.000Z',
                'status': 'HIEN_THI',
              },
        }),
        201,
        headers: jsonHeaders,
      );
    }
    throw StateError(
      'Unexpected fixture request: ${request.method} ${request.url.path}',
    );
  }

  Future<void> load() async {
    final done = bloc.stream.firstWhere(
      (s) =>
          s.status == MyTicketsStatus.loaded ||
          s.status == MyTicketsStatus.error,
    );
    bloc.add(const LoadMyTicketsEvent());
    final result = await done.timeout(const Duration(seconds: 3));
    if (result.status == MyTicketsStatus.error) {
      throw StateError(result.errorMessage!);
    }
  }

  Future<MyTicketsState> submit() async {
    final done = bloc.stream.firstWhere(
      (s) => s.errorMessage != null || s.successMessage != null,
    );
    bloc.add(
      const SubmitTicketReviewEvent(ticketId: '501', review: submittedReview),
    );
    return done.timeout(const Duration(seconds: 3));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(
      accessToken: 'fixture-access',
      refreshToken: 'fixture-refresh',
    );
  });
  tearDown(() {
    ApiConfig.isDemoMode = false;
    TokenStorage.resetStorageAdapter();
  });

  test(
    'flat merged contract maps the real trip ID and completed ticket status',
    () {
      final ticket = TicketModel.fromJson(flatTicket());
      expect(ticket.trip.id, '902');
      expect(ticket.status, TicketStatus.completed);
    },
  );

  test(
    'flat ticket HTTP -> one POST -> server receipt; reload never restores unsupported tags',
    () async {
      final h = ReviewHarness();
      addTearDown(h.bloc.close);
      await h.load();
      final result = await h.submit();
      expect(h.posts, [
        {'tripId': 902, 'rating': 4, 'comment': submittedReview.comment},
      ]);
      expect(h.bookingReads, 0);
      expect(result.errorMessage, isNull);
      final saved = result.tickets.single.review!;
      expect(saved.comment, 'Chuyến đi tốt');
      expect(saved.createdAt, '2026-10-20T08:00:00.000Z');
      expect(saved.tags, isEmpty);
      await h.load();
      // Current ticket API does not hydrate reviews; do not manufacture one on reload.
      expect(h.bloc.state.tickets.single.review, isNull);
      expect(h.posts, hasLength(1));
    },
  );

  test(
    'missing trip ID in both legacy flat responses fails without POST or success',
    () async {
      final h = ReviewHarness()..ticket = flatTicket(tripId: null);
      h.ticket.remove('tripId');
      h.booking.remove('tripId');
      addTearDown(h.bloc.close);
      await h.load();
      final result = await h.submit();
      expect(h.bookingReads, 1);
      expect(h.posts, isEmpty);
      expect(result.errorMessage, contains('Không thể xác định'));
      expect(result.successMessage, isNull);
      expect(result.tickets.single.review, isNull);
    },
  );

  test(
    'booking fallback uses its server trip ID only for the matching booking',
    () async {
      final h = ReviewHarness()..ticket = flatTicket(tripId: null);
      h.booking['tripId'] = 703;
      addTearDown(h.bloc.close);
      await h.load();
      await h.submit();
      expect(h.posts.single['tripId'], 703);
      expect(h.bookingReads, 1);
    },
  );

  test('mismatched booking identity cannot supply a review trip ID', () async {
    final h = ReviewHarness()..ticket = flatTicket(tripId: null);
    h.booking['bookingId'] = 999;
    addTearDown(h.bloc.close);
    await h.load();
    final result = await h.submit();
    expect(result.errorMessage, isNotNull);
    expect(result.successMessage, isNull);
    expect(h.posts, isEmpty);
  });

  for (final invalid in <Map<String, dynamic>>[
    {},
    {'reviewId': 0},
    {'tripId': 999},
    {'rating': 1},
    {'createdAt': 'not-a-date'},
    {'comment': 123},
  ]) {
    test(
      'invalid server receipt $invalid cannot become saved review',
      () async {
        final h = ReviewHarness()
          ..receiptOverride = invalid.isEmpty
              ? {}
              : {
                  'reviewId': 71,
                  'tripId': 902,
                  'rating': 4,
                  'comment': 'Saved',
                  'createdAt': '2026-10-20T08:00:00.000Z',
                  ...invalid,
                };
        addTearDown(h.bloc.close);
        await h.load();
        final result = await h.submit();
        expect(result.successMessage, isNull);
        expect(result.errorMessage, isNotNull);
        expect(result.tickets.single.review, isNull);
      },
    );
  }

  for (final status in [403, 409, 503]) {
    test(
      'HTTP $status does not save client tags or report success; retry is explicit',
      () async {
        final h = ReviewHarness()..reviewStatus = status;
        addTearDown(h.bloc.close);
        await h.load();
        final result = await h.submit();
        expect(result.successMessage, isNull);
        expect(result.tickets.single.review, isNull);
        expect(h.posts, hasLength(1));
        h.reviewStatus = 201;
        final retried = await h.submit();
        expect(retried.errorMessage, isNull);
        expect(retried.tickets.single.review!.tags, isEmpty);
        expect(h.posts, hasLength(2));
      },
    );
  }

  test('rapid repeated submit sends only one review POST', () async {
    final h = ReviewHarness()..responseGate = Completer<void>();
    addTearDown(h.bloc.close);
    await h.load();
    final finished = h.submit();
    await h.reviewStarted.future;
    h.bloc.add(
      const SubmitTicketReviewEvent(ticketId: '501', review: submittedReview),
    );
    await Future<void>.delayed(Duration.zero);
    expect(h.posts, hasLength(1));
    h.responseGate!.complete();
    expect((await finished).successMessage, isNotNull);
    expect(h.posts, hasLength(1));
  });

  test(
    'late review response after logout cannot restore another session ticket',
    () async {
      final h = ReviewHarness()..responseGate = Completer<void>();
      addTearDown(h.bloc.close);
      await h.load();
      h.bloc.add(
        const SubmitTicketReviewEvent(ticketId: '501', review: submittedReview),
      );
      await h.reviewStarted.future;
      h.bloc.setSession(null);
      h.responseGate!.complete();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(h.bloc.state.requiresLogin, isTrue);
      expect(h.bloc.state.tickets, isEmpty);
      expect(h.bloc.state.successMessage, isNull);
    },
  );

  for (final demo in [false, true]) {
    testWidgets(
      'review tags are ${demo ? 'available in Demo' : 'hidden in Real'} Mode',
      (tester) async {
        ApiConfig.isDemoMode = demo;
        final h = ReviewHarness();
        addTearDown(h.bloc.close);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReviewBottomSheet(
                ticket: TicketModel.fromJson(flatTicket()),
                bloc: h.bloc,
              ),
            ),
          ),
        );
        expect(find.byType(FilterChip), demo ? findsNWidgets(6) : findsNothing);
        expect(
          find.text('Điểm bạn hài lòng nhất'),
          demo ? findsOneWidget : findsNothing,
        );
        expect(find.text('Nhận xét chi tiết'), findsOneWidget);
      },
    );
  }
}
