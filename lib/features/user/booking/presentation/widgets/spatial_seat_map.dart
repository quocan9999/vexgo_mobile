import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'seat_item.dart';

/// Fixed and centered seat layout renderer based on vehicle coordinates.
/// Eliminates horizontal scrolling by fitting all columns within the viewport
/// while preserving relative gap proportions and alignment across floors.
class SpatialSeatMap extends StatelessWidget {
  final List<SeatModel> seats;
  final List<SeatModel>? allSeats;
  final List<SeatModel> selectedSeats;
  final bool showPrice;
  final ValueChanged<SeatModel> onSeatToggled;

  const SpatialSeatMap({
    super.key,
    required this.seats,
    this.allSeats,
    required this.selectedSeats,
    required this.showPrice,
    required this.onSeatToggled,
  });

  @override
  Widget build(BuildContext context) {
    if (seats.isEmpty) return const SizedBox.shrink();

    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final inheritedStyle = DefaultTextStyle.of(context).style;

    // Shared vehicle reference across floors maintains column alignment on floor switch.
    final refSeats = (allSeats != null && allSeats!.isNotEmpty)
        ? allSeats!
        : seats;
    final minX = refSeats.map((s) => s.x!).reduce(math.min).toDouble();
    final maxX = refSeats.map((s) => s.x!).reduce(math.max).toDouble();
    final minY = refSeats.map((s) => s.y!).reduce(math.min).toDouble();
    final maxY = seats.map((s) => s.y!).reduce(math.max).toDouble();
    final dxRange = maxX - minX;

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        // Keep a reasonable maximum cabin width on very wide/landscape screens.
        final contentWidth = math.min(containerWidth, 380.0);

        // Find minimum distance between distinct columns on the same row.
        var minRowDx = dxRange > 0 ? dxRange : 1.0;
        for (var i = 0; i < refSeats.length; i++) {
          for (var j = i + 1; j < refSeats.length; j++) {
            if (refSeats[i].floor == refSeats[j].floor &&
                refSeats[i].y == refSeats[j].y) {
              final dx = (refSeats[i].x! - refSeats[j].x!).abs().toDouble();
              if (dx > 0 && dx < minRowDx) {
                minRowDx = dx;
              }
            }
          }
        }

        // Clamp cellWidth to guarantee touch target >= 48dp while preventing adjacent overlap.
        final maxCellAllowed = dxRange > 0 && minRowDx < dxRange
            ? ((minRowDx / dxRange) * contentWidth - 4.0) /
                  (1.0 + minRowDx / dxRange)
            : contentWidth;
        final cellWidth = math.max(48.0, math.min(64.0, maxCellAllowed));
        final availableSpan = math.max(0.0, contentWidth - cellWidth);

        // Compute maximum seat height based on actual text wrapping within cellWidth.
        var maxSeatHeight = 58.0;
        for (final seat in seats) {
          var height = 60.0;
          final separateLabel = scaler.scale(1) > 1.3 || seat.name.length > 4;
          if (separateLabel) {
            final label = TextPainter(
              text: TextSpan(
                text: seat.name,
                style: inheritedStyle.merge(
                  DiscoveryTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              textDirection: direction,
              textScaler: scaler,
            )..layout(maxWidth: cellWidth);
            height += label.height;
            label.dispose();
          }
          if (showPrice && seat.price != null && seat.price! > 0) {
            final price = TextPainter(
              text: TextSpan(
                text: '${seat.price! ~/ 1000}k',
                style: inheritedStyle.merge(
                  DiscoveryTextStyles.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              textDirection: direction,
              textScaler: scaler,
            )..layout(maxWidth: cellWidth);
            height += price.height + 2.0;
            price.dispose();
          }
          maxSeatHeight = math.max(maxSeatHeight, height);
        }

        // Calculate vertical scale without excessive blank space.
        var minRowDy = 1000.0;
        for (var i = 0; i < seats.length; i++) {
          for (var j = i + 1; j < seats.length; j++) {
            final dy = (seats[i].y! - seats[j].y!).abs().toDouble();
            if (dy > 0 && dy < minRowDy) {
              minRowDy = dy;
            }
          }
        }
        const minGapY = 12.0;
        final yScale = math.max(
          64.0 / 1000.0,
          (maxSeatHeight + minGapY) / minRowDy,
        );
        final totalHeight = (maxY - minY) * yScale + maxSeatHeight + 16.0;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            key: const ValueKey('spatial-seat-canvas'),
            width: contentWidth,
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final seat in seats)
                  Positioned(
                    left: dxRange == 0
                        ? (contentWidth - cellWidth) / 2
                        : (seat.x! - minX) / dxRange * availableSpan,
                    top: (seat.y! - minY) * yScale,
                    width: cellWidth,
                    child: SeatItem(
                      key: ValueKey('seat-${seat.id}'),
                      seat: seat,
                      isSelected: selectedSeats.any(
                        (selected) => selected.id == seat.id,
                      ),
                      showPrice: showPrice,
                      onTap: () => onSeatToggled(seat),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
