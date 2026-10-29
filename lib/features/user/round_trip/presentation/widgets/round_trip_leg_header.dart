import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';

/// Compact header for round-trip booking flow.
/// Allows toggling between outbound and inbound legs while clearly displaying
/// route, active step, and current selection status.
class RoundTripLegHeader extends StatelessWidget {
  final RoundTripRequest request;
  final TripLeg activeLeg;
  final BookingFlowState outboundState;
  final BookingFlowState inboundState;
  final ValueChanged<TripLeg> onLegChanged;
  final VoidCallback onBack;
  final bool busy;

  const RoundTripLegHeader({
    super.key,
    required this.request,
    required this.activeLeg,
    required this.outboundState,
    required this.inboundState,
    required this.onLegChanged,
    required this.onBack,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentLegState = activeLeg == TripLeg.outbound
        ? outboundState
        : inboundState;
    final currentTrip = currentLegState.trip;

    return ColoredBox(
      color: DiscoveryColors.header,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row 1: Back | Operator & Route | Active Leg Badge
              Row(
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: busy ? null : onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTrip != null
                              ? '${currentTrip.operatorName} • ${activeLeg == TripLeg.outbound ? "Lượt đi" : "Lượt về"}'
                              : (activeLeg == TripLeg.outbound
                                    ? 'Lượt đi'
                                    : 'Lượt về'),
                          style: DiscoveryTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          activeLeg == TripLeg.outbound
                              ? '${request.origin.name} → ${request.destination.name}'
                              : '${request.destination.name} → ${request.origin.name}',
                          style: DiscoveryTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Row 2: Leg Switcher Tabs (Lượt đi / Lượt về)
              Row(
                children: [
                  Expanded(
                    child: _buildLegTab(
                      context,
                      leg: TripLeg.outbound,
                      label: 'Lượt đi',
                      summary: _legSummary(outboundState),
                      isSelected: activeLeg == TripLeg.outbound,
                      onTap: busy ? null : () => onLegChanged(TripLeg.outbound),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLegTab(
                      context,
                      leg: TripLeg.inbound,
                      label: 'Lượt về',
                      summary: _legSummary(inboundState),
                      isSelected: activeLeg == TripLeg.inbound,
                      onTap: busy ? null : () => onLegChanged(TripLeg.inbound),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _legSummary(BookingFlowState s) {
    if (s.selectedSeats.isNotEmpty) {
      return s.selectedSeats.map((e) => e.name).join(', ');
    }
    return 'Chưa chọn ghế';
  }

  Widget _buildLegTab(
    BuildContext context, {
    required TripLeg leg,
    required String label,
    required String summary,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      key: ValueKey('leg-tab-${leg.name}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  leg == TripLeg.outbound
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_back_rounded,
                  size: 13,
                  color: isSelected ? DiscoveryColors.header : Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: DiscoveryTextStyles.caption.copyWith(
                    color: isSelected ? DiscoveryColors.header : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              summary,
              style: DiscoveryTextStyles.caption.copyWith(
                color: isSelected
                    ? DiscoveryColors.neutral800
                    : Colors.white.withValues(alpha: 0.9),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
