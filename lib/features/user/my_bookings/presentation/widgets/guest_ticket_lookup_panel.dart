import 'package:vexgo_app/core/localization/client_labels.dart';
import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/app/routes.dart';
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
          context.l10n.uiLookUpATicketWithoutSigningIn,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(context.l10n.uiEnterYourTicketCodeAndThePhoneNumber),
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
                decoration: InputDecoration(
                  labelText: context.l10n.uiTicketCode3c82be,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? context.l10n.uiEnterATicketCode
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
                decoration: InputDecoration(
                  labelText: context.l10n.uiBookingPhoneNumber,
                ),
                validator: (value) =>
                    RegExp(
                      r'^(?:\+84|0)(?:3[2-9]|5[689]|7[06-9]|8[1-9]|9\d)\d{7}$',
                    ).hasMatch(value?.trim() ?? '')
                    ? null
                    : context.l10n.uiInvalidPhoneNumber,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed:
                    state.status == TicketReadStatus.loading ||
                        state.status == TicketReadStatus.cancelling ||
                        state.status == TicketReadStatus.invalidated
                    ? null
                    : _lookup,
                child: Text(context.l10n.uiLookUpTicket),
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
            child: Text(localizedClientLabel(context, state.error!)),
          ),
        if (state.message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(state.message!),
          ),
        if (state.status == TicketReadStatus.failure)
          TextButton(onPressed: _lookup, child: Text(context.l10n.uiTryAgain)),
        if (state.ticket != null) ...[
          const SizedBox(height: 20),
          BoardingPassCard(ticket: state.ticket!, ticketReader: _reader),
          ReceiptEntryButton(ticket: state.ticket!),
          TextButton(
            onPressed: _reader.refresh,
            child: Text(context.l10n.uiRefreshTicketStatus),
          ),
          if (state.ticket!.status == TicketStatus.cancelled) ...[
            Text(
              context
                  .l10n
                  .uiOnlineRefundsAreNotAvailableAfterCancellingContact311d2f,
            ),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.supportChat),
              icon: const Icon(Icons.support_agent),
              label: Text(context.l10n.uiContactSupport),
            ),
          ],
          if (state.ticket!.status == TicketStatus.upcoming)
            OutlinedButton(
              onPressed: () => GuestCancelTicketSheet.show(context, _reader),
              child: Text(context.l10n.uiCancelTicket),
            ),
        ],
      ],
    ),
  );
}
