import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'shipment_cancellation_section.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_typography.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart' hide ButtonType;
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/features/user/shipments/shipment_flow_cubit.dart';
import 'shipment_status_badge.dart';

class ShipmentDetailView extends StatefulWidget {
  final ShipmentFlowCubit cubit;
  final ShipmentFlowState state;
  final VoidCallback onNewShipment;
  final VoidCallback? onGoToList;
  final bool enablePollingTimer;
  final Widget Function(BuildContext context, String url)? qrImageBuilder;

  const ShipmentDetailView({
    super.key,
    required this.cubit,
    required this.state,
    required this.onNewShipment,
    this.onGoToList,
    this.enablePollingTimer = true,
    this.qrImageBuilder,
  });

  @override
  State<ShipmentDetailView> createState() => _ShipmentDetailViewState();
}

class _ShipmentDetailViewState extends State<ShipmentDetailView>
    with WidgetsBindingObserver {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enablePollingTimer &&
        widget.state.record?.paymentMethod == ShipmentPaymentMethod.online) {
      widget.cubit.refreshPayment();
      _startTicker();
    }
  }

  @override
  void didUpdateWidget(ShipmentDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.record?.status == ShipmentStatus.cancelled) {
      _stopTicker();
      return;
    }
    if (widget.enablePollingTimer &&
        widget.state.record?.paymentMethod == ShipmentPaymentMethod.online &&
        _ticker == null) {
      widget.cubit.refreshPayment();
      _startTicker();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // Re-render each second to evaluate paymentQrUrl freshness (< 30s)
      setState(() {});
      final record = widget.state.record;
      final verified = widget.cubit.verifiedPayment;
      if (record != null &&
          record.paymentMethod == ShipmentPaymentMethod.online &&
          verified?.paid != true &&
          !widget.state.refreshing) {
        final nextAt = widget.state.nextPaymentReadAt;
        if (nextAt == null || widget.cubit.now().toUtc().isAfter(nextAt)) {
          widget.cubit.refreshPayment();
        }
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (widget.enablePollingTimer &&
          widget.state.record?.paymentMethod == ShipmentPaymentMethod.online) {
        widget.cubit.refreshPayment();
        _startTicker();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopTicker();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTicker();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.uiCopiedd3e09c(label, text)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.state.record;
    if (record == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.state.refreshing)
                const CircularProgressIndicator()
              else ...[
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: DiscoveryColors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.state.refreshError ??
                      context.l10n.uiShipmentDetailsNotFound,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    color: DiscoveryColors.neutral700,
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: context.l10n.uiCreateNewShipment,
                  onPressed: widget.onNewShipment,
                  type: ButtonType.primary,
                ),
              ],
            ],
          ),
        ),
      );
    }

    final verifiedPayment = widget.cubit.verifiedPayment;
    final isPaid = verifiedPayment?.paid == true;
    final isOnline = record.paymentMethod == ShipmentPaymentMethod.online;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.base,
        AppDimensions.base,
        AppDimensions.base,
        AppDimensions.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header card: Waybill, order code, status
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.uiShipmentCode9dec85,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: DiscoveryColors.neutral500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  record.identity.waybillCode,
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: DiscoveryColors.primaryDark,
                                  ),
                                  softWrap: true,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  size: 18,
                                  color: DiscoveryColors.primary,
                                ),
                                tooltip: context.l10n.uiCopyShipmentCode,
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                onPressed: () => _copyToClipboard(
                                  record.identity.waybillCode,
                                  context.l10n.uiShipmentCode09837d,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ShipmentStatusBadge(status: record.status),
                  ],
                ),
                const Divider(height: 16, color: DiscoveryColors.neutral200),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.uiBookingCoded6f725,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        color: DiscoveryColors.neutral600,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        record.identity.orderCode,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DiscoveryColors.neutral900,
                        ),
                        softWrap: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      tooltip: context.l10n.uiCopyBookingCodeffae60,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: () => _copyToClipboard(
                        record.identity.orderCode,
                        context.l10n.uiBookingCodeee647d,
                      ),
                    ),
                  ],
                ),
                Text(
                  context.l10n.uiCreatedb409e6(
                    DateFormatter.formatDayMonthYear(record.sentAt.toLocal()),
                  ),
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    color: DiscoveryColors.neutral600,
                  ),
                ),
                if (record.expectedSendDate != null) ...[
                  Text(
                    context.l10n.uiExpectedShippingDate(
                      record.expectedSendDate ?? '—',
                    ),
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      color: DiscoveryColors.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Dropoff deadline banner if present
          if (record.dropoffDeadline != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.base),
              decoration: BoxDecoration(
                color: DiscoveryColors.warningLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: DiscoveryColors.warning),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: DiscoveryColors.warningDark,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.uiDropOffDeadline,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DiscoveryColors.warningDark,
                          ),
                        ),
                        Text(
                          _formatLocalDateTime(record.dropoffDeadline!),
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: DiscoveryColors.neutral900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Route & Carrier Card
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.directions_bus_rounded,
                      color: DiscoveryColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${record.trip.carrier} • ${record.trip.code ?? context.l10n.uiNoTripAssigned}',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: DiscoveryColors.neutral900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.uiRoute97d69f(
                    record.trip.origin,
                    record.trip.destination,
                  ),
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    color: DiscoveryColors.neutral700,
                  ),
                ),
                Text(
                  record.trip.departure == null
                      ? context.l10n.uiNoTripAssigned
                      : context.l10n.uiDeparture(
                          DateFormatter.formatFullDate(
                            record.trip.departure!.toLocal(),
                          ),
                        ),
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    color: DiscoveryColors.neutral600,
                  ),
                ),
                const Divider(height: 16, color: DiscoveryColors.neutral200),
                _buildPointRow(
                  icon: Icons.trip_origin_rounded,
                  iconColor: DiscoveryColors.primary,
                  label: context.l10n.uiDropOffPoint,
                  name: record.pickup.name,
                  address: record.pickup.address,
                ),
                const SizedBox(height: 8),
                _buildPointRow(
                  icon: Icons.location_on_rounded,
                  iconColor: DiscoveryColors.secondary,
                  label: context.l10n.uiCollectionPoint,
                  name: record.dropoff.name,
                  address: record.dropoff.address,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Contact details: Sender & Receiver
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.uiDeliveryInformation,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DiscoveryColors.neutral900,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.uiSenderfeefc2,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: DiscoveryColors.neutral500,
                            ),
                          ),
                          Text(
                            record.senderName,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: DiscoveryColors.neutral800,
                            ),
                          ),
                          Text(
                            record.senderPhone,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
                              color: DiscoveryColors.neutral700,
                            ),
                          ),
                          if (record.senderEmail != null &&
                              record.senderEmail!.isNotEmpty)
                            Text(
                              record.senderEmail!,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                color: DiscoveryColors.neutral500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.uiRecipient2a6b0f,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: DiscoveryColors.neutral500,
                            ),
                          ),
                          Text(
                            record.receiverName,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: DiscoveryColors.neutral800,
                            ),
                          ),
                          Text(
                            record.receiverPhone,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
                              color: DiscoveryColors.neutral700,
                            ),
                          ),
                          if (record.receiverCccd != null &&
                              record.receiverCccd!.isNotEmpty)
                            Text(
                              'CCCD: ${record.receiverCccd}',
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                color: DiscoveryColors.neutral500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Packages list
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.uiItemsCount(record.items.length),
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DiscoveryColors.neutral900,
                  ),
                ),
                const SizedBox(height: 8),
                ...record.items.map((pkg) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DiscoveryColors.neutral50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DiscoveryColors.neutral200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                pkg.name,
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: DiscoveryColors.neutral900,
                                ),
                              ),
                            ),
                            Text(
                              'x${pkg.quantity}',
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: DiscoveryColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.uiTypeWeightKgItem(
                            pkg.category,
                            pkg.weight,
                          ),
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            color: DiscoveryColors.neutral700,
                          ),
                        ),
                        if (pkg.dimensions != null &&
                            pkg.dimensions!.isNotEmpty) ...[
                          Text(
                            context.l10n.uiDimensions(pkg.dimensions ?? '—'),
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              color: DiscoveryColors.neutral600,
                            ),
                          ),
                        ],
                        if (pkg.note != null && pkg.note!.isNotEmpty) ...[
                          Text(
                            context.l10n.uiNotes(pkg.note ?? '—'),
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: DiscoveryColors.neutral600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Pricing Summary (Estimated vs Confirmed)
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.confirmedAt == null
                      ? context.l10n.uiEstimatedFee321adb
                      : context.l10n.uiConfirmedFee,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DiscoveryColors.neutral900,
                  ),
                ),
                if (record.confirmedAt == null) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.uiTheFinalFeeWillBeConfirmedAfterWeighing,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      color: DiscoveryColors.neutral600,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.uiConfirmed(
                      _formatLocalDateTime(record.confirmedAt!),
                    ),
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      color: DiscoveryColors.neutral600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _buildFeeRow(context.l10n.uiBaseFee, record.baseFee),
                _buildFeeRow(
                  context.l10n.uiServiceSurcharge,
                  record.serviceFee,
                ),
                if (record.discount > 0)
                  _buildFeeRow(context.l10n.uiDiscount, -record.discount),
                const Divider(height: 16, color: DiscoveryColors.neutral200),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.uiTotalShippingFee,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: DiscoveryColors.neutral900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.format(record.totalFee),
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: DiscoveryColors.primary,
                      ),
                    ),
                  ],
                ),
                if (record.paidAmount != null) ...[
                  const SizedBox(height: 6),
                  _buildFeeRow(context.l10n.uiPaid, record.paidAmount!),
                ],
                if (record.outstandingAmount != null &&
                    record.status != ShipmentStatus.cancelled) ...[
                  const SizedBox(height: 4),
                  _buildFeeRow(
                    context.l10n.uiAmountOutstanding,
                    record.outstandingAmount!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment Handling Block
          if (record.status == ShipmentStatus.cancelled) ...[
            Text(context.l10n.uiThisShipmentIsCancelledDoNotBringItems),
          ] else if (!isOnline) ...[
            // COUNTER PAYMENT VIEW
            Container(
              padding: const EdgeInsets.all(AppDimensions.base),
              decoration: BoxDecoration(
                color: DiscoveryColors.primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: DiscoveryColors.primary),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.store_rounded,
                    color: DiscoveryColors.primary,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.uiPayAtTheStation,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: DiscoveryColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.uiPaysAtTheStationCounterWhenDroppingOff(
                      record.payer == ShipmentPayer.sender
                          ? context.l10n.uiSender53bc00
                          : context.l10n.uiRecipient449171,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      color: DiscoveryColors.neutral800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  QrImageView(
                    data: record.identity.waybillCode,
                    version: QrVersions.auto,
                    size: 160.0,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context
                        .l10n
                        .uiShipmentIdentificationQrCodeForVerificationAtThe,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      color: DiscoveryColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              isPaid
                  ? context.l10n.uiPaymentConfirmedSuccessfully
                  : verifiedPayment?.requiresReconciliation == true
                  ? context.l10n.uiPaymentReconciliationInProgress
                  : context
                        .l10n
                        .uiThisShipmentPreviouslyUsedOnlinePaymentContactThe,
            ),
            CustomButton(
              text: context.l10n.uiCheckStatus,
              onPressed: () => widget.cubit.refreshPayment(),
              type: ButtonType.outline,
            ),
            if (widget.state.refreshError != null)
              Text(widget.state.refreshError!),
          ],
          const SizedBox(height: 20),

          ShipmentCancellationSection(cubit: widget.cubit, state: widget.state),

          // Bottom CTA Buttons
          CustomButton(
            text: context.l10n.uiCreateAnotherShipment,
            onPressed: widget.onNewShipment,
            type: ButtonType.primary,
          ),
          if (widget.onGoToList != null) ...[
            const SizedBox(height: 10),
            CustomButton(
              text: context.l10n.uiViewShipments,
              onPressed: widget.onGoToList!,
              type: ButtonType.outline,
            ),
          ],
        ],
      ),
    );
  }

  String _formatLocalDateTime(DateTime value) {
    final local = value.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm - ${DateFormatter.formatFullDate(local)}';
  }

  Widget _buildPointRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String name,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: DiscoveryColors.neutral500,
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: DiscoveryColors.neutral800,
                ),
              ),
              Text(
                address,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  color: DiscoveryColors.neutral600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeeRow(String label, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                color: DiscoveryColors.neutral700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: amount < 0
                  ? DiscoveryColors.successDark
                  : DiscoveryColors.neutral800,
            ),
          ),
        ],
      ),
    );
  }
}
