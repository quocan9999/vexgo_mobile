import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import '../../shipment_flow_cubit.dart';

class ShipmentCancellationSection extends StatelessWidget {
  final ShipmentFlowCubit cubit;
  final ShipmentFlowState state;
  final bool fromLookup;
  const ShipmentCancellationSection({
    super.key,
    required this.cubit,
    required this.state,
    this.fromLookup = false,
  });

  Future<void> _confirm(BuildContext context) async {
    final code = cubit.cancellationCode(fromLookup: fromLookup);
    if (code == null || !cubit.canCancelShipment(fromLookup: fromLookup)) {
      return;
    }
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ShipmentCancelDialog(
        cubit: cubit,
        code: code,
        fromLookup: fromLookup,
      ),
    );
    if (reason != null &&
        context.mounted &&
        cubit.cancellationCode(fromLookup: fromLookup) == code) {
      await cubit.cancelShipment(fromLookup: fromLookup, reason: reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = cubit.cancellationCode(fromLookup: fromLookup);
    final result = state.cancellation?.waybillCode == code
        ? state.cancellation
        : null;
    final error = state.cancellationWaybill == code
        ? state.cancellationError
        : null;
    final uncertain =
        state.cancellationWaybill == code && state.cancellationUncertain;
    final status = fromLookup ? state.lookup?.status : state.record?.status;
    final done = status == ShipmentStatus.cancelled;
    if (!cubit.canCancelShipment(fromLookup: fromLookup) &&
        !state.cancelling &&
        !uncertain &&
        error == null &&
        !done) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                error,
                style: const TextStyle(color: DiscoveryColors.error),
              ),
            ),
          if (done)
            Text(
              result?.hasPaidBeforeCancel == true
                  ? context
                        .l10n
                        .uiShipmentCancelledContactTheOperatorForHelpRefunding
                  : context.l10n.uiShipmentCancelledIfYouAlreadyPaidContactThe,
            ),
          if (state.cancelling)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            ),
          if (uncertain && !state.cancelling)
            OutlinedButton(
              key: const ValueKey('shipment-cancel-recheck'),
              onPressed: () =>
                  cubit.refreshCancellationStatus(fromLookup: fromLookup),
              child: Text(context.l10n.uiCheckCancellationStatus),
            ),
          if (cubit.canCancelShipment(fromLookup: fromLookup))
            OutlinedButton.icon(
              key: ValueKey(
                fromLookup
                    ? 'shipment-lookup-cancel'
                    : 'shipment-detail-cancel',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: DiscoveryColors.error,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => _confirm(context),
              icon: const Icon(Icons.cancel_outlined),
              label: Text(context.l10n.uiCancelShipment),
            ),
        ],
      ),
    );
  }
}

class _ShipmentCancelDialog extends StatefulWidget {
  final ShipmentFlowCubit cubit;
  final String code;
  final bool fromLookup;
  const _ShipmentCancelDialog({
    required this.cubit,
    required this.code,
    required this.fromLookup,
  });
  @override
  State<_ShipmentCancelDialog> createState() => _ShipmentCancelDialogState();
}

class _ShipmentCancelDialogState extends State<_ShipmentCancelDialog> {
  String selected = 'Không còn nhu cầu gửi hàng';
  final other = TextEditingController();
  @override
  void dispose() {
    other.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ShipmentFlowCubit, ShipmentFlowState>(
    bloc: widget.cubit,
    builder: (context, state) {
      if (state.phase == ShipmentCreationPhase.invalidated ||
          widget.cubit.cancellationCode(fromLookup: widget.fromLookup) !=
              widget.code) {
        return AlertDialog(
          title: Text(context.l10n.uiShipmentDetailsChanged),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.uiClose),
            ),
          ],
        );
      }
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.uiCancelThisShipment,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(context.l10n.uiShipmentCodeee9663(widget.code)),
              const SizedBox(height: 12),
              Text(
                context
                    .l10n
                    .uiCancellationIsAvailableOnlyBeforeItemsAreAccepted,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selected,
                isExpanded: true,
                itemHeight: null,
                decoration: InputDecoration(
                  labelText: context.l10n.uiCancellationReason,
                ),
                items:
                    [
                          context.l10n.uiShippingNoLongerNeeded,
                          context.l10n.uiIncorrectShipmentDetails,
                          context.l10n.uiOther,
                        ]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                onChanged: (v) => setState(() => selected = v!),
              ),
              if (selected == 'Khác')
                TextField(
                  key: const ValueKey('shipment-cancel-reason'),
                  controller: other,
                  maxLength: 255,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.l10n.uiOtherReasonOptional,
                  ),
                ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.l10n.uiKeepShipment),
                  ),
                  FilledButton(
                    key: const ValueKey('shipment-cancel-confirm'),
                    style: FilledButton.styleFrom(
                      backgroundColor: DiscoveryColors.errorDark,
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed:
                        widget.cubit.canCancelShipment(
                          fromLookup: widget.fromLookup,
                        )
                        ? () => Navigator.pop(
                            context,
                            selected == 'Khác' ? other.text.trim() : selected,
                          )
                        : null,
                    child: Text(context.l10n.uiConfirmCancellation1939df),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
