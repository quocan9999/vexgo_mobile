import '../widgets/booking_rate_limit_view.dart';
import 'package:vexgo_app/app/routes.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/widgets/custom_app_bar.dart';
import 'package:vexgo_app/data/models/booking_cargo_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/cargo_repository.dart';
import 'package:vexgo_app/data/repositories/luggage_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/bloc/luggage_cubit.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_state.dart';
import 'package:vexgo_app/features/user/search_trips/presentation/widgets/trip_detail_sheet.dart';
import '../steps/step_1_seat_selection.dart';
import '../steps/step_2_pickup_point.dart';
import '../steps/step_3_dropoff_point.dart';
import '../steps/step_4_passenger_info.dart';
import '../steps/step_5_trip_summary.dart';
import '../steps/step_6_payment.dart';
import '../widgets/booking_bottom_bar.dart';
import '../widgets/booking_passenger_info_view.dart';
import '../widgets/booking_payment_view.dart';
import '../widgets/booking_selection_view.dart';
import '../widgets/booking_stepper.dart';
import '../widgets/booking_trip_summary_view.dart';
import '../widgets/seat_hold_countdown_bar.dart';

class BookingFlowScreen extends StatelessWidget {
  final TripModel trip;
  final DateTime date;
  final int ticketCount;
  final BookingFlowBloc? bloc;
  final LuggageRepository? luggageRepository;
  final DateTime Function()? now;

  const BookingFlowScreen({
    super.key,
    required this.trip,
    required this.date,
    this.ticketCount = 1,
    this.bloc,
    this.luggageRepository,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc?>()?.state;
    final authUser = (auth?.isAuthenticated ?? false) ? auth?.user : null;
    final content = _BookingFlowContent(
      luggageRepository: luggageRepository,
      now: now,
    );
    if (bloc != null) {
      return BlocProvider<BookingFlowBloc>.value(value: bloc!, child: content);
    }
    return BlocProvider<BookingFlowBloc>(
      create: (context) =>
          BookingFlowBloc(
            seatRepository: context.read<SeatRepository>(),
            bookingRepository: context.read<BookingRepository>(),
            cargoRepository: context.read<CargoRepository?>(),
            now: now,
          )..add(
            InitBookingFlowEvent(
              trip: trip,
              date: date,
              ticketCount: ticketCount,
              passengerName: authUser?.hoTen,
              passengerPhone: authUser?.soDienThoai,
              passengerEmail: authUser?.email,
            ),
          ),
      child: content,
    );
  }
}

class _BookingFlowContent extends StatefulWidget {
  final LuggageRepository? luggageRepository;
  final DateTime Function()? now;

