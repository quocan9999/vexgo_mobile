import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_typography.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/data/models/shipment_model.dart';

class ShipmentStatusBadge extends StatelessWidget {
  final ShipmentStatus status;

  const ShipmentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      ShipmentStatus.created => (
        context.l10n.uiCreated,
        DiscoveryColors.primaryLight,
        DiscoveryColors.primary,
      ),
      ShipmentStatus.accepted => (
        context.l10n.uiAccepted,
        DiscoveryColors.infoLight,
        DiscoveryColors.info,
      ),
      ShipmentStatus.inTransit => (
        context.l10n.uiInTransit,
        DiscoveryColors.warningLight,
        DiscoveryColors.warningDark,
      ),
      ShipmentStatus.delivered => (
        context.l10n.uiDelivered,
        DiscoveryColors.successLight,
        DiscoveryColors.successDark,
      ),
      ShipmentStatus.cancelled => (
        context.l10n.uiCancelled,
        DiscoveryColors.errorLight,
        DiscoveryColors.errorDark,
      ),
      ShipmentStatus.unknown => (
        context.l10n.uiUnknown,
        DiscoveryColors.neutral100,
        DiscoveryColors.neutral600,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ).copyWith(color: fg),
      ),
    );
  }
}

class ShipmentPaymentBadge extends StatelessWidget {
  final bool paid;
  final bool pendingOnline;
  final bool counter;
  final bool requiresReconciliation;
  final String? rawStatus;

  const ShipmentPaymentBadge({
    super.key,
    required this.paid,
    this.pendingOnline = false,
    this.counter = false,
    this.requiresReconciliation = false,
    this.rawStatus,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bg;
    final Color fg;

    if (requiresReconciliation) {
      label = context.l10n.uiReconciling;
      bg = DiscoveryColors.warningLight;
      fg = DiscoveryColors.warningDark;
    } else if (paid) {
      label = context.l10n.uiPaid;
      bg = DiscoveryColors.successLight;
      fg = DiscoveryColors.successDark;
    } else if (pendingOnline) {
      label = context.l10n.uiAwaitingPaymentac4098;
      bg = DiscoveryColors.warningLight;
      fg = DiscoveryColors.warningDark;
    } else if (counter) {
      label = context.l10n.uiPayAtStation;
      bg = DiscoveryColors.primaryLight;
      fg = DiscoveryColors.primary;
    } else {
      label = rawStatus ?? context.l10n.uiUnknown;
      bg = DiscoveryColors.neutral100;
      fg = DiscoveryColors.neutral600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ).copyWith(color: fg),
      ),
    );
  }
}
