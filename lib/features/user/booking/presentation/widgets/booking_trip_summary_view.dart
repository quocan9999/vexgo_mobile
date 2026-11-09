import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/booking_cargo_model.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/bloc/luggage_cubit.dart';
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
  final LuggageCubit? luggageCubit;
  final String? luggageSeatChangeNotice;
  final VoidCallback? onDismissLuggageSeatChangeNotice;
  final Future<void> Function(BookingCargoDraft? draft)? onSyncBookingCargo;

  const BookingTripSummaryView({
    super.key,
    required this.state,
    required this.bloc,
    required this.onBack,
    required this.onNext,
    this.onStep,
    this.onDetails,
    this.luggageCubit,
    this.luggageSeatChangeNotice,
    this.onDismissLuggageSeatChangeNotice,
    this.onSyncBookingCargo,
  });

  @override
  Widget build(BuildContext context) {
    final busy =
        state.status == BookingFlowStatus.loading ||
        state.status == BookingFlowStatus.submitting ||
        state.isCheckoutLocked;
    final mediaQuery = MediaQuery.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final availableHeight = mediaQuery.size.height;
    final isShortViewport =
        mediaQuery.size.height < 420 || availableHeight < 380;
    final inlineCountdown = isShortViewport || textScale > 1.35;

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
      luggageCubit: luggageCubit,
      luggageSeatChangeNotice: luggageSeatChangeNotice,
      onDismissLuggageSeatChangeNotice: onDismissLuggageSeatChangeNotice,
      onSyncBookingCargo: onSyncBookingCargo,
    );

    return DiscoveryTheme(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
          luggageCubit: luggageCubit,
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
  final LuggageCubit? luggageCubit;

  const BookingTripSummaryDock({
    super.key,
    required this.state,
    required this.onBack,
    required this.onNext,
    this.luggageCubit,
  });

  @override
  Widget build(BuildContext context) {
    if (luggageCubit != null) {
      return BlocBuilder<LuggageCubit, LuggageState>(
        bloc: luggageCubit,
        builder: (context, _) => _buildDockContent(context),
      );
    }
    return _buildDockContent(context);
  }

  Widget _buildDockContent(BuildContext context) {
    final busy =
        state.status == BookingFlowStatus.loading ||
        state.status == BookingFlowStatus.submitting ||
        state.isCheckoutLocked ||
        state.cargo.loading;
    final expired = state.seatHold == null || state.countdownSeconds <= 0;
    final luggageError = luggageCubit?.validationError;
    final luggageValid =
        luggageCubit == null ||
        (luggageError == null &&
            (luggageCubit!.state.phase == LuggagePhase.idle ||
                luggageCubit!.policyIsFresh));
    final enabled = state.canProceed && luggageValid && !busy && !expired;

    final mediaQuery = MediaQuery.of(context);
    final isShortViewport = mediaQuery.size.height < 420;
    final compactDock = isShortViewport;

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
                      context.l10n.uiTotalPayment,
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
                                ? context.l10n.uiVerifyingFare
                                : state.cargo.enabled &&
                                      state.ticketFinalAmount != null
                                ? context.l10n.uiTicket(
                                    CurrencyFormatter.format(
                                      state.ticketFinalAmount!,
                                    ),
                                  )
                                : state.cargo.enabled
                                ? context.l10n.uiCalculatedWhenBookingIsCreated
                                : context.l10n.uiFareUnavailable),
                      style: DiscoveryTextStyles.titleMedium.copyWith(
                        color: DiscoveryColors.secondary,
                        fontWeight: FontWeight.w800,
                        fontSize: compactDock ? 16 : 18,
                      ),
                    ),
                    if (state.cargo.enabled && state.finalAmount == null)
                      Text(
                        context.l10n.uiItemFeesArePaidSeparatelyAtTheStation,
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.neutral600,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (state.discountAmount > 0)
                      Text(
                        context.l10n.uiDiscounted(
                          CurrencyFormatter.format(state.discountAmount),
                        ),
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.successDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                );

                final ctaBtn = DiscoveryButton(
                  text: context.l10n.uiPayment,
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
                          context.l10n.uiYourSeatHoldHasExpiredSelectYourSeats,
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
                        context.l10n.uiYourSeatHoldHasExpiredSelectYourSeats,
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