  const _BookingFlowContent({this.luggageRepository, this.now});
  @override
  State<_BookingFlowContent> createState() => _BookingFlowContentState();
}

class _BookingFlowContentState extends State<_BookingFlowContent>
    with WidgetsBindingObserver {
  int? _initialAccountId;
  bool _initialAuthenticated = false;
  LuggageCubit? _luggageCubit;
  int? _luggageTripId;
  int? _luggagePassengerCount;
  int? _luggageSessionVersion;
  String? _luggageSeatChangeNotice;

  LuggageRepository _resolveLuggageRepository(BuildContext context) {
    return widget.luggageRepository ??
        context.read<LuggageRepository?>() ??
        RealLuggageRepository(
          cargoRepository: context.read<CargoRepository?>(),
        );
  }

  void _ensureLuggageCubit(BookingFlowState state, BookingFlowBloc bloc) {
    final tripId =
        state.trip?.numericTripId ?? int.tryParse(state.trip?.id ?? '');
    final passengerCount = state.selectedSeats.length;
    final sessionVersion = TokenStorage.sessionVersion;

    if (tripId == null ||
        tripId <= 0 ||
        passengerCount < 1 ||
        passengerCount > 5) {
      if (_luggageCubit != null) {
        unawaited(_luggageCubit!.close());
        _luggageCubit = null;
        _luggageTripId = null;
        _luggagePassengerCount = null;
      }
      return;
    }

    if (_luggageCubit != null &&
        _luggageTripId == tripId &&
        _luggagePassengerCount == passengerCount &&
        _luggageSessionVersion == sessionVersion) {
      return;
    }

    if (_luggageCubit != null) {
      final oldCubit = _luggageCubit!;
      final hadLuggage =
          oldCubit.state.phase != LuggagePhase.idle ||
          oldCubit.state.selection.carryOn.isNotEmpty ||
          oldCubit.state.selection.checked.isNotEmpty ||
          state.cargo.enabled;
      if (_luggageTripId == tripId &&
          _luggagePassengerCount != null &&
          _luggagePassengerCount != passengerCount &&
          hadLuggage) {
        _luggageSeatChangeNotice =
            'Số ghế đã thay đổi ($_luggagePassengerCount → $passengerCount hành khách). Vui lòng kiểm tra lại hạn mức hành lý theo số hành khách mới.';
        if (state.cargo.enabled && !state.isCheckoutLocked) {
          unawaited(
            bloc.applyDraftAction(const SetBookingCargoEnabledEvent(false)),
          );
        }
      }
      unawaited(oldCubit.close());
    }

    _luggageTripId = tripId;
    _luggagePassengerCount = passengerCount;
    _luggageSessionVersion = sessionVersion;
    _luggageCubit = LuggageCubit(
      tripId: tripId,
      passengerCount: passengerCount,
      repository: _resolveLuggageRepository(context),
      now: widget.now,
    );
  }

  Future<void> _syncLuggageToBookingFlow(
    BookingFlowBloc bloc,
    BookingCargoDraft? _,
  ) async {
    final cubit = _luggageCubit;
    final tripId =
        bloc.state.trip?.numericTripId ??
        int.tryParse(bloc.state.trip?.id ?? '');
    final passengerCount = bloc.state.selectedSeats.length;
    if (cubit == null || tripId == null || passengerCount < 1) return;
    final draft = cubit.exportForBooking(
      expectedTripId: tripId,
      expectedPassengerCount: passengerCount,
    );
    await bloc.applyDraftAction(
      SetBookingCargoEnabledEvent(draft != null, initialDraft: draft),
    );
  }

  Future<void> _advanceWithLuggageSync(BookingFlowBloc bloc) async {
    final cubit = _luggageCubit;
    if (cubit != null) {
      if (cubit.validationError != null ||
          (cubit.state.phase != LuggagePhase.idle && !cubit.policyIsFresh)) {
        return;
      }
      if (cubit.state.phase == LuggagePhase.ready) {
        await _syncLuggageToBookingFlow(bloc, null);
      }
    }
    if (!bloc.isClosed) {
      bloc.add(const NextStepEvent());
    }
  }

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc?>()?.state;
    _initialAccountId = auth?.user?.taiKhoanId;
    _initialAuthenticated = auth?.isAuthenticated ?? false;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<BookingFlowBloc>().add(const TickCountdownEvent());
    }
  }

  @override
  void dispose() {
    _luggageCubit?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<bool> _handlePop(
    BuildContext context,
    BookingFlowState state,
    BookingFlowBloc bloc,
  ) async {
    if (state.status == BookingFlowStatus.submitting ||
        state.status == BookingFlowStatus.loading) {
      return false;
    }
    if (state.step.index > 0 && !state.isCheckoutLocked) {
      bloc.add(const PreviousStepEvent());
      return false;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thoát khỏi đặt vé?'),
        content: Text(
          state.isCheckoutLocked
              ? 'Đơn hiện tại chưa hoàn tất xác minh. Kiểm tra trong Vé của tôi trước khi tạo đơn khác.'
              : 'Bạn có chắc chắn muốn rời khỏi tiến trình đặt vé này không? Vị trí ghế đang giữ sẽ được giải phóng cho người khác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Tiếp tục đặt vé'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Rời khỏi',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true && !state.isCheckoutLocked) {
      bloc.add(const ReleaseSeatHoldEvent());
    }

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BookingFlowBloc>();
    final authBloc = context.read<AuthBloc?>();

    final content = BlocConsumer<BookingFlowBloc, BookingFlowState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (bloc.sessionInvalidated) return;
        if (state.status == BookingFlowStatus.success &&
            state.createdTicket != null) {
          context.pushReplacement(
            '/booking-success',
            extra: {
              'ticket': state.createdTicket,
              'tickets': state.createdTickets,
              'booking': state.checkoutBooking,
            },
          );
        } else if (state.errorMessage != null && state.rateLimit == null) {
          if (state.errorMessage!.contains('Hết thời gian') ||
              state.errorMessage!.contains('hết hạn')) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.timer_off_rounded, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Hết giờ giữ ghế'),
                  ],
                ),
                content: const Text(
                  'Thời gian giữ ghế tạm thời (10 phút) đã kết thúc. Vị trí ghế đã được giải phóng để nhường cho khách khác. Vui lòng chọn lại chỗ ngồi để tiếp tục.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Đã hiểu'),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      builder: (context, state) {
        if (bloc.sessionInvalidated) return _sessionChangedView(context);
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await _handlePop(context, state, bloc);
            if (shouldPop && context.mounted) {
              context.pop();
            }
          },
          child: state.rateLimit != null
              ? BookingRateLimitView(
                  notice: state.rateLimit!,
                  hasAnyOrder: state.pendingBookingId != null,
                  onResume: () =>
                      bloc.add(const ResumeAfterBookingRateLimitEvent()),
                  onReviewOrders: () => context.push(AppRoutes.myTickets),
                  onSupport: () => context.push(AppRoutes.supportChat),
                )
              : _buildStepShell(context, state, bloc),
        );
      },
    );

    if (authBloc == null) {
      return content;
    }

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.user?.taiKhoanId != current.user?.taiKhoanId ||
          previous.isAuthenticated != current.isAuthenticated,
      listener: (context, authState) {
        bloc.invalidateSession();
      },
      builder: (context, authState) {
        if (bloc.sessionInvalidated ||
            authState.user?.taiKhoanId != _initialAccountId ||
            authState.isAuthenticated != _initialAuthenticated) {
          return _sessionChangedView(context);
        }
        return content;
      },
    );
  }

  Widget _sessionChangedView(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đặt vé')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Phiên tài khoản đã thay đổi.',
              key: ValueKey('booking-session-changed'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Vui lòng mở lại đặt vé. Nếu đã gửi tạo đơn, hãy đăng nhập đúng tài khoản và kiểm tra Vé của tôi trước khi tạo đơn khác. Ghế chưa tạo đơn sẽ được yêu cầu giải phóng hoặc tự hết hạn theo máy chủ.',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Rời khỏi đặt vé'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildStepShell(
    BuildContext context,
    BookingFlowState state,
    BookingFlowBloc bloc,
  ) {
    _ensureLuggageCubit(state, bloc);
    final trip = state.trip;

    if (state.step.index <= BookingStep.dropoffPoint.index) {
      return BookingSelectionView(
        state: state,
        child: _buildCurrentStepView(state, bloc),
        onBack: () async {
          final shouldPop = await _handlePop(context, state, bloc);
          if (shouldPop && context.mounted) context.pop();
        },
        onNext: () => bloc.add(const NextStepEvent()),
        onStep: (index) => bloc.add(GoToStepEvent(index)),
        onRetry: () {
          if (trip != null && state.date != null) {
            bloc.add(
              InitBookingFlowEvent(
                trip: trip,
                date: state.date!,
                ticketCount: state.targetTicketCount,
                passengerName: state.passengerName,
                passengerPhone: state.passengerPhone,
                passengerEmail: state.passengerEmail,
              ),
            );
          }
        },
        onDetails: () {
          if (trip != null) {
            TripDetailSheet.show(context, trip: trip, onSelectTrip: (_) {});
          }
        },
      );
    }

    if (state.step == BookingStep.passengerInfo) {
      return BookingPassengerInfoView(
        state: state,
        bloc: bloc,
        luggageCubit: _luggageCubit,
        luggageSeatChangeNotice: _luggageSeatChangeNotice,
        onDismissLuggageSeatChangeNotice: () =>
            setState(() => _luggageSeatChangeNotice = null),
        onSyncBookingCargo: (draft) => _syncLuggageToBookingFlow(bloc, draft),
        onBack: () => bloc.add(const PreviousStepEvent()),
        onNext: () => _advanceWithLuggageSync(bloc),
        onStep: (index) => bloc.add(GoToStepEvent(index)),
        onDetails: () {
          if (trip != null) {
            TripDetailSheet.show(context, trip: trip, onSelectTrip: (_) {});
          }
        },
      );
    }

    if (state.step == BookingStep.tripSummary) {
      return BookingTripSummaryView(
        state: state,
        bloc: bloc,
        luggageCubit: _luggageCubit,
        luggageSeatChangeNotice: _luggageSeatChangeNotice,
        onDismissLuggageSeatChangeNotice: () =>
            setState(() => _luggageSeatChangeNotice = null),
        onSyncBookingCargo: (draft) => _syncLuggageToBookingFlow(bloc, draft),
        onBack: () => bloc.add(const PreviousStepEvent()),
        onNext: () => _advanceWithLuggageSync(bloc),
        onStep: (index) => bloc.add(GoToStepEvent(index)),
        onDetails: () {
          if (trip != null) {
            TripDetailSheet.show(context, trip: trip, onSelectTrip: (_) {});
          }
        },
      );
    }

    if (state.step == BookingStep.payment) {
      return BookingPaymentView(
        state: state,
        bloc: bloc,
        onBack: () async {
          final shouldPop = await _handlePop(context, state, bloc);
          if (shouldPop && context.mounted) context.pop();
        },
        onStep: (index) => bloc.add(GoToStepEvent(index)),
        onDetails: () {
          if (trip != null) {
            TripDetailSheet.show(context, trip: trip, onSelectTrip: (_) {});
          }
        },
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: state.step.title,
        subtitle: trip != null
            ? '${trip.operatorName} • ${trip.fromCityName} -> ${trip.toCityName}'
            : null,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () async {
            final shouldPop = await _handlePop(context, state, bloc);
            if (shouldPop && context.mounted) {
              context.pop();
            }
          },
        ),
      ),
      body:
          state.status == BookingFlowStatus.loading && state.seatLayout == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                BookingStepper(
                  currentStep: state.step,
                  onStepTapped: (index) => bloc.add(GoToStepEvent(index)),
                ),
                if (state.seatHold != null &&
                    state.step != BookingStep.seatSelection)
                  SeatHoldCountdownBar(
                    remainingSeconds: state.countdownSeconds,
                    seatCodes: state.selectedSeats.map((s) => s.name).toList(),
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildCurrentStepView(state, bloc),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: state.status == BookingFlowStatus.loading
          ? null
          : BookingBottomBar(
              state: state,
              onNext: () => bloc.add(const NextStepEvent()),
              onBack: () => bloc.add(const PreviousStepEvent()),
              onConfirmPayment: () => bloc.add(const ConfirmPaymentEvent()),
            ),
    );
  }

  Widget _buildCurrentStepView(BookingFlowState state, BookingFlowBloc bloc) {
    switch (state.step) {
      case BookingStep.seatSelection:
        return Step1SeatSelection(
          key: const ValueKey('step_1_seats'),
          state: state,
          bloc: bloc,
        );

      case BookingStep.pickupPoint:
        return Step2PickupPoint(
          key: const ValueKey('step_2_pickup'),
          state: state,
          bloc: bloc,
        );

      case BookingStep.dropoffPoint:
        return Step3DropoffPoint(
          key: const ValueKey('step_3_dropoff'),
          state: state,
          bloc: bloc,
        );

      case BookingStep.passengerInfo:
        return Step4PassengerInfo(
          key: const ValueKey('step_4_passenger'),
          state: state,
          bloc: bloc,
        );

      case BookingStep.tripSummary:
        return Step5TripSummary(
          key: const ValueKey('step_5_summary'),
          state: state,
          bloc: bloc,
        );

      case BookingStep.payment:
        return Step6Payment(
          key: const ValueKey('step_6_payment'),
          state: state,
          bloc: bloc,
        );
    }
  }
}
