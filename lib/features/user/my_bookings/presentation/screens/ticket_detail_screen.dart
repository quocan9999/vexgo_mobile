import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart' hide ButtonType;
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/widgets/custom_app_bar.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_state.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/boarding_pass_card.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/cancel_ticket_sheet.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/review_bottom_sheet.dart';
import '../../bloc/ticket_read_cubit.dart';

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
  void didUpdateWidget(TicketDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTicket.id != widget.initialTicket.id ||
        oldWidget.initialTicket.ticketCode != widget.initialTicket.ticketCode) {
      _reader.loadTicket(widget.initialTicket);
    }
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
            backgroundColor: DiscoveryColors.background,
            appBar: const CustomAppBar(title: 'Chi tiết vé xe'),
            body: Center(
              child: state.status == TicketReadStatus.loading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: DiscoveryColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Đang tải thông tin vé...',
                          style: DiscoveryTextStyles.bodyMedium.copyWith(
                            color: DiscoveryColors.neutral500,
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(AppDimensions.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: DiscoveryColors.errorLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline_rounded,
                              color: DiscoveryColors.error,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.error ?? 'Không thể tải thông tin vé.',
                            style: DiscoveryTextStyles.bodyMedium.copyWith(
                              color: DiscoveryColors.neutral700,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (state.status != TicketReadStatus.invalidated) ...[
                            const SizedBox(height: 16),
                            CustomButton(
                              text: 'Thử lại',
                              width: 140,
                              onPressed: _reader.refresh,
                            ),
                          ],
                        ],
                      ),
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

  Future<void> Function() _contactCopyAction(
    BuildContext context,
    String phone,
  ) {
    final reader = context.read<TicketReadCubit>();
    final owner = reader.owner;
    final generation = owner.sessionGeneration;
    final tokenVersion = TokenStorage.sessionVersion;
    final readState = reader.state;

    bool current() =>
        context.mounted &&
        !owner.isClosed &&
        !reader.isClosed &&
        owner.sessionGeneration == generation &&
        TokenStorage.sessionVersion == tokenVersion &&
        identical(reader.state, readState) &&
        readState.status == TicketReadStatus.loaded &&
        identical(readState.ticket, ticket);

    return () async {
      if (!current()) return;
      await Clipboard.setData(ClipboardData(text: phone));
      if (!context.mounted || !current()) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép số liên hệ.'),
          duration: Duration(seconds: 2),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final contactPhone = ticket.driverPhone?.trim();
    final copyContact = contactPhone == null || contactPhone.isEmpty
        ? null
        : _contactCopyAction(context, contactPhone);
    final canManage = !context.read<MyTicketsBloc>().state.requiresLogin;

    return Scaffold(
      backgroundColor: DiscoveryColors.background,
      appBar: CustomAppBar(
        title: 'Chi tiết vé xe',
        actions: [
          IconButton(
            tooltip: 'Cập nhật trạng thái vé',
            icon: const Icon(
              Icons.refresh_rounded,
              color: DiscoveryColors.neutral800,
            ),
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

            const SizedBox(height: AppDimensions.base),

            // Driver & Hotline Card
            Container(
              padding: const EdgeInsets.all(AppDimensions.base),
              decoration: BoxDecoration(
                color: DiscoveryColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DiscoveryColors.divider, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: DiscoveryColors.neutral900.withValues(alpha: 0.04),
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
                    style: DiscoveryTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: DiscoveryColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 320;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: DiscoveryColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.phone_rounded,
                                    color: DiscoveryColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Liên hệ chuyến đi ${ticket.trip.operatorName}',
                                        style: DiscoveryTextStyles.caption
                                            .copyWith(
                                              color: DiscoveryColors.neutral500,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        contactPhone == null ||
                                                contactPhone.isEmpty
                                            ? 'Nhà xe chưa cung cấp số liên hệ.'
                                            : contactPhone,
                                        style: DiscoveryTextStyles.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  contactPhone == null ||
                                                      contactPhone.isEmpty
                                                  ? DiscoveryColors.neutral500
                                                  : DiscoveryColors.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (contactPhone != null &&
                                contactPhone.isNotEmpty) ...[
                              const SizedBox(height: AppDimensions.sm),
                              OutlinedButton(
                                onPressed: copyContact,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: DiscoveryColors.primary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text('Sao chép số'),
                              ),
                            ],
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: DiscoveryColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.phone_rounded,
                              color: DiscoveryColors.primary,
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
                                  style: DiscoveryTextStyles.caption.copyWith(
                                    color: DiscoveryColors.neutral500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  contactPhone == null || contactPhone.isEmpty
                                      ? 'Nhà xe chưa cung cấp số liên hệ.'
                                      : contactPhone,
                                  style: DiscoveryTextStyles.bodyMedium
                                      .copyWith(
                                        fontWeight: FontWeight.w700,
                                        color:
                                            contactPhone == null ||
                                                contactPhone.isEmpty
                                            ? DiscoveryColors.neutral500
                                            : DiscoveryColors.primary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (contactPhone != null && contactPhone.isNotEmpty)
                            OutlinedButton(
                              onPressed: copyContact,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: DiscoveryColors.primary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text('Sao chép số'),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.base),

            // Bottom Action buttons depending on ticket status
            if (ticket.status == TicketStatus.upcoming && canManage) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 280) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomButton(
                          text: 'Tìm chuyến khác',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () => context.go('/search-trips'),
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        CustomButton(
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
                      ],
                    );
                  }
                  return Row(
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
                  );
                },
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DiscoveryColors.divider),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Đã đánh giá • ${ticket.review!.rating}/5',
                            style: DiscoveryTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: DiscoveryColors.neutral800,
                            ),
                          ),
                        ],
                      ),
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
                  color: DiscoveryColors.errorLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: DiscoveryColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.cancel_outlined,
                      color: DiscoveryColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Text(
                        'Vé này đã bị hủy. Trạng thái hoàn tiền chưa được xác nhận. Vui lòng kiểm tra với nhà xe hoặc đơn vị thanh toán.',
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.errorDark,
                          height: 1.4,
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
