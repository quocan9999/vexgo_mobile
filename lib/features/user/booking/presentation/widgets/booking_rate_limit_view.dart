import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:flutter/material.dart';
import '../../bloc/booking_rate_limit.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';

class BookingRateLimitView extends StatelessWidget {
  final BookingRateLimit notice;
  final bool hasAnyOrder, busy;
  final VoidCallback onResume, onReviewOrders, onSupport;
  const BookingRateLimitView({
    super.key,
    required this.notice,
    required this.onResume,
    required this.onReviewOrders,
    required this.onSupport,
    this.hasAnyOrder = false,
    this.busy = false,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.uiBookTickets),
      automaticallyImplyLeading: false,
      backgroundColor: DiscoveryColors.header,
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.hourglass_top_rounded, size: 36),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                notice.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            Text(notice.message),
            const SizedBox(height: 12),
            Text(
              hasAnyOrder || notice.existingOrder
                  ? context.l10n.uiYourExistingBookingIsPreservedCheckItBefore
                  : context.l10n.uiYourEnteredDetailsAreKeptSeatAvailabilityAnd,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: busy ? null : onReviewOrders,
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(context.l10n.uiCheckTicketBooking),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: busy ? null : onResume,
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(context.l10n.uiBackToBooking),
            ),
            TextButton(
              onPressed: busy ? null : onSupport,
              child: Text(context.l10n.uiContactSupport),
            ),
          ],
        ),
      ),
    ),
  );
}
