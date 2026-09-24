import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'seat_item.dart';

class SeatMapView extends StatelessWidget {
  final SeatLayoutModel layout;
  final int selectedFloor;
  final List<SeatModel> selectedSeats;
  final Function(int) onFloorChanged;
  final Function(SeatModel) onSeatToggled;

  const SeatMapView({
    super.key,
    required this.layout,
    required this.selectedFloor,
    required this.selectedSeats,
    required this.onFloorChanged,
    required this.onSeatToggled,
  });

  @override
  Widget build(BuildContext context) {
    final currentFloorSeats =
        selectedFloor == 1 ? layout.lowerFloor : layout.upperFloor;

    final lowerAvailCount =
        layout.lowerFloor.where((s) => s.status == SeatStatus.available).length;
    final upperAvailCount =
        layout.upperFloor.where((s) => s.status == SeatStatus.available).length;

    return Column(
      children: [
        // Floor Switcher (Only if vehicle has 2 floors)
        if (layout.hasTwoFloors) ...[
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppDimensions.base,
              vertical: AppDimensions.sm,
            ),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFloorTab(
                    floor: 1,
                    title: 'Tầng 1 (Dưới)',
                    countBadge: '$lowerAvailCount trống',
                    isSelected: selectedFloor == 1,
                  ),
                ),
                Expanded(
                  child: _buildFloorTab(
                    floor: 2,
                    title: 'Tầng 2 (Trên)',
                    countBadge: '$upperAvailCount trống',
                    isSelected: selectedFloor == 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
        ],

        // Bus Frame Container
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.neutral300, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Bus Front Header: Steering Wheel & Door
              _buildBusFrontHeader(),

              const SizedBox(height: AppDimensions.sm),
              const Divider(height: 1, color: AppColors.neutral200),
              const SizedBox(height: AppDimensions.md),

              // Seats Grid by Rows
              _buildSeatsGrid(currentFloorSeats),

              const SizedBox(height: AppDimensions.md),
              const Divider(height: 1, color: AppColors.neutral200),
              const SizedBox(height: AppDimensions.sm),

              // Bus Rear Indicator
              Text(
                '--- Cuối xe ---',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.neutral400,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloorTab({
    required int floor,
    required String title,
    required String countBadge,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onFloorChanged(floor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.neutral600,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryLight
                    : AppColors.neutral200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                countBadge,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.neutral500,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusFrontHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Driver Steering Wheel
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.neutral300),
              ),
              child: const Icon(
                Icons.directions_bus_filled_rounded,
                size: 20,
                color: AppColors.neutral700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Tài xế',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.neutral600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        // Front Sign
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Đầu xe',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // Passenger Door
        Row(
          children: [
            Text(
              'Cửa lên',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.neutral600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.meeting_room_outlined,
              size: 20,
              color: AppColors.neutral600,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeatsGrid(List<SeatModel> seats) {
    if (seats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Text(
          'Không có chỗ trên tầng này',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
        ),
      );
    }

    // Group seats by row
    final Map<int, List<SeatModel>> rowsMap = {};
    for (var seat in seats) {
      rowsMap.putIfAbsent(seat.row, () => []).add(seat);
    }

    // Sort rows
    final sortedRowKeys = rowsMap.keys.toList()..sort();

    return Column(
      children: sortedRowKeys.map((rowKey) {
        final rowSeats = rowsMap[rowKey]!..sort((a, b) => a.col.compareTo(b.col));
        return _buildRow(rowSeats);
      }).toList(),
    );
  }

  Widget _buildRow(List<SeatModel> rowSeats) {
    // Check max column count in this row to determine spacing/aisle
    final maxCol = rowSeats.map((s) => s.col).fold(1, (prev, curr) => curr > prev ? curr : prev);

    if (maxCol == 2) {
      // 2 columns with central aisle (Left - Aisle - Right)
      final leftSeat = rowSeats.where((s) => s.col == 1).firstOrNull;
      final rightSeat = rowSeats.where((s) => s.col == 2).firstOrNull;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: leftSeat != null
                  ? SeatItem(
                      seat: leftSeat,
                      isSelected: selectedSeats.any((s) => s.id == leftSeat.id),
                      onTap: () => onSeatToggled(leftSeat),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  'Lối đi',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.neutral300,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: rightSeat != null
                  ? SeatItem(
                      seat: rightSeat,
                      isSelected: selectedSeats.any((s) => s.id == rightSeat.id),
                      onTap: () => onSeatToggled(rightSeat),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    } else if (maxCol >= 3) {
      // 3 columns (Left - Aisle - Middle - Aisle - Right)
      final col1 = rowSeats.where((s) => s.col == 1).firstOrNull;
      final col2 = rowSeats.where((s) => s.col == 2).firstOrNull;
      final col3 = rowSeats.where((s) => s.col == 3).firstOrNull;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: col1 != null
                  ? SeatItem(
                      seat: col1,
                      isSelected: selectedSeats.any((s) => s.id == col1.id),
                      onTap: () => onSeatToggled(col1),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 3,
              child: col2 != null
                  ? SeatItem(
                      seat: col2,
                      isSelected: selectedSeats.any((s) => s.id == col2.id),
                      onTap: () => onSeatToggled(col2),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 3,
              child: col3 != null
                  ? SeatItem(
                      seat: col3,
                      isSelected: selectedSeats.any((s) => s.id == col3.id),
                      onTap: () => onSeatToggled(col3),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    // Default row fallback
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: rowSeats.map((seat) {
        return Expanded(
          child: SeatItem(
            seat: seat,
            isSelected: selectedSeats.any((s) => s.id == seat.id),
            onTap: () => onSeatToggled(seat),
          ),
        );
      }).toList(),
    );
  }
}
