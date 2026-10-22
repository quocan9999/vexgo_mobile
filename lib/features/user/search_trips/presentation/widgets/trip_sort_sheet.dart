import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/features/user/search_trips/data/models/trip_filter_model.dart';

class TripSortSheet extends StatelessWidget {
  final TripSortType currentSort;

  const TripSortSheet({super.key, required this.currentSort});

  static Future<TripSortType?> show(
    BuildContext context,
    TripSortType currentSort,
  ) {
    return showModalBottomSheet<TripSortType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TripSortSheet(currentSort: currentSort),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXl),
          topRight: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DiscoveryColors.neutral300,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            'Sắp xếp theo',
            style: DiscoveryTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppDimensions.sm),
          const Divider(),
          ...TripSortType.values.map((sort) {
            final isSelected = sort == currentSort;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _getSortIcon(sort),
                color: isSelected
                    ? DiscoveryColors.primary
                    : DiscoveryColors.neutral500,
                size: 20,
              ),
              title: Text(
                sort.label,
                style: DiscoveryTextStyles.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? DiscoveryColors.primary
                      : DiscoveryColors.neutral900,
                ),
              ),
              trailing: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: DiscoveryColors.primary,
                      size: 22,
                    )
                  : null,
              onTap: () => Navigator.of(context).pop(sort),
            );
          }),
          const SizedBox(height: AppDimensions.md),
        ],
      ),
    );
  }

  IconData _getSortIcon(TripSortType sort) {
    switch (sort) {
      case TripSortType.earliest:
        return Icons.access_time_rounded;
      case TripSortType.latest:
        return Icons.history_rounded;
      case TripSortType.priceAsc:
        return Icons.arrow_upward_rounded;
      case TripSortType.priceDesc:
        return Icons.arrow_downward_rounded;
      case TripSortType.ratingDesc:
        return Icons.star_rate_rounded;
    }
  }
}
