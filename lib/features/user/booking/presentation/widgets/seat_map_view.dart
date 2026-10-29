import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'seat_item.dart';
import 'seat_vector.dart';
import 'spatial_seat_map.dart';

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
    final twoFloors =
        layout.lowerFloor.isNotEmpty && layout.upperFloor.isNotEmpty;
    final seats = twoFloors
        ? (selectedFloor == 2 ? layout.upperFloor : layout.lowerFloor)
        : layout.lowerFloor.isNotEmpty
        ? layout.lowerFloor
        : layout.upperFloor;
    final prices = [
      ...layout.lowerFloor,
      ...layout.upperFloor,
    ].map((s) => s.price).toSet();

    return Column(
      children: [
        if (twoFloors)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: DiscoveryColors.neutral200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  for (final floor in [1, 2])
                    Expanded(
                      child: InkWell(
                        onTap: () => onFloorChanged(floor),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selectedFloor == floor
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: selectedFloor == floor
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.06,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  floor == 1 ? 'Tầng dưới' : 'Tầng trên',
                                  style: DiscoveryTextStyles.bodyMedium
                                      .copyWith(
                                        fontWeight: selectedFloor == floor
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: selectedFloor == floor
                                            ? DiscoveryColors.primary
                                            : DiscoveryColors.neutral700,
                                      ),
                                ),
                                if (selectedSeats.any(
                                  (s) => s.floor == floor,
                                )) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${selectedSeats.where((s) => s.floor == floor).length})',
                                    style: DiscoveryTextStyles.bodySmall
                                        .copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: DiscoveryColors.primary,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: DiscoveryColors.neutral200, width: 1.5),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 32,
                      child: Tooltip(
                        message: 'Vô lăng tài xế',
                        child: SteeringWheelVector(),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Đầu xe',
                        textAlign: TextAlign.center,
                        style: DiscoveryTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: DiscoveryColors.neutral400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 32,
                      child: Tooltip(
                        message: 'Cửa lên xuống',
                        child: BusDoorVector(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Divider(height: 1, color: DiscoveryColors.neutral200),
              const SizedBox(height: 6),
              if (seats.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có sơ đồ ghế.'),
                )
              else if (seats.every((seat) => seat.hasSpatialCoordinates))
                SpatialSeatMap(
                  seats: seats,
                  allSeats: [...layout.lowerFloor, ...layout.upperFloor],
                  selectedSeats: selectedSeats,
                  showPrice: prices.length > 1,
                  onSeatToggled: onSeatToggled,
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxCol = math.max(
                      layout.columnCount ?? 1,
                      seats.map((s) => s.col).reduce(math.max),
                    );
                    final rows = seats.map((s) => s.row).toSet().toList()
                      ..sort();
                    final aisleAfter = layout.columnCount != null
                        ? layout.aisleAfterColumn
                        : maxCol == 4
                        ? 2
                        : maxCol == 2
                        ? 1
                        : null;
                    final large =
                        MediaQuery.textScalerOf(context).scale(1) > 1.3;
                    final minCell = prices.length > 1
                        ? 90.0
                        : large
                        ? 72.0
                        : 54.0;
                    final gaps =
                        (maxCol - 1) * 8.0 + (aisleAfter == null ? 0 : 16);
                    final width = math.max(
                      constraints.maxWidth,
                      maxCol * minCell + gaps,
                    );
                    final cellWidth = (width - gaps) / maxCol;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: width,
                        child: Column(
                          children: [
                            for (final row in rows)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var col = 1; col <= maxCol; col++) ...[
                                      if (col > 1)
                                        SizedBox(
                                          width: col - 1 == aisleAfter ? 24 : 8,
                                        ),
                                      SizedBox(
                                        width: cellWidth,
                                        child: Builder(
                                          builder: (_) {
                                            final seat = seats
                                                .where(
                                                  (s) =>
                                                      s.row == row &&
                                                      s.col == col,
                                                )
                                                .firstOrNull;
                                            if (seat == null) {
                                              return const SizedBox(height: 58);
                                            }
                                            return SeatItem(
                                              key: ValueKey('seat-${seat.id}'),
                                              seat: seat,
                                              isSelected: selectedSeats.any(
                                                (s) => s.id == seat.id,
                                              ),
                                              showPrice: prices.length > 1,
                                              onTap: () => onSeatToggled(seat),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const Divider(height: 24, color: DiscoveryColors.neutral200),
              Text(
                'Cuối xe',
                style: DiscoveryTextStyles.caption.copyWith(
                  color: DiscoveryColors.neutral500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
