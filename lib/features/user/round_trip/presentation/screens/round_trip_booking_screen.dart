import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/app/routes.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/cargo_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/seat_legend.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/seat_map_view.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/stop_point_selection.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_checkout_cubit.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';
import '../widgets/round_trip_leg_header.dart';
import '../widgets/round_trip_passenger_step.dart';
import '../widgets/round_trip_payment_view.dart';
import '../widgets/round_trip_success_view.dart';
import '../widgets/round_trip_summary_step.dart';

class RoundTripBookingScreen extends StatelessWidget {
  final RoundTripSelection? selection;
  final RoundTripCheckoutCubit? cubit;

  const RoundTripBookingScreen({
    super.key,
    required this.selection,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (selection == null) {
      return DiscoveryTheme(
        child: Scaffold(
          backgroundColor: DiscoveryColors.background,
          appBar: AppBar(
            backgroundColor: DiscoveryColors.header,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.home),
            ),
            title: Text(
              'Đặt vé khứ hồi',
              style: DiscoveryTextStyles.titleMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 56,
                    color: DiscoveryColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Thiếu dữ liệu chuyến đi',
                    style: DiscoveryTextStyles.h1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Không tìm thấy thông tin cặp chuyến đã chọn. Vui lòng quay lại tìm chuyến.',
                    style: DiscoveryTextStyles.bodyMedium.copyWith(
                      color: DiscoveryColors.neutral600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DiscoveryColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(180, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.home),
                    child: const Text('Quay lại tìm kiếm'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final view = _RoundTripBookingView(selection: selection!);
    return DiscoveryTheme(
      child: cubit != null
          ? BlocProvider<RoundTripCheckoutCubit>.value(
              value: cubit!,
              child: view,
            )
          : BlocProvider<RoundTripCheckoutCubit>(
              create: (context) {
                final c = RoundTripCheckoutCubit(
                  request: selection!.request,
                  outbound: selection!.outbound,
                  inbound: selection!.inbound,
                  seatRepository: context.read<SeatRepository>(),
                  bookingRepository: context.read<BookingRepository>(),
                  cargoRepository: context.read<CargoRepository?>(),
                );
                // Hydrate user info from AuthBloc if logged in
                final auth = context.read<AuthBloc?>()?.state;
                if (auth != null && auth.isAuthenticated && auth.user != null) {
                  final u = auth.user!;
                  c.updatePassenger(
                    UpdatePassengerInfoEvent(
                      name: u.hoTen,
                      phone: u.soDienThoai,
                      email: u.email ?? '',
                    ),
                  );
                }
                return c;
              },
              child: view,
            ),
    );
  }
}

class _RoundTripBookingView extends StatefulWidget {
  final RoundTripSelection selection;

  const _RoundTripBookingView({required this.selection});

  @override
  State<_RoundTripBookingView> createState() => _RoundTripBookingViewState();
}

class _RoundTripBookingViewState extends State<_RoundTripBookingView> {
  TripLeg _activeLeg = TripLeg.outbound;

  Future<bool> _handlePop(
    BuildContext context,
    RoundTripCheckoutState state,
  ) async {
    final cubit = context.read<RoundTripCheckoutCubit>();
    if (state.busy) return false;

    // After orders are created: confirm without auto cancelling
    if (state.hasAnyOrder) {
      final exit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rời khỏi trang thanh toán?'),
          content: const Text(
            'Đơn hàng của bạn đã được ghi nhận trên hệ thống. Việc rời khỏi đây sẽ không tự động hủy đơn. Bạn có thể tra cứu và thanh toán lại tại mục "Vé của tôi".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Ở lại'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Rời khỏi',
                style: TextStyle(color: DiscoveryColors.error),
              ),
            ),
          ],
        ),
      );
      return exit ?? false;
    }

    // Step backwards through the flow
    final bothAtSummaryOrPayment =
        state.outbound.step.index >= BookingStep.tripSummary.index &&
        state.inbound.step.index >= BookingStep.tripSummary.index;
    if (bothAtSummaryOrPayment) {
      if (state.outbound.pendingBookingId == null) {
        cubit.dispatch(
          TripLeg.outbound,
          GoToStepEvent(BookingStep.passengerInfo.index),
        );
      }
      if (state.inbound.pendingBookingId == null) {
        cubit.dispatch(
          TripLeg.inbound,
          GoToStepEvent(BookingStep.passengerInfo.index),
        );
      }
      return false;
    }

    final bothAtPassenger =
        state.outbound.step.index >= BookingStep.passengerInfo.index &&
        state.inbound.step.index >= BookingStep.passengerInfo.index;
    if (bothAtPassenger) {
      final targetLeg = state.leg(_activeLeg).pendingBookingId == null
          ? _activeLeg
          : (_activeLeg == TripLeg.outbound
                ? TripLeg.inbound
                : TripLeg.outbound);
      cubit.dispatch(targetLeg, GoToStepEvent(BookingStep.dropoffPoint.index));
      return false;
    }

    final activeState = state.leg(_activeLeg);
    if (activeState.step.index > 0) {
      cubit.dispatch(_activeLeg, const PreviousStepEvent());
      return false;
    }

    if (_activeLeg == TripLeg.inbound) {
      setState(() => _activeLeg = TripLeg.outbound);
      return false;
    }

    // At the very beginning of outbound: confirm release of holds
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thoát khỏi đặt vé khứ hồi?'),
        content: const Text(
          'Bạn có chắc chắn muốn rời khỏi tiến trình đặt vé không? Vị trí ghế đang giữ sẽ được giải phóng cho hành khách khác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tiếp tục đặt vé'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Rời khỏi',
              style: TextStyle(color: DiscoveryColors.error),
            ),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  Future<void> _handleProceedToPayment(RoundTripCheckoutCubit cubit) async {
    if (cubit.state.outbound.pendingBookingId == null &&
        cubit.state.outbound.step == BookingStep.tripSummary) {
      cubit.dispatch(TripLeg.outbound, const NextStepEvent());
    }
    if (cubit.state.inbound.pendingBookingId == null &&
        cubit.state.inbound.step == BookingStep.tripSummary) {
      cubit.dispatch(TripLeg.inbound, const NextStepEvent());
    }

    // Wait until pending draft transitions settle
    while (!cubit.isClosed && cubit.state.busy) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    if (!cubit.isClosed &&
        cubit.state.outbound.step == BookingStep.payment &&
        cubit.state.inbound.step == BookingStep.payment) {
      await cubit.submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoundTripCheckoutCubit>();

    return BlocConsumer<RoundTripCheckoutCubit, RoundTripCheckoutState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: DiscoveryColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.invalidated) {
          return _buildSessionInvalidatedView(context);
        }

        if (state.isComplete) {
          return RoundTripSuccessView(
            request: widget.selection.request,
            outbound: state.outbound,
            inbound: state.inbound,
            onOpenMyTickets: () => context.go(AppRoutes.myTickets),
            onOpenHome: () => context.go(AppRoutes.home),
          );
        }

        final isEditingUncreatedLeg =
            state.hasAnyOrder &&
            !state.hasUnknownOutcome &&
            ((state.outbound.pendingBookingId == null &&
                    state.outbound.step != BookingStep.payment) ||
                (state.inbound.pendingBookingId == null &&
                    state.inbound.step != BookingStep.payment));

        final showPayment =
            !isEditingUncreatedLeg &&
            (state.hasAnyOrder ||
                state.hasUnknownOutcome ||
                state.phase == RoundTripPhase.paymentPending ||
                state.phase == RoundTripPhase.partiallyPaid ||
                state.phase == RoundTripPhase.partiallyCreated ||
                state.phase == RoundTripPhase.verificationRequired);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final canExit = await _handlePop(context, state);
            if (canExit && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: DiscoveryColors.background,
            body: Column(
              children: [
                RoundTripLegHeader(
                  request: widget.selection.request,
                  activeLeg: _activeLeg,
                  outboundState: state.outbound,
                  inboundState: state.inbound,
                  onLegChanged: (leg) => setState(() => _activeLeg = leg),
                  onBack: () async {
                    final canExit = await _handlePop(context, state);
                    if (canExit && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  busy: state.busy,
                ),
                Expanded(
                  child: showPayment
                      ? RoundTripPaymentView(
                          request: widget.selection.request,
                          state: state,
                          onRecheck: (leg) => cubit.recheck(leg),
                          onRetrySubmitMissing: () => cubit.submit(),
                          onEditMissingLeg: (leg) {
                            cubit.dispatch(
                              leg,
                              GoToStepEvent(BookingStep.seatSelection.index),
                            );
                            setState(() => _activeLeg = leg);
                          },
                          onOpenMyTickets: () =>
                              context.push(AppRoutes.myTickets),
                          onOpenSupport: () =>
                              context.push(AppRoutes.supportChat),
                        )
                      : _buildEditingStepContent(context, cubit, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditingStepContent(
    BuildContext context,
    RoundTripCheckoutCubit cubit,
    RoundTripCheckoutState state,
  ) {
    final bothAtSummary =
        state.outbound.step.index >= BookingStep.tripSummary.index &&
        state.inbound.step.index >= BookingStep.tripSummary.index;
    if (bothAtSummary) {
      return RoundTripSummaryStep(
        request: widget.selection.request,
        outbound: state.outbound,
        inbound: state.inbound,
        totalAmount: state.totalAmount,
        busy: state.busy,
        error: state.error,
        onApplyOutboundVoucher: (code) {
          if (state.outbound.step == BookingStep.payment) {
            cubit.dispatch(
              TripLeg.outbound,
              GoToStepEvent(BookingStep.tripSummary.index),
            );
          }
          cubit.dispatch(TripLeg.outbound, ApplyPromotionCodeEvent(code));
        },
        onRemoveOutboundVoucher: () {
          if (state.outbound.step == BookingStep.payment) {
            cubit.dispatch(
              TripLeg.outbound,
              GoToStepEvent(BookingStep.tripSummary.index),
            );
          }
          cubit.dispatch(TripLeg.outbound, const RemoveVoucherEvent());
        },
        onApplyInboundVoucher: (code) {
          if (state.inbound.step == BookingStep.payment) {
            cubit.dispatch(
              TripLeg.inbound,
              GoToStepEvent(BookingStep.tripSummary.index),
            );
          }
          cubit.dispatch(TripLeg.inbound, ApplyPromotionCodeEvent(code));
        },
        onRemoveInboundVoucher: () {
          if (state.inbound.step == BookingStep.payment) {
            cubit.dispatch(
              TripLeg.inbound,
              GoToStepEvent(BookingStep.tripSummary.index),
            );
          }
          cubit.dispatch(TripLeg.inbound, const RemoveVoucherEvent());
        },
        onEditLeg: (leg) {
          cubit.dispatch(leg, GoToStepEvent(BookingStep.seatSelection.index));
          setState(() => _activeLeg = leg);
        },
        onDispatchCargo: (leg, event) => cubit.dispatch(leg, event),
        onSubmit: () => _handleProceedToPayment(cubit),
        onBack: () {
          if (state.outbound.pendingBookingId == null) {
            cubit.dispatch(
              TripLeg.outbound,
              GoToStepEvent(BookingStep.passengerInfo.index),
            );
          }
          if (state.inbound.pendingBookingId == null) {
            cubit.dispatch(
              TripLeg.inbound,
              GoToStepEvent(BookingStep.passengerInfo.index),
            );
          }
        },
      );
    }

    final bothAtPassenger =
        state.outbound.step.index >= BookingStep.passengerInfo.index &&
        state.inbound.step.index >= BookingStep.passengerInfo.index;
    if (bothAtPassenger) {
      return RoundTripPassengerStep(
        readOnly: state.hasAnyOrder,
        initialName: state.outbound.passengerName,
        initialPhone: state.outbound.passengerPhone,
        initialEmail: state.outbound.passengerEmail,
        initialNote: state.outbound.passengerNote,
        outboundState: state.outbound,
        inboundState: state.inbound,
        onDispatchCargo: (leg, event) => cubit.dispatch(leg, event),
        isValid:
            state.outbound.isPassengerValid &&
            state.inbound.isPassengerValid &&
            state.outbound.cargo.isValid &&
            state.inbound.cargo.isValid,
        busy: state.busy,
        onUpdate: (event) => cubit.updatePassenger(event),
        onNext: () {
          if (state.outbound.step == BookingStep.passengerInfo) {
            cubit.dispatch(TripLeg.outbound, const NextStepEvent());
          }
          if (state.inbound.step == BookingStep.passengerInfo) {
            cubit.dispatch(TripLeg.inbound, const NextStepEvent());
          }
        },
        onBack: () {
          final targetLeg = state.leg(_activeLeg).pendingBookingId == null
              ? _activeLeg
              : (_activeLeg == TripLeg.outbound
                    ? TripLeg.inbound
                    : TripLeg.outbound);
          cubit.dispatch(
            targetLeg,
            GoToStepEvent(BookingStep.dropoffPoint.index),
          );
        },
      );
    }

    // Otherwise, configure the active leg
    final activeState = state.leg(_activeLeg);
    return _buildActiveLegConfig(context, cubit, state, activeState);
  }

  Widget _buildActiveLegConfig(
    BuildContext context,
    RoundTripCheckoutCubit cubit,
    RoundTripCheckoutState state,
    BookingFlowState activeState,
  ) {
    if (activeState.step.index >= BookingStep.passengerInfo.index) {
      final otherLeg = _activeLeg == TripLeg.outbound
          ? TripLeg.inbound
          : TripLeg.outbound;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 56,
                color: DiscoveryColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Đã xong ${_activeLeg == TripLeg.outbound ? "Lượt đi" : "Lượt về"}',
                style: DiscoveryTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Vui lòng chọn chỗ ngồi và điểm đón/trả cho ${otherLeg == TripLeg.outbound ? "Lượt đi" : "Lượt về"} để tiếp tục tiến trình.',
                style: DiscoveryTextStyles.bodyMedium.copyWith(
                  color: DiscoveryColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiscoveryColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(
                  'Chuyển sang ${otherLeg == TripLeg.outbound ? "Lượt đi" : "Lượt về"}',
                ),
                onPressed: () => setState(() => _activeLeg = otherLeg),
              ),
            ],
          ),
        ),
      );
    }

    switch (activeState.step) {
      case BookingStep.seatSelection:
        return _buildSeatStep(context, cubit, state, activeState);
      case BookingStep.pickupPoint:
        return _buildPickupStep(context, cubit, state, activeState);
      case BookingStep.dropoffPoint:
        return _buildDropoffStep(context, cubit, state, activeState);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSeatStep(
    BuildContext context,
    RoundTripCheckoutCubit cubit,
    RoundTripCheckoutState state,
    BookingFlowState activeState,
  ) {
    final layout = activeState.seatLayout;
    if (activeState.status == BookingFlowStatus.loading || layout == null) {
      return const Center(
        child: CircularProgressIndicator(color: DiscoveryColors.primary),
      );
    }

    final canContinue = activeState.isSeatsValid && !state.busy;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SeatLegend(),
                const SizedBox(height: 14),
                SeatMapView(
                  layout: layout,
                  selectedFloor: activeState.selectedFloor,
                  selectedSeats: activeState.selectedSeats,
                  onFloorChanged: (floor) =>
                      cubit.dispatch(_activeLeg, ChangeFloorEvent(floor)),
                  onSeatToggled: (seat) =>
                      cubit.dispatch(_activeLeg, ToggleSeatEvent(seat)),
                ),
              ],
            ),
          ),
        ),
        _buildBottomSelectionBar(
          context: context,
          seatCount: activeState.selectedSeats.length,
          seatNames: activeState.selectedSeats.map((s) => s.name).join(', '),
          totalPrice: activeState.finalAmount ?? 0,
          canContinue: canContinue,
          onNext: () {
            cubit.dispatch(_activeLeg, const NextStepEvent());
          },
        ),
      ],
    );
  }

  Widget _buildPickupStep(
    BuildContext context,
    RoundTripCheckoutCubit cubit,
    RoundTripCheckoutState state,
    BookingFlowState activeState,
  ) {
    final canContinue = activeState.isPickupValid && !state.busy;

    return Column(
      children: [
        Expanded(
          child: StopPointSelection(
            title:
                'Chọn điểm đón (${_activeLeg == TripLeg.outbound ? "Lượt đi" : "Lượt về"})',
            points: activeState.availablePickupPoints,
            selected: activeState.selectedPickupPoint,
            onSelected: (p) =>
                cubit.dispatch(_activeLeg, SelectPickupPointEvent(p)),
          ),
        ),
        _buildBottomSelectionBar(
          context: context,
          seatCount: activeState.selectedSeats.length,
          seatNames: activeState.selectedSeats.map((s) => s.name).join(', '),
          totalPrice: activeState.finalAmount ?? 0,
          canContinue: canContinue,
          onNext: () => cubit.dispatch(_activeLeg, const NextStepEvent()),
        ),
      ],
    );
  }

  Widget _buildDropoffStep(
    BuildContext context,
    RoundTripCheckoutCubit cubit,
    RoundTripCheckoutState state,
    BookingFlowState activeState,
  ) {
    final canContinue = activeState.isDropoffValid && !state.busy;

    return Column(
      children: [
        Expanded(
          child: StopPointSelection(
            title:
                'Chọn điểm trả (${_activeLeg == TripLeg.outbound ? "Lượt đi" : "Lượt về"})',
            points: activeState.availableDropoffPoints,
            selected: activeState.selectedDropoffPoint,
            onSelected: (p) =>
                cubit.dispatch(_activeLeg, SelectDropoffPointEvent(p)),
          ),
        ),
        _buildBottomSelectionBar(
          context: context,
          seatCount: activeState.selectedSeats.length,
          seatNames: activeState.selectedSeats.map((s) => s.name).join(', '),
          totalPrice: activeState.finalAmount ?? 0,
          canContinue: canContinue,
          onNext: () {
            cubit.dispatch(_activeLeg, const NextStepEvent());
            // If the other leg is still selecting seats, automatically switch to it
            final otherLeg = _activeLeg == TripLeg.outbound
                ? TripLeg.inbound
                : TripLeg.outbound;
            if (state.leg(otherLeg).step == BookingStep.seatSelection) {
              setState(() => _activeLeg = otherLeg);
            }
          },
        ),
      ],
    );
  }

  Widget _buildBottomSelectionBar({
    required BuildContext context,
    required int seatCount,
    required String seatNames,
    required int totalPrice,
    required bool canContinue,
    required VoidCallback onNext,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
        border: Border(top: BorderSide(color: DiscoveryColors.neutral200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seatCount > 0 ? 'Đã chọn: $seatNames' : 'Chưa chọn ghế',
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral700,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(totalPrice),
                    style: DiscoveryTextStyles.titleMedium.copyWith(
                      color: DiscoveryColors.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              key: const ValueKey('round-trip-step-next-btn'),
              onPressed: canContinue ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: DiscoveryColors.secondary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: DiscoveryColors.neutral300,
                minimumSize: const Size(120, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'Tiếp tục',
                style: DiscoveryTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInvalidatedView(BuildContext context) {
    return Scaffold(
      backgroundColor: DiscoveryColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_reset_rounded,
                size: 64,
                color: DiscoveryColors.warningDark,
              ),
              const SizedBox(height: 16),
              Text(
                'Phiên đăng nhập đã thay đổi',
                style: DiscoveryTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tài khoản đã đăng xuất hoặc thay đổi phiên. Vui lòng quay lại tìm kiếm chuyến đi mới.',
                style: DiscoveryTextStyles.bodyMedium.copyWith(
                  color: DiscoveryColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiscoveryColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Về Trang chủ'),
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
