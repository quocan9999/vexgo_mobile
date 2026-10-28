import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import '../../bloc/cancellation_policy.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import '../../bloc/ticket_read_cubit.dart';

class GuestCancelTicketSheet extends StatefulWidget {
  final TicketReadCubit reader;
  const GuestCancelTicketSheet({super.key, required this.reader});

  static Future<void> show(BuildContext context, TicketReadCubit reader) async {
    await reader.refresh();
    if (!context.mounted ||
        reader.isClosed ||
        reader.state.status != TicketReadStatus.loaded) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GuestCancelTicketSheet(reader: reader),
    );
  }

  @override
  State<GuestCancelTicketSheet> createState() => _GuestCancelTicketSheetState();
}

class _GuestCancelTicketSheetState extends State<GuestCancelTicketSheet> {
  bool _agreed = false;
  TicketModel? _agreedTicket;
  final _reason = TextEditingController(text: 'Thay đổi kế hoạch cá nhân');

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketReadCubit, TicketReadState>(
      bloc: widget.reader,
      builder: (context, state) {
        final ticket = state.ticket;
        final quote = ticket?.cancellation;
        final tokenVersion = TokenStorage.sessionVersion;
        final generation = widget.reader.owner.sessionGeneration;
        bool current() =>
            mounted &&
            !widget.reader.isClosed &&
            tokenVersion == TokenStorage.sessionVersion &&
            generation == widget.reader.owner.sessionGeneration;
        final agreed =
            _agreed &&
            ticket != null &&
            _agreedTicket != null &&
            sameCancellationQuote(_agreedTicket!, ticket);
        final busy =
            state.status == TicketReadStatus.cancelling ||
            state.status == TicketReadStatus.loading;
        final canCancel =
            state.status == TicketReadStatus.loaded &&
            ticket != null &&
            hasUsableCancellationQuote(ticket) &&
            quote != null &&
            !state.cancellationUncertain;

        return Container(
          decoration: const BoxDecoration(
            color: DiscoveryColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
            AppDimensions.base,
            AppDimensions.base,
            AppDimensions.base,
            MediaQuery.viewInsetsOf(context).bottom + AppDimensions.base,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: DiscoveryColors.neutral300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.base),

                  if (state.cancellationUncertain) ...[
                    const Text(
                      'Chưa xác minh kết quả hủy. Chỉ kiểm tra trạng thái, không gửi lại yêu cầu.',
                    ),
                    TextButton(
                      onPressed: busy ? null : widget.reader.refresh,
                      child: const Text('Kiểm tra trạng thái'),
                    ),
                  ],
                  if (state.status == TicketReadStatus.failure &&
                      !state.cancellationUncertain)
                    TextButton(
                      onPressed: widget.reader.refresh,
                      child: const Text('Thử lại'),
                    ),
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: canCancel
                              ? DiscoveryColors.errorLight
                              : DiscoveryColors.warningLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          canCancel
                              ? Icons.cancel_outlined
                              : Icons.warning_amber_rounded,
                          color: canCancel
                              ? DiscoveryColors.error
                              : DiscoveryColors.warningDark,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hủy vé',
                              style: DiscoveryTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: DiscoveryColors.neutral900,
                              ),
                            ),
                            if (ticket != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Mã vé: ${ticket.ticketCode}',
                                style: DiscoveryTextStyles.caption.copyWith(
                                  color: DiscoveryColors.neutral500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Đóng',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.base),

                  if (busy)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: DiscoveryColors.primary,
                        ),
                      ),
                    ),

                  if (state.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: DiscoveryColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        state.error!,
                        style: DiscoveryTextStyles.bodySmall.copyWith(
                          color: DiscoveryColors.errorDark,
                        ),
                      ),
                    ),

                  if (ticket != null && quote != null) ...[
                    // Ticket summary strip
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.sm),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.neutral50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DiscoveryColors.neutral200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_bus_rounded,
                                size: 16,
                                color: DiscoveryColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${ticket.trip.operatorName} · ${ticket.trip.vehicleType}',
                                  style: DiscoveryTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: DiscoveryColors.neutral700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${ticket.trip.fromCity} ➔ ${ticket.trip.toCity}',
                            style: DiscoveryTextStyles.h4.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: DiscoveryColors.neutral900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                '${ticket.trip.departureTime} · ${ticket.trip.departureDate}',
                                style: DiscoveryTextStyles.bodySmall.copyWith(
                                  color: DiscoveryColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Chỗ ngồi: ${ticket.seats.join(', ')}',
                                style: DiscoveryTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: DiscoveryColors.neutral800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.base),

                    if (!canCancel && !state.cancellationUncertain) ...[
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.base),
                        decoration: BoxDecoration(
                          color: DiscoveryColors.errorLight.withValues(
                            alpha: 0.6,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: DiscoveryColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          cancellationReasonText(quote.reason),
                          style: DiscoveryTextStyles.bodySmall.copyWith(
                            color: DiscoveryColors.errorDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],

                    if (canCancel) ...[
                      // Fee breakdown card
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.base),
                        decoration: BoxDecoration(
                          color: DiscoveryColors.neutral50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DiscoveryColors.neutral200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phí hủy (${(quote.cancelFeeRate * 100).round()}%): '
                              '${CurrencyFormatter.format(quote.cancelFee)}',
                              style: DiscoveryTextStyles.bodyMedium.copyWith(
                                color: DiscoveryColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Số tiền dự kiến hoàn: '
                              '${CurrencyFormatter.format(quote.refundAmount)}',
                              style: DiscoveryTextStyles.h4.copyWith(
                                color: DiscoveryColors.successDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Hủy vé không đồng nghĩa đã hoàn tiền. '
                              'Trạng thái hoàn tiền cần được xác nhận riêng.',
                              style: TextStyle(
                                fontSize: 11,
                                color: DiscoveryColors.neutral600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppDimensions.base),

                      TextField(
                        controller: _reason,
                        onChanged: (_) => setState(() {}),
                        maxLength: 500,
                        decoration: InputDecoration(
                          labelText: 'Lý do hủy',
                          labelStyle: DiscoveryTextStyles.bodySmall,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      CheckboxListTile(
                        value: agreed,
                        onChanged: busy
                            ? null
                            : (value) => setState(() {
                                _agreed = value ?? false;
                                _agreedTicket = ticket;
                              }),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: DiscoveryColors.primary,
                        title: const Text(
                          'Tôi đồng ý hủy vé với mức phí trên.',
                        ),
                      ),

                      const SizedBox(height: AppDimensions.sm),

                      FilledButton(
                        onPressed:
                            (!agreed || busy || _reason.text.trim().isEmpty)
                            ? null
                            : () async {
                                if (!current()) return;
                                setState(() => _agreed = false);
                                await widget.reader.cancelTicket(
                                  quotedTicket: ticket,
                                  reason: _reason.text.trim(),
                                );
                                final result = widget.reader.state;
                                if (context.mounted &&
                                    current() &&
                                    result.status == TicketReadStatus.loaded &&
                                    result.ticket?.id == ticket.id &&
                                    result.ticket?.ticketCode ==
                                        ticket.ticketCode &&
                                    result.ticket?.status ==
                                        TicketStatus.cancelled &&
                                    ModalRoute.of(context)?.isCurrent == true) {
                                  Navigator.of(context).pop();
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: DiscoveryColors.error,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: DiscoveryColors.neutral300,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Xác nhận hủy vé',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: AppDimensions.sm),

                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
