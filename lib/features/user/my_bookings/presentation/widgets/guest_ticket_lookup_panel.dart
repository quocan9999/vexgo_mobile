import 'package:flutter/material.dart';
import 'package:vexgo_app/features/user/receipts/presentation/receipt_entry_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/my_tickets_bloc.dart';
import '../../bloc/ticket_read_cubit.dart';
import 'boarding_pass_card.dart';
import 'guest_cancel_ticket_sheet.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';

class GuestTicketLookupPanel extends StatefulWidget {
  const GuestTicketLookupPanel({super.key});
  @override
  State<GuestTicketLookupPanel> createState() => _GuestTicketLookupPanelState();
}

class _GuestTicketLookupPanelState extends State<GuestTicketLookupPanel> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _phone = TextEditingController();
  late final TicketReadCubit _reader;
  @override
  void initState() {
    super.initState();
    _reader = TicketReadCubit(owner: context.read<MyTicketsBloc>());
  }

  void _lookup() {
    if (_form.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      _reader.lookup(ticketCode: _code.text, phoneNumber: _phone.text);
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _phone.dispose();
    _reader.close();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<TicketReadCubit, TicketReadState>(
    bloc: _reader,
    listener: (_, state) {
      if (state.status == TicketReadStatus.invalidated) {
        _code.clear();
        _phone.clear();
      }
    },
    builder: (context, state) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Tra cứu vé không cần đăng nhập',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text('Nhập mã vé và số điện thoại đã dùng khi đặt vé.'),
        const SizedBox(height: 12),
        Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                key: const Key('lookup-ticket-code'),
                controller: _code,
                enabled:
                    state.status != TicketReadStatus.loading &&
                    state.status != TicketReadStatus.cancelling &&
                    state.status != TicketReadStatus.invalidated,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Mã vé'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập mã vé.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('lookup-phone'),
                controller: _phone,
                enabled:
                    state.status != TicketReadStatus.loading &&
                    state.status != TicketReadStatus.cancelling &&
                    state.status != TicketReadStatus.invalidated,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại đặt vé',
                ),
                validator: (value) =>
                    RegExp(
                      r'^(?:\+84|0)(?:3[2-9]|5[689]|7[06-9]|8[1-9]|9\d)\d{7}$',
                    ).hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Số điện thoại không hợp lệ.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed:
                    state.status == TicketReadStatus.loading ||
                        state.status == TicketReadStatus.cancelling ||
                        state.status == TicketReadStatus.invalidated
                    ? null
                    : _lookup,
                child: const Text('Tra cứu vé'),
              ),
            ],
          ),
        ),
        if (state.status == TicketReadStatus.loading ||
            state.status == TicketReadStatus.cancelling)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(state.error!),
          ),
        if (state.message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(state.message!),
          ),
        if (state.status == TicketReadStatus.failure)
          TextButton(onPressed: _lookup, child: const Text('Thử lại')),
        if (state.ticket != null) ...[
          const SizedBox(height: 20),
          BoardingPassCard(ticket: state.ticket!, ticketReader: _reader),
          ReceiptEntryButton(ticket: state.ticket!),
          TextButton(
            onPressed: _reader.refresh,
            child: const Text('Cập nhật trạng thái vé'),
          ),
          if (state.ticket!.status == TicketStatus.upcoming)
            OutlinedButton(
              onPressed: () => GuestCancelTicketSheet.show(context, _reader),
              child: const Text('Hủy vé'),
            ),
        ],
      ],
    ),
  );
}
