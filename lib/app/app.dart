import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/network/api_config.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/booking_receipt_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/seat_repository.dart';
import '../data/repositories/trip_repository.dart';
import '../features/user/my_bookings/bloc/my_tickets_bloc.dart';
import '../features/user/notification/bloc/notification_bloc.dart';
import '../features/user/profile/bloc/auth_bloc.dart';
import '../features/user/profile/bloc/auth_event.dart';
import '../features/user/profile/bloc/auth_state.dart';
import 'routes.dart';

class VexGoApp extends StatelessWidget {
  const VexGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDemo = ApiConfig.isDemoMode;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<BookingReceiptRepository>(
          create: (_) => BookingReceiptRepository.forCurrentMode(),
        ),
        RepositoryProvider<TripRepository>(
          create: (context) =>
              isDemo ? MockTripRepository() : RealTripRepository(),
        ),
        RepositoryProvider<SeatRepository>(
          create: (context) =>
              isDemo ? MockSeatRepository() : RealSeatRepository(),
        ),
        RepositoryProvider<BookingRepository>(
          create: (context) =>
              isDemo ? MockBookingRepository() : RealBookingRepository(),
        ),
        RepositoryProvider<AuthRepository>(
          create: (context) =>
              isDemo ? MockAuthRepository() : RealAuthRepository(),
        ),
        RepositoryProvider<NotificationRepository>(
          create: (context) => isDemo
              ? MockNotificationRepository()
              : RealNotificationRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<MyTicketsBloc>(
            create: (context) => MyTicketsBloc(
              bookingRepository: context.read<BookingRepository>(),
              authenticated: false,
            ),
          ),
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(authRepository: context.read<AuthRepository>())
                  ..add(const CheckAuthStatusEvent()),
          ),
          BlocProvider<NotificationBloc>(
            create: (context) => NotificationBloc(
              notificationRepository: context.read<NotificationRepository>(),
              authenticated: false,
            ),
          ),
        ],
        child: _SessionSynchronization(
          child: MaterialApp.router(
            title: 'VexGo - Đặt vé xe khách trực tuyến',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: AppRoutes.router,
          ),
        ),
      ),
    );
  }
}

class _SessionSynchronization extends StatefulWidget {
  final Widget child;
  const _SessionSynchronization({required this.child});
  @override
  State<_SessionSynchronization> createState() =>
      _SessionSynchronizationState();
}

class _SessionSynchronizationState extends State<_SessionSynchronization> {
  StreamSubscription<AuthState>? _subscription;
  String? _previousSession;
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>();
    _synchronize(auth.state);
    _subscription = auth.stream.listen(_synchronize);
  }

  void _synchronize(AuthState state) {
    final key = state.isAuthenticated
        ? state.user!.taiKhoanId.toString()
        : null;
    context.read<MyTicketsBloc>().setSession(key);
    context.read<NotificationBloc>().setSession(key);
    if (_previousSession != null && key != _previousSession) {
      AppRoutes.router.go(AppRoutes.home);
    }
    _previousSession = key;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
