import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_typography.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart' hide ButtonType;
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/features/user/shipments/shipment_flow_cubit.dart';

class ShipmentUncertainView extends StatelessWidget {
  final ShipmentFlowCubit cubit;
  final ShipmentFlowState state;
  final bool isAuthenticated;
  final ValueChanged<String>? onNavigateToLookup;

  const ShipmentUncertainView({
    super.key,
    required this.cubit,
    required this.state,
    required this.isAuthenticated,
    this.onNavigateToLookup,
  });

  @override
  Widget build(BuildContext context) {
    final recovery = state.recovery;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.lg),
            decoration: BoxDecoration(
              color: DiscoveryColors.warningLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: DiscoveryColors.warning),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: DiscoveryColors.warningDark,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.uiShipmentResultNotYetVerified,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DiscoveryColors.warningDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.createError ??
                      context.l10n.uiANetworkIssueOccurredOrTheResponseIs,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    color: DiscoveryColors.neutral800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (recovery != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: DiscoveryColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.uiProvisionalShipmentDetails,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DiscoveryColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        context.l10n.uiShipmentCode9f610f,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          color: DiscoveryColors.neutral600,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          recovery.waybillCode,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: DiscoveryColors.primaryDark,
                          ),
                          softWrap: true,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: context.l10n.uiCopyCode,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: recovery.waybillCode),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.uiShipmentCodeCopied),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                          recovery.orderCode,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: DiscoveryColors.neutral800,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isAuthenticated) ...[
              CustomButton(
                text: context.l10n.uiCheckExistingShipment,
                isLoading: state.refreshing,
                onPressed: () => cubit.recoverKnownCreation(),
                type: ButtonType.primary,
              ),
              const SizedBox(height: 8),
            ] else if (onNavigateToLookup != null) ...[
              CustomButton(
                text: context.l10n.uiLookUpThisShipment,
                onPressed: () => onNavigateToLookup!(recovery.waybillCode),
                type: ButtonType.primary,
              ),
              const SizedBox(height: 8),
            ],
          ],
          if (state.draft != null) ...[
            CustomButton(
              text: context.l10n.uiCheckShipmentCreationResult,
              isLoading: state.phase == ShipmentCreationPhase.submitting,
              onPressed: state.phase == ShipmentCreationPhase.submitting
                  ? null
                  : () => cubit.retryUncertainCreation(),
              type: ButtonType.outline,
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.uiResubmitTheSameDetailsAndTransactionCodeTo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                color: DiscoveryColors.neutral600,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (state.refreshError != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                state.refreshError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  color: DiscoveryColors.error,
                ),
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: DiscoveryColors.neutral100,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  color: DiscoveryColors.neutral700,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.uiForUrgentHelpContactVexgoSupportOrTake,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      color: DiscoveryColors.neutral700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
