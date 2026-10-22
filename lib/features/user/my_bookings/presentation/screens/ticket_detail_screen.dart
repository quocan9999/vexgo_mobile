import 'package:flutter/material.dart';
import 'package:vexgo_app/features/user/receipts/presentation/receipt_entry_button.dart';
import 'package:flutter/services.dart';
import '../../bloc/ticket_read_cubit.dart';
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

class TicketDetailScreen extends StatefulWidget {
  final TicketModel initialTicket;
  const TicketDetailScreen({super.key, required this.initialTicket});
  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late final TicketReadCubit _reader;
  @override
  void initState() {
    super.initState();
    _reader = TicketReadCubit(owner: context.read<MyTicketsBloc>())
      ..loadTicket(widget.initialTicket);
  }

  @override
  void dispose() {
    _reader.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _reader,
    child: BlocListener<MyTicketsBloc, MyTicketsState>(
      listenWhen: (previous, current) =>
          previous.successMessage != current.successMessage &&
          current.successMessage != null,
      listener: (_, state) => _reader.refresh(),
      child: BlocBuilder<TicketReadCubit, TicketReadState>(
        builder: (context, state) {
          if (state.status == TicketReadStatus.loaded) {
            return _TicketDetailContent(ticket: state.ticket!);
          }
          return Scaffold(
            appBar: const CustomAppBar(title: 'Chi tiết vé xe'),
            body: Center(
              child: state.status == TicketReadStatus.loading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            state.error ?? 'Không thể tải thông tin vé.',
                          ),
                        ),
                        if (state.status != TicketReadStatus.invalidated)
                          TextButton(
                            onPressed: _reader.refresh,
                            child: const Text('Thử lại'),
                          ),
                      ],
                    ),
            ),
          );
        },
      ),
    ),
  );
}

class _TicketDetailContent extends StatelessWidget {
  final TicketModel ticket;
  const _TicketDetailContent({required this.ticket});
  @override
  Widget build(BuildContext context) {
    final contactPhone = ticket.driverPhone?.trim();
    final canManage = !context.read<MyTicketsBloc>().state.requiresLogin;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: CustomAppBar(
        title: 'Chi tiết vé xe',
        actions: [
          IconButton(
            tooltip: 'Cập nhật trạng thái vé',
            icon: const Icon(Icons.refresh),
            onPressed: context.read<TicketReadCubit>().refresh,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Boarding Pass Card
            BoardingPassCard(
              ticket: ticket,
              ticketReader: context.read<TicketReadCubit>(),
            ),

            const SizedBox(height: AppDimensions.sm),
            ReceiptEntryButton(ticket: ticket),
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
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
                        child: const Icon(
                          Icons.phone_rounded,
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
                              'Liên hệ chuyến đi ${ticket.trip.operatorName}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.neutral500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              contactPhone == null || contactPhone.isEmpty
                                  ? 'Nhà xe chưa cung cấp số liên hệ.'
                                  : contactPhone,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (contactPhone != null && contactPhone.isNotEmpty)
                        OutlinedButton(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: contactPhone),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép số liên hệ.'),
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
                          child: const Text('Sao chép số'),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.base),

            // Bottom Action buttons depending on ticket status
            if (ticket.status == TicketStatus.upcoming && canManage) ...[
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
                      text: 'Tìm chuyến khác',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => context.go('/search-trips'),
                    ),
                  ),
                ],
              ),
            ],

            if (ticket.status == TicketStatus.completed && canManage) ...[
              if (ticket.review == null)
                CustomButton(
                  text: 'Đánh giá chuyến đi',
                  prefixIcon: const Icon(
                    Icons.star_rate_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () {
                    ReviewBottomSheet.show(
                      context,
                      ticket,
                      context.read<MyTicketsBloc>(),
                    );
                  },
                )
              else
                Column(
                  children: [
                    Text(
                      'Đã đánh giá • ${ticket.review!.rating}/5',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    CustomButton(
                      text: 'Đặt lại chuyến xe này',
                      prefixIcon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => context.go('/search-trips'),
                    ),
                  ],
                ),
            ],

            if (ticket.status == TicketStatus.cancelled) ...[
              Container(
                padding: const EdgeInsets.all(AppDimensions.base),
                decoration: BoxDecoration(
                  color: AppColors.errorLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel_outlined, color: AppColors.error),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Text(
                        'Vé này đã bị hủy. Trạng thái hoàn tiền chưa được xác nhận. Vui lòng kiểm tra với nhà xe hoặc đơn vị thanh toán.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                        ),
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
  }
}
