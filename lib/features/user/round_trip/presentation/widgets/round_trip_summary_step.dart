import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';

/// Unified review & summary step for both round-trip legs.
/// Displays operator details, seats, pickup/dropoff, separate quotes/vouchers,
/// and total overview before order creation.
class RoundTripSummaryStep extends StatefulWidget {
  final RoundTripRequest request;
  final BookingFlowState outbound;
  final BookingFlowState inbound;
  final int? totalAmount;
  final bool busy;
  final String? error;
  final ValueChanged<String> onApplyOutboundVoucher;
  final VoidCallback onRemoveOutboundVoucher;
  final ValueChanged<String> onApplyInboundVoucher;
  final VoidCallback onRemoveInboundVoucher;
  final ValueChanged<TripLeg>? onEditLeg;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const RoundTripSummaryStep({
    super.key,
    required this.request,
    required this.outbound,
    required this.inbound,
    required this.totalAmount,
    required this.busy,
    this.error,
    required this.onApplyOutboundVoucher,
    required this.onRemoveOutboundVoucher,
    required this.onApplyInboundVoucher,
    required this.onRemoveInboundVoucher,
    this.onEditLeg,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  State<RoundTripSummaryStep> createState() => _RoundTripSummaryStepState();
}

class _RoundTripSummaryStepState extends State<RoundTripSummaryStep> {
  final TextEditingController _outboundVoucherController =
      TextEditingController();
  final TextEditingController _inboundVoucherController =
      TextEditingController();

  @override
  void dispose() {
    _outboundVoucherController.dispose();
    _inboundVoucherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final out = widget.outbound;
    final back = widget.inbound;
    final outReady =
        out.pendingBookingId != null ||
        (out.hasUsableQuote && !out.quoteLoading);
    final backReady =
        back.pendingBookingId != null ||
        (back.hasUsableQuote && !back.quoteLoading);
    final canSubmit =
        !widget.busy &&
        !out.bookingOutcomeUnknown &&
        !back.bookingOutcomeUnknown &&
        widget.totalAmount != null &&
        outReady &&
        backReady;
    final effectiveError =
        widget.error ??
        ((out.status == BookingFlowStatus.failure ||
                out.status == BookingFlowStatus.blockedByBackend)
            ? out.errorMessage
            : null) ??
        ((back.status == BookingFlowStatus.failure ||
                back.status == BookingFlowStatus.blockedByBackend)
            ? back.errorMessage
            : null);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (effectiveError != null && effectiveError.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: DiscoveryColors.errorLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DiscoveryColors.error),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: DiscoveryColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      effectiveError,
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Card 1: Lượt đi
          _buildLegCard(
            context,
            leg: TripLeg.outbound,
            title:
                'Lượt đi: ${widget.request.origin.name} → ${widget.request.destination.name}',
            dateStr: DateFormatter.formatFullDate(widget.request.departureDate),
            state: out,
            voucherController: _outboundVoucherController,
            onApplyVoucher: widget.onApplyOutboundVoucher,
            onRemoveVoucher: widget.onRemoveOutboundVoucher,
          ),

          const SizedBox(height: 16),

          // Card 2: Lượt về
          _buildLegCard(
            context,
            leg: TripLeg.inbound,
            title:
                'Lượt về: ${widget.request.destination.name} → ${widget.request.origin.name}',
            dateStr: DateFormatter.formatFullDate(widget.request.returnDate),
            state: back,
            voucherController: _inboundVoucherController,
            onApplyVoucher: widget.onApplyInboundVoucher,
            onRemoveVoucher: widget.onRemoveInboundVoucher,
          ),

          const SizedBox(height: 16),

          // Card 3: Thông tin hành khách
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      color: DiscoveryColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hành khách đại diện',
                        style: DiscoveryTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${out.passengerName} • ${out.passengerPhone}',
                  style: DiscoveryTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (out.passengerEmail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    out.passengerEmail,
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      color: DiscoveryColors.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Card 4: Tổng kết chi phí
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: DiscoveryColors.primary.withValues(alpha: 0.3),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0a000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng kết chi phí',
                  style: DiscoveryTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPriceRow(
                  'Lượt đi (${out.selectedSeats.length} vé)',
                  CurrencyFormatter.format(out.finalAmount ?? 0),
                ),
                const SizedBox(height: 6),
                _buildPriceRow(
                  'Lượt về (${back.selectedSeats.length} vé)',
                  CurrencyFormatter.format(back.finalAmount ?? 0),
                ),
                const Divider(height: 20, color: DiscoveryColors.neutral200),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Tổng tiền thanh toán',
                      style: DiscoveryTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.totalAmount != null
                          ? CurrencyFormatter.format(widget.totalAmount!)
                          : 'Đang xác minh giá...',
                      style: DiscoveryTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: DiscoveryColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Lưu ý: Hai đơn hàng sẽ được tạo tuần tự và thanh toán riêng từng chiều.',
                  style: DiscoveryTextStyles.caption.copyWith(
                    color: DiscoveryColors.neutral500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              OutlinedButton(
                onPressed: widget.busy ? null : widget.onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(100, 48),
                  side: const BorderSide(color: DiscoveryColors.neutral300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Quay lại',
                  style: DiscoveryTextStyles.bodyMedium.copyWith(
                    color: DiscoveryColors.neutral700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  key: const ValueKey('confirm-and-pay-btn'),
                  onPressed: canSubmit ? widget.onSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DiscoveryColors.secondary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: DiscoveryColors.neutral300,
                    minimumSize: const Size(140, 48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: widget.busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Tạo đơn & Thanh toán',
                          style: DiscoveryTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegCard(
    BuildContext context, {
    required TripLeg leg,
    required String title,
    required String dateStr,
    required BookingFlowState state,
    required TextEditingController voucherController,
    required ValueChanged<String> onApplyVoucher,
    required VoidCallback onRemoveVoucher,
  }) {
    final trip = state.trip;
    final seatsStr = state.selectedSeats.map((s) => s.name).join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DiscoveryColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DiscoveryColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  leg == TripLeg.outbound ? 'LƯỢT ĐI' : 'LƯỢT VỀ',
                  style: DiscoveryTextStyles.caption.copyWith(
                    color: DiscoveryColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: DiscoveryTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${trip?.operatorName ?? "Nhà xe"} • $dateStr',
            style: DiscoveryTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ghế đã chọn: $seatsStr',
            style: DiscoveryTextStyles.bodySmall.copyWith(
              color: DiscoveryColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          if (state.selectedPickupPoint != null) ...[
            Text(
              'Đón: ${state.selectedPickupPoint!.time} - ${state.selectedPickupPoint!.name}',
              style: DiscoveryTextStyles.caption.copyWith(
                color: DiscoveryColors.neutral600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (state.selectedDropoffPoint != null) ...[
            Text(
              'Trả: ${state.selectedDropoffPoint!.time} - ${state.selectedDropoffPoint!.name}',
              style: DiscoveryTextStyles.caption.copyWith(
                color: DiscoveryColors.neutral600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if ((state.status == BookingFlowStatus.failure ||
                  state.status == BookingFlowStatus.blockedByBackend) &&
              state.errorMessage != null &&
              state.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              state.errorMessage!,
              style: DiscoveryTextStyles.caption.copyWith(
                color: DiscoveryColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (widget.onEditLeg != null &&
              state.pendingBookingId == null &&
              !state.bookingOutcomeUnknown) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: ValueKey('edit-summary-leg-${leg.name}-btn'),
                onPressed: widget.busy ? null : () => widget.onEditLeg!(leg),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Đổi ghế / điểm đón trả'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: DiscoveryColors.neutral200),
          const SizedBox(height: 10),

          // Voucher row
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: ValueKey('voucher-input-${leg.name}'),
                  controller: voucherController,
                  decoration: InputDecoration(
                    hintText:
                        'Mã giảm giá ${leg == TripLeg.outbound ? "lượt đi" : "lượt về"}',
                    hintStyle: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral400,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                key: ValueKey('apply-voucher-btn-${leg.name}'),
                onPressed: () {
                  final code = voucherController.text.trim();
                  if (code.isNotEmpty) onApplyVoucher(code);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiscoveryColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(64, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Áp dụng', style: TextStyle(fontSize: 12)),
              ),
              if (state.appliedVoucher != null ||
                  state.requestedPromotionCode.isNotEmpty) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Gỡ voucher',
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: DiscoveryColors.error,
                  ),
                  onPressed: onRemoveVoucher,
                ),
              ],
            ],
          ),
          if (state.quoteError != null) ...[
            const SizedBox(height: 4),
            Text(
              state.quoteError!,
              style: DiscoveryTextStyles.caption.copyWith(
                color: DiscoveryColors.error,
              ),
            ),
          ],

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Giá vé chặng',
                  style: DiscoveryTextStyles.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.format(state.finalAmount ?? 0),
                style: DiscoveryTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: DiscoveryColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: DiscoveryTextStyles.bodySmall.copyWith(
              color: DiscoveryColors.neutral700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: DiscoveryTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
