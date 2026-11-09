import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:vexgo_app/data/models/cargo_settlement.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/network/vietqr_config.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_cargo_section_card.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/payment_display_state.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_checkout_cubit.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';

/// One combo QR only after both independent orders are confirmed by the server.
class RoundTripPaymentView extends StatefulWidget {
  final RoundTripRequest request;
  final RoundTripCheckoutState state;
  final ValueChanged<TripLeg> onRecheck;
  final VoidCallback? onRecheckAll;
  final VietQrReceivingAccount receivingAccount;
  final VoidCallback? onRetrySubmitMissing;
  final ValueChanged<TripLeg>? onEditMissingLeg;
  final VoidCallback onOpenMyTickets;
  final VoidCallback onOpenSupport;

  const RoundTripPaymentView({
    super.key,
    required this.request,
    required this.state,
    required this.onRecheck,
    this.onRecheckAll,
    this.receivingAccount = VietQrConfig.account,
    this.onRetrySubmitMissing,
    this.onEditMissingLeg,
    required this.onOpenMyTickets,
    required this.onOpenSupport,
  });

  @override
  State<RoundTripPaymentView> createState() => _RoundTripPaymentViewState();
}

class _RoundTripPaymentViewState extends State<RoundTripPaymentView>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final out = widget.state.outbound;
    final back = widget.state.inbound;
    final phase = widget.state.phase;

    final partiallyPaid = phase == RoundTripPhase.partiallyPaid;
    final hasUnknown = widget.state.hasUnknownOutcome;
    final conflict = widget.state.ordersConflict;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner notification
          if (conflict) ...[
            _buildAlertBanner(
              color: DiscoveryColors.errorLight,
              borderColor: DiscoveryColors.error,
              icon: Icons.warning_rounded,
              iconColor: DiscoveryColors.error,
              title: context.l10n.uiDuplicateBookingCodes,
              message: context.l10n.uiTheTwoLegsHaveDuplicateBookingOrTransfer,
            ),
          ] else if (hasUnknown) ...[
            _buildAlertBanner(
              color: DiscoveryColors.warningLight,
              borderColor: DiscoveryColors.warning,
              icon: Icons.help_outline_rounded,
              iconColor: DiscoveryColors.warningDark,
              title: context.l10n.uiBookingStatusNeedsVerification,
              message:
                  context.l10n.uiNoBookingConfirmationWasReceivedDoNotCreate,
            ),
          ] else if (partiallyPaid && !widget.state.canDisplayCombo(now)) ...[
            _buildAlertBanner(
              color: DiscoveryColors.primaryLight,
              borderColor: DiscoveryColors.primary,
              icon: Icons.check_circle_rounded,
              iconColor: DiscoveryColors.primary,
              title: context.l10n.uiOneLegPaid,
              message: widget.state.requestedComboCode != null
                  ? context.l10n.uiPaymentForOneLegIsRecordedCheckBoth
                  : context.l10n.uiPaymentForIsCompletePayForToComplete(
                      out.paymentConfirmed
                          ? context.l10n.uiOutbound
                          : context.l10n.uiReturn,
                      out.paymentConfirmed
                          ? context.l10n.uiReturn
                          : context.l10n.uiOutbound,
                    ),
            ),
          ] else ...[
            _buildAlertBanner(
              color: DiscoveryColors.primaryLight,
              borderColor: DiscoveryColors.primary.withValues(alpha: 0.3),
              icon: Icons.payment_rounded,
              iconColor: DiscoveryColors.primary,
              title: widget.state.requestedComboCode == null
                  ? context.l10n.uiPayForEachLegSeparately
                  : context.l10n.uiPayForBothLegsTogether,
              message: widget.state.requestedComboCode == null
                  ? context.l10n.uiTransferTheExactAmountAndReferenceForEach
                  : context.l10n.uiTransferOnlyAfterBothBookingsAndTheCombined,
            ),
          ],

          const SizedBox(height: 16),

          if (widget.state.canDisplayCombo(now)) ...[
            _buildComboPaymentCard(context, now),
            const SizedBox(height: 16),
          ],

          if (widget.state.requestedComboCode != null &&
              widget.state.hasAnyOrder &&
              !widget.state.canDisplayCombo(now)) ...[
            OutlinedButton.icon(
              key: const ValueKey('round-trip-combo-check-all'),
              onPressed: widget.state.busy ? null : widget.onRecheckAll,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.uiCheckBothBookings),
            ),
            const SizedBox(height: 16),
          ],

          // Payment Card 1: Lượt đi
          _buildLegPaymentCard(
            context,
            leg: TripLeg.outbound,
            title: context.l10n.ui1OutboundPayment(
              widget.request.origin.name,
              widget.request.destination.name,
            ),
            state: out,
            now: now,
          ),

          const SizedBox(height: 16),

          // Payment Card 2: Lượt về
          _buildLegPaymentCard(
            context,
            leg: TripLeg.inbound,
            title: context.l10n.ui2ReturnPayment(
              widget.request.destination.name,
              widget.request.origin.name,
            ),
            state: back,
            now: now,
          ),

          const SizedBox(height: 24),

          // Utility buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onOpenMyTickets,
                  icon: const Icon(
                    Icons.confirmation_number_outlined,
                    size: 18,
                  ),
                  label: Text(context.l10n.uiMyTickets),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    side: const BorderSide(color: DiscoveryColors.neutral300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onOpenSupport,
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: Text(context.l10n.uiCustomerSupport),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    side: const BorderSide(color: DiscoveryColors.neutral300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner({
    required Color color,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DiscoveryTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    color: DiscoveryColors.neutral800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboPaymentCard(BuildContext context, DateTime now) {
    final state = widget.state;
    final code = state.confirmedComboCode!;
    final amount = state.comboAmount!;
    final account = widget.receivingAccount;
    final url = account.imageUrl(amount, code);
    return Container(
      key: const ValueKey('round-trip-combo-payment'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DiscoveryColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.uiRoundTripPayment,
            style: DiscoveryTextStyles.titleSmall,
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.format(amount),
            key: const ValueKey('round-trip-combo-amount'),
            style: DiscoveryTextStyles.price,
          ),
          if (state.comboExpiresAt != null) ...[
            const SizedBox(height: 8),
            _buildCountdown(state.comboExpiresAt!, now),
          ],
          const SizedBox(height: 16),
          if (url != null) ...[
            Center(
              child: Image.network(
                url,
                key: const ValueKey('round-trip-combo-qr'),
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (_, error, stack) => SizedBox(
                  height: 64,
                  child: Center(
                    child: Text(context.l10n.uiUnableToLoadTheQrImageUseThe),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildCopyableRow(
              label: context.l10n.uiBank,
              value: account.bankId,
              copyText: account.bankId,
            ),
            const SizedBox(height: 8),
            _buildCopyableRow(
              label: context.l10n.uiAccountNumber,
              value: account.accountNumber,
              copyText: account.accountNumber,
            ),
            const SizedBox(height: 8),
            _buildCopyableRow(
              label: context.l10n.uiAccountHolder,
              value: account.accountName,
              copyText: account.accountName,
            ),
            const SizedBox(height: 8),
            _buildCopyableRow(
              label: context.l10n.uiReference,
              value: code,
              copyText: code,
              highlight: true,
            ),
          ] else
            Text(
              context
                  .l10n
                  .uiReceivingAccountDetailsAreNotConfiguredContactSupport,
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('round-trip-combo-recheck'),
              onPressed: widget.onRecheckAll,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.uiCheckPaymentForBothLegs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegPaymentCard(
    BuildContext context, {
    required TripLeg leg,
    required String title,
    required BookingFlowState state,
    required DateTime now,
  }) {
    final booking = state.checkoutBooking;
    final isPaid = state.paymentConfirmed;
    final isExpired = state.paymentDeadlineExpired(now);
    final canTransfer = widget.state.canDisplayTransfer(leg, now);
    final hasOrder = state.pendingBookingId != null;
    final needsTicketSync =
        isPaid &&
        (state.status != BookingFlowStatus.success ||
            state.createdTickets.isEmpty);
    final legError =
        (state.status == BookingFlowStatus.failure ||
            state.status == BookingFlowStatus.blockedByBackend ||
            !hasOrder)
        ? (state.errorMessage ?? (!hasOrder ? widget.state.error : null))
        : null;

    final qrUrl =
        state.pendingQrCodeUrl ??
        ((booking?.orderCode != null && (booking?.totalAmount ?? 0) > 0)
            ? VietQrConfig.imageUrl(booking!.totalAmount, booking.orderCode!)
            : null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPaid ? DiscoveryColors.success : DiscoveryColors.neutral200,
          width: isPaid ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Status Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DiscoveryTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (isPaid)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.successLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: DiscoveryColors.success),
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: DiscoveryColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.uiPaida446a8,
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.successDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isExpired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.neutral100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    context.l10n.uiExpired303872,
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (hasOrder)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.warningLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    context.l10n.uiAwaitingPayment,
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.warningDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.neutral100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    context.l10n.uiNotBooked,
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Order ID & Amount
          if (booking != null) ...[
            _buildCopyableRow(
              label: context.l10n.uiBookingCode,
              value: '#${booking.bookingId}',
              copyText: '${booking.bookingId}',
            ),
            const SizedBox(height: 6),
            _buildCopyableRow(
              label: widget.state.requestedComboCode != null
                  ? context.l10n.uiLegTransactionCode
                  : context.l10n.uiTransferReference,
              value: booking.orderCode ?? '',
              copyText: booking.orderCode ?? '',
              highlight: true,
            ),
            const SizedBox(height: 6),
            if (BookingCargoSummaryBox.hasCargo(
              state: state,
              booking: booking,
            )) ...[
              if (booking.ticketSubtotal != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        Text(
                          context.l10n.uiFareAfterDiscounts,
                          style: DiscoveryTextStyles.bodySmall.copyWith(
                            color: DiscoveryColors.neutral600,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(booking.ticketSubtotal!),
                          style: DiscoveryTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (booking.shippingFee != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        Text(
                          cargoSettlementLabel(booking.cargoPayment),
                          style: DiscoveryTextStyles.bodySmall.copyWith(
                            color: DiscoveryColors.neutral600,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(booking.shippingFee!),
                          style: DiscoveryTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 2,
                children: [
                  Text(
                    context.l10n.uiAmountToTransfer,
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      color: DiscoveryColors.neutral600,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(booking.totalAmount),
                    style: DiscoveryTextStyles.titleMedium.copyWith(
                      color: DiscoveryColors.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (BookingCargoSummaryBox.hasCargo(
              state: state,
              booking: booking,
            )) ...[
              const SizedBox(height: 10),
              BookingCargoSummaryBox(
                state: state,
                booking: booking,
                scopeKey: 'payment-${leg.name}',
              ),
            ],
          ] else ...[
            if (state.selectedSeats.isNotEmpty)
              Text(
                context.l10n.uiSelectedSeats09ff88(
                  state.selectedSeats.map((s) => s.name).join(", "),
                ),
                style: DiscoveryTextStyles.bodySmall.copyWith(
                  color: DiscoveryColors.neutral700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (state.finalAmount != null) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    Text(
                      context.l10n.uiEstimatedAmount,
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.neutral600,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(state.finalAmount!),
                      style: DiscoveryTextStyles.titleSmall.copyWith(
                        color: DiscoveryColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (state.cargo.enabled) ...[
              const SizedBox(height: 6),
              BookingCargoSummaryBox(
                state: state,
                scopeKey: 'payment-${leg.name}',
              ),
            ],
          ],

          if (legError != null && legError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DiscoveryColors.errorLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DiscoveryColors.error),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: DiscoveryColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      legError,
                      style: DiscoveryTextStyles.caption.copyWith(
                        color: DiscoveryColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // QR Code section
          if (canTransfer && booking != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: DiscoveryColors.neutral200),
            const SizedBox(height: 14),
            Center(
              child: Column(
                children: [
                  if (qrUrl != null && qrUrl.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DiscoveryColors.neutral300),
                      ),
                      child: Image.network(
                        qrUrl,
                        width: 170,
                        height: 170,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 170,
                          height: 170,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            size: 100,
                            color: DiscoveryColors.neutral400,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (booking.expiresAt != null)
                    _buildCountdown(booking.expiresAt!, now),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Bank details
            _buildBankInfo(),
          ] else if (isPaid) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DiscoveryColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: DiscoveryColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      !needsTicketSync
                          ? context.l10n.uiETicketsIssuedSuccessfully
                          : context
                                .l10n
                                .uiPaymentReceivedTicketsAreBeingUpdated,
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.successDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isExpired) ...[
            const SizedBox(height: 10),
            Text(
              context.l10n.uiThePaymentDeadlineHasExpiredIfYouAlready,
              style: DiscoveryTextStyles.caption.copyWith(
                color: DiscoveryColors.neutral600,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Recheck Button (for unpaid orders OR paid orders needing ticket hydration)
          if (hasOrder && (!isPaid || needsTicketSync))
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: ValueKey('recheck-${leg.name}-btn'),
                onPressed: widget.state.busy
                    ? null
                    : () => widget.onRecheck(leg),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  isPaid
                      ? context.l10n.uiSyncTickets
                      : context.l10n.uiCheckPayment,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiscoveryColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: DiscoveryColors.neutral300,
                  minimumSize: const Size(double.infinity, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),

          // Retry / Edit actions for uncreated missing leg
          if (!hasOrder &&
              !state.bookingOutcomeUnknown &&
              !widget.state.hasUnknownOutcome) ...[
            if (widget.onRetrySubmitMissing != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: ValueKey('retry-create-${leg.name}-btn'),
                  onPressed: widget.state.busy
                      ? null
                      : widget.onRetrySubmitMissing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DiscoveryColors.secondary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: DiscoveryColors.neutral300,
                    minimumSize: const Size(double.infinity, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(context.l10n.uiRetryBookThisLeg),
                ),
              ),
            if (widget.onEditMissingLeg != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: ValueKey('edit-missing-${leg.name}-btn'),
                  onPressed: widget.state.busy
                      ? null
                      : () => widget.onEditMissingLeg!(leg),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    side: const BorderSide(color: DiscoveryColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(context.l10n.uiReselectSeatsStopsForThisLeg),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCountdown(DateTime expiresAt, DateTime now) {
    final diff = expiresAt.difference(now);
    if (diff.isNegative) {
      return Text(
        context.l10n.uiPaymentDeadlineExpiredbda98b,
        style: DiscoveryTextStyles.caption.copyWith(
          color: DiscoveryColors.error,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    final mins = diff.inMinutes.toString().padLeft(2, '0');
    final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        const Icon(
          Icons.timer_outlined,
          size: 16,
          color: DiscoveryColors.warningDark,
        ),
        const SizedBox(width: 4),
        Text(
          context.l10n.uiExpiresIn(mins, secs),
          style: DiscoveryTextStyles.caption.copyWith(
            color: DiscoveryColors.warningDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBankInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DiscoveryColors.neutral100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildCopyableRow(
            label: context.l10n.uiBank,
            value: VietQrConfig.bankId,
            copyText: VietQrConfig.bankId,
          ),
          const SizedBox(height: 6),
          _buildCopyableRow(
            label: context.l10n.uiAccountNumber,
            value: VietQrConfig.accountNumber,
            copyText: VietQrConfig.accountNumber,
            highlight: true,
          ),
          const SizedBox(height: 6),
          _buildCopyableRow(
            label: context.l10n.uiAccountHolder,
            value: VietQrConfig.accountName,
            copyText: VietQrConfig.accountName,
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableRow({
    required String label,
    required String value,
    required String copyText,
    bool highlight = false,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final detail = Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: DiscoveryTextStyles.bodySmall.copyWith(
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight
                    ? DiscoveryColors.primary
                    : DiscoveryColors.neutral900,
              ),
            ),
          ),
          IconButton(
            tooltip: context.l10n.uiCopy4ecb8d(label),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(
              Icons.copy_rounded,
              size: 20,
              color: DiscoveryColors.primary,
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: copyText));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.uiCopied),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      );
      final caption = Text(
        label,
        style: DiscoveryTextStyles.caption.copyWith(
          color: DiscoveryColors.neutral600,
        ),
      );
      if (constraints.maxWidth < 360) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [caption, detail],
        );
      }
      return Row(
        children: [
          Expanded(flex: 4, child: caption),
          Expanded(flex: 6, child: detail),
        ],
      );
    },
  );
}
