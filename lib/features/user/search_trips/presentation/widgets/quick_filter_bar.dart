import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
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
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.neutral200),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.base,
          vertical: 6,
        ),
        children: [
          // Filter Button
          InkWell(
            onTap: onOpenFilterSheet,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: activeCount > 0 ? AppColors.primaryLight : AppColors.neutral100,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: activeCount > 0 ? AppColors.primary : AppColors.neutral300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: activeCount > 0 ? AppColors.primary : AppColors.neutral700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Bộ lọc',
                    style: AppTextStyles.caption.copyWith(
                      color: activeCount > 0 ? AppColors.primary : AppColors.neutral700,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
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

          const SizedBox(width: AppDimensions.sm),

          // Sort Button
          InkWell(
            onTap: onOpenSortSheet,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.neutral300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_vert_rounded, size: 16, color: AppColors.neutral700),
                  const SizedBox(width: 4),
                  Text(
                    currentSort.label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutral700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: AppDimensions.sm),

          // Quick Filter: Sáng (06-12h)
          _buildQuickChip(
            label: 'Sáng (06:00 - 12:00)',
            isSelected: currentFilter.selectedTimeSlots.contains(TimeSlot.morning),
            onTap: () {
              final newSlots = List<TimeSlot>.from(currentFilter.selectedTimeSlots);
              if (newSlots.contains(TimeSlot.morning)) {
                newSlots.remove(TimeSlot.morning);
              } else {
                newSlots.add(TimeSlot.morning);
              }
              onFilterChanged(currentFilter.copyWith(selectedTimeSlots: newSlots));
            },
          ),

          const SizedBox(width: AppDimensions.sm),

          // Quick Filter: Tối (18-24h)
          _buildQuickChip(
            label: 'Tối (18:00 - 24:00)',
            isSelected: currentFilter.selectedTimeSlots.contains(TimeSlot.evening),
            onTap: () {
              final newSlots = List<TimeSlot>.from(currentFilter.selectedTimeSlots);
              if (newSlots.contains(TimeSlot.evening)) {
                newSlots.remove(TimeSlot.evening);
              } else {
                newSlots.add(TimeSlot.evening);
              }
              onFilterChanged(currentFilter.copyWith(selectedTimeSlots: newSlots));
            },
          ),

          const SizedBox(width: AppDimensions.sm),

          // Quick Filter: Limousine
          _buildQuickChip(
            label: 'Xe Limousine',
            isSelected: currentFilter.selectedVehicleTypes.any((v) => v.contains('Limousine')),
            onTap: () {
              final newTypes = List<String>.from(currentFilter.selectedVehicleTypes);
              if (newTypes.any((v) => v.contains('Limousine'))) {
                newTypes.removeWhere((v) => v.contains('Limousine'));
              } else {
                newTypes.add('Limousine 34 Phòng VIP');
              }
              onFilterChanged(currentFilter.copyWith(selectedVehicleTypes: newTypes));
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.neutral300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? AppColors.primary : AppColors.neutral700,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
