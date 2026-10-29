import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/widgets/custom_app_bar.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
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

  const BookingFlowScreen({
    super.key,
    required this.trip,
    required this.date,
    this.ticketCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    final authUser = auth.isAuthenticated ? auth.user : null;
    return BlocProvider(
      create: (context) =>
          BookingFlowBloc(
            seatRepository: context.read<SeatRepository>(),
            bookingRepository: context.read<BookingRepository>(),
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
      child: const _BookingFlowContent(),
    );
  }
}

class _BookingFlowContent extends StatefulWidget {
  const _BookingFlowContent();
  @override
  State<_BookingFlowContent> createState() => _BookingFlowContentState();
}

class _BookingFlowContentState extends State<_BookingFlowContent>
    with WidgetsBindingObserver {
  int? _initialAccountId;
  bool _initialAuthenticated = false;

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
            },
          );
        } else if (state.errorMessage != null) {
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
          child: _buildStepShell(context, state, bloc),
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
        onBack: () => bloc.add(const PreviousStepEvent()),
        onNext: () => bloc.add(const NextStepEvent()),
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
        onBack: () => bloc.add(const PreviousStepEvent()),
        onNext: () => bloc.add(const NextStepEvent()),
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
