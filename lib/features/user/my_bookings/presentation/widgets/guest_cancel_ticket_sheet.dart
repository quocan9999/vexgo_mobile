import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      builder: (_) => GuestCancelTicketSheet(reader: reader),
    );
  }

  @override
  State<GuestCancelTicketSheet> createState() => _GuestCancelTicketSheetState();
}

class _GuestCancelTicketSheetState extends State<GuestCancelTicketSheet> {
  bool _agreed = false;
  final _reason = TextEditingController(text: 'Thay đổi kế hoạch cá nhân');

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<TicketReadCubit, TicketReadState>(
    bloc: widget.reader,
    builder: (context, state) {
      final ticket = state.ticket;
      final quote = ticket?.cancellation;
      final busy =
          state.status == TicketReadStatus.cancelling ||
          state.status == TicketReadStatus.loading;
      final canCancel =
          state.status == TicketReadStatus.loaded &&
          ticket != null &&
          ticket.canCancel &&
          quote != null;
      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Hủy vé', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (busy) const Center(child: CircularProgressIndicator()),
              if (state.error != null) Text(state.error!),
              if (ticket != null && quote != null) ...[
                Text('Mã vé: ${ticket.ticketCode}'),
                const SizedBox(height: 12),
                if (!canCancel)
                  Text(
                    quote.reason ??
                        'Vé hiện không đủ điều kiện hủy trực tuyến.',
                  ),
                if (canCancel) ...[
                  Text(
                    'Phí hủy (${(quote.cancelFeeRate * 100).round()}%): '
                    '${CurrencyFormatter.format(quote.cancelFee)}',
                  ),
                  Text(
                    'Số tiền dự kiến hoàn: '
                    '${CurrencyFormatter.format(quote.refundAmount)}',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hủy vé không đồng nghĩa đã hoàn tiền. '
                    'Trạng thái hoàn tiền cần được xác nhận riêng.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reason,
                    maxLength: 500,
                    decoration: const InputDecoration(labelText: 'Lý do hủy'),
                  ),
                  CheckboxListTile(
                    value: _agreed,
                    onChanged: (value) =>
                        setState(() => _agreed = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tôi đồng ý hủy vé với mức phí trên.'),
                  ),
                  FilledButton(
                    onPressed: !_agreed
                        ? null
                        : () async {
                            await widget.reader.cancelTicket(
                              quotedTicket: ticket,
                              reason: _reason.text.trim(),
                            );
                            if (context.mounted) Navigator.of(context).pop();
                          },
                    child: const Text('Xác nhận hủy vé'),
                  ),
                ],
              ],
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
