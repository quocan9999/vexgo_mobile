import 'package:vexgo_app/features/user/main_shell/main_shell_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vexgo_app/data/models/notification_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/notification_repository.dart';
import 'package:vexgo_app/features/user/notification/bloc/notification_bloc.dart';
import 'package:vexgo_app/features/user/notification/presentation/screens/notifications_screen.dart';
import 'qa/qa_fixtures.dart';

class _Notifications implements NotificationRepository {
  int loads = 0;
  @override
  Future<List<NotificationModel>> getNotifications() async {
    loads++;
    return [
      NotificationModel.fromJson({
        'id': 1,
        'title': 'Paid booking',
        'content': 'Your tickets are ready',
        'category': 'TRIP',
        'ticketId': 42,
        'bookingId': 12,
        'createdAt': '2026-11-01T08:00:00Z',
      }),
    ];
  }

  @override
  Future<void> markAsRead(String id) async {}
  @override
  Future<void> markAllAsRead() async {}
}

class _Bookings extends MockBookingRepository {
  final pending = Completer<TicketModel?>();
  int reads = 0;
  @override
  Future<TicketModel?> getTicketById(String id) {
    reads++;
    return pending.future;
  }
}

TicketModel _ticket() => const TicketModel(
  id: '42',
  ticketCode: 'TICKET-42',
  status: TicketStatus.upcoming,
  bookingDate: '01/11/2026',
  trip: qaSummary,
  seats: ['A01'],
  totalAmount: 190000,
  discountAmount: 0,
  finalAmount: 190000,
  paymentMethod: 'SEPAY',
  passenger: qaPassenger,
);

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  test(
    'reads routing identifiers independently from recipient notification ID',
    () {
      final n = NotificationModel.fromJson({
        'id': 9,
        'notificationId': 10,
        'ticketId': 42,
        'bookingId': 12,
        'category': 'TRIP',
      });
      expect(n.id, '9');
      expect(n.ticketId, '42');
      expect(n.bookingId, '12');
      expect(n.category, NotificationCategory.trip);
      expect(n.copyWith(isRead: true).ticketId, '42');
    },
  );
  for (final logout in [false, true]) {
    testWidgets(
      'opens only authoritative ticket; ignores pending result after logout=$logout',
      (tester) async {
        final repo = _Notifications();
        final bookings = _Bookings();
        final bloc = NotificationBloc(notificationRepository: repo);
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const NotificationsScreen()),
            GoRoute(
              path: '/ticket-detail',
              builder: (_, state) =>
                  Text('OPEN-${(state.extra as TicketModel).id}'),
            ),
          ],
        );
        await tester.pumpWidget(
          RepositoryProvider<BookingRepository>.value(
            value: bookings,
            child: BlocProvider.value(
              value: bloc,
              child: MaterialApp.router(routerConfig: router),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Paid booking'));
        await tester.pump();
        await tester.tap(find.text('Paid booking'));
        await tester.pump();
        expect(bookings.reads, 1);
        if (logout) bloc.setSession(null);
        bookings.pending.complete(_ticket());
        await tester.pumpAndSettle();
        expect(find.text('OPEN-42'), logout ? findsNothing : findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        await tester.runAsync(bloc.close);
      },
    );
  }
  testWidgets('reloads the inbox when returning to foreground', (tester) async {
    final repo = _Notifications();
    final bloc = NotificationBloc(notificationRepository: repo);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final before = repo.loads;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repo.loads, greaterThan(before));
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(bloc.close);
  });
  testWidgets(
    'refreshes a previously mounted inbox when selecting its navigation tab',
    (tester) async {
      final repo = _Notifications();
      final bloc = NotificationBloc(notificationRepository: repo);
      final router = GoRouter(
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => MainShellScreen(navigationShell: shell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (_, _) => const Text('Home content'),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/tickets',
                    builder: (_, _) => const Text('Tickets content'),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/notifications',
                    builder: (_, _) => const NotificationsScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/account',
                    builder: (_, _) => const Text('Account content'),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thông báo'));
      await tester.pumpAndSettle();
      final before = repo.loads;
      expect(before, greaterThan(0));
      await tester.tap(find.text('Trang chủ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thông báo'));
      await tester.pumpAndSettle();
      expect(repo.loads, greaterThan(before));
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await tester.runAsync(bloc.close);
    },
  );
}
