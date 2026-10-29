import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/network/vietqr_config.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/payment_display_state.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_checkout_cubit.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';

/// Payment view displaying two independent orders and VietQR payment cards.
/// Never combines totals for a single QR. Each leg is checked and paid separately.
class RoundTripPaymentView extends StatefulWidget {
  final RoundTripRequest request;
  final RoundTripCheckoutState state;
  final ValueChanged<TripLeg> onRecheck;
  final VoidCallback? onRetrySubmitMissing;
  final ValueChanged<TripLeg>? onEditMissingLeg;
  final VoidCallback onOpenMyTickets;
  final VoidCallback onOpenSupport;

  const RoundTripPaymentView({
    super.key,
    required this.request,
    required this.state,
    required this.onRecheck,
    this.onRetrySubmitMissing,
    this.onEditMissingLeg,
    required this.onOpenMyTickets,
    required this.onOpenSupport,
  });

  @override
  State<RoundTripPaymentView> createState() => _RoundTripPaymentViewState();
}

class _RoundTripPaymentViewState extends State<RoundTripPaymentView>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final out = widget.state.outbound;
    final back = widget.state.inbound;
    final phase = widget.state.phase;

    final partiallyPaid = phase == RoundTripPhase.partiallyPaid;
    final hasUnknown = widget.state.hasUnknownOutcome;
    final conflict = widget.state.ordersConflict;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner notification
          if (conflict) ...[
            _buildAlertBanner(
              color: DiscoveryColors.errorLight,
              borderColor: DiscoveryColors.error,
              icon: Icons.warning_rounded,
              iconColor: DiscoveryColors.error,
              title: 'Mã đơn bị trùng lặp',
              message:
                  'Mã đơn hàng hoặc mã chuyển khoản giữa 2 chiều bị trùng. Để bảo vệ giao dịch, mã QR đã bị khóa. Vui lòng liên hệ tổng đài hỗ trợ.',
            ),
          ] else if (hasUnknown) ...[
            _buildAlertBanner(
              color: DiscoveryColors.warningLight,
              borderColor: DiscoveryColors.warning,
              icon: Icons.help_outline_rounded,
              iconColor: DiscoveryColors.warningDark,
              title: 'Cần xác minh trạng thái đơn',
              message:
                  'Không nhận được phản hồi tạo đơn từ máy chủ. Vui lòng không tạo lại đơn mới để tránh trừ tiền 2 lần. Hãy kiểm tra mục Vé của tôi hoặc bấm "Kiểm tra" bên dưới.',
            ),
          ] else if (partiallyPaid) ...[
            _buildAlertBanner(
              color: DiscoveryColors.primaryLight,
              borderColor: DiscoveryColors.primary,
              icon: Icons.check_circle_rounded,
              iconColor: DiscoveryColors.primary,
              title: 'Đã thanh toán 1 chiều',
              message:
                  'Bạn đã thanh toán thành công cho ${out.paymentConfirmed ? "Lượt đi" : "Lượt về"}. Vui lòng hoàn tất thanh toán cho ${out.paymentConfirmed ? "Lượt về" : "Lượt đi"} để hoàn thành chuyến khứ hồi.',
            ),
          ] else ...[
            _buildAlertBanner(
              color: DiscoveryColors.primaryLight,
              borderColor: DiscoveryColors.primary.withValues(alpha: 0.3),
              icon: Icons.payment_rounded,
              iconColor: DiscoveryColors.primary,
              title: 'Thanh toán riêng từng chiều',
              message:
                  'Hai đơn hàng được thanh toán độc lập. Vui lòng quét mã QR hoặc chuyển khoản chính xác nội dung cho từng chặng.',
            ),
          ],

          const SizedBox(height: 16),

          // Payment Card 1: Lượt đi
          _buildLegPaymentCard(
            context,
            leg: TripLeg.outbound,
            title:
                '1. Thanh toán Lượt đi: ${widget.request.origin.name} → ${widget.request.destination.name}',
            state: out,
            now: now,
          ),

          const SizedBox(height: 16),

          // Payment Card 2: Lượt về
          _buildLegPaymentCard(
            context,
            leg: TripLeg.inbound,
            title:
                '2. Thanh toán Lượt về: ${widget.request.destination.name} → ${widget.request.origin.name}',
            state: back,
            now: now,
          ),

          const SizedBox(height: 24),

          // Utility buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onOpenMyTickets,
                  icon: const Icon(
                    Icons.confirmation_number_outlined,
                    size: 18,
                  ),
                  label: const Text('Vé của tôi'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    side: const BorderSide(color: DiscoveryColors.neutral300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onOpenSupport,
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('Hỗ trợ khách hàng'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    side: const BorderSide(color: DiscoveryColors.neutral300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildAlertBanner({
    required Color color,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DiscoveryTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    color: DiscoveryColors.neutral800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegPaymentCard(
    BuildContext context, {
    required TripLeg leg,
    required String title,
    required BookingFlowState state,
    required DateTime now,
  }) {
    final booking = state.checkoutBooking;
    final isPaid = state.paymentConfirmed;
    final isExpired = state.paymentDeadlineExpired(now);
    final canTransfer = widget.state.canDisplayTransfer(leg, now);
    final hasOrder = state.pendingBookingId != null;
    final needsTicketSync =
        isPaid &&
        (state.status != BookingFlowStatus.success ||
            state.createdTickets.isEmpty);
    final legError =
        (state.status == BookingFlowStatus.failure ||
            state.status == BookingFlowStatus.blockedByBackend ||
            !hasOrder)
        ? (state.errorMessage ?? (!hasOrder ? widget.state.error : null))
        : null;

    final qrUrl =
        state.pendingQrCodeUrl ??
        ((booking?.orderCode != null && (booking?.totalAmount ?? 0) > 0)
            ? VietQrConfig.imageUrl(booking!.totalAmount, booking.orderCode!)
            : null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPaid ? DiscoveryColors.success : DiscoveryColors.neutral200,
          width: isPaid ? 1.5 : 1,
        ),
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
          // Header & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: DiscoveryTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isPaid)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.successLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: DiscoveryColors.success),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: DiscoveryColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ĐÃ THANH TOÁN',
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.successDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isExpired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.neutral100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'HẾT HẠN',
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (hasOrder)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.warningLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'CHỜ THANH TOÁN',
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.warningDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.neutral100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'CHƯA TẠO ĐƠN',
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Order ID & Amount
          if (booking != null) ...[
            _buildCopyableRow(
              label: 'Mã đơn hàng',
              value: '#${booking.bookingId}',
              copyText: '${booking.bookingId}',
            ),
            const SizedBox(height: 6),
            _buildCopyableRow(
              label: 'Nội dung CK',
              value: booking.orderCode ?? '',
              copyText: booking.orderCode ?? '',
              highlight: true,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Số tiền cần chuyển',
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    color: DiscoveryColors.neutral600,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(booking.totalAmount),
                  style: DiscoveryTextStyles.titleMedium.copyWith(
                    color: DiscoveryColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ] else ...[
            if (state.selectedSeats.isNotEmpty)
              Text(
                'Ghế đã chọn: ${state.selectedSeats.map((s) => s.name).join(", ")}',
                style: DiscoveryTextStyles.bodySmall.copyWith(
                  color: DiscoveryColors.neutral700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (state.finalAmount != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Số tiền dự kiến',
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      color: DiscoveryColors.neutral600,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(state.finalAmount!),
                    style: DiscoveryTextStyles.titleSmall.copyWith(
                      color: DiscoveryColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ],

          if (legError != null && legError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DiscoveryColors.errorLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DiscoveryColors.error),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: DiscoveryColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      legError,
                      style: DiscoveryTextStyles.caption.copyWith(
                        color: DiscoveryColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // QR Code section
          if (canTransfer && booking != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: DiscoveryColors.neutral200),
            const SizedBox(height: 14),
            Center(
              child: Column(
                children: [
                  if (qrUrl != null && qrUrl.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DiscoveryColors.neutral300),
                      ),
                      child: Image.network(
                        qrUrl,
                        width: 170,
                        height: 170,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 170,
                          height: 170,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            size: 100,
                            color: DiscoveryColors.neutral400,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (booking.expiresAt != null)
                    _buildCountdown(booking.expiresAt!, now),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Bank details
            _buildBankInfo(),
          ] else if (isPaid) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DiscoveryColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: DiscoveryColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      !needsTicketSync
                          ? 'Đã xuất vé điện tử thành công.'
                          : 'Hệ thống đã nhận thanh toán, đang cập nhật vé.',
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.successDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isExpired) ...[
            const SizedBox(height: 10),
            Text(
              'Đơn hàng đã quá thời hạn thanh toán. Nếu bạn đã chuyển khoản, hãy bấm nút "Kiểm tra thanh toán" dưới đây.',
              style: DiscoveryTextStyles.caption.copyWith(
                color: DiscoveryColors.neutral600,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Recheck Button (for unpaid orders OR paid orders needing ticket hydration)
          if (hasOrder && (!isPaid || needsTicketSync))
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: ValueKey('recheck-${leg.name}-btn'),
                onPressed: widget.state.busy
                    ? null
                    : () => widget.onRecheck(leg),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(isPaid ? 'Đồng bộ lại vé' : 'Kiểm tra thanh toán'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiscoveryColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: DiscoveryColors.neutral300,
                  minimumSize: const Size(double.infinity, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),

          // Retry / Edit actions for uncreated missing leg
          if (!hasOrder &&
              !state.bookingOutcomeUnknown &&
              !widget.state.hasUnknownOutcome) ...[
            if (widget.onRetrySubmitMissing != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: ValueKey('retry-create-${leg.name}-btn'),
                  onPressed: widget.state.busy
                      ? null
                      : widget.onRetrySubmitMissing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DiscoveryColors.secondary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: DiscoveryColors.neutral300,
                    minimumSize: const Size(double.infinity, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Thử lại / Tạo đơn chiều này'),
                ),
              ),
            if (widget.onEditMissingLeg != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: ValueKey('edit-missing-${leg.name}-btn'),
                  onPressed: widget.state.busy
                      ? null
                      : () => widget.onEditMissingLeg!(leg),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    side: const BorderSide(color: DiscoveryColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Chọn lại ghế / điểm đón trả chiều này'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCountdown(DateTime expiresAt, DateTime now) {
    final diff = expiresAt.difference(now);
    if (diff.isNegative) {
      return Text(
        'Đã hết hạn thanh toán',
        style: DiscoveryTextStyles.caption.copyWith(
          color: DiscoveryColors.error,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    final mins = diff.inMinutes.toString().padLeft(2, '0');
    final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.timer_outlined,
          size: 16,
          color: DiscoveryColors.warningDark,
        ),
        const SizedBox(width: 4),
        Text(
          'Hết hạn sau: $mins:$secs',
          style: DiscoveryTextStyles.caption.copyWith(
            color: DiscoveryColors.warningDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBankInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DiscoveryColors.neutral100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildCopyableRow(
            label: 'Ngân hàng',
            value: VietQrConfig.bankId,
            copyText: VietQrConfig.bankId,
          ),
          const SizedBox(height: 6),
          _buildCopyableRow(
            label: 'Số tài khoản',
            value: VietQrConfig.accountNumber,
            copyText: VietQrConfig.accountNumber,
            highlight: true,
          ),
          const SizedBox(height: 6),
          _buildCopyableRow(
            label: 'Chủ tài khoản',
            value: VietQrConfig.accountName,
            copyText: VietQrConfig.accountName,
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableRow({
    required String label,
    required String value,
    required String copyText,
    bool highlight = false,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: DiscoveryTextStyles.caption.copyWith(
              color: DiscoveryColors.neutral600,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                    color: highlight
                        ? DiscoveryColors.primary
                        : DiscoveryColors.neutral900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: copyText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã sao chép: $copyText'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: DiscoveryColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
