import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/network/api_config.dart';
import '../../../../data/models/booking_receipt_model.dart';
import '../../../../data/models/ticket_model.dart';

class ReceiptEntryButton extends StatefulWidget {
  final TicketModel ticket;
  const ReceiptEntryButton({super.key, required this.ticket});
  @override
  State<ReceiptEntryButton> createState() => _ReceiptEntryButtonState();
}

class _ReceiptEntryButtonState extends State<ReceiptEntryButton> {
  final _session = TokenStorage.sessionVersion;
  late final StreamSubscription<void> _subscription;
  @override
  void initState() {
    super.initState();
    _subscription = TokenStorage.sessionChanges.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ApiConfig.isDemoMode
      ? const SizedBox.shrink()
      : OutlinedButton.icon(
          icon: const Icon(Icons.receipt_long_outlined),
          label: const Text('Xem chứng từ thanh toán'),
          onPressed: _session != TokenStorage.sessionVersion
              ? null
              : () {
                  if (_session != TokenStorage.sessionVersion) return;
                  context.push(
                    '/booking-receipt',
                    extra: ReceiptLookupRequest(
                      widget.ticket.ticketCode,
                      widget.ticket.passenger.phone,
                      _session,
                    ),
                  );
                },
        );
}
