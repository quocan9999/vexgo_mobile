import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import '../widgets/booking_cargo_section_card.dart';
import '../widgets/seat_hold_countdown_bar.dart';
import '../widgets/voucher_selection_sheet.dart';

class Step5TripSummary extends StatelessWidget {
  final BookingFlowState state;
  final BookingFlowBloc bloc;
  final bool showInlineCountdown;

  const Step5TripSummary({
    super.key,
    required this.state,
    required this.bloc,
    this.showInlineCountdown = false,
  });

  @override
  Widget build(BuildContext context) {
    final trip = state.trip;
    final dateStr = state.date != null
        ? DateFormatter.formatFullDate(state.date!)
        : '';
    final seatNames = state.selectedSeats.map((s) => s.name).join(', ');
    final promotionCode = state.requestedPromotionCode.trim().toUpperCase();
    final promotionAccepted = state.requiresAuthoritativeQuote
        ? state.hasUsableQuote &&
              promotionCode.isNotEmpty &&
              state.quote?.appliedPromotionCode?.toUpperCase() == promotionCode
        : state.appliedVoucher != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showInlineCountdown && state.seatHold != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SeatHoldCountdownBar(
                remainingSeconds: state.countdownSeconds,
                compact: true,
                seatCodes: state.selectedSeats.map((s) => s.name).toList(),
              ),
            ),

