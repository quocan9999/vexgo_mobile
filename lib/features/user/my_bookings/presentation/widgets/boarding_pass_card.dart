import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'ticket_qr_modal.dart';

class BoardingPassCard extends StatelessWidget {
  final TicketModel ticket;

  const BoardingPassCard({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Upper Section: Header, Route, QR Code
          Padding(
            padding: const EdgeInsets.all(AppDimensions.base),
            child: Column(
              children: [
                // Operator Name & Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.trip.operatorName,
                            style: AppTextStyles.h4.copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.trip.vehicleType,
                            style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.xs),
                    _buildStatusBadge(),
                  ],
                ),

                const SizedBox(height: AppDimensions.base),

                // Cities Flow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Điểm đi',
                            style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.trip.fromCity,
                            style: AppTextStyles.h3.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            ticket.trip.departureTime,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Điểm đến',
                            style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.trip.toCity,
                            style: AppTextStyles.h3.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            ticket.trip.arrivalTime,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.base),

                // QR Code Tap Box
                GestureDetector(
                  onTap: () => TicketQrModal.show(context, ticket),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.neutral100.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        QrImageView(
                          data: 'VEXGO:${ticket.ticketCode}:${ticket.id}',
                          version: QrVersions.auto,
                          size: 72.0,
                          backgroundColor: Colors.transparent,
                        ),
                        const SizedBox(width: AppDimensions.base),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mã vé: ${ticket.ticketCode}',
                                style: AppTextStyles.h4.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 15,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.fullscreen_rounded, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Chạm để phóng to mã QR',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Perforated Tear Line with Cutouts
          _buildTearLine(),

          // Lower Section: Journey Details, Seats, Payment
          Padding(
            padding: const EdgeInsets.all(AppDimensions.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seats and Date Key Info
                Row(
                  children: [
                    Expanded(
                      child: _buildPassDetailBlock(
                        title: 'Chỗ ngồi',
                        value: ticket.seats.join(', '),
                        valueColor: AppColors.primary,
                        isHighlight: true,
                      ),
                    ),
                    Expanded(
                      child: _buildPassDetailBlock(
                        title: 'Ngày khởi hành',
                        value: ticket.trip.departureDate,
                      ),
                    ),
                    if (ticket.licensePlate != null)
                      Expanded(
                        child: _buildPassDetailBlock(
                          title: 'Biển số xe',
                          value: ticket.licensePlate!,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: AppDimensions.base),
                const Divider(height: 1),
                const SizedBox(height: AppDimensions.base),

                // Pickup Point
                _buildTimelinePoint(
                  time: ticket.trip.departureTime,
                  title: ticket.trip.pickupPoint,
                  address: ticket.trip.pickupAddress,
                  isStart: true,
                ),

                const SizedBox(height: AppDimensions.md),

                // Dropoff Point
                _buildTimelinePoint(
                  time: ticket.trip.arrivalTime,
                  title: ticket.trip.dropoffPoint,
                  address: ticket.trip.dropoffAddress,
                  isStart: false,
                ),

                const SizedBox(height: AppDimensions.base),
                const Divider(height: 1),
                const SizedBox(height: AppDimensions.base),

                // Passenger and Contact
                _buildInfoLine(
                  label: 'Hành khách:',
                  value: '${ticket.passenger.fullName} · ${ticket.passenger.phone}',
                ),
                const SizedBox(height: 8),
                _buildInfoLine(
                  label: 'Email nhận vé:',
                  value: ticket.passenger.email,
                ),
                const SizedBox(height: 8),
                _buildInfoLine(
                  label: 'Thanh toán qua:',
                  value: ticket.paymentMethod,
                ),
                const SizedBox(height: 8),
                _buildInfoLine(
                  label: 'Tổng tiền vé:',
                  value: CurrencyFormatter.format(ticket.finalAmount),
                  valueColor: ticket.status == TicketStatus.cancelled
                      ? AppColors.neutral500
                      : AppColors.secondary,
                  isBold: true,
                ),

                if (ticket.status == TicketStatus.cancelled) ...[
                  const SizedBox(height: 8),
                  _buildInfoLine(
                    label: 'Số tiền hoàn lại:',
                    value: ticket.refundAmount != null
                        ? CurrencyFormatter.format(ticket.refundAmount!)
                        : 'Đang xử lý',
                    valueColor: AppColors.success,
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoLine(
                    label: 'Lý do hủy:',
                    value: ticket.cancelReason ?? 'Hủy theo yêu cầu',
                    valueColor: AppColors.error,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTearLine() {
    return SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dashed line
          LayoutBuilder(
            builder: (context, constraints) {
              const dashWidth = 6.0;
              const dashSpace = 4.0;
              final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(dashCount, (_) {
                  return Container(
                    width: dashWidth,
                    height: 1.5,
                    color: AppColors.neutral300,
                    margin: const EdgeInsets.symmetric(horizontal: dashSpace / 2),
                  );
                }),
              );
            },
          ),
          // Left cutout
          Positioned(
            left: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6F8), // Match background page
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Right cutout
          Positioned(
            right: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6F8),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelinePoint({
    required String time,
    required String title,
    required String address,
    required bool isStart,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isStart ? Icons.radio_button_checked : Icons.location_on,
          size: 16,
          color: isStart ? AppColors.primary : AppColors.secondary,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            time,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: AppDimensions.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPassDetailBlock({
    required String title,
    required String value,
    Color? valueColor,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.neutral500,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.neutral900,
            fontSize: isHighlight ? 15 : 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInfoLine({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.neutral600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: valueColor ?? AppColors.neutral900,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
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
}
