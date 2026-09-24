import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';

class CancelTicketSheet extends StatefulWidget {
  final TicketModel ticket;
  final MyTicketsBloc bloc;

  const CancelTicketSheet({
    super.key,
    required this.ticket,
    required this.bloc,
  });

  static Future<void> show(BuildContext context, TicketModel ticket, MyTicketsBloc bloc) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CancelTicketSheet(ticket: ticket, bloc: bloc),
    );
  }

  @override
  State<CancelTicketSheet> createState() => _CancelTicketSheetState();
}

class _CancelTicketSheetState extends State<CancelTicketSheet> {
  String _selectedReason = 'Thay đổi kế hoạch cá nhân';
  bool _agreedToPolicy = false;

  final List<String> _reasons = [
    'Thay đổi kế hoạch cá nhân',
    'Đặt nhầm ngày/giờ khởi hành',
    'Tìm được phương tiện di chuyển khác',
    'Lý do sức khỏe / việc bận đột xuất',
    'Khác',
  ];

  @override
  Widget build(BuildContext context) {
    final canCancel = widget.ticket.canCancel;
    final refundAmount = (widget.ticket.finalAmount * 0.9).round();
    final cancellationFee = widget.ticket.finalAmount - refundAmount;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.base,
        AppDimensions.base,
        AppDimensions.base,
        MediaQuery.of(context).viewInsets.bottom + AppDimensions.base,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.base),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: canCancel ? AppColors.errorLight : AppColors.warningLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      canCancel ? Icons.cancel_outlined : Icons.warning_amber_rounded,
                      color: canCancel ? AppColors.error : AppColors.warningDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          canCancel ? 'Hủy vé xe' : 'Không thể hủy vé',
                          style: AppTextStyles.h4.copyWith(fontSize: 16),
                        ),
                        Text(
                          'Mã vé: ${widget.ticket.ticketCode}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.base),

              // CASE 1: Cannot Cancel (< 3 hours rule from sub_uc_huy_ve)
              if (!canCancel) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.base),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Quy định hủy vé (sub_uc_huy_ve)',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Theo chính sách của nhà xe ${widget.ticket.trip.operatorName}, vé chỉ có thể hủy trực tuyến trước giờ khởi hành ít nhất 3 giờ.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutral700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Chuyến xe của bạn khởi hành lúc ${widget.ticket.trip.departureTime} ngày ${widget.ticket.trip.departureDate} (trong vòng dưới 3 giờ). Vui lòng liên hệ trực tiếp hotline để được hỗ trợ đặc biệt.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.lg),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Đã hiểu'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đang liên hệ tổng đài: ${widget.ticket.driverPhone ?? "1900 6067"}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text('Gọi Hotline'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // CASE 2: Can Cancel (>= 3 hours)
              if (canCancel) ...[
                // Refund Breakdown Card
                Container(
                  padding: const EdgeInsets.all(AppDimensions.base),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tiền vé đã thanh toán:', style: AppTextStyles.bodySmall),
                          Text(
                            CurrencyFormatter.format(widget.ticket.finalAmount),
                            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Phí hủy theo quy định (10%):', style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                          Text(
                            '- ${CurrencyFormatter.format(cancellationFee)}',
                            style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Số tiền hoàn lại:',
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            CurrencyFormatter.format(refundAmount),
                            style: AppTextStyles.h4.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 13, color: AppColors.neutral500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Tiền sẽ hoàn về ${widget.ticket.paymentMethod} trong 24 - 48h làm việc.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.neutral500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.base),

                // Cancellation Reason
                Text(
                  'Chọn lý do hủy vé',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                RadioGroup<String>(
                  groupValue: _selectedReason,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedReason = val);
                  },
                  child: Column(
                    children: _reasons.map((r) {
                      return RadioListTile<String>(
                        value: r,
                        title: Text(r, style: AppTextStyles.bodySmall),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        activeColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppDimensions.sm),

                // Agreement checkbox
                CheckboxListTile(
                  value: _agreedToPolicy,
                  onChanged: (val) => setState(() => _agreedToPolicy = val ?? false),
                  title: Text(
                    'Tôi đã đọc và đồng ý với chính sách hủy vé và khấu trừ phí của nhà xe.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.neutral700),
                  ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                ),

                const SizedBox(height: AppDimensions.base),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _agreedToPolicy
                        ? () {
                            widget.bloc.add(CancelTicketEvent(
                              ticketId: widget.ticket.id,
                              reason: _selectedReason,
                              refundAmount: refundAmount,
                            ));
                            Navigator.of(context).pop();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.neutral300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Xác nhận hủy vé & Hoàn tiền',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
