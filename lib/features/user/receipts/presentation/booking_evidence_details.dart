import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:vexgo_app/data/models/cargo_settlement.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/booking_evidence_model.dart';

/// Common read-only details for boarding pass and payment evidence.
class StopSnapshotDetails extends StatelessWidget {
  final StopSnapshot? snapshot;
  final DateTime? departure;
  final bool pickup, showAddress;
  const StopSnapshotDetails({
    super.key,
    required this.snapshot,
    required this.departure,
    required this.pickup,
    this.showAddress = false,
  });
  @override
  Widget build(BuildContext context) {
    final stop = snapshot;
    if (stop == null) return const SizedBox.shrink();
    final time = stop.at(departure);
    final arriveBy = pickup ? stop.arriveBy(departure) : null;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAddress && stop.address.isNotEmpty) Text(stop.address),
          if (time != null)
            Text(
              '${pickup ? context.l10n.uiPickUpTimeAtStop : context.l10n.uiDropOffTimeAtStop}: ${evidenceClock(time)}',
            ),
          if (arriveBy != null)
            Text(context.l10n.uiArriveBy(evidenceClock(arriveBy))),
          if (pickup && arriveBy == null && stop.arrivalLeadMinutes != null)
            Text(
              context.l10n.uiArriveMinutesBeforePickUp(
                stop.arrivalLeadMinutes ?? '—',
              ),
            ),
          if ((stop.surcharge ?? 0) > 0)
            Text(
              context.l10n.uiStopSurcharge(
                CurrencyFormatter.format(stop.surcharge),
              ),
            ),
          if (stop.phone.isNotEmpty)
            Text(context.l10n.uiStopContact(stop.phone)),
          if (stop.transferName.isNotEmpty)
            Text(context.l10n.uiShuttle(stop.transferName)),
          if (stop.transferAddress.isNotEmpty)
            Text(context.l10n.uiShuttleAddress(stop.transferAddress)),
        ],
      ),
    );
  }
}

class OrderCargoDetails extends StatelessWidget {
  final List<EvidenceCargo> items;
  final int? fee;
  final bool showFee;
  final CargoSettlement settlement;
  const OrderCargoDetails({
    super.key,
    required this.items,
    this.fee,
    this.showFee = true,
    this.settlement = CargoSettlement.unknown,
  });
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && (fee == null || fee == 0)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.uiAccompanyingItemsWholeBooking,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.quantity} × ${item.name.isEmpty ? context.l10n.uiItems73b007 : item.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (item.categoryName.isNotEmpty)
                  Text(context.l10n.uiType(item.categoryName)),
                if (item.weight != null)
                  Text(
                    context.l10n.uiDeclaredWeightKg(
                      NumberFormat('0.###', 'vi_VN').format(item.weight),
                    ),
                  ),
                if (item.note.isNotEmpty) Text(context.l10n.uiNotes(item.note)),
              ],
            ),
          ),
        Text(cargoSettlementDescription(settlement)),
        if (showFee && fee != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${cargoSettlementLabel(settlement)}: ${CurrencyFormatter.format(fee)}',
            ),
          ),
      ],
    );
  }
}
