import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import '../steps/step_6_payment.dart';
import 'booking_stepper.dart';
import 'seat_hold_countdown_bar.dart';
import 'payment_display_state.dart';

/// Scoped shell for Step 6 (Thanh toán vé) sharing BookingCompactHeader & Stepper with Steps 1–5.
class BookingPaymentView extends StatelessWidget {
  final BookingFlowState state;
  final BookingFlowBloc bloc;
  final VoidCallback onBack;
  final ValueChanged<int>? onStep;
  final VoidCallback? onDetails;

  const BookingPaymentView({
    super.key,
    required this.state,
    required this.bloc,
    required this.onBack,
    this.onStep,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final busy =
        state.status == BookingFlowStatus.loading ||
        state.status == BookingFlowStatus.submitting;
    final mediaQuery = MediaQuery.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final isShortViewport =
        mediaQuery.size.height < 420 || availableHeight < 380;
    final inlineCountdown =
        isShortViewport || textScale > 1.35 || mediaQuery.viewInsets.bottom > 0;

    // Disallow prior-step tapping when checkout is locked or submitting
    final effectiveOnStep = (state.isCheckoutLocked || busy)
        ? null
        : (onStep ?? (index) => bloc.add(GoToStepEvent(index)));

    final header = BookingCompactHeader(
      state: state,
      onBack: onBack,
      onStep: effectiveOnStep,
      onDetails: onDetails,
      busy: busy,
      compact: isShortViewport,
    );

    final paymentStep = Step6Payment(
      key: const ValueKey('step_6_payment'),
      state: state,
      bloc: bloc,
      showInlineCountdown:
          state.pendingBookingId == null &&
          state.seatHold != null &&
          inlineCountdown,
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
                  if (state.pendingBookingId == null &&
                      state.seatHold != null &&
                      !inlineCountdown)
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
          body: paymentStep,
        ),
        bottomNavigationBar: BookingPaymentDock(state: state, bloc: bloc),
      ),
    );
  }
}

/// Bottom dock for Step 6 displaying payment status and single clear CTA.
class BookingPaymentDock extends StatelessWidget {
  final BookingFlowState state;
  final BookingFlowBloc bloc;

  const BookingPaymentDock({
    super.key,
    required this.state,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    final isSubmitting = state.status == BookingFlowStatus.submitting;
    final hasPendingOrder = state.pendingBookingId != null;
    final isUnknown = state.bookingOutcomeUnknown;
    final isBlocked = state.status == BookingFlowStatus.blockedByBackend;

    final isPaid = state.hasConfirmedPayment;

    // Evaluate authoritative deadlines
    final bool isHoldExpired =
        !hasPendingOrder &&
        (state.seatHold == null || state.countdownSeconds <= 0);
    final isOrderExpired = state.paymentDeadlineExpired(DateTime.now());

    final mediaQuery = MediaQuery.of(context);
    final keyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final isShortViewport = mediaQuery.size.height < 420;
    final compactDock = keyboardOpen || isShortViewport;

    final bool canPress;
    final String ctaText;
    final IconData? ctaIcon;

    if (!hasPendingOrder) {
      ctaText = state.finalAmount != null
          ? 'Thanh toán ${CurrencyFormatter.format(state.finalAmount!)}'
          : 'Thanh toán';
      ctaIcon = Icons.shield_rounded;
      canPress =
          !isSubmitting &&
          !isUnknown &&
          !isBlocked &&
          !isHoldExpired &&
          state.canProceed &&
          state.hasUsableQuote;
    } else {
      ctaText = 'Kiểm tra kết quả thanh toán';
      ctaIcon = Icons.refresh_rounded;
      canPress = !isSubmitting && !isBlocked && !isUnknown;
    }

    return Material(
      color: Colors.white,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * (compactDock ? 0.36 : 0.46),
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

                final int? displayAmount = hasPendingOrder
                    ? (state.checkoutBooking?.totalAmount ??
                          state.pendingPaymentAmount ??
                          state.finalAmount)
                    : state.finalAmount;

                final priceSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isPaid
                          ? 'Đã thanh toán:'
                          : hasPendingOrder
                          ? 'Giá trị đơn:'
                          : 'Tổng thanh toán:',
                      style: DiscoveryTextStyles.caption.copyWith(
                        color: DiscoveryColors.neutral500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      displayAmount != null
                          ? CurrencyFormatter.format(displayAmount)
                          : (state.quoteLoading
                                ? 'Đang xác minh giá'
                                : 'Chưa có giá vé'),
                      style: DiscoveryTextStyles.titleMedium.copyWith(
                        color: DiscoveryColors.secondary,
                        fontWeight: FontWeight.w800,
                        fontSize: compactDock ? 16 : 18,
                      ),
                    ),
                    if (hasPendingOrder)
                      Text(
                        'Đơn #${state.pendingBookingId}',
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.neutral600,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (state.discountAmount > 0)
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
                  text: ctaText,
                  prefixIcon: ctaIcon != null
                      ? Icon(ctaIcon, size: 18, color: Colors.white)
                      : null,
                  type: ButtonType.secondary,
                  isLoading: isSubmitting,
                  width: stack
                      ? double.infinity
                      : (hasPendingOrder ? 210 : 170),
                  onPressed: canPress
                      ? () => bloc.add(const ConfirmPaymentEvent())
                      : null,
                );

                Widget? alertBelow;
                if (!hasPendingOrder && isHoldExpired) {
                  alertBelow = Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Thời gian giữ ghế đã hết. Vui lòng chọn lại ghế.',
                      style: DiscoveryTextStyles.caption.copyWith(
                        color: DiscoveryColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                } else if (hasPendingOrder &&
                    isPaid &&
                    state.status == BookingFlowStatus.failure) {
                  alertBelow = Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Đã xác nhận thanh toán. Nhấn kiểm tra để nhận vé.',
                      style: DiscoveryTextStyles.caption.copyWith(
                        color: DiscoveryColors.successDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                } else if (hasPendingOrder && isOrderExpired) {
                  alertBelow = Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Đơn đặt vé đã hết hạn thanh toán.',
                      style: DiscoveryTextStyles.caption.copyWith(
                        color: DiscoveryColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                } else if (isUnknown) {
                  alertBelow = Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Kết quả chưa xác định. Vui lòng kiểm tra Vé của tôi.',
                      style: DiscoveryTextStyles.caption.copyWith(
                        color: DiscoveryColors.warningDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

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
                      ?alertBelow,
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
                        const SizedBox(width: 10),
                        ctaBtn,
                      ],
                    ),
                    ?alertBelow,
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
