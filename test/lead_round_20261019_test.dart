import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/widgets/rating_badge.dart';
import 'package:vexgo_app/data/datasources/remote/notification_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/ticket_remote_data_source.dart';
import 'package:vexgo_app/data/models/notification_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/notification_repository.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/ticket_read_cubit.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/guest_ticket_lookup_panel.dart';
import 'package:vexgo_app/features/user/notification/bloc/notification_bloc.dart';
import 'package:vexgo_app/features/user/notification/bloc/notification_event.dart';
import 'package:vexgo_app/features/user/notification/presentation/screens/notifications_screen.dart';
import 'package:vexgo_app/features/user/search_trips/bloc/search_trips_bloc.dart';
import 'package:vexgo_app/features/user/search_trips/bloc/search_trips_event.dart';
import 'package:vexgo_app/features/user/search_trips/bloc/search_trips_state.dart';
import 'package:vexgo_app/features/user/search_trips/data/models/trip_filter_model.dart';
import 'package:vexgo_app/features/user/search_trips/presentation/widgets/trip_card.dart';
import 'qa/qa_fixtures.dart';

// Isolated HTTP fixtures through real data sources/repositories; no live
// cancellation, refund, bank transaction or customer account is used here.
http.Response reply(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

class GuestHarness {
  int lookups = 0;
  final posts = <Map<String, dynamic>>[];
  double rate = .1;
  bool eligible = true;
  bool cancelled = false;
  bool lookupFails = false;
  bool quoteExpires = false;
  bool wrongResponse = false;
  bool unknownPost = false;
  bool staleReadAfterCancel = false;
  bool failedReadAfterCancel = false;
  Completer<void>? pendingPost;
  late final client = ApiClient(httpClient: MockClient(handle));
  late final owner = MyTicketsBloc(
    authenticated: false,
    bookingRepository: RealBookingRepository(
      remoteTicketDataSource: TicketRemoteDataSourceImpl(client: client),
    ),
  )..setSession(null);
  late final reader = TicketReadCubit(owner: owner);

  Future<http.Response> handle(http.Request request) async {
    expect(request.headers['authorization'], isNull);
    expect(request.method, 'POST');
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['ticketCode'], 'TICKET-AUTH-91');
    expect(body['phoneNumber'], '0901234567');
    if (request.url.path.endsWith('/tickets/lookup')) {
      lookups++;
      if (lookupFails || (cancelled && failedReadAfterCancel)) {
        return reply({'message': 'offline'}, 503);
      }
      return reply({
        'data': {
          ...qaTicketJson(),
          'status': cancelled && !staleReadAfterCancel
              ? 'HUY'
              : 'DA_THANH_TOAN',
          'cancellation': {
            'eligible': eligible && !cancelled,
            'reason': eligible ? null : 'Ngoài thời hạn hủy trực tuyến.',
            'cancelFeeRate': rate,
            'cancelFee': rate == .1 ? 25000 : 50000,
            'refundAmount': rate == .1 ? 225000 : 200000,
          },
        },
      });
    }
    expect(request.url.path.endsWith('/tickets/cancel'), true);
    posts.add(body);
    if (pendingPost != null) await pendingPost!.future;
    if (quoteExpires) {
      rate = .2;
      return reply({
        'error': 'CANCELLATION_QUOTE_EXPIRED',
        'message': 'Phí đã đổi',
      }, 409);
    }
    if (!wrongResponse) cancelled = true;
    if (unknownPost) throw TimeoutException('unknown POST result');
    return reply({
      'data': {
        'ticketId': wrongResponse ? 999 : 91,
        'ticketCode': wrongResponse ? 'OTHER-TICKET' : 'TICKET-AUTH-91',
        'status': 'HUY',
        'refundAmount': 225000,
      },
    }, 201);
  }

  Future<void> lookup() =>
      reader.lookup(ticketCode: 'TICKET-AUTH-91', phoneNumber: '0901234567');
  Future<void> close() async {
    await reader.close();
    await owner.close();
  }
}

class RatedTrips extends MockTripRepository {
  final List<TripModel> trips;
  RatedTrips(this.trips);
  @override
  Future<List<TripModel>> searchTrips({
    required String fromCityId,
    required String toCityId,
    String? date,
  }) async => trips;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(TokenStorage.resetStorageAdapter);

