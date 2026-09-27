import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/data/models/voucher_model.dart';

class VoucherSelectionSheet extends StatefulWidget {
  final List<VoucherModel> vouchers;
  final VoucherModel? currentVoucher;
  final int currentOrderAmount;
  final Function(VoucherModel) onVoucherSelected;
  final VoidCallback onVoucherRemoved;

  const VoucherSelectionSheet({
    super.key,
    required this.vouchers,
    required this.currentVoucher,
    required this.currentOrderAmount,
    required this.onVoucherSelected,
    required this.onVoucherRemoved,
  });

  static Future<void> show(
    BuildContext context, {
    required List<VoucherModel> vouchers,
    required VoucherModel? currentVoucher,
    required int currentOrderAmount,
    required Function(VoucherModel) onVoucherSelected,
    required VoidCallback onVoucherRemoved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoucherSelectionSheet(
        vouchers: vouchers,
        currentVoucher: currentVoucher,
        currentOrderAmount: currentOrderAmount,
        onVoucherSelected: onVoucherSelected,
        onVoucherRemoved: onVoucherRemoved,
      ),
    );
  }

  @override
  State<VoucherSelectionSheet> createState() => _VoucherSelectionSheetState();
}

class _VoucherSelectionSheetState extends State<VoucherSelectionSheet> {
  final TextEditingController _codeController = TextEditingController();
  String? _inputError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _applyManualCode() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final match = widget.vouchers.where((v) => v.code.toUpperCase() == code).firstOrNull;
    if (match != null) {
      if (widget.currentOrderAmount < match.minOrderAmount) {
        setState(() {
          _inputError = 'Đơn hàng chưa đạt mức tối thiểu ${CurrencyFormatter.format(match.minOrderAmount)}';
        });
        return;
      }
      widget.onVoucherSelected(match);
      Navigator.pop(context);
    } else {
      setState(() {
        _inputError = 'Mã giảm giá không hợp lệ hoặc đã hết hạn!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chọn mã giảm giá VexGo',
                  style: AppTextStyles.h3.copyWith(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Code input row
          Padding(
            padding: const EdgeInsets.all(AppDimensions.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Nhập mã khuyến mãi...',
                          prefixIcon: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary),
                          filled: true,
                          fillColor: AppColors.neutral50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.neutral300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    CustomButton(
                      text: 'Áp dụng',
                      height: 48,
                      onPressed: _applyManualCode,
                    ),
                  ],
                ),
                if (_inputError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _inputError!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.error),
                  ),
                ],
              ],
            ),
          ),

          // Active Voucher removal banner
          if (widget.currentVoucher != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đang áp dụng: ${widget.currentVoucher!.code}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onVoucherRemoved();
                      Navigator.pop(context);
                    },
                    child: const Text('Gỡ bỏ', style: TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
          ],

          // Voucher list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
              itemCount: widget.vouchers.length,
              itemBuilder: (context, index) {
                final voucher = widget.vouchers[index];
                final isSelected = widget.currentVoucher?.code == voucher.code;
                final isEligible = widget.currentOrderAmount >= voucher.minOrderAmount;

                return Opacity(
                  opacity: isEligible ? 1.0 : 0.6,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppDimensions.sm),
                    padding: const EdgeInsets.all(AppDimensions.base),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.3) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.neutral300,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.discount_rounded,
                            color: AppColors.secondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                voucher.code,
                                style: AppTextStyles.h4.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                voucher.title,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                voucher.description,
                                style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'HSD: ${voucher.expiryDate}',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.neutral400, fontSize: 11),
                                  ),
                                  const Spacer(),
                                  if (!isEligible)
                                    Text(
                                      'Cần thêm ${CurrencyFormatter.format(voucher.minOrderAmount - widget.currentOrderAmount)}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  else
                                    CustomButton(
                                      text: isSelected ? 'Đã chọn' : 'Dùng ngay',
                                      height: 32,
                                      type: isSelected ? ButtonType.outline : ButtonType.primary,
                                      onPressed: () {
                                        widget.onVoucherSelected(voucher);
                                        Navigator.pop(context);
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
