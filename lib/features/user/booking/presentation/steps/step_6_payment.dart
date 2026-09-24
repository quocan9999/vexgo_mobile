import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';

class Step6Payment extends StatelessWidget {
  final BookingFlowState state;
  final BookingFlowBloc bloc;

  const Step6Payment({
    super.key,
    required this.state,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Countdown Timer Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warningLight.withValues(alpha: 0.8),
                  Colors.white,
                ],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thời gian giữ chỗ còn lại:',
                        style: AppTextStyles.caption.copyWith(color: AppColors.neutral700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.countdownFormatted,
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.warningDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '10:00 phút',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.neutral500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.base),

          // Total Amount Header
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số tiền thanh toán',
                      style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(state.finalAmount),
                      style: AppTextStyles.price.copyWith(
                        color: AppColors.secondary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.selectedSeats.length} Vé',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.base),

          // Payment Methods Section
          Text('Chọn phương thức thanh toán', style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.sm),

          _buildPaymentMethodTile(
            methodId: 'momo',
            title: 'Ví MoMo',
            subtitle: 'Thanh toán tức thì qua ứng dụng MoMo (Khuyên dùng)',
            iconData: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFFA50064), // MoMo magenta
            badgeText: 'Khuyên dùng',
          ),

          _buildPaymentMethodTile(
            methodId: 'zalopay',
            title: 'Ví ZaloPay',
            subtitle: 'Thanh toán an toàn với ví ZaloPay hoặc Zalo',
            iconData: Icons.wallet_rounded,
            iconColor: const Color(0xFF0068FF),
          ),

          _buildPaymentMethodTile(
            methodId: 'vietqr',
            title: 'Chuyển khoản VietQR',
            subtitle: 'Quét mã QR tự động xác nhận 24/7 (Mọi ngân hàng)',
            iconData: Icons.qr_code_2_rounded,
            iconColor: AppColors.success,
            badgeText: 'Miễn phí',
          ),

          _buildPaymentMethodTile(
            methodId: 'napas',
            title: 'Thẻ ATM nội địa',
            subtitle: 'Internet Banking hơn 40 ngân hàng Việt Nam',
            iconData: Icons.credit_card_rounded,
            iconColor: AppColors.primary,
          ),

          _buildPaymentMethodTile(
            methodId: 'visa',
            title: 'Thẻ quốc tế',
            subtitle: 'Thanh toán thẻ Visa, MasterCard, JCB',
            iconData: Icons.payment_rounded,
            iconColor: const Color(0xFF1A1F71), // Visa navy
          ),

          const SizedBox(height: AppDimensions.md),

          // Security Badge
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded, size: 14, color: AppColors.neutral500),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Bảo mật thông tin thanh toán chuẩn quốc tế PCI DSS',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutral500,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String methodId,
    required String title,
    required String subtitle,
    required IconData iconData,
    required Color iconColor,
    String? badgeText,
  }) {
    final isSelected = state.selectedPaymentMethod == methodId;

    return GestureDetector(
      onTap: () => bloc.add(SelectPaymentMethodEvent(methodId)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: AppDimensions.sm),
        padding: const EdgeInsets.all(AppDimensions.base),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.3) : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.neutral200,
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
            // Radio
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.neutral400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
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

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppTextStyles.bodyMedium.copyWith(
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.secondary,
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
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutral500,
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
