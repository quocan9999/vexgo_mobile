import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';

class BookingSuccessScreen extends StatefulWidget {
  final TicketModel ticket;

  const BookingSuccessScreen({
    super.key,
    required this.ticket,
  });

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<MyTicketsBloc>().add(AddNewTicketEvent(widget.ticket));
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final trip = ticket.trip;
    final seatsStr = ticket.seats.join(', ');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => context.go('/'),
          ),
          title: Text(
            'Vé điện tử VexGo',
            style: AppTextStyles.h4.copyWith(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.base),
          child: Column(
            children: [
              // Success Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Green Checkmark
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.successLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text(
                      'Đặt vé thành công!',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.successDark,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cảm ơn bạn đã lựa chọn VexGo!',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600),
                    ),

                    const SizedBox(height: AppDimensions.base),

                    // Ticket Code Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mã vé: ',
                            style: AppTextStyles.caption.copyWith(color: AppColors.neutral600),
                          ),
                          Text(
                            ticket.ticketCode,
                            style: AppTextStyles.h4.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: ticket.ticketCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã sao chép mã vé vào bộ nhớ tạm!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.lg),

                    // QR Code
                    QrImageView(
                      data: 'VEXGO:${ticket.ticketCode}:${ticket.id}',
                      version: QrVersions.auto,
                      size: 160.0,
                      backgroundColor: Colors.white,
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Đưa mã này cho phụ xe khi lên xe',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.neutral500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.base),

              // Trip Details Ticket Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.base),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_bus_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trip.operatorName,
                            style: AppTextStyles.h4.copyWith(fontSize: 16),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Đã thanh toán',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.sm),
                    Text(
                      '${trip.fromCity} -> ${trip.toCity} • ${trip.vehicleType}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                    ),

                    const SizedBox(height: AppDimensions.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppDimensions.md),

                    _buildInfoRow('Ngày đi:', trip.departureDate),
                    const SizedBox(height: 8),
                    _buildInfoRow('Giờ đón:', trip.departureTime),
                    const SizedBox(height: 8),
                    _buildInfoRow('Điểm đón:', '${trip.pickupPoint} (${trip.pickupAddress})'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Điểm trả:', '${trip.dropoffPoint} (${trip.dropoffAddress})'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Chỗ ngồi:', seatsStr, valueColor: AppColors.primary, isBold: true),
                    const SizedBox(height: 8),
                    _buildInfoRow('Hành khách:', '${ticket.passenger.fullName} - ${ticket.passenger.phone}'),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Tổng thanh toán:',
                      CurrencyFormatter.format(ticket.finalAmount),
                      valueColor: AppColors.secondary,
                      isBold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.base),

              // Email notice
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Text(
                        'Chi tiết vé điện tử đã được gửi tới email ${ticket.passenger.email}.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.neutral700),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.lg),

              // Action Buttons
              CustomButton(
                text: 'Xem vé của tôi',
                prefixIcon: const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 20),
                onPressed: () => context.go('/my-tickets'),
              ),
              const SizedBox(height: AppDimensions.sm),
              CustomButton(
                text: 'Về trang chủ',
                type: ButtonType.outline,
                prefixIcon: const Icon(Icons.home_rounded, color: AppColors.primary, size: 20),
                onPressed: () => context.go('/'),
              ),

              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500),
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
}
