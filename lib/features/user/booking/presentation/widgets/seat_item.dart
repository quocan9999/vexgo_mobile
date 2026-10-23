import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'seat_vector.dart';

class SeatItem extends StatelessWidget {
  final SeatModel seat;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showPrice;

  const SeatItem({
    super.key,
    required this.seat,
    required this.isSelected,
    required this.onTap,
    this.showPrice = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = ![
      SeatStatus.available,
      SeatStatus.selected,
    ].contains(seat.status);
    final selected =
        !disabled && (isSelected || seat.status == SeatStatus.selected);
    final held = seat.status == SeatStatus.held;
    final fill = disabled
        ? (held ? const Color(0xFFFEF3C7) : DiscoveryColors.neutral200)
        : selected
        ? DiscoveryColors.primary
        : Colors.white;
    final stroke = held
        ? const Color(0xFFB45309)
        : selected
        ? DiscoveryColors.primaryDark
        : DiscoveryColors.neutral400;

    final label = seat.status == SeatStatus.unavailable
        ? 'Không khả dụng'
        : held
        ? 'Đang giữ'
        : disabled
        ? 'Đã đặt'
        : selected
        ? 'Đang chọn'
        : 'Trống';

    final separateLabel =
        MediaQuery.textScalerOf(context).scale(1) > 1.3 || seat.name.length > 4;

    final name = Text(
      seat.name,
      textAlign: TextAlign.center,
      style: DiscoveryTextStyles.bodySmall.copyWith(
        fontWeight: FontWeight.w700,
        color: separateLabel
            ? DiscoveryColors.neutral900
            : selected
            ? Colors.white
            : DiscoveryColors.neutral700,
      ),
    );

    return Semantics(
      button: true,
      onTap: disabled ? null : onTap,
      enabled: !disabled,
      selected: selected,
      label:
          'Ghế ${seat.name}, $label${seat.price == null ? '' : ', ${CurrencyFormatter.format(seat.price)}'}',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : onTap,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 58),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SeatVector(fill: fill, stroke: stroke),
                          if (!separateLabel)
                            Positioned(top: 10, left: 1, right: 1, child: name),
                          if (selected || disabled)
                            Positioned(
                              bottom: 0,
                              child: Icon(
                                selected
                                    ? Icons.check_circle
                                    : held
                                    ? Icons.hourglass_bottom
                                    : Icons.close,
                                size: 14,
                                color: selected
                                    ? Colors.white
                                    : held
                                    ? const Color(0xFFB45309)
                                    : DiscoveryColors.neutral500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (separateLabel) name,
                    if (showPrice && seat.price != null && seat.price! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${seat.price! ~/ 1000}k',
                          style: DiscoveryTextStyles.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? DiscoveryColors.primary
                                : DiscoveryColors.neutral600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
