import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/vietqr_config.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import '../widgets/booking_cargo_section_card.dart';
import '../widgets/payment_display_state.dart';

class Step6Payment extends StatefulWidget {
  final BookingFlowState state;
  final BookingFlowBloc bloc;
  final bool showInlineCountdown;

  const Step6Payment({
    super.key,
    required this.state,
    required this.bloc,
    this.showInlineCountdown = false,
  });

  @override
  State<Step6Payment> createState() => _Step6PaymentState();
}

class _Step6PaymentState extends State<Step6Payment>
    with WidgetsBindingObserver {
  Timer? _renderTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startRenderTimer();
  }

  void _startRenderTimer() {
    _renderTimer?.cancel();
    if (widget.state.checkoutBooking?.expiresAt != null) {
      _renderTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(Step6Payment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.checkoutBooking?.expiresAt !=
        widget.state.checkoutBooking?.expiresAt) {
      _startRenderTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed && mounted) {
      // Re-evaluate wall-clock time immediately upon resuming
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _renderTimer?.cancel();
    super.dispose();
  }

  bool get _isOrderPaid => widget.state.hasConfirmedPayment;

  bool get _isBookingExpired =>
      widget.state.paymentDeadlineExpired(DateTime.now());

  int get _bookingRemainingSeconds {
    final booking = widget.state.checkoutBooking;
    if (booking == null || booking.expiresAt == null) return 0;
    final diff = booking.expiresAt!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  String get _bookingRemainingFormatted {
    final secs = _bookingRemainingSeconds;
    final minutes = (secs ~/ 60).toString().padLeft(2, '0');
    final seconds = (secs % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final bloc = widget.bloc;
    final hasPendingOrder = state.pendingBookingId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.base,
        AppDimensions.sm,
        AppDimensions.base,
        AppDimensions.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quote Error Alert
          if (state.quoteError != null && state.pendingBookingId == null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.md),
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: DiscoveryColors.errorLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: DiscoveryColors.error),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: DiscoveryColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.quoteError!,
                      style: DiscoveryTextStyles.bodyMedium.copyWith(
                        color: DiscoveryColors.error,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: state.quoteLoading
                        ? null
                        : () => bloc.add(const RefreshBookingQuoteEvent()),
                    child: const Text('Cập nhật giá vé'),
                  ),
                ],
              ),
            ),
          ],

          // Unknown Outcome Alert
          if (state.bookingOutcomeUnknown) ...[
            Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.md),
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: DiscoveryColors.warningLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: DiscoveryColors.warningDark.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: DiscoveryColors.warningDark,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kết quả tạo đơn chưa xác định',
                          style: DiscoveryTextStyles.bodyMedium.copyWith(
                            color: DiscoveryColors.warningDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Máy chủ chưa phản hồi trạng thái tạo đơn. Không gửi lại yêu cầu để tránh trừ tiền nhiều lần. Vui lòng kiểm tra mục "Vé của tôi" hoặc liên hệ tổng đài.',
                          style: DiscoveryTextStyles.bodySmall.copyWith(
                            color: DiscoveryColors.neutral700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Error Message Alert
          if (state.errorMessage != null &&
              (state.isCheckoutLocked ||
                  state.status == BookingFlowStatus.blockedByBackend))
            Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.md),
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: DiscoveryColors.errorLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: DiscoveryColors.error.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: DiscoveryColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.errorDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Inline Seat Hold Countdown (Narrow viewports / Large text scale before order)
          if (widget.showInlineCountdown &&
              state.seatHold != null &&
              !hasPendingOrder)
            Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.md),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: DiscoveryColors.warningLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: DiscoveryColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: DiscoveryColors.warningDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thời gian giữ chỗ còn lại: ${state.countdownFormatted}',
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.warningDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Main Content: Pre-Order vs Post-Order
          if (!hasPendingOrder) ...[
            _buildPreOrderView(context),
          ] else ...[
            _buildPostOrderView(context),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PRE-ORDER VIEW
  // -------------------------------------------------------------
  Widget _buildPreOrderView(BuildContext context) {
    final state = widget.state;
    final trip = state.trip;
    final date = state.date;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Total Amount Header Card
        Container(
          padding: const EdgeInsets.all(AppDimensions.base),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: DiscoveryColors.neutral200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số tiền thanh toán',
                      style: DiscoveryTextStyles.caption.copyWith(
                        color: DiscoveryColors.neutral500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (state.pendingPaymentAmount ?? state.finalAmount) != null
                          ? CurrencyFormatter.format(
                              state.pendingPaymentAmount ?? state.finalAmount,
                            )
                          : state.cargo.enabled
                          ? 'Xác định khi tạo đơn'
                          : 'Chưa có giá vé',
                      style: DiscoveryTextStyles.price.copyWith(
                        color: DiscoveryColors.secondary,
                        fontSize:
                            (state.pendingPaymentAmount ?? state.finalAmount) !=
                                null
                            ? 22
                            : 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (state.cargo.enabled &&
                        (state.pendingPaymentAmount ?? state.finalAmount) ==
                            null) ...[
                      const SizedBox(height: 4),
                      Text(
                        state.ticketFinalAmount != null
                            ? 'Tiền vé sau ưu đãi: ${CurrencyFormatter.format(state.ticketFinalAmount!)} • Phí gửi hàng được xác định khi tạo đơn'
                            : 'Phí gửi hàng được xác định khi tạo đơn',
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.neutral600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DiscoveryColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.selectedSeats.length} Vé',
                  style: DiscoveryTextStyles.caption.copyWith(
                    color: DiscoveryColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.base),

        if (state.cargo.enabled) ...[
          BookingCargoSummaryBox(state: state, scopeKey: 'oneway-preorder'),
          const SizedBox(height: AppDimensions.base),
        ],

        // Trip & Seats Recap Card
        if (trip != null)
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.directions_bus_rounded,
                      size: 18,
                      color: DiscoveryColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Thông tin chuyến đi',
                        style: DiscoveryTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${trip.departureTime}${date != null ? ' • ${DateFormatter.formatShortDate(date)}' : ''} • ${trip.fromCityName} → ${trip.toCityName}',
                  style: DiscoveryTextStyles.bodyMedium.copyWith(
                    color: DiscoveryColors.neutral700,
                  ),
                ),
                const Divider(height: 20),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final seat in state.selectedSeats)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DiscoveryColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: DiscoveryColors.primary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          'Ghế ${seat.name}',
                          style: DiscoveryTextStyles.caption.copyWith(
                            color: DiscoveryColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                if (state.selectedPickupPoint != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Điểm đón: ${state.selectedPickupPoint!.name}',
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      color: DiscoveryColors.neutral600,
                    ),
                  ),
                ],
                if (state.selectedDropoffPoint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Điểm trả: ${state.selectedDropoffPoint!.name}',
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      color: DiscoveryColors.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: AppDimensions.base),

        // Payment Methods Section
        Text(
          'Chọn phương thức thanh toán',
          style: DiscoveryTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),

        // Real Mode only exposes VietQR; Demo mode exposes all demo methods
        _buildPaymentMethodTile(
          methodId: 'vietqr',
          title: 'Chuyển khoản VietQR',
          subtitle:
              'Quét mã QR tự động xác nhận 24/7 (Hỗ trợ mọi ngân hàng & ví điện tử)',
          iconData: Icons.qr_code_2_rounded,
          iconColor: DiscoveryColors.successDark,
          badgeText: 'Khuyên dùng',
        ),

        if (ApiConfig.isDemoMode) ...[
          _buildPaymentMethodTile(
            methodId: 'momo',
            title: 'Ví MoMo',
            subtitle: 'Thanh toán tức thì qua ứng dụng MoMo (Demo)',
            iconData: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFFA50064),
          ),
          _buildPaymentMethodTile(
            methodId: 'zalopay',
            title: 'Ví ZaloPay',
            subtitle: 'Thanh toán an toàn với ví ZaloPay hoặc Zalo (Demo)',
            iconData: Icons.wallet_rounded,
            iconColor: const Color(0xFF0068FF),
          ),
          _buildPaymentMethodTile(
            methodId: 'napas',
            title: 'Thẻ ATM nội địa',
            subtitle: 'Internet Banking hơn 40 ngân hàng Việt Nam (Demo)',
            iconData: Icons.credit_card_rounded,
            iconColor: DiscoveryColors.primary,
          ),
          _buildPaymentMethodTile(
            methodId: 'visa',
            title: 'Thẻ quốc tế',
            subtitle: 'Thanh toán thẻ Visa, MasterCard, JCB (Demo)',
            iconData: Icons.payment_rounded,
            iconColor: const Color(0xFF1A1F71),
          ),
        ],

        const SizedBox(height: AppDimensions.md),

        // Security Badge
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_rounded,
                size: 14,
                color: DiscoveryColors.neutral500,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Chỉ xuất vé sau khi hệ thống xác nhận thanh toán',
                  style: DiscoveryTextStyles.caption.copyWith(
                    color: DiscoveryColors.neutral500,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // POST-ORDER VIEW (PENDING BOOKING)
  // -------------------------------------------------------------
  Widget _buildPostOrderView(BuildContext context) {
    final state = widget.state;
    final booking = state.checkoutBooking;
    final isPaid = _isOrderPaid;
    final isExpired = _isBookingExpired;
    final canTransfer = state.canDisplayBankTransfer(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pending booking ID line
        if (state.pendingBookingId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Đơn đặt chỗ: #${state.pendingBookingId}',
              style: DiscoveryTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: DiscoveryColors.neutral800,
              ),
            ),
          ),

        // Paid / Ticket Sync Notice if Paid
        if (isPaid) ...[
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: DiscoveryColors.successLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: DiscoveryColors.success),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: DiscoveryColors.success,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đã xác nhận thanh toán',
                        style: DiscoveryTextStyles.bodyMedium.copyWith(
                          color: DiscoveryColors.successDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hệ thống đã ghi nhận thanh toán thành công cho đơn hàng này. Vé điện tử đang được đồng bộ và xử lý phát hành. Vui lòng nhấn "Kiểm tra kết quả thanh toán" ở thanh bên dưới để làm mới trạng thái vé.',
                        style: DiscoveryTextStyles.bodySmall.copyWith(
                          color: DiscoveryColors.neutral700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else if (isExpired) ...[
          // Expiration Warning if Expired
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: DiscoveryColors.errorLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: DiscoveryColors.error),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.timer_off_rounded,
                  color: DiscoveryColors.error,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đơn đặt vé đã hết hạn thanh toán',
                        style: DiscoveryTextStyles.bodyMedium.copyWith(
                          color: DiscoveryColors.errorDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thời gian giữ chỗ và thanh toán của đơn đã kết thúc. Vui lòng không thực hiện chuyển khoản cho đơn này. Nếu đã chuyển tiền sát giờ, vui lòng nhấn "Kiểm tra kết quả thanh toán" hoặc liên hệ tổng đài hỗ trợ.',
                        style: DiscoveryTextStyles.bodySmall.copyWith(
                          color: DiscoveryColors.neutral700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else if (canTransfer) ...[
          // Active Authoritative Countdown Timer Card
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DiscoveryColors.warningLight.withValues(alpha: 0.9),
                  Colors.white,
                ],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: DiscoveryColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: DiscoveryColors.warning,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thời gian thanh toán còn lại:',
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.neutral700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _bookingRemainingFormatted,
                        style: DiscoveryTextStyles.h3.copyWith(
                          color: DiscoveryColors.warningDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Booking Codes & Tickets Card
        if (booking != null) ...[
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: DiscoveryColors.neutral200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SelectableText(
                        'Mã đặt vé: ${booking.bookingCode}',
                        style: DiscoveryTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: DiscoveryColors.neutral900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sao chép mã đặt vé',
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: DiscoveryColors.primary,
                      ),
                      onPressed: () => _copyToClipboard(
                        context,
                        booking.bookingCode,
                        'mã đặt vé: ${booking.bookingCode}',
                      ),
                    ),
                  ],
                ),
                for (final ticket in booking.tickets)
                  if (ticket.ticketCode.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SelectableText(
                              'Mã vé: ${ticket.ticketCode}',
                              style: DiscoveryTextStyles.bodyMedium.copyWith(
                                color: DiscoveryColors.neutral700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Sao chép mã vé',
                            icon: const Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: DiscoveryColors.neutral500,
                            ),
                            onPressed: () => _copyToClipboard(
                              context,
                              ticket.ticketCode,
                              'mã vé: ${ticket.ticketCode}',
                            ),
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 8),
                if (BookingCargoSummaryBox.hasCargo(
                  state: state,
                  booking: booking,
                )) ...[
                  const Divider(height: 16),
                  if (booking.ticketSubtotal != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 2,
                          children: [
                            Text(
                              'Tiền vé sau ưu đãi:',
                              style: DiscoveryTextStyles.bodySmall.copyWith(
                                color: DiscoveryColors.neutral600,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(booking.ticketSubtotal!),
                              style: DiscoveryTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: DiscoveryColors.neutral900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (booking.shippingFee != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 2,
                          children: [
                            Text(
                              'Phí gửi hàng:',
                              style: DiscoveryTextStyles.bodySmall.copyWith(
                                color: DiscoveryColors.neutral600,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(booking.shippingFee!),
                              style: DiscoveryTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: DiscoveryColors.neutral900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          Text(
                            'Tổng đơn thanh toán:',
                            style: DiscoveryTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: DiscoveryColors.neutral900,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(booking.totalAmount),
                            style: DiscoveryTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: DiscoveryColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  BookingCargoSummaryBox(
                    state: state,
                    booking: booking,
                    scopeKey: 'oneway-postorder',
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Lưu mã vé và tra cứu bằng số điện thoại liên hệ để kiểm tra đơn sau khi rời màn hình.',
                  style: DiscoveryTextStyles.caption.copyWith(
                    color: DiscoveryColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.base),
        ],

        // VietQR Transfer Details Card (When active & not expired & not paid)
        if (canTransfer && booking != null) ...[
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: DiscoveryColors.neutral200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Thông tin chuyển khoản VietQR',
                  style: DiscoveryTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: DiscoveryColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quét mã QR qua app ngân hàng hoặc sao chép thông tin chuyển khoản chính xác bên dưới:',
                  style: DiscoveryTextStyles.caption.copyWith(
                    color: DiscoveryColors.neutral600,
                  ),
                ),
                const Divider(height: 20),

                // Nội dung chuyển khoản
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SelectableText(
                        'Nội dung chuyển khoản: ${booking.orderCode ?? ''}',
                        style: DiscoveryTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: DiscoveryColors.secondary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sao chép nội dung chuyển khoản',
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: DiscoveryColors.secondary,
                      ),
                      onPressed: () => _copyToClipboard(
                        context,
                        booking.orderCode ?? '',
                        'nội dung chuyển khoản: ${booking.orderCode ?? ''}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Ngân hàng
                Text(
                  'Ngân hàng: ${VietQrConfig.bankId}',
                  style: DiscoveryTextStyles.bodyMedium.copyWith(
                    color: DiscoveryColors.neutral800,
                  ),
                ),
                const SizedBox(height: 6),

                // Số tài khoản
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SelectableText(
                        'Số tài khoản: ${VietQrConfig.accountNumber}',
                        style: DiscoveryTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: DiscoveryColors.neutral800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sao chép số tài khoản',
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: DiscoveryColors.primary,
                      ),
                      onPressed: () => _copyToClipboard(
                        context,
                        VietQrConfig.accountNumber,
                        'số tài khoản: ${VietQrConfig.accountNumber}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Chủ tài khoản
                Text(
                  'Chủ tài khoản: ${VietQrConfig.accountName}',
                  style: DiscoveryTextStyles.bodyMedium.copyWith(
                    color: DiscoveryColors.neutral800,
                  ),
                ),
                const SizedBox(height: 6),

                // Số tiền
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Số tiền: ${CurrencyFormatter.format(booking.totalAmount)}',
                        style: DiscoveryTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: DiscoveryColors.secondary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sao chép số tiền',
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: DiscoveryColors.secondary,
                      ),
                      onPressed: () => _copyToClipboard(
                        context,
                        booking.totalAmount.toString(),
                        'số tiền: ${CurrencyFormatter.format(booking.totalAmount)}',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // QR Image container
                if (state.pendingQrCodeUrl != null ||
                    (booking.orderCode != null && booking.totalAmount > 0)) ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DiscoveryColors.neutral300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.network(
                        state.pendingQrCodeUrl ??
                            VietQrConfig.imageUrl(
                              booking.totalAmount,
                              booking.orderCode!,
                            )!,
                        height: 260,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Không tải được QR. Bạn có thể chuyển khoản theo thông tin và nội dung bên trên.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.base),
        ],

        // Demo Gateway Card (MoMo / ZaloPay in Demo Mode)
        if (state.pendingPaymentId != null &&
            state.status != BookingFlowStatus.blockedByBackend) ...[
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: DiscoveryColors.infoLight.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: DiscoveryColors.info),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.hourglass_top_rounded,
                      color: DiscoveryColors.info,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Giao dịch thanh toán đang chờ xử lý',
                        style: DiscoveryTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: DiscoveryColors.neutral800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Mã giao dịch: #${state.pendingPaymentId}',
                  style: DiscoveryTextStyles.caption.copyWith(
                    color: DiscoveryColors.neutral600,
                  ),
                ),
                if (state.pendingPaymentUrl != null &&
                    state.pendingPaymentUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      _copyToClipboard(
                        context,
                        state.pendingPaymentUrl!,
                        'đường dẫn thanh toán',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: DiscoveryColors.neutral300),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.link,
                            size: 18,
                            color: DiscoveryColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.pendingPaymentUrl!,
                              style: DiscoveryTextStyles.caption.copyWith(
                                color: DiscoveryColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.copy,
                            size: 16,
                            color: DiscoveryColors.neutral500,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.base),
        ],

        // Instructions
        if (isPaid) ...[
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: DiscoveryColors.neutral50,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: DiscoveryColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lưu ý về vé điện tử',
                        style: DiscoveryTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Đơn hàng đã được xác nhận thanh toán thành công.\n'
                  '2. Nếu danh sách vé chưa hiển thị hoặc đang đồng bộ, vui lòng nhấn nút "Kiểm tra kết quả thanh toán" ở thanh bên dưới.\n'
                  '3. Bạn cũng có thể tra cứu lại vé bất kỳ lúc nào trong mục "Vé của tôi" bằng số điện thoại đặt vé.',
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    color: DiscoveryColors.neutral700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ] else if (isExpired) ...[
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: DiscoveryColors.neutral50,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: DiscoveryColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lưu ý khi đơn hàng hết hạn',
                        style: DiscoveryTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Vui lòng không thực hiện chuyển khoản cho đơn hàng này.\n'
                  '2. Nếu bạn đã chuyển khoản trước khi đơn hết hạn, nhấn "Kiểm tra kết quả thanh toán" để hệ thống đối soát.\n'
                  '3. Trường hợp cần trợ giúp hoặc đã trừ tiền nhưng chưa có vé, vui lòng liên hệ tổng đài VexGo để được hỗ trợ.',
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    color: DiscoveryColors.neutral700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ] else if (canTransfer) ...[
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: DiscoveryColors.neutral50,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: DiscoveryColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: DiscoveryColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hướng dẫn sau khi chuyển tiền',
                        style: DiscoveryTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Mở ứng dụng ngân hàng và chuyển khoản đúng số tiền cùng nội dung chuyển khoản.\n'
                  '2. Nhấn nút "Kiểm tra kết quả thanh toán" ở thanh bên dưới.\n'
                  '3. Vé được hiển thị sau khi hệ thống xác nhận thanh toán và đồng bộ đầy đủ.',
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    color: DiscoveryColors.neutral700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: DiscoveryColors.warningLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Text(
              'Đơn hiện tại chưa đủ điều kiện thanh toán hoặc chưa xác minh được trạng thái. '
              'Vui lòng không chuyển thêm tiền. Nhấn "Kiểm tra kết quả thanh toán" '
              'để kiểm tra đơn hiện tại hoặc liên hệ hỗ trợ nếu đã chuyển khoản.',
              style: DiscoveryTextStyles.bodySmall.copyWith(
                color: DiscoveryColors.neutral700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------
  // PAYMENT METHOD TILE
  // -------------------------------------------------------------
  Widget _buildPaymentMethodTile({
    required String methodId,
    required String title,
    required String subtitle,
    required IconData iconData,
    required Color iconColor,
    String? badgeText,
  }) {
    if (!ApiConfig.isDemoMode && methodId != 'vietqr') {
      return const SizedBox.shrink();
    }
    final isSelected = widget.state.selectedPaymentMethod == methodId;

    return GestureDetector(
      onTap: widget.state.isCheckoutLocked
          ? null
          : () => widget.bloc.add(SelectPaymentMethodEvent(methodId)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: AppDimensions.sm),
        padding: const EdgeInsets.all(AppDimensions.base),
        decoration: BoxDecoration(
          color: isSelected
              ? DiscoveryColors.primaryLight.withValues(alpha: 0.3)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isSelected
                ? DiscoveryColors.primary
                : DiscoveryColors.neutral200,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Radio circle
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? DiscoveryColors.primary
                      : DiscoveryColors.neutral400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: DiscoveryColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: AppDimensions.md),

            // Icon box
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),

            const SizedBox(width: AppDimensions.md),

            // Text section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: DiscoveryTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: DiscoveryColors.secondaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: DiscoveryTextStyles.caption.copyWith(
                              color: DiscoveryColors.secondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
