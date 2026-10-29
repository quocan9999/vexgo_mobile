import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import '../steps/step_5_trip_summary.dart';
import 'booking_stepper.dart';
import 'seat_hold_countdown_bar.dart';

/// Scoped shell for Step 5 (Xác nhận đặt vé & mã ưu đãi) sharing BookingCompactHeader & Stepper with Steps 1–4.
class BookingTripSummaryView extends StatelessWidget {
  final BookingFlowState state;
  final BookingFlowBloc bloc;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final ValueChanged<int>? onStep;
  final VoidCallback? onDetails;

  const BookingTripSummaryView({
    super.key,
    required this.state,
    required this.bloc,
    required this.onBack,
    required this.onNext,
    this.onStep,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final busy =
        state.status == BookingFlowStatus.loading ||
        state.status == BookingFlowStatus.submitting ||
        state.isCheckoutLocked;
    final mediaQuery = MediaQuery.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final isShortViewport =
        mediaQuery.size.height < 420 || availableHeight < 380;
    final inlineCountdown =
        isShortViewport || textScale > 1.35 || mediaQuery.viewInsets.bottom > 0;

    final header = BookingCompactHeader(
      state: state,
      onBack: onBack,
      onStep: onStep ?? (index) => bloc.add(GoToStepEvent(index)),
      onDetails: onDetails,
      busy: busy,
      compact: isShortViewport,
    );

    final summaryStep = Step5TripSummary(
      key: const ValueKey('step_5_summary'),
      state: state,
      bloc: bloc,
      showInlineCountdown: state.seatHold != null && inlineCountdown,
    );

    return DiscoveryTheme(
      child: Scaffold(
        backgroundColor: DiscoveryColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  header,
                  if (state.seatHold != null && !inlineCountdown)
                    SeatHoldCountdownBar(
                      remainingSeconds: state.countdownSeconds,
                      compact: true,
                      seatCodes: state.selectedSeats
                          .map((s) => s.name)
                          .toList(),
                    ),
                ],
              ),
            ),
          ],
          body: summaryStep,
        ),
        bottomNavigationBar: BookingTripSummaryDock(
          state: state,
          onBack: onBack,
          onNext: onNext,
        ),
      ),
    );
  }
}

/// Bottom dock for Step 5 displaying total payment and CTA to proceed to payment (Step 6).
class BookingTripSummaryDock extends StatelessWidget {
  final BookingFlowState state;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const BookingTripSummaryDock({
    super.key,
    required this.state,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final busy =
        state.status == BookingFlowStatus.loading ||
        state.status == BookingFlowStatus.submitting ||
        state.isCheckoutLocked;
    final expired = state.seatHold == null || state.countdownSeconds <= 0;
    final enabled = state.canProceed && !busy && !expired;

    final mediaQuery = MediaQuery.of(context);
    final keyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final isShortViewport = mediaQuery.size.height < 420;
    final compactDock = keyboardOpen || isShortViewport;

    return Material(
      color: Colors.white,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * (compactDock ? 0.34 : 0.44),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              compactDock ? 8 : 10,
              16,
              compactDock ? 8 : 12,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final stack =
                    constraints.maxWidth < 340 &&
                    (textScale > 1.3 || constraints.maxWidth < 280);

                final priceSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tổng thanh toán:',
                      style: DiscoveryTextStyles.caption.copyWith(
                        color: DiscoveryColors.neutral500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      state.finalAmount != null
                          ? CurrencyFormatter.format(state.finalAmount!)
                          : (state.quoteLoading
                                ? 'Đang xác minh giá'
                                : state.cargo.enabled &&
                                      state.ticketFinalAmount != null
                                ? 'Vé ${CurrencyFormatter.format(state.ticketFinalAmount!)}'
                                : state.cargo.enabled
                                ? 'Xác định khi tạo đơn'
                                : 'Chưa có giá vé'),
                      style: DiscoveryTextStyles.titleMedium.copyWith(
                        color: DiscoveryColors.secondary,
                        fontWeight: FontWeight.w800,
                        fontSize: compactDock ? 16 : 18,
                      ),
                    ),
                    if (state.cargo.enabled && state.finalAmount == null)
                      Text(
                        'Phí gửi hàng được xác định khi tạo đơn',
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.neutral600,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (state.discountAmount > 0)
                      Text(
                        'Đã giảm ${CurrencyFormatter.format(state.discountAmount)}',
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.successDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                );

                final ctaBtn = DiscoveryButton(
                  text: 'Thanh toán',
                  type: ButtonType.secondary,
                  isLoading: state.status == BookingFlowStatus.submitting,
                  width: stack ? double.infinity : 160,
                  onPressed: enabled ? onNext : null,
                );

                if (stack) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Expanded(child: priceSection)],
                      ),
                      const SizedBox(height: 8),
                      ctaBtn,
                      if (expired) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Thời gian giữ ghế đã hết. Vui lòng chọn lại ghế.',
                          style: DiscoveryTextStyles.caption.copyWith(
                            color: DiscoveryColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: priceSection),
                        const SizedBox(width: 12),
                        ctaBtn,
                      ],
                    ),
                    if (expired) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Thời gian giữ ghế đã hết. Vui lòng chọn lại ghế.',
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
