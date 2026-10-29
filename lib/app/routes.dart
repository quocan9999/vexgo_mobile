import 'package:flutter/material.dart';
import '../data/models/booking_receipt_model.dart';
import '../features/user/receipts/presentation/booking_receipt_screen.dart';
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
import '../features/user/support_chat/presentation/screens/support_chat_screen.dart';
import '../features/user/search_trips/presentation/screens/search_trips_screen.dart';
import '../features/user/round_trip/round_trip_request.dart';
import '../features/user/round_trip/presentation/screens/round_trip_search_screen.dart';
import '../features/user/round_trip/presentation/screens/round_trip_booking_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'home',
);
final GlobalKey<NavigatorState> _ticketsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'tickets');
final GlobalKey<NavigatorState> _notificationsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'notifications');
final GlobalKey<NavigatorState> _profileNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'profile');

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
  static const String supportChat = '/support-chat';
  static const String bookingReceipt = '/booking-receipt';
  static const String roundTripSearch = '/round-trip/search';
  static const String roundTripBooking = '/round-trip/booking';

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: home,
    routes: [
      // Top-level pushed routes (without BottomNavBar)
      GoRoute(
        path: bookingReceipt,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => BookingReceiptScreen(
          initialRequest: state.extra is ReceiptLookupRequest
              ? state.extra as ReceiptLookupRequest
              : null,
        ),
      ),
      GoRoute(
        path: supportChat,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SupportChatScreen(),
      ),
      GoRoute(
        path: searchTrips,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final query = state.uri.queryParameters;

          CityModel? fromCity = extra?['fromCity'] as CityModel?;
          if (fromCity == null && query.containsKey('fromCityId')) {
            fromCity = CityModel(
              id: query['fromCityId']!,
              name: query['fromCityName'] ?? query['fromCityId']!,
              region: '',
              isPopular: false,
            );
          }

          CityModel? toCity = extra?['toCity'] as CityModel?;
          if (toCity == null && query.containsKey('toCityId')) {
            toCity = CityModel(
              id: query['toCityId']!,
              name: query['toCityName'] ?? query['toCityId']!,
              region: '',
              isPopular: false,
            );
          }

          DateTime? date = extra?['date'] as DateTime?;
          if (date == null && query.containsKey('date')) {
            date = DateTime.tryParse(query['date']!);
          }

          final ticketCount =
              extra?['ticketCount'] as int? ??
              int.tryParse(query['ticketCount'] ?? '1') ??
              1;

          return SearchTripsScreen(
            fromCity: fromCity,
            toCity: toCity,
            date: date,
            ticketCount: ticketCount,
          );
        },
      ),
      GoRoute(
        path: roundTripSearch,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : const <String, dynamic>{};
          return RoundTripSearchScreen(
            query: state.uri.queryParameters,
            extra: extra,
          );
        },
      ),
      GoRoute(
        path: roundTripBooking,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final selection = state.extra is RoundTripSelection
              ? state.extra as RoundTripSelection
              : null;
          return RoundTripBookingScreen(selection: selection);
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
          return BookingSuccessScreen(
            ticket: ticket,
            tickets:
                (extra?['tickets'] as List?)
                    ?.whereType<TicketModel>()
                    .toList() ??
                const [],
          );
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
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),

          // Branch 2: Vé của tôi
          StatefulShellBranch(
            navigatorKey: _ticketsNavigatorKey,
            routes: [
              GoRoute(
                path: myTickets,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MyTicketsScreen()),
              ),
            ],
          ),

          // Branch 3: Thông báo
          StatefulShellBranch(
            navigatorKey: _notificationsNavigatorKey,
            routes: [
              GoRoute(
                path: notifications,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: NotificationsScreen()),
              ),
            ],
          ),

          // Branch 4: Tài khoản
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: profile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
