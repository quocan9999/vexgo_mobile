import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';

class TicketSummaryCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onReview;
  final VoidCallback? onRebook;

  const TicketSummaryCard({
    super.key,
    required this.ticket,
    required this.onTap,
    this.onCancel,
    this.onReview,
    this.onRebook,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.base),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: _getBorderColor(),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Operator Name & Status Badge
            Padding(
              padding: const EdgeInsets.all(AppDimensions.base),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.trip.operatorName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mã vé: ${ticket.ticketCode}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.neutral500,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.xs),
                  _buildStatusBadge(),
                ],
              ),
            ),

            const Divider(height: 1),

            // Route & Time Info
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.base,
                vertical: AppDimensions.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // From - To Cities
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ticket.trip.fromCity} → ${ticket.trip.toCity}',
                          style: AppTextStyles.h4.copyWith(
                            fontSize: 15,
                            color: AppColors.neutral900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: AppColors.neutral500,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${ticket.trip.departureTime} · ${ticket.trip.departureDate}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.neutral600,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppDimensions.sm),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Tổng tiền',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.neutral500,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(ticket.finalAmount),
                        style: AppTextStyles.price.copyWith(
                          fontSize: 16,
                          color: ticket.status == TicketStatus.cancelled
                              ? AppColors.neutral500
                              : AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Seats and Pickup point
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: AppColors.neutral100.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.airline_seat_recline_extra_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Ghế: ',
                    style: AppTextStyles.caption.copyWith(color: AppColors.neutral600),
                  ),
                  Text(
                    ticket.seats.join(', '),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      ticket.trip.vehicleType,
                      style: AppTextStyles.caption.copyWith(color: AppColors.neutral600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Cancelled Details if applicable
            if (ticket.status == TicketStatus.cancelled) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.base,
                  AppDimensions.sm,
                  AppDimensions.base,
                  0,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Lý do: ${ticket.cancelReason ?? "Đã hủy theo yêu cầu"}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (ticket.refundAmount != null)
                      Text(
                        'Hoàn: ${CurrencyFormatter.format(ticket.refundAmount!)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // Action Buttons Row
            Padding(
              padding: const EdgeInsets.all(AppDimensions.base),
              child: Row(
                children: [
                  // Left Action button if applicable
                  if (ticket.status == TicketStatus.upcoming) ...[
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.errorLight),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Hủy vé',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                  ],

                  if (ticket.status == TicketStatus.completed && ticket.review == null) ...[
                    SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: onReview,
                        icon: const Icon(Icons.star_rate_rounded, size: 16, color: AppColors.secondary),
                        label: Text(
                          'Đánh giá',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.secondaryLight),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                  ],

                  if (ticket.status == TicketStatus.completed && ticket.review != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            '${ticket.review!.rating}.0 (Đã đánh giá)',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                  ],

                  // Primary Button (View Details / Rebook)
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ticket.status == TicketStatus.cancelled
                              ? AppColors.neutral200
                              : AppColors.primary,
                          foregroundColor: ticket.status == TicketStatus.cancelled
                              ? AppColors.neutral700
                              : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              ticket.status == TicketStatus.cancelled
                                  ? Icons.receipt_long_rounded
                                  : Icons.qr_code_2_rounded,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                ticket.status == TicketStatus.cancelled ? 'Xem chi tiết' : 'Xem vé & QR',
                                style: AppTextStyles.caption.copyWith(
                                  color: ticket.status == TicketStatus.cancelled
                                      ? AppColors.neutral700
                                      : Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildStatusBadge() {
    Color bg;
    Color text;
    String label;

    switch (ticket.status) {
      case TicketStatus.upcoming:
        bg = AppColors.primaryLight;
        text = AppColors.primary;
        label = 'Sắp đi';
        break;
      case TicketStatus.completed:
        bg = AppColors.successLight;
        text = AppColors.success;
        label = 'Đã đi';
        break;
      case TicketStatus.cancelled:
        bg = AppColors.errorLight;
        text = AppColors.error;
        label = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Color _getBorderColor() {
    switch (ticket.status) {
      case TicketStatus.upcoming:
        return AppColors.primary.withValues(alpha: 0.35);
      case TicketStatus.completed:
        return AppColors.neutral200;
      case TicketStatus.cancelled:
        return AppColors.neutral300;
    }
  }
}
