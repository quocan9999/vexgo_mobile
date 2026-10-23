import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';
import 'stop_point_item.dart';

class StopPointSelection extends StatelessWidget {
  final String title;
  final List<StopPointModel> points;
  final StopPointModel? selected;
  final ValueChanged<StopPointModel> onSelected;

  const StopPointSelection({
    super.key,
    required this.title,
    required this.points,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DiscoveryTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          points.isEmpty
              ? 'Chưa có điểm dừng cho chuyến xe này. Vui lòng quay lại chọn chuyến khác.'
              : 'Có ${points.length} điểm để lựa chọn',
          style: DiscoveryTextStyles.bodySmall.copyWith(
            color: DiscoveryColors.neutral500,
          ),
        ),
        const SizedBox(height: 14),
        for (final point in points)
          StopPointItem(
            point: point,
            isSelected: selected?.id == point.id,
            onTap: () => onSelected(point),
          ),
      ],
    ),
  );
}
