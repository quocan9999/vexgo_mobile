import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/widgets/rating_badge.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'trip_detail_sheet.dart';

class TripCard extends StatelessWidget {
  final TripModel trip;
  final ValueChanged<TripModel> onSelect;
  const TripCard({super.key, required this.trip, required this.onSelect});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: DiscoveryColors.neutral200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DiscoveryColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.directions_bus_outlined,
                color: DiscoveryColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.operatorName,
                    style: DiscoveryTextStyles.titleMedium,
                  ),
                  Text(trip.vehicleType, style: DiscoveryTextStyles.bodySmall),
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
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _stop(trip.departureTime, trip.pickupPoint)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Icon(
                Icons.arrow_forward,
                color: DiscoveryColors.neutral400,
                size: 20,
              ),
            ),
            Expanded(child: _stop(trip.arrivalTime, trip.dropoffPoint)),
          ],
        ),
        if (trip.duration.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(trip.duration, style: DiscoveryTextStyles.bodySmall),
          ),
        if (trip.amenities.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: trip.amenities
                  .map(
                    (value) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.neutral50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(value, style: DiscoveryTextStyles.bodySmall),
                    ),
                  )
                  .toList(),
            ),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(color: DiscoveryColors.neutral200),
        ),
        Text(
          CurrencyFormatter.format(trip.discountPrice),
          style: DiscoveryTextStyles.price.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (trip.originalPrice > trip.discountPrice)
          Text(
            CurrencyFormatter.format(trip.originalPrice),
            style: DiscoveryTextStyles.priceOriginal,
          ),
        Text(
          '/vé · Còn ${trip.availableSeats} chỗ',
          style: DiscoveryTextStyles.bodySmall,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () =>
              TripDetailSheet.show(context, trip: trip, onSelectTrip: onSelect),
          child: const Text('Chi tiết chuyến xe'),
        ),
        DiscoveryButton(
          text: 'Chọn chuyến',
          type: ButtonType.secondary,
          width: double.infinity,
          onPressed: () => onSelect(trip),
        ),
      ],
    ),
  );

  Widget _stop(String time, String point) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        time,
        style: DiscoveryTextStyles.h2.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(point, style: DiscoveryTextStyles.bodySmall),
    ],
  );
}
