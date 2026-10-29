import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/widgets/rating_badge.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/features/user/search_trips/presentation/widgets/trip_detail_sheet.dart';

/// Trip card for round trip search list.
/// Clearly communicates operator, timing, price, vehicle, and selection status.
class RoundTripTripCard extends StatelessWidget {
  final TripModel trip;
  final bool isSelected;
  final VoidCallback onSelect;

  const RoundTripTripCard({
    super.key,
    required this.trip,
    this.isSelected = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSoldOut = trip.availableSeats <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? DiscoveryColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? DiscoveryColors.primary
              : DiscoveryColors.neutral200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Operator, vehicle type, rating badge, selection chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : DiscoveryColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: DiscoveryColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.operatorName,
                      style: DiscoveryTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trip.vehicleType,
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.neutral500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Đã chọn',
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (trip.rating != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: RatingBadge(
                rating: trip.rating!,
                reviewCount: trip.reviewCount,
              ),
            ),

          const SizedBox(height: 14),

          // 2. Route timeline: Departure time/stop -> Journey line -> Arrival time/stop
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _buildStop(
                  time: trip.departureTime,
                  point: trip.pickupPoint,
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Column(
                    children: [
                      Text(
                        trip.duration,
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.neutral500,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: DiscoveryColors.primary,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1.5,
                              color: DiscoveryColors.neutral300,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: DiscoveryColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: _buildStop(
                  time: trip.arrivalTime,
                  point: trip.dropoffPoint,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: DiscoveryColors.neutral200),
          const SizedBox(height: 12),

          // 3. Footer: Price & Seats, Action buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.format(trip.discountPrice),
                      style: DiscoveryTextStyles.titleMedium.copyWith(
                        color: DiscoveryColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSoldOut ? 'Hết vé' : 'Còn ${trip.availableSeats} chỗ',
                      style: DiscoveryTextStyles.caption.copyWith(
                        color: isSoldOut
                            ? DiscoveryColors.neutral500
                            : DiscoveryColors.successDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => TripDetailSheet.show(
                  context,
                  trip: trip,
                  onSelectTrip: (_) => onSelect(),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  side: const BorderSide(color: DiscoveryColors.neutral300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Chi tiết',
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    color: DiscoveryColors.neutral700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                key: ValueKey('select-trip-${trip.id}'),
                onPressed: isSoldOut ? null : onSelect,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(48, 40),
                  backgroundColor: isSelected
                      ? DiscoveryColors.primary
                      : DiscoveryColors.secondary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: DiscoveryColors.neutral300,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isSelected
                      ? 'Đang chọn'
                      : (isSoldOut ? 'Hết chỗ' : 'Chọn chuyến'),
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStop({
    required String time,
    required String point,
    required CrossAxisAlignment crossAxisAlignment,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          time,
          style: DiscoveryTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          point,
          style: DiscoveryTextStyles.caption.copyWith(
            color: DiscoveryColors.neutral600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
