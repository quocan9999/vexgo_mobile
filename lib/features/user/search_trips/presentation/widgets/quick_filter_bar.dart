import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/features/user/search_trips/data/models/trip_filter_model.dart';

class QuickFilterBar extends StatelessWidget {
  final TripFilterModel currentFilter;
  final TripSortType currentSort;
  final VoidCallback onOpenFilterSheet;
  final VoidCallback onOpenSortSheet;
  final ValueChanged<TripFilterModel> onFilterChanged;

  const QuickFilterBar({
    super.key,
    required this.currentFilter,
    required this.currentSort,
    required this.onOpenFilterSheet,
    required this.onOpenSortSheet,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = currentFilter.activeFilterCount;

    return Container(
      height: 42 + MediaQuery.textScalerOf(context).scale(18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: DiscoveryColors.neutral200)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.base,
          vertical: 5,
        ),
        children: [
          // Filter Button
          Semantics(
            button: true,
            label: activeCount > 0
                ? 'Mở bộ lọc, có $activeCount bộ lọc đang chọn'
                : 'Mở bộ lọc',
            child: InkWell(
              onTap: onOpenFilterSheet,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: activeCount > 0
                      ? DiscoveryColors.primaryLight
                      : DiscoveryColors.neutral100,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: activeCount > 0
                        ? DiscoveryColors.primary
                        : DiscoveryColors.neutral300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: activeCount > 0
                          ? DiscoveryColors.primary
                          : DiscoveryColors.neutral700,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Bộ lọc',
                      style: DiscoveryTextStyles.caption.copyWith(
                        color: activeCount > 0
                            ? DiscoveryColors.primary
                            : DiscoveryColors.neutral700,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    if (activeCount > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: DiscoveryColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$activeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: AppDimensions.sm),

          // Sort Button
          Semantics(
            button: true,
            label: 'Sắp xếp theo: ${currentSort.label}',
            child: InkWell(
              onTap: onOpenSortSheet,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: DiscoveryColors.neutral100,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: DiscoveryColors.neutral300),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_vert_rounded,
                      size: 16,
                      color: DiscoveryColors.neutral700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currentSort.label,
                      style: DiscoveryTextStyles.caption.copyWith(
                        color: DiscoveryColors.neutral700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: AppDimensions.sm),

          // Quick Filter: Sáng (06-12h)
          _buildQuickChip(
            label: 'Sáng (06:00 - 12:00)',
            isSelected: currentFilter.selectedTimeSlots.contains(
              TimeSlot.morning,
            ),
            onTap: () {
              final newSlots = List<TimeSlot>.from(
                currentFilter.selectedTimeSlots,
              );
              if (newSlots.contains(TimeSlot.morning)) {
                newSlots.remove(TimeSlot.morning);
              } else {
                newSlots.add(TimeSlot.morning);
              }
              onFilterChanged(
                currentFilter.copyWith(selectedTimeSlots: newSlots),
              );
            },
          ),

          const SizedBox(width: AppDimensions.sm),

          // Quick Filter: Tối (18-24h)
          _buildQuickChip(
            label: 'Tối (18:00 - 24:00)',
            isSelected: currentFilter.selectedTimeSlots.contains(
              TimeSlot.evening,
            ),
            onTap: () {
              final newSlots = List<TimeSlot>.from(
                currentFilter.selectedTimeSlots,
              );
              if (newSlots.contains(TimeSlot.evening)) {
                newSlots.remove(TimeSlot.evening);
              } else {
                newSlots.add(TimeSlot.evening);
              }
              onFilterChanged(
                currentFilter.copyWith(selectedTimeSlots: newSlots),
              );
            },
          ),

          const SizedBox(width: AppDimensions.sm),

          // Quick Filter: Limousine
          _buildQuickChip(
            label: 'Xe Limousine',
            isSelected: currentFilter.selectedVehicleTypes.any(
              (v) => v.contains('Limousine'),
            ),
            onTap: () {
              final newTypes = List<String>.from(
                currentFilter.selectedVehicleTypes,
              );
              if (newTypes.any((v) => v.contains('Limousine'))) {
                newTypes.removeWhere((v) => v.contains('Limousine'));
              } else {
                newTypes.add('Limousine 34 Phòng VIP');
              }
              onFilterChanged(
                currentFilter.copyWith(selectedVehicleTypes: newTypes),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? DiscoveryColors.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isSelected
                  ? DiscoveryColors.primary
                  : DiscoveryColors.neutral300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: DiscoveryTextStyles.caption.copyWith(
                color: isSelected
                    ? DiscoveryColors.primary
                    : DiscoveryColors.neutral700,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