          if (state.quoteLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LinearProgressIndicator(
                    color: DiscoveryColors.primary,
                    backgroundColor: DiscoveryColors.primaryLight,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đang cập nhật giá vé & ưu đãi...',
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),

          if (state.quoteError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DiscoveryColors.errorLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DiscoveryColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: DiscoveryColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.quoteError!,
                          style: DiscoveryTextStyles.bodySmall.copyWith(
                            color: DiscoveryColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: state.quoteLoading
                              ? null
                              : () =>
                                    bloc.add(const RefreshBookingQuoteEvent()),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.refresh_rounded,
                                size: 16,
                                color: DiscoveryColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Cập nhật giá vé',
                                style: DiscoveryTextStyles.caption.copyWith(
                                  color: DiscoveryColors.primary,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Section Title
          Text('Xem lại thông tin chuyến đi', style: DiscoveryTextStyles.h4),
          const SizedBox(height: 4),
          Text(
            'Vui lòng kiểm tra kỹ thông tin hành trình và hành khách trước khi sang bước thanh toán.',
            style: DiscoveryTextStyles.caption.copyWith(
              color: DiscoveryColors.neutral500,
            ),
          ),
          const SizedBox(height: 14),

          // 1. Trip & Route Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final stack = constraints.maxWidth < 280 && textScale > 1.3;

                    final titleSection = Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: DiscoveryColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            color: DiscoveryColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip?.operatorName ?? 'Nhà xe',
                                style: DiscoveryTextStyles.titleMedium.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${trip?.vehicleType ?? ""} • $dateStr',
                                style: DiscoveryTextStyles.caption.copyWith(
                                  color: DiscoveryColors.neutral500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final editBtn = _buildEditButton(
                      label: 'Sửa đón/trả',
                      onPressed: state.isCheckoutLocked
                          ? null
                          : () => bloc.add(const GoToStepEvent(1)),
                    );

                    if (stack) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [titleSection, editBtn],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: titleSection),
                        const SizedBox(width: 8),
                        editBtn,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: DiscoveryColors.divider),
                const SizedBox(height: 12),

                // Pickup & Dropoff timeline
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(
                          Icons.radio_button_checked,
                          size: 16,
                          color: DiscoveryColors.primary,
                        ),
                        Container(
                          width: 2,
                          height: 38,
                          color: DiscoveryColors.neutral300,
                        ),
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: DiscoveryColors.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pickup
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 48,
                                child: Text(
                                  state.selectedPickupPoint?.time ??
                                      trip?.departureTime ??
                                      '',
                                  style: DiscoveryTextStyles.bodyMedium
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.selectedPickupPoint?.name ??
                                          trip?.pickupPoint ??
                                          '',
                                      style: DiscoveryTextStyles.bodyMedium
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      state.selectedPickupPoint?.address ??
                                          trip?.pickupAddress ??
                                          '',
                                      style: DiscoveryTextStyles.caption
                                          .copyWith(
                                            color: DiscoveryColors.neutral500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Dropoff
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 48,
                                child: Text(
                                  state.selectedDropoffPoint?.time ??
                                      trip?.arrivalTime ??
                                      '',
                                  style: DiscoveryTextStyles.bodyMedium
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.selectedDropoffPoint?.name ??
                                          trip?.dropoffPoint ??
                                          '',
                                      style: DiscoveryTextStyles.bodyMedium
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      state.selectedDropoffPoint?.address ??
                                          trip?.dropoffAddress ??
                                          '',
                                      style: DiscoveryTextStyles.caption
                                          .copyWith(
                                            color: DiscoveryColors.neutral500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Seats Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final stack = constraints.maxWidth < 280 && textScale > 1.3;

                    final titleSection = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: DiscoveryColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.airline_seat_recline_extra_rounded,
                            color: DiscoveryColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Chỗ ngồi đã chọn',
                            overflow: TextOverflow.ellipsis,
                            style: DiscoveryTextStyles.titleMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DiscoveryColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${state.selectedSeats.length} chỗ',
                            style: DiscoveryTextStyles.caption.copyWith(
                              color: DiscoveryColors.primaryDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    );

                    final editBtn = _buildEditButton(
                      label: 'Đổi ghế',
                      onPressed: state.isCheckoutLocked
                          ? null
                          : () => bloc.add(const GoToStepEvent(0)),
                    );

                    if (stack) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [titleSection, editBtn],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: titleSection),
                        const SizedBox(width: 8),
                        editBtn,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: DiscoveryColors.divider),
                const SizedBox(height: 10),

                // Seat Chips list
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final seat in state.selectedSeats)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: DiscoveryColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: DiscoveryColors.primary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              seat.name,
                              style: DiscoveryTextStyles.bodySmall.copyWith(
                                color: DiscoveryColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (seat.price != null && seat.price! > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${seat.price! ~/ 1000}k)',
                                style: DiscoveryTextStyles.caption.copyWith(
                                  color: DiscoveryColors.neutral600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
                // Expose explicit comma-separated text string for accessibility and test matchers
                Semantics(
                  label: 'Ghế: $seatNames',
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Vị trí chỗ ngồi: $seatNames',
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.neutral500,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Passenger Info Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final stack = constraints.maxWidth < 280 && textScale > 1.3;

                    final titleSection = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: DiscoveryColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: DiscoveryColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Thông tin hành khách',
                            overflow: TextOverflow.ellipsis,
                            style: DiscoveryTextStyles.titleMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    );

                    final editBtn = _buildEditButton(
                      label: 'Sửa',
                      onPressed: state.isCheckoutLocked
                          ? null
                          : () => bloc.add(const GoToStepEvent(3)),
                    );

                    if (stack) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [titleSection, editBtn],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: titleSection),
                        const SizedBox(width: 8),
                        editBtn,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: DiscoveryColors.divider),
                const SizedBox(height: 10),

                _buildRowInfo(
                  icon: Icons.person_rounded,
                  label: 'Họ tên',
                  value: state.passengerName.isNotEmpty
                      ? state.passengerName
                      : 'Chưa nhập',
                  isBold: true,
                ),
                const SizedBox(height: 8),
                _buildRowInfo(
                  icon: Icons.phone_iphone_rounded,
                  label: 'Số điện thoại',
                  value: state.passengerPhone.isNotEmpty
                      ? state.passengerPhone
                      : 'Chưa nhập',
                ),
                const SizedBox(height: 8),
                _buildRowInfo(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: state.passengerEmail.isNotEmpty
                      ? state.passengerEmail
                      : 'Chưa cung cấp (tùy chọn)',
                  valueColor: state.passengerEmail.isNotEmpty
                      ? null
                      : DiscoveryColors.neutral500,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3b. Cargo Card
          BookingCargoSectionCard(
            cargo: state.cargo,
            locked: state.isCheckoutLocked,
            scopeKey: 'oneway',
            onToggleEnabled: (enabled) =>
                bloc.add(SetBookingCargoEnabledEvent(enabled)),
            onRefresh: () => bloc.add(const RefreshBookingCargoEvent()),
            onUpdateDraft: (draft) => bloc.add(UpdateBookingCargoEvent(draft)),
          ),
          const SizedBox(height: 12),

          // 4. Voucher / Promotion Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.secondaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.discount_outlined,
                        color: DiscoveryColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mã khuyến mãi & ưu đãi',
                        style: DiscoveryTextStyles.titleMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: DiscoveryColors.divider),
                const SizedBox(height: 10),

                if (!promotionAccepted && promotionCode.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      state.quoteLoading
                          ? 'Đang kiểm tra mã: $promotionCode'
                          : 'Mã chưa được xác nhận: $promotionCode',
                      style: DiscoveryTextStyles.bodySmall,
                    ),
                  ),
                if (promotionAccepted)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DiscoveryColors.successLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: DiscoveryColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: DiscoveryColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mã đã áp dụng: ${state.appliedVoucher?.code ?? state.requestedPromotionCode}',
                                style: DiscoveryTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: DiscoveryColors.successDark,
                                ),
                              ),
                              Text(
                                state.discountAmount > 0
                                    ? 'Tiết kiệm được ${CurrencyFormatter.format(state.discountAmount)}'
                                    : 'Mã hợp lệ',
                                style: DiscoveryTextStyles.caption.copyWith(
                                  color: DiscoveryColors.successDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed:
                              state.isCheckoutLocked || state.quoteLoading
                              ? null
                              : () => bloc.add(const RemoveVoucherEvent()),
                          child: Text(
                            'Bỏ mã',
                            style: DiscoveryTextStyles.bodySmall.copyWith(
                              color: DiscoveryColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: state.isCheckoutLocked || state.quoteLoading
                        ? null
                        : () {
                            if (state.requiresAuthoritativeQuote) {
                              _enterPromotion(context);
                              return;
                            }
                            VoucherSelectionSheet.show(
                              context,
                              vouchers: state.availableVouchers,
                              currentVoucher: state.appliedVoucher,
                              currentOrderAmount: state.seatsTotalAmount ?? 0,
                              onVoucherSelected: (v) =>
                                  bloc.add(ApplyVoucherEvent(v)),
                              onVoucherRemoved: () =>
                                  bloc.add(const RemoveVoucherEvent()),
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.neutral50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DiscoveryColors.neutral300),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_offer_outlined,
                            size: 18,
                            color: DiscoveryColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chọn hoặc nhập mã khuyến mãi',
                                  style: DiscoveryTextStyles.bodyMedium
                                      .copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: DiscoveryColors.neutral800,
                                      ),
                                ),
                                Text(
                                  'Nhập mã để hệ thống kiểm tra điều kiện',
                                  style: DiscoveryTextStyles.caption.copyWith(
                                    color: DiscoveryColors.neutral500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: DiscoveryColors.neutral400,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 5. Price Breakdown Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: DiscoveryColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chi tiết thanh toán',
                        style: DiscoveryTextStyles.titleMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPriceRow(
                  label: 'Giá vé (${state.selectedSeats.length} chỗ)',
                  value: state.quotedSubtotal != null
                      ? CurrencyFormatter.format(state.quotedSubtotal!)
                      : (state.seatsTotalAmount != null
                            ? CurrencyFormatter.format(state.seatsTotalAmount!)
                            : 'Chưa có giá vé'),
                ),
                const SizedBox(height: 8),
                _buildPriceRow(
                  label: 'Phí dịch vụ',
                  value: state.quotedServiceFee == null
                      ? (state.requiresAuthoritativeQuote
                            ? 'Đang xác minh'
                            : 'Miễn phí')
                      : (state.quotedServiceFee == 0
                            ? 'Miễn phí'
                            : CurrencyFormatter.format(
                                state.quotedServiceFee!,
                              )),
                  valueColor: DiscoveryColors.success,
                ),
                if (state.discountAmount > 0) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    label: 'Giảm giá ưu đãi',
                    value: '-${CurrencyFormatter.format(state.discountAmount)}',
                    valueColor: DiscoveryColors.secondary,
                  ),
                ],
                if (BookingCargoSummaryBox.hasCargo(state: state)) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    label: 'Tiền vé sau ưu đãi',
                    value: state.ticketFinalAmount != null
                        ? CurrencyFormatter.format(state.ticketFinalAmount!)
                        : 'Chưa có giá vé',
                  ),
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    label: 'Phí gửi hàng',
                    value: state.checkoutBooking?.shippingFee != null
                        ? CurrencyFormatter.format(
                            state.checkoutBooking!.shippingFee!,
                          )
                        : 'Phí gửi hàng được xác định khi tạo đơn',
                    valueColor: state.checkoutBooking?.shippingFee != null
                        ? DiscoveryColors.neutral900
                        : DiscoveryColors.secondary,
                  ),
                ],
                const SizedBox(height: 10),
                const Divider(height: 1, color: DiscoveryColors.divider),
                const SizedBox(height: 10),
                _buildPriceRow(
                  label: 'Tổng tiền cần thanh toán',
                  value: state.finalAmount != null
                      ? CurrencyFormatter.format(state.finalAmount!)
                      : (state.cargo.enabled
                            ? 'Xác định khi tạo đơn'
                            : 'Chưa có giá vé'),
                  valueColor: DiscoveryColors.secondary,
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 6. Guarantee Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DiscoveryColors.successLight.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DiscoveryColors.success.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: DiscoveryColors.success,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Giá vé và ưu đãi được hệ thống xác nhận theo ghế, chuyến đi và thông tin liên hệ. Vé chỉ có hiệu lực sau khi xác minh thanh toán.',
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enterPromotion(BuildContext context) async {
    var code = state.requestedPromotionCode;
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mã khuyến mãi'),
        content: TextFormField(
          initialValue: code,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Nhập mã khuyến mãi'),
          onChanged: (value) => code = value,
          onFieldSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          if (state.requestedPromotionCode.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(''),
              child: const Text('Bỏ mã'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(code),
            child: const Text('Kiểm tra mã'),
          ),
        ],
      ),
    );
    if (selected == null || bloc.isClosed) return;
    bloc.add(
      selected.trim().isEmpty
          ? const RemoveVoucherEvent()
          : ApplyPromotionCodeEvent(selected),
    );
  }

  Widget _buildEditButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: DiscoveryColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(48, 48),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: DiscoveryTextStyles.bodySmall.copyWith(
          color: DiscoveryColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DiscoveryColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildRowInfo({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    double labelWidth = 90,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Icon(icon, size: 16, color: DiscoveryColors.neutral500),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: DiscoveryTextStyles.bodySmall.copyWith(
              color: DiscoveryColors.neutral600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: DiscoveryTextStyles.bodySmall.copyWith(
              color: valueColor ?? DiscoveryColors.neutral900,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isTotal = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stack = constraints.maxWidth < 280 && textScale > 1.3;

        final labelWidget = Text(
          label,
          style: isTotal
              ? DiscoveryTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                )
              : DiscoveryTextStyles.bodySmall.copyWith(
                  color: DiscoveryColors.neutral600,
                ),
        );

        final valueWidget = Text(
          value,
          textAlign: stack ? TextAlign.start : TextAlign.end,
          style: isTotal
              ? DiscoveryTextStyles.titleMedium.copyWith(
                  color: valueColor ?? DiscoveryColors.secondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                )
              : DiscoveryTextStyles.bodySmall.copyWith(
                  color: valueColor ?? DiscoveryColors.neutral900,
                  fontWeight: FontWeight.w600,
                ),
        );

        if (stack) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelWidget, const SizedBox(height: 2), valueWidget],
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: labelWidget),
            const SizedBox(width: 8),
            Flexible(child: valueWidget),
          ],
        );
      },
    );
  }
}
