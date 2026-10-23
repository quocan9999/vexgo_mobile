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
  Widget build(BuildContext context) {
    final isSoldOut = trip.availableSeats <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DiscoveryColors.neutral200),
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
          // 1. Header: Operator, vehicle type, rating badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DiscoveryColors.primaryLight,
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

          const SizedBox(height: 16),

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
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (trip.duration.isNotEmpty) ...[
                        Text(
                          trip.duration,
                          style: DiscoveryTextStyles.caption.copyWith(
                            color: DiscoveryColors.neutral500,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                      ],
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: DiscoveryColors.primary,
                              shape: BoxShape.circle,
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
                            color: DiscoveryColors.neutral400,
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
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),

          // 3. Amenities tags
          if (trip.amenities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: trip.amenities
                  .map(
                    (value) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.neutral50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: DiscoveryColors.neutral200,
                        ),
                      ),
                      child: Text(
                        value,
                        style: DiscoveryTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: DiscoveryColors.neutral700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: DiscoveryColors.neutral200, height: 1),
          ),

          // 4. Footer: Price, seat status, detail link & CTA button
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1.0);
              final isNarrow = constraints.maxWidth < 340 || textScale > 1.2;

              final priceSection = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(
                        CurrencyFormatter.format(trip.discountPrice),
                        style: DiscoveryTextStyles.price.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (trip.originalPrice > trip.discountPrice)
                        Text(
                          CurrencyFormatter.format(trip.originalPrice),
                          style: DiscoveryTextStyles.priceOriginal,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSoldOut
                        ? 'Chuyến xe đã hết chỗ'
                        : '/vé · Còn ${trip.availableSeats} chỗ',
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      color: isSoldOut
                          ? DiscoveryColors.error
                          : DiscoveryColors.neutral500,
                      fontWeight: isSoldOut ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 11,
                    ),
                  ),
                  InkWell(
                    onTap: () => TripDetailSheet.show(
                      context,
                      trip: trip,
                      onSelectTrip: onSelect,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Chi tiết chuyến xe',
                        style: DiscoveryTextStyles.bodySmall.copyWith(
                          color: DiscoveryColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              );

              final ctaButton = DiscoveryButton(
                text: 'Chọn chuyến',
                type: ButtonType.secondary,
                width: isNarrow ? double.infinity : 130,
                height: 44,
                onPressed: isSoldOut ? null : () => onSelect(trip),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    priceSection,
                    const SizedBox(height: 10),
                    ctaButton,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: priceSection),
                  const SizedBox(width: 8),
                  ctaButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStop({
    required String time,
    required String point,
    required CrossAxisAlignment crossAxisAlignment,
    required TextAlign textAlign,
  }) => Column(
    crossAxisAlignment: crossAxisAlignment,
    children: [
      Text(
        time,
        style: DiscoveryTextStyles.h2.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 19,
        ),
        textAlign: textAlign,
      ),
      const SizedBox(height: 3),
      Text(
        point,
        style: DiscoveryTextStyles.bodySmall.copyWith(
          color: DiscoveryColors.neutral700,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
      ),
    ],
  );
}
