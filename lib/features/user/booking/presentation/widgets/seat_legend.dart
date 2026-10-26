import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';

class SeatLegend extends StatelessWidget {
  const SeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          _item('Trống', Colors.white, DiscoveryColors.neutral400),
          _item(
            'Đang chọn',
            DiscoveryColors.primary,
            DiscoveryColors.primary,
            Icons.check,
          ),
          _item(
            'Đang giữ',
            const Color(0xFFFEF3C7),
            const Color(0xFFB45309),
            Icons.hourglass_bottom,
          ),
          _item(
            'Đã đặt',
            DiscoveryColors.neutral200,
            DiscoveryColors.neutral500,
            Icons.close,
          ),
        ],
      ),
    );
  }

  Widget _item(String text, Color fill, Color stroke, [IconData? icon]) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: stroke, width: 1.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: icon == null
            ? null
            : Icon(
                icon,
                size: 12,
                color: fill == DiscoveryColors.primary ? Colors.white : stroke,
              ),
      ),
      const SizedBox(width: 6),
      Text(
        text,
        style: DiscoveryTextStyles.caption.copyWith(
          color: DiscoveryColors.neutral700,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
