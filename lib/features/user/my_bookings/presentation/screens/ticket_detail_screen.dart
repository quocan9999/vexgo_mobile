import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/widgets/custom_app_bar.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_state.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/boarding_pass_card.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/cancel_ticket_sheet.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/review_bottom_sheet.dart';

class TicketDetailScreen extends StatelessWidget {
  final TicketModel initialTicket;

  const TicketDetailScreen({super.key, required this.initialTicket});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyTicketsBloc, MyTicketsState>(
      builder: (context, state) {
        // Find latest ticket from bloc state if it was updated (e.g. cancelled or reviewed)
        final ticket = state.tickets.firstWhere(
          (t) => t.id == initialTicket.id,
          orElse: () => initialTicket,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          appBar: CustomAppBar(
            title: 'Chi tiết vé xe',
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang tạo liên kết chia sẻ vé điện tử...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Boarding Pass Card
                BoardingPassCard(ticket: ticket),

                const SizedBox(height: AppDimensions.base),

                // Driver & Hotline Card
                Container(
                  padding: const EdgeInsets.all(AppDimensions.base),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin liên hệ chuyến đi',
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tổng đài nhà xe ${ticket.trip.operatorName}',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ticket.driverPhone ?? '1900 6067 (24/7)',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đang quay số: ${ticket.driverPhone ?? "1900 6067"}'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Gọi ngay'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.base),

                // Bottom Action buttons depending on ticket status
                if (ticket.status == TicketStatus.upcoming) ...[
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        flex: 1,
                        child: CustomButton(
                          text: 'Hủy vé',
                          type: ButtonType.outline,
                          onPressed: () {
                            CancelTicketSheet.show(
                              context,
                              ticket,
                              context.read<MyTicketsBloc>(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),

                      // Change Ticket Button
                      Expanded(
                        flex: 2,
                        child: CustomButton(
                          text: 'Đổi vé xe',
                          prefixIcon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18),
                          onPressed: () {
                            _showChangeTicketDialog(context, ticket);
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                if (ticket.status == TicketStatus.completed) ...[
                  if (ticket.review == null)
                    CustomButton(
                      text: 'Đánh giá chuyến đi',
                      prefixIcon: const Icon(Icons.star_rate_rounded, color: Colors.white, size: 18),
                      onPressed: () {
                        ReviewBottomSheet.show(
                          context,
                          ticket,
                          context.read<MyTicketsBloc>(),
                        );
                      },
                    )
                  else
                    CustomButton(
                      text: 'Đặt lại chuyến xe này',
                      prefixIcon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                      onPressed: () => context.go('/search-trips'),
                    ),
                ],

                if (ticket.status == TicketStatus.cancelled) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.base),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_outlined, color: AppColors.error),
                        const SizedBox(width: AppDimensions.sm),
                        Expanded(
                          child: Text(
                            'Vé này đã bị hủy. Tiền hoàn đã được gửi về tài khoản theo quy định.',
                            style: AppTextStyles.caption.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  CustomButton(
                    text: 'Tìm vé mới',
                    onPressed: () => context.go('/search-trips'),
                  ),
                ],

                const SizedBox(height: AppDimensions.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangeTicketDialog(BuildContext context, TicketModel ticket) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppDimensions.sm),
            const Expanded(
              child: Text(
                'Đổi vé xe',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quy trình đổi vé xe:',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '1. Chọn chuyến xe mới cùng tuyến:\n${ticket.trip.fromCity} → ${ticket.trip.toCity}.',
              style: AppTextStyles.bodySmall.copyWith(height: 1.4),
            ),
            const SizedBox(height: 6),
            Text(
              '2. Chọn chỗ ngồi mới trên sơ đồ xe.',
              style: AppTextStyles.bodySmall.copyWith(height: 1.4),
            ),
            const SizedBox(height: 6),
            Text(
              '3. Xử lý chênh lệch giá vé: Thu thêm nếu vé mới cao hơn hoặc hoàn tiền nếu vé mới rẻ hơn.',
              style: AppTextStyles.bodySmall.copyWith(height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/search-trips');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Chọn chuyến mới'),
          ),
        ],
      ),
    );
  }
}
