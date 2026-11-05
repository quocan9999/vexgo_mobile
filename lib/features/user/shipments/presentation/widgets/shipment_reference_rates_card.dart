import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_typography.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/booking_cargo_model.dart';
import 'package:vexgo_app/data/models/shipment_model.dart';

class ShipmentReferenceRatesCard extends StatefulWidget {
  final List<ShipmentRate> rates;
  final List<CargoCategory> categories;

  const ShipmentReferenceRatesCard({
    super.key,
    required this.rates,
    required this.categories,
  });

  @override
  State<ShipmentReferenceRatesCard> createState() =>
      _ShipmentReferenceRatesCardState();
}

class _ShipmentReferenceRatesCardState
    extends State<ShipmentReferenceRatesCard> {
  bool _expanded = false;

  String _categoryName(int id) {
    for (final c in widget.categories) {
      if (c.id == id) return c.name;
    }
    return 'Loại $id';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rates.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: DiscoveryColors.neutral50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: DiscoveryColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bảng cước tham khảo theo tuyến (${widget.rates.length} mức)',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DiscoveryColors.neutral800,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: DiscoveryColors.neutral600,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: DiscoveryColors.neutral200),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DiscoveryColors.warningLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: DiscoveryColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: DiscoveryColors.warningDark,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Cước hiển thị chỉ để tham khảo. Cước phí chính xác do máy chủ xác nhận khi tạo đơn.',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              color: DiscoveryColors.warningDark,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.rates.map((rate) {
                    final weightRange = rate.maxWeight != null
                        ? '${rate.minWeight} - ${rate.maxWeight} kg'
                        : '≥ ${rate.minWeight} kg';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${_categoryName(rate.categoryId)} ($weightRange)',
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                color: DiscoveryColors.neutral700,
                              ),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(rate.fee),
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: DiscoveryColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
