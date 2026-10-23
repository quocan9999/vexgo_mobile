import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';

class StopPointItem extends StatelessWidget {
  final StopPointModel point;
  final bool isSelected;
  final VoidCallback onTap;

  const StopPointItem({
    super.key,
    required this.point,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      checked: isSelected,
      inMutuallyExclusiveGroup: true,
      label:
          '${point.name}, ${point.time}, ${point.typeLabel}, ${point.address}',
      child: Material(
        color: isSelected ? DiscoveryColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? DiscoveryColors.primary
                    : DiscoveryColors.neutral200,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: DiscoveryColors.primary.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? DiscoveryColors.primary
                      : DiscoveryColors.neutral400,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (point.time.isNotEmpty)
                            Text(
                              point.time,
                              style: DiscoveryTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: DiscoveryColors.primary,
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: DiscoveryColors.neutral100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              point.typeLabel,
                              style: DiscoveryTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: DiscoveryColors.neutral700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        point.name,
                        style: DiscoveryTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: DiscoveryColors.neutral900,
                        ),
                      ),
                      if (point.address.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          point.address,
                          style: DiscoveryTextStyles.caption.copyWith(
                            color: DiscoveryColors.neutral500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
