import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import '../widgets/voucher_selection_sheet.dart';

class Step5TripSummary extends StatelessWidget {
  final BookingFlowState state;
  final BookingFlowBloc bloc;

  const Step5TripSummary({
    super.key,
    required this.state,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    final trip = state.trip;
    final dateStr = state.date != null ? DateFormatter.formatFullDate(state.date!) : '';
    final seatNames = state.selectedSeats.map((s) => s.name).join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text('Xem lại thông tin chuyến đi', style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Vui lòng kiểm tra kỹ thông tin hành trình và hành khách trước khi sang bước thanh toán.',
            style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
          ),
          const SizedBox(height: AppDimensions.base),

          // Trip & Route Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.directions_bus_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip?.operatorName ?? '',
                            style: AppTextStyles.h4.copyWith(fontSize: 15),
                          ),
                          Text(
                            '${trip?.vehicleType ?? ""} • $dateStr',
                            style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.md),
                const Divider(height: 1),
                const SizedBox(height: AppDimensions.md),

                // Pickup timeline
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.radio_button_checked, size: 16, color: AppColors.primary),
                        Container(width: 2, height: 36, color: AppColors.neutral300),
                        const Icon(Icons.location_on, size: 16, color: AppColors.secondary),
                      ],
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pickup
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 50,
                                child: Text(
                                  state.selectedPickupPoint?.time ?? trip?.departureTime ?? '',
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.xs),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.selectedPickupPoint?.name ?? trip?.pickupPoint ?? '',
                                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      state.selectedPickupPoint?.address ?? trip?.pickupAddress ?? '',
                                      style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                width: 50,
                                child: Text(
                                  state.selectedDropoffPoint?.time ?? trip?.arrivalTime ?? '',
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.xs),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.selectedDropoffPoint?.name ?? trip?.dropoffPoint ?? '',
                                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      state.selectedDropoffPoint?.address ?? trip?.dropoffAddress ?? '',
                                      style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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

          const SizedBox(height: AppDimensions.base),

          // Seats & Passenger Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRowInfo(
                  icon: Icons.airline_seat_recline_extra_rounded,
                  label: 'Vị trí chỗ ngồi:',
                  value: '$seatNames (${state.selectedSeats.length} chỗ)',
                  valueColor: AppColors.primary,
                  isBold: true,
                ),
                const SizedBox(height: AppDimensions.sm),
                const Divider(height: 1),
                const SizedBox(height: AppDimensions.sm),
                _buildRowInfo(
                  icon: Icons.person_outline_rounded,
                  label: 'Họ tên hành khách:',
                  value: state.passengerName,
                ),
                const SizedBox(height: 6),
                _buildRowInfo(
                  icon: Icons.phone_iphone_rounded,
                  label: 'Số điện thoại:',
                  value: state.passengerPhone,
                ),
                const SizedBox(height: 6),
                _buildRowInfo(
                  icon: Icons.email_outlined,
                  label: 'Email nhận vé:',
                  value: state.passengerEmail,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.base),

          // Voucher selector card
          _buildCard(
            child: InkWell(
              onTap: () {
                VoucherSelectionSheet.show(
                  context,
                  vouchers: state.availableVouchers,
                  currentVoucher: state.appliedVoucher,
                  currentOrderAmount: state.seatsTotalAmount,
                  onVoucherSelected: (v) => bloc.add(ApplyVoucherEvent(v)),
                  onVoucherRemoved: () => bloc.add(const RemoveVoucherEvent()),
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.discount_outlined, color: AppColors.secondary, size: 22),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.appliedVoucher != null
                              ? 'Mã đã áp dụng: ${state.appliedVoucher!.code}'
                              : 'Chọn hoặc nhập mã khuyến mãi',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: state.appliedVoucher != null ? AppColors.secondary : AppColors.neutral800,
                          ),
                        ),
                        Text(
                          state.appliedVoucher != null
                              ? 'Tiết kiệm được ${CurrencyFormatter.format(state.discountAmount)}'
                              : 'Ưu đãi đến 50.000đ cho chuyến đi',
                          style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.neutral400),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.base),

          // Price Breakdown Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chi tiết thanh toán', style: AppTextStyles.h4.copyWith(fontSize: 15)),
                const SizedBox(height: AppDimensions.md),
                _buildPriceRow(
                  label: 'Giá vé (${state.selectedSeats.length} chỗ)',
                  value: CurrencyFormatter.format(state.seatsTotalAmount),
                ),
                const SizedBox(height: 6),
                _buildPriceRow(
                  label: 'Phí dịch vụ',
                  value: '0 đ (Miễn phí)',
                  valueColor: AppColors.success,
                ),
                if (state.discountAmount > 0) ...[
                  const SizedBox(height: 6),
                  _buildPriceRow(
                    label: 'Giảm giá ưu đãi',
                    value: '-${CurrencyFormatter.format(state.discountAmount)}',
                    valueColor: AppColors.secondary,
                  ),
                ],
                const SizedBox(height: AppDimensions.sm),
                const Divider(height: 1),
                const SizedBox(height: AppDimensions.sm),
                _buildPriceRow(
                  label: 'Tổng tiền cần thanh toán',
                  value: CurrencyFormatter.format(state.finalAmount),
                  valueColor: AppColors.secondary,
                  isTotal: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.base),

          // Guarantee badge
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.successLight.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 22),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    'Cam kết 100% giữ đúng chỗ đã chọn hoặc hoàn tiền 150% nếu nhà xe không cung cấp dịch vụ.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutral700,
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

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.neutral200),
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
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.neutral500),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral600),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: valueColor ?? AppColors.neutral900,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)
              : AppTextStyles.bodySmall.copyWith(color: AppColors.neutral600),
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.h4.copyWith(
                  color: valueColor ?? AppColors.secondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                )
              : AppTextStyles.bodySmall.copyWith(
                  color: valueColor ?? AppColors.neutral900,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}
