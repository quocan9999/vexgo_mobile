import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/data/models/city_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import '../features/user/booking/presentation/screens/booking_flow_screen.dart';
import '../features/user/booking/presentation/screens/booking_success_screen.dart';
import '../features/user/home/presentation/screens/home_screen.dart';
import '../features/user/main_shell/main_shell_screen.dart';
import '../features/user/my_bookings/presentation/screens/my_tickets_screen.dart';
import '../features/user/my_bookings/presentation/screens/ticket_detail_screen.dart';
import '../features/user/notification/presentation/screens/notifications_screen.dart';
import '../features/user/profile/presentation/screens/profile_screen.dart';
import '../features/user/search_trips/presentation/screens/search_trips_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final GlobalKey<NavigatorState> _ticketsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'tickets');
final GlobalKey<NavigatorState> _notificationsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'notifications');
final GlobalKey<NavigatorState> _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String myTickets = '/my-tickets';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String searchTrips = '/search-trips';
  static const String seatSelection = '/seat-selection';
  static const String checkout = '/checkout';
  static const String bookingSuccess = '/booking-success';
  static const String ticketDetail = '/ticket-detail';

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: home,
    routes: [
      // Top-level pushed routes (without BottomNavBar)
      GoRoute(
        path: searchTrips,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SearchTripsScreen(
            fromCity: extra?['fromCity'] as CityModel?,
            toCity: extra?['toCity'] as CityModel?,
            date: extra?['date'] as DateTime?,
            ticketCount: extra?['ticketCount'] as int? ?? 1,
          );
        },
      ),
      GoRoute(
        path: seatSelection,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final trip = extra?['trip'] as TripModel;
          final date = extra?['date'] as DateTime? ?? DateTime.now();
          final ticketCount = extra?['ticketCount'] as int? ?? 1;
          return BookingFlowScreen(
            trip: trip,
            date: date,
            ticketCount: ticketCount,
          );
        },
      ),
      GoRoute(
        path: bookingSuccess,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final ticket = extra?['ticket'] as TicketModel;
          return BookingSuccessScreen(ticket: ticket);
        },
      ),
      GoRoute(
        path: ticketDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final ticket = state.extra as TicketModel;
          return TicketDetailScreen(initialTicket: ticket);
        },
      ),

      // Stateful Shell with BottomNavBar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Trang chủ
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: home,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),

          // Branch 2: Vé của tôi
          StatefulShellBranch(
            navigatorKey: _ticketsNavigatorKey,
            routes: [
              GoRoute(
                path: myTickets,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MyTicketsScreen(),
                ),
              ),
            ],
          ),

          // Branch 3: Thông báo
          StatefulShellBranch(
            navigatorKey: _notificationsNavigatorKey,
            routes: [
              GoRoute(
                path: notifications,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: NotificationsScreen(),
                ),
              ),
            ],
          ),

          // Branch 4: Tài khoản
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: profile,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