  group('Lead rating finding', () {
    testWidgets('backend missing/null rating stays unknown and hides badge', (
      tester,
    ) async {
      for (final raw in [
        {
          'tripId': 101,
          'price': 260000,
          'busCompany': {'rating': null},
        },
        {...qaTrip.toJson(), 'rating': null},
      ]) {
        final trip = TripModel.fromJson(raw);
        expect(trip.rating, isNull);
        expect(TripModel.fromJson(trip.toJson()).rating, isNull);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TripCard(trip: trip, onSelect: (_) {}),
            ),
          ),
        );
        expect(find.byType(RatingBadge), findsNothing);
      }
      final trip = TripModel.fromJson({...qaTrip.toJson(), 'rating': 4.3});
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripCard(trip: trip, onSelect: (_) {}),
          ),
        ),
      );
      expect(find.byType(RatingBadge), findsOneWidget);
      expect(find.text('4.3'), findsOneWidget);
    });
    test('rating sort places unknown after known ratings', () async {
      final trips = [
        TripModel.fromJson({...qaTrip.toJson(), 'tripId': 1, 'rating': null}),
        TripModel.fromJson({...qaTrip.toJson(), 'tripId': 2, 'rating': 3.2}),
        TripModel.fromJson({...qaTrip.toJson(), 'tripId': 3, 'rating': 4.7}),
      ];
      final bloc = SearchTripsBloc(tripRepository: RatedTrips(trips));
      addTearDown(bloc.close);
      bloc.add(
        LoadTripsEvent(
          fromCityId: 'HCM',
          toCityId: 'DL',
          date: DateTime(2030, 10, 20),
        ),
      );
      await bloc.stream.firstWhere(
        (s) => s.status == SearchTripsStatus.success,
      );
      bloc.add(const ChangeSortTypeEvent(TripSortType.ratingDesc));
      final state = await bloc.stream.firstWhere(
        (s) => s.currentSort == TripSortType.ratingDesc,
      );
      expect(state.filteredTrips.map((t) => t.id), ['3', '2', '1']);
    });
  });

  group('Lead notification contract finding', () {
    testWidgets(
      'delivery type stays unclassified, all rows visible with no category tabs',
      (tester) async {
        await tester.runAsync(
          () => TokenStorage.saveTokens(
            accessToken: 'fixture-access',
            refreshToken: 'fixture-refresh',
          ),
        );
        final bloc = NotificationBloc(
          notificationRepository: RealNotificationRepository(
            remoteDataSource: NotificationRemoteDataSourceImpl(
              client: ApiClient(
                httpClient: MockClient(
                  (request) async => reply({
                    'data': [
                      {
                        'id': 1,
                        'title': 'Vé đã xác nhận',
                        'content': 'Cập nhật từ nhà xe',
                        'createdAt': '2026-10-19T12:00:00Z',
                        'isRead': false,
                        'type': 'DA_GUI',
                      },
                      {
                        'id': 2,
                        'title': 'Thông tin mới',
                        'content': 'Nội dung',
                        'createdAt': '2026-10-19T12:00:00Z',
                        'isRead': true,
                        'type': 'SYSTEM',
                      },
                    ],
                  }),
                ),
              ),
            ),
          ),
        );
        addTearDown(bloc.close);
        bloc.add(const LoadNotificationsEvent());
        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: const MaterialApp(home: NotificationsScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          bloc.state.notifications.every(
            (n) => n.category == NotificationCategory.unknown,
          ),
          true,
        );
        expect(find.text('Vé đã xác nhận'), findsOneWidget);
        expect(find.text('Thông tin mới'), findsOneWidget);
        for (final label in ['Chuyến đi', 'Ưu đãi', 'Hệ thống']) {
          expect(find.text(label), findsNothing);
        }
        bloc.add(const ChangeNotificationTabEvent(1));
        await tester.pumpAndSettle();
        expect(bloc.state.filteredNotifications.length, 2);
        expect(bloc.state.activeTabIndex, 0);
        final explicit = NotificationModel.fromJson({'category': 'PROMO'});
        expect(explicit.category, NotificationCategory.promo);
        expect(
          NotificationModel.fromJson(explicit.toJson()).category,
          NotificationCategory.promo,
        );
      },
    );
  });

  group('Lead guest cancellation finding', () {
    for (final stale in [true, false]) {
      test(
        'accepted cancel with ${stale ? 'stale' : 'failed'} read cannot restore paid QR',
        () async {
          final h = GuestHarness();
          addTearDown(h.close);
          await h.lookup();
          h.staleReadAfterCancel = stale;
          h.failedReadAfterCancel = !stale;
          await h.reader.cancelTicket(
            quotedTicket: h.reader.state.ticket!,
            reason: 'test',
          );
          expect(h.posts.length, 1);
          expect(h.reader.state.status, TicketReadStatus.failure);
          expect(h.reader.state.ticket, isNull);
          expect(h.reader.state.message, contains('kiểm tra riêng'));
          h.staleReadAfterCancel = false;
          h.failedReadAfterCancel = false;
          await h.reader.refresh();
          expect(h.posts.length, 1);
          expect(h.reader.state.ticket!.status, TicketStatus.cancelled);
        },
      );
    }
    test(
      'fresh quote drives public cancel, then authoritative cancelled read hides QR',
      () async {
        final h = GuestHarness();
        addTearDown(h.close);
        await h.lookup();
        final old = h.reader.state.ticket!;
        h.rate = .2;
        await h.reader.refresh();
        await h.reader.cancelTicket(quotedTicket: old, reason: 'stale');
        expect(h.posts, isEmpty);
        await h.reader.cancelTicket(
          quotedTicket: h.reader.state.ticket!,
          reason: 'Đổi kế hoạch',
        );
        expect(h.posts.single, {
          'ticketCode': 'TICKET-AUTH-91',
          'phoneNumber': '0901234567',
          'expectedCancelFeeRate': .2,
          'reason': 'Đổi kế hoạch',
        });
        expect(h.lookups, 3);
        expect(h.reader.state.ticket!.status, TicketStatus.cancelled);
        expect(h.reader.state.ticket!.canShowQr, false);
        expect(
          h.reader.state.message,
          contains('hoàn tiền cần được kiểm tra riêng'),
        );
        expect(h.owner.state.tickets, isEmpty);
      },
    );
    test(
      'ineligible or failed quote lookup cannot submit cancellation',
      () async {
        final h = GuestHarness();
        addTearDown(h.close);
        h.eligible = false;
        await h.lookup();
        final prior = h.reader.state.ticket!;
        await h.reader.cancelTicket(quotedTicket: prior, reason: 'test');
        h.lookupFails = true;
        await h.reader.refresh();
        await h.reader.cancelTicket(quotedTicket: prior, reason: 'test');
        expect(h.posts, isEmpty);
        expect(h.reader.state.status, TicketReadStatus.failure);
        expect(h.reader.state.ticket, isNull);
      },
    );
    test(
      'expired fee quote refreshes and requires a new explicit confirmation',
      () async {
        final h = GuestHarness();
        addTearDown(h.close);
        await h.lookup();
        h.quoteExpires = true;
        await h.reader.cancelTicket(
          quotedTicket: h.reader.state.ticket!,
          reason: 'test',
        );
        expect(h.posts.length, 1);
        expect(h.reader.state.error, isNotNull);
        expect(h.reader.state.message, isNull);
        expect(h.reader.state.ticket!.cancellation!.cancelFeeRate, .2);
        h.quoteExpires = false;
        await h.reader.cancelTicket(
          quotedTicket: h.reader.state.ticket!,
          reason: 'reconfirmed',
        );
        expect(h.posts.length, 2);
        expect(h.posts.last['expectedCancelFeeRate'], .2);
        expect(h.reader.state.ticket!.status, TicketStatus.cancelled);
      },
    );
    test(
      'double submit produces one POST and clears QR while pending',
      () async {
        final h = GuestHarness();
        addTearDown(h.close);
        await h.lookup();
        final quote = h.reader.state.ticket!;
        h.pendingPost = Completer<void>();
        final first = h.reader.cancelTicket(
          quotedTicket: quote,
          reason: 'test',
        );
        await Future<void>.delayed(Duration.zero);
        await h.reader.cancelTicket(quotedTicket: quote, reason: 'duplicate');
        await h.reader.lookup(ticketCode: 'OTHER', phoneNumber: '0999999999');
        await h.reader.refresh();
        expect(h.posts.length, 1);
        expect(h.reader.state.status, TicketReadStatus.cancelling);
        expect(h.reader.state.ticket, isNull);
        h.pendingPost!.complete();
        await first;
        expect(h.reader.state.ticket!.status, TicketStatus.cancelled);
      },
    );
    for (final action in ['session', 'token', 'dispose']) {
      test(
        'late cancellation response discarded after $action invalidation',
        () async {
          final h = GuestHarness();
          addTearDown(h.owner.close);
          await h.lookup();
          h.pendingPost = Completer<void>();
          final pending = h.reader.cancelTicket(
            quotedTicket: h.reader.state.ticket!,
            reason: 'test',
          );
          await Future<void>.delayed(Duration.zero);
          if (action == 'session') {
            h.owner.setSession('another-account');
          }
          if (action == 'token') await TokenStorage.clearTokens();
          if (action == 'dispose') await h.reader.close();
          h.pendingPost!.complete();
          await pending;
          expect(h.reader.state.status, TicketReadStatus.invalidated);
          expect(h.reader.state.ticket, isNull);
          expect(h.lookups, 1);
          if (!h.reader.isClosed) await h.reader.close();
        },
      );
    }
    test(
      'unknown POST result reconciles without retry and never claims bank refund',
      () async {
        final h = GuestHarness();
        addTearDown(h.close);
        await h.lookup();
        h.unknownPost = true;
        await h.reader.cancelTicket(
          quotedTicket: h.reader.state.ticket!,
          reason: 'test',
        );
        expect(h.posts.length, 1);
        expect(h.reader.state.ticket!.status, TicketStatus.cancelled);
        expect(h.reader.state.message, contains('kiểm tra riêng'));
      },
    );
    test(
      'mismatched response cannot fabricate cancelled status or success',
      () async {
        final h = GuestHarness();
        addTearDown(h.close);
        await h.lookup();
        h.wrongResponse = true;
        await h.reader.cancelTicket(
          quotedTicket: h.reader.state.ticket!,
          reason: 'test',
        );
        expect(h.reader.state.ticket!.status, TicketStatus.upcoming);
        expect(h.reader.state.error, isNotNull);
        expect(h.reader.state.message, isNull);
      },
    );
    test(
      'incomplete cancellation fee is rejected rather than defaulting to zero',
      () {
        final raw = qaTicketJson();
        raw['cancellation'] = {'eligible': true, 'refundAmount': 250000};
        expect(() => TicketModel.fromJson(raw), throwsFormatException);
      },
    );
    testWidgets(
      'guest UI refreshes quote, confirms fee, submits and shows refreshed status',
      (tester) async {
        tester.view.physicalSize = const Size(900, 1700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = GuestHarness();
        addTearDown(h.owner.close);
        await tester.pumpWidget(
          BlocProvider.value(
            value: h.owner,
            child: const MaterialApp(
              home: Scaffold(body: GuestTicketLookupPanel()),
            ),
          ),
        );
        await tester.enterText(
          find.byKey(const Key('lookup-ticket-code')),
          'TICKET-AUTH-91',
        );
        await tester.enterText(
          find.byKey(const Key('lookup-phone')),
          '0901234567',
        );
        await tester.tap(find.text('Tra cứu vé'));
        await tester.pumpAndSettle();
        h.rate = .2;
        await tester.ensureVisible(find.text('Hủy vé'));
        await tester.tap(find.text('Hủy vé'));
        await tester.pumpAndSettle();
        expect(h.lookups, 2);
        expect(find.textContaining('Phí hủy (20%)'), findsOneWidget);
        expect(find.textContaining('200.000'), findsOneWidget);
        final confirm = find.widgetWithText(FilledButton, 'Xác nhận hủy vé');
        expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(h.posts.length, 1);
        expect(h.posts.single['expectedCancelFeeRate'], .2);
        expect(h.lookups, 3);
        expect(
          find.textContaining('Yêu cầu hủy vé đã được xác nhận'),
          findsOneWidget,
        );
        expect(find.text('Hủy vé'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
