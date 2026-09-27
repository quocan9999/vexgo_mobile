import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/core/widgets/rating_badge.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'trip_detail_sheet.dart';

class TripCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onSelect;

  const TripCard({
    super.key,
    required this.trip,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isLowSeats = trip.availableSeats <= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm + 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Operator Logo/Icon, Operator Name & Rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.operatorName,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            trip.vehicleType,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.neutral500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    RatingBadge(rating: trip.rating, reviewCount: trip.reviewCount),
                  ],
                ),

                const SizedBox(height: AppDimensions.md),

                // Time & Route points Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Time Column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.departureTime,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trip.arrivalTime,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.neutral500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    // Route Line Icon
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                      child: Column(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 22,
                            color: AppColors.neutral300,
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Station / Pickup & Dropoff names
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.pickupPoint,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '(${trip.duration})',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.neutral400,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            trip.dropoffPoint,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutral700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.md),
                const Divider(height: 1),
                const SizedBox(height: AppDimensions.sm),

                // Bottom Row: Price, Seats Left & Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppDimensions.xs,
                            children: [
                              if (trip.originalPrice > trip.discountPrice)
                                Text(
                                  CurrencyFormatter.format(trip.originalPrice),
                                  style: AppTextStyles.priceOriginal,
                                ),
                              Text(
                                CurrencyFormatter.format(trip.discountPrice),
                                style: AppTextStyles.price.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppDimensions.xs + 2,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isLowSeats ? AppColors.errorLight : AppColors.successLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isLowSeats
                                      ? 'Chỉ còn ${trip.availableSeats} chỗ'
                                      : 'Còn ${trip.availableSeats} chỗ trống',
                                  style: AppTextStyles.caption.copyWith(
                                    color: isLowSeats ? AppColors.error : AppColors.success,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10.5,
                                  ),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Text(
                                    'Chi tiết',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.xs),
                    CustomButton(
                      text: 'Chọn chuyến',
                      height: 36,
                      type: ButtonType.secondary,
                      onPressed: onSelect,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
