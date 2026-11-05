import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_typography.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart' hide ButtonType;
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/core/widgets/custom_text_field.dart';
import 'package:vexgo_app/features/user/shipments/shipment_flow_cubit.dart';
import 'shipment_status_badge.dart';

class ShipmentLookupView extends StatefulWidget {
  final ShipmentFlowCubit cubit;
  final ShipmentFlowState state;
  final String? initialWaybillCode;

  const ShipmentLookupView({
    super.key,
    required this.cubit,
    required this.state,
    this.initialWaybillCode,
  });

  @override
  State<ShipmentLookupView> createState() => _ShipmentLookupViewState();
}

class _ShipmentLookupViewState extends State<ShipmentLookupView> {
  late final TextEditingController _waybillController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _waybillController = TextEditingController(
      text: widget.initialWaybillCode ?? '',
    );
    _phoneController = TextEditingController();
  }

  @override
  void didUpdateWidget(ShipmentLookupView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialWaybillCode != null &&
        widget.initialWaybillCode != oldWidget.initialWaybillCode &&
        _waybillController.text.isEmpty) {
      _waybillController.text = widget.initialWaybillCode!;
    }
  }

  @override
  void dispose() {
    _waybillController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onLookup() {
    final waybill = _waybillController.text.trim();
    final phone = _phoneController.text.trim();
    if (waybill.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mã vận đơn và số điện thoại.'),
        ),
      );
      return;
    }
    widget.cubit.lookup(waybillCode: waybill, phone: phone);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lookup = widget.state.lookup;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lookup input form
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tra cứu trạng thái vận đơn',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DiscoveryColors.neutral900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nhập mã vận đơn và số điện thoại người gửi/nhận để theo dõi hành trình kiện hàng.',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    color: DiscoveryColors.neutral600,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Mã vận đơn',
                  hintText: 'VD: WAY-123456',
                  controller: _waybillController,
                  prefixIcon: const Icon(
                    Icons.inventory_2_outlined,
                    color: DiscoveryColors.neutral500,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Số điện thoại',
                  hintText: 'Số điện thoại người gửi hoặc người nhận',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: DiscoveryColors.neutral500,
                  ),
                ),
                const SizedBox(height: 18),
                CustomButton(
                  text: 'Tra cứu vận đơn',
                  isLoading: widget.state.lookingUp,
                  onPressed: _onLookup,
                  type: ButtonType.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Error handling
          if (widget.state.lookupError != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: DiscoveryColors.errorLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: DiscoveryColors.error),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: DiscoveryColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.state.lookupError!,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        color: DiscoveryColors.errorDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Lookup result display
          if (lookup != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.base),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: DiscoveryColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MÃ VẬN ĐƠN',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: DiscoveryColors.neutral500,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    lookup.waybillCode,
                                    style: const TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: DiscoveryColors.primaryDark,
                                    ),
                                    softWrap: true,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 16,
                                  ),
                                  tooltip: 'Sao chép mã',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  onPressed: () => _copyToClipboard(
                                    lookup.waybillCode,
                                    'mã vận đơn',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ShipmentStatusBadge(status: lookup.status),
                    ],
                  ),
                  const Divider(height: 16, color: DiscoveryColors.neutral200),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Mã đơn hàng: ',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          color: DiscoveryColors.neutral600,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          lookup.orderCode,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: DiscoveryColors.neutral800,
                          ),
                          softWrap: true,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        tooltip: 'Sao chép mã đơn',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () =>
                            _copyToClipboard(lookup.orderCode, 'mã đơn hàng'),
                      ),
                    ],
                  ),
                  if (lookup.dropoffDeadline != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Hạn mang hàng ra bến: ${_formatLocalDateTime(lookup.dropoffDeadline!)}',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DiscoveryColors.warningDark,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Trạng thái thanh toán: ',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          color: DiscoveryColors.neutral600,
                        ),
                      ),
                      ShipmentPaymentBadge(
                        paid: lookup.paid,
                        pendingOnline: lookup.pendingOnline,
                        counter:
                            lookup.paymentMethod ==
                            ShipmentPaymentMethod.counter,
                        requiresReconciliation: lookup.requiresReconciliation,
                        rawStatus: lookup.rawPaymentStatus,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        'Số kiện: ${lookup.packageCount}',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          color: DiscoveryColors.neutral700,
                        ),
                      ),
                      Text(
                        'Cước: ${CurrencyFormatter.format(lookup.amount)}',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: DiscoveryColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16, color: DiscoveryColors.neutral200),
                  Text(
                    'Nhà xe: ${lookup.carrier}',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: DiscoveryColors.neutral800,
                    ),
                  ),
                  Text(
                    'Tuyến: ${lookup.origin} → ${lookup.destination}',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      color: DiscoveryColors.neutral700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPoint(
                    icon: Icons.trip_origin_rounded,
                    color: DiscoveryColors.primary,
                    label: 'Điểm gửi:',
                    name: lookup.pickupName,
                    address: lookup.pickupAddress,
                  ),
                  const SizedBox(height: 6),
                  _buildPoint(
                    icon: Icons.location_on_rounded,
                    color: DiscoveryColors.secondary,
                    label: 'Điểm nhận:',
                    name: lookup.dropoffName,
                    address: lookup.dropoffAddress,
                  ),
                  if (lookup.timeline.isNotEmpty) ...[
                    const Divider(
                      height: 20,
                      color: DiscoveryColors.neutral200,
                    ),
                    const Text(
                      'Lịch trình vận chuyển',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: DiscoveryColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...lookup.timeline.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 8,
                              color: DiscoveryColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.rawStatus,
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13,
                                  color: DiscoveryColors.neutral800,
                                ),
                              ),
                            ),
                            Text(
                              DateFormatter.formatFullDate(
                                entry.time.toLocal(),
                              ),
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11,
                                color: DiscoveryColors.neutral500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatLocalDateTime(DateTime value) {
    final local = value.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm - ${DateFormatter.formatFullDate(local)}';
  }

  Widget _buildPoint({
    required IconData icon,
    required Color color,
    required String label,
    required String name,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                color: DiscoveryColors.neutral700,
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: '$name ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (address.isNotEmpty) TextSpan(text: '($address)'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
