import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';

class BookingBottomBar extends StatelessWidget {
  final BookingFlowState state;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onConfirmPayment;

  const BookingBottomBar({
    super.key,
    required this.state,
    required this.onNext,
    required this.onBack,
    required this.onConfirmPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.base,
        AppDimensions.sm,
        AppDimensions.base,
        AppDimensions.base,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _buildContentByStep(context),
      ),
    );
  }

  Widget _buildContentByStep(BuildContext context) {
    switch (state.step) {
      case BookingStep.seatSelection:
        return _buildSeatSelectionBottom();

      case BookingStep.pickupPoint:
        return _buildPickupBottom();

      case BookingStep.dropoffPoint:
        return _buildDropoffBottom();

      case BookingStep.passengerInfo:
        return _buildPassengerBottom();

      case BookingStep.tripSummary:
        return _buildSummaryBottom();

      case BookingStep.payment:
        return _buildPaymentBottom();
    }
  }

  Widget _buildSeatSelectionBottom() {
    final hasSeats = state.selectedSeats.isNotEmpty;
    final seatNames = state.selectedSeats.map((s) => s.name).join(', ');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasSeats ? 'Ghế: $seatNames (${state.selectedSeats.length} chỗ)' : 'Vui lòng chọn chỗ',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: hasSeats ? AppColors.primary : AppColors.neutral500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                hasSeats ? CurrencyFormatter.format(state.seatsTotalAmount) : '0 đ',
                style: AppTextStyles.price.copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.base),
        SizedBox(
          width: 140,
          child: CustomButton(
            text: 'Tiếp tục',
            onPressed: hasSeats ? onNext : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPickupBottom() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: CustomButton(
            text: 'Quay lại',
            type: ButtonType.outline,
            onPressed: onBack,
          ),
        ),
        const SizedBox(width: AppDimensions.base),
        Expanded(
          flex: 2,
          child: CustomButton(
            text: 'Chọn điểm trả',
            onPressed: state.isPickupValid ? onNext : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropoffBottom() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: CustomButton(
            text: 'Quay lại',
            type: ButtonType.outline,
            onPressed: onBack,
          ),
        ),
        const SizedBox(width: AppDimensions.base),
        Expanded(
          flex: 2,
          child: CustomButton(
            text: 'Nhập thông tin',
            onPressed: state.isDropoffValid ? onNext : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerBottom() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: CustomButton(
            text: 'Quay lại',
            type: ButtonType.outline,
            onPressed: onBack,
          ),
        ),
        const SizedBox(width: AppDimensions.base),
        Expanded(
          flex: 2,
          child: CustomButton(
            text: 'Xem chuyến đi',
            onPressed: state.isPassengerValid ? onNext : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBottom() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tổng thanh toán:',
                style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.format(state.finalAmount),
                style: AppTextStyles.price.copyWith(
                  fontSize: 19,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.base),
        SizedBox(
          width: 170,
          child: CustomButton(
            text: 'Thanh toán',
            onPressed: onNext,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentBottom() {
    final isSubmitting = state.status == BookingFlowStatus.submitting;

    return Row(
      children: [
        SizedBox(
          width: 88,
          child: CustomButton(
            text: 'Quay lại',
            type: ButtonType.outline,
            onPressed: isSubmitting ? null : onBack,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: CustomButton(
            text: 'Thanh toán ${CurrencyFormatter.format(state.finalAmount)}',
            isLoading: isSubmitting,
            prefixIcon: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
            onPressed: isSubmitting ? null : onConfirmPayment,
          ),
        ),
      ],
    );
  }
}
