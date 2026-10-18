import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/datasources/remote/notification_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/ticket_remote_data_source.dart';
import 'package:vexgo_app/data/models/booking_model.dart';
import 'package:vexgo_app/data/models/notification_model.dart';
import 'package:vexgo_app/data/models/review_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/notification_repository.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_state.dart';
import 'package:vexgo_app/features/user/notification/bloc/notification_bloc.dart';
import 'package:vexgo_app/features/user/notification/bloc/notification_event.dart';
import 'package:vexgo_app/features/user/notification/bloc/notification_state.dart';

class TicketsRepository implements BookingRepository {
  int calls = 0;
  final pending = <Completer<List<TicketModel>>>[];
  @override
  Future<List<TicketModel>> getMyTickets() {
    calls++;
    final p = Completer<List<TicketModel>>();
    pending.add(p);
    return p.future;
  }

  @override
  Future<BookingModel?> getBookingById(dynamic bookingId) async =>
      throw Exception('lookup offline');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class NotificationsRepository implements NotificationRepository {
  int calls = 0;
  bool failRead = false;
  final pending = <Completer<List<NotificationModel>>>[];
  @override
  Future<List<NotificationModel>> getNotifications() {
    calls++;
    final p = Completer<List<NotificationModel>>();
    pending.add(p);
    return p.future;
  }

  @override
  Future<void> markAsRead(String id) async {
    if (failRead) throw Exception('offline');
  }

  @override
  Future<void> markAllAsRead() async {
    if (failRead) throw Exception('offline');
  }
}

NotificationModel notification(String id) => NotificationModel(
  id: id,
  title: id,
  message: 'message',
  category: NotificationCategory.system,
  createdAt: DateTime.utc(2026),
);
Future<void> tick() => Future<void>.delayed(Duration.zero);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TicketModel ticket;
  setUp(() async {
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    final list =
        jsonDecode(
              await rootBundle.loadString('assets/mock_data/my_tickets.json'),
            )
            as List;
    ticket = TicketModel.fromJson(list.first as Map<String, dynamic>);
  });
  tearDown(TokenStorage.resetStorageAdapter);
  test(
    'guest protected blocs make no API calls; login reloads once; repeated identity does not reload',
    () async {
      final tickets = TicketsRepository();
      final notifications = NotificationsRepository();
      final tb = MyTicketsBloc(
        bookingRepository: tickets,
        authenticated: false,
      );
      final nb = NotificationBloc(
        notificationRepository: notifications,
        authenticated: false,
      );
      addTearDown(tb.close);
      addTearDown(nb.close);
      tb.setSession(null);
      nb.setSession(null);
      tb.add(const LoadMyTicketsEvent());
      nb.add(const LoadNotificationsEvent());
      await tick();
      expect(tickets.calls, 0);
      expect(notifications.calls, 0);
      expect(tb.state.requiresLogin, true);
      expect(nb.state.requiresLogin, true);
      tb.setSession('A');
      nb.setSession('A');
      await tick();
      tb.setSession('A');
      nb.setSession('A');
      await tick();
      expect(tickets.calls, 1);
      expect(notifications.calls, 1);
      tickets.pending.single.complete([ticket]);
      notifications.pending.single.complete([notification('A')]);
      await tick();
      expect(tb.state.tickets.length, 1);
      expect(nb.state.notifications.length, 1);
      tb.setSession(null);
      nb.setSession(null);
      expect(tb.state.tickets, isEmpty);
      expect(nb.state.notifications, isEmpty);
    },
  );
  test('late account A loads never overwrite account B caches', () async {
    final tr = TicketsRepository();
    final nr = NotificationsRepository();
    final tb = MyTicketsBloc(bookingRepository: tr, authenticated: false);
    final nb = NotificationBloc(
      notificationRepository: nr,
      authenticated: false,
    );
    addTearDown(tb.close);
    addTearDown(nb.close);
    tb.setSession('A');
    nb.setSession('A');
    await tick();
    tb.setSession('B');
    nb.setSession('B');
    await tick();
    tr.pending[1].complete([]);
    nr.pending[1].complete([notification('B')]);
    await tick();
    tr.pending[0].complete([ticket]);
    nr.pending[0].complete([notification('A')]);
    await tick();
    expect(tb.state.tickets, isEmpty);
    expect(nb.state.notifications.single.id, 'B');
  });
  test('late errors after logout do not replace guest state', () async {
    final tr = TicketsRepository();
    final nr = NotificationsRepository();
    final tb = MyTicketsBloc(bookingRepository: tr, authenticated: false);
    final nb = NotificationBloc(
      notificationRepository: nr,
      authenticated: false,
    );
    addTearDown(tb.close);
    addTearDown(nb.close);
    tb.setSession('A');
    nb.setSession('A');
    await tick();
    tb.setSession(null);
    nb.setSession(null);
    tr.pending[0].completeError(Exception('offline'));
    nr.pending[0].completeError(Exception('offline'));
    await tick();
    expect(tb.state.requiresLogin, true);
    expect(tb.state.errorMessage, isNull);
    expect(nb.state.requiresLogin, true);
    expect(nb.state.errorMessage, isNull);
  });
  test(
    'tickets can reload when nonempty and recover after network error',
    () async {
      final tr = TicketsRepository();
      final tb = MyTicketsBloc(bookingRepository: tr);
      addTearDown(tb.close);
      tb.add(const LoadMyTicketsEvent());
      await tick();
      tr.pending[0].complete([ticket]);
      await tick();
      tb.add(const LoadMyTicketsEvent());
      await tick();
      expect(tr.calls, 2);
      tr.pending[1].completeError(Exception('offline'));
      await tick();
      expect(tb.state.status, MyTicketsStatus.error);
      expect(tb.state.tickets.length, 1);
      tb.add(const LoadMyTicketsEvent());
      await tick();
      tr.pending[2].complete([]);
      await tick();
      expect(tb.state.status, MyTicketsStatus.loaded);
      expect(tb.state.errorMessage, isNull);
      expect(tb.state.tickets, isEmpty);
    },
  );
  for (final all in [false, true]) {
    test(
      'notification ${all ? 'all' : 'single'} mark failure is reported without changing unread state',
      () async {
        final nr = NotificationsRepository()..failRead = true;
        final nb = NotificationBloc(notificationRepository: nr);
        addTearDown(nb.close);
        nb.add(const LoadNotificationsEvent());
        await tick();
        nr.pending.single.complete([notification('A')]);
        await tick();
        nb.add(
          all
              ? const MarkAllNotificationsAsReadEvent()
              : const MarkNotificationAsReadEvent('A'),
        );
        await tick();
        expect(nb.state.unreadCount, 1);
        expect(nb.state.errorMessage, contains('offline'));
        nr.failRead = false;
        nb.add(
          all
              ? const MarkAllNotificationsAsReadEvent()
              : const MarkNotificationAsReadEvent('A'),
        );
        await tick();
        expect(nb.state.unreadCount, 0);
        expect(nb.state.errorMessage, isNull);
      },
    );
  }
  test(
    'review booking lookup failure emits error rather than escaping handler',
    () async {
      final tb = MyTicketsBloc(bookingRepository: TicketsRepository());
      addTearDown(tb.close);
      final json = ticket.toJson();
      json['bookingId'] = 99;
      final trip = Map<String, dynamic>.from(json['trip'] as Map);
      trip['id'] = 'unknown';
      json['trip'] = trip;
      final target = TicketModel.fromJson(json);
      tb.add(AddNewTicketEvent(target));
      await tick();
      tb.add(
        SubmitTicketReviewEvent(
          ticketId: target.id,
          review: const ReviewModel(
            rating: 5,
            comment: 'ok',
            createdAt: '2026-10-18',
          ),
        ),
      );
      await tick();
      expect(tb.state.errorMessage, contains('lookup offline'));
      expect(tb.state.tickets.single.review, isNull);
    },
  );
  test(
    'HTTP notification pagination follows backend meta and preserves all items',
    () async {
      await TokenStorage.saveTokens(accessToken: 'a', refreshToken: 'r');
      final pages = <String>[];
      final ds = NotificationRemoteDataSourceImpl(
        client: ApiClient(
          httpClient: MockClient((request) async {
            pages.add(request.url.queryParameters['page']!);
            return http.Response(
              jsonEncode({
                'data': [
                  {
                    'id': pages.length,
                    'title': 'notice',
                    'content': 'body',
                    'createdAt': '2026-10-18T00:00:00Z',
                  },
                ],
                'meta': {'totalPages': 2},
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      );
      final items = await ds.getNotifications();
      expect(pages, ['1', '2']);
      expect(items.map((n) => n.id), ['1', '2']);
    },
  );
  test('HTTP ticket pagination follows backend meta', () async {
    await TokenStorage.saveTokens(accessToken: 'a', refreshToken: 'r');
    final pages = <String>[];
    final ds = TicketRemoteDataSourceImpl(
      client: ApiClient(
        httpClient: MockClient((request) async {
          pages.add(request.url.queryParameters['page']!);
          return http.Response(
            jsonEncode({
              'data': [ticket.toJson()],
              'meta': {'totalPages': 2},
            }),
            200,
          );
        }),
      ),
    );
    expect((await ds.getCustomerTickets()).length, 2);
    expect(pages, ['1', '2']);
  });
}
