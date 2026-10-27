import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';

class TicketSummaryCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onReview;
  final VoidCallback? onRebook;

  const TicketSummaryCard({
    super.key,
    required this.ticket,
    required this.onTap,
    this.onCancel,
    this.onReview,
    this.onRebook,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        key: Key('ticket-card-${ticket.ticketCode}'),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: DiscoveryColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getBorderColor(), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: DiscoveryColors.neutral900.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppDimensions.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Operator info & Badges
            _buildHeader(context),

            const SizedBox(height: 12),
            const Divider(height: 1, color: DiscoveryColors.divider),
            const SizedBox(height: 12),

            // Journey Route & Schedule
            _buildJourneySection(context),

            const SizedBox(height: 10),

            // Ticket Meta Strip (Code, Seats, Price)
            _buildMetaStrip(context),

            // Cancel reason or review note if applicable
            if (ticket.status == TicketStatus.cancelled) ...[
              const SizedBox(height: 8),
              _buildCancellationNote(context),
            ],

            if (ticket.status == TicketStatus.completed &&
                ticket.review != null) ...[
              const SizedBox(height: 8),
              _buildReviewBadge(context),
            ],

            const SizedBox(height: 12),

            // Action Buttons Row / Wrap
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bus operator icon
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: DiscoveryColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: DiscoveryColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),

        // Operator name and vehicle type
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.trip.operatorName.isNotEmpty
                    ? ticket.trip.operatorName
                    : 'Nhà xe VexGo',
                style: DiscoveryTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: DiscoveryColors.neutral900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (ticket.trip.vehicleType.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  ticket.trip.vehicleType,
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    color: DiscoveryColors.neutral500,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Status Badges
        _buildStatusBadges(),
      ],
    );
  }

  Widget _buildStatusBadges() {
    Color bg;
    Color text;
    String label;

    switch (ticket.status) {
      case TicketStatus.upcoming:
        bg = DiscoveryColors.primaryLight;
        text = DiscoveryColors.primary;
        label = 'Sắp đi';
        break;
      case TicketStatus.completed:
        bg = DiscoveryColors.successLight;
        text = DiscoveryColors.successDark;
        label = 'Đã đi';
        break;
      case TicketStatus.cancelled:
        bg = DiscoveryColors.errorLight;
        text = DiscoveryColors.errorDark;
        label = 'Đã hủy';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: DiscoveryTextStyles.caption.copyWith(
              color: text,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        if (ticket.status == TicketStatus.upcoming) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ticket.isPaid
                  ? DiscoveryColors.successLight
                  : DiscoveryColors.warningLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              ticket.isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
              style: DiscoveryTextStyles.caption.copyWith(
                color: ticket.isPaid
                    ? DiscoveryColors.successDark
                    : DiscoveryColors.warningDark,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildJourneySection(BuildContext context) {
    final pickup = ticket.trip.pickupPoint.trim();
    final pickupAddress = ticket.trip.pickupAddress.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route Cities
        Text(
          '${ticket.trip.fromCity} ➔ ${ticket.trip.toCity}',
          style: DiscoveryTextStyles.h4.copyWith(
            fontWeight: FontWeight.w700,
            color: DiscoveryColors.neutral900,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),

        // Departure time & date
        Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: DiscoveryColors.neutral500,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${ticket.trip.departureTime} · ${ticket.trip.departureDate}',
                style: DiscoveryTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: DiscoveryColors.neutral700,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // Pickup point only when data exists
        if (pickup.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 14,
                color: DiscoveryColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pickupAddress.isNotEmpty
                      ? 'Đón: $pickup ($pickupAddress)'
                      : 'Đón: $pickup',
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    color: DiscoveryColors.neutral600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMetaStrip(BuildContext context) {
    final code = ticket.ticketCode.trim().isNotEmpty
        ? ticket.ticketCode
        : (ticket.bookingCode ?? '--');
    final seatsStr = ticket.seats.isNotEmpty
        ? ticket.seats.join(', ')
        : (ticket.seatNumber ?? '--');

    Widget field(String label, String value, Color color) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DiscoveryTextStyles.caption.copyWith(
            color: DiscoveryColors.neutral500,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: DiscoveryTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DiscoveryColors.neutral50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: field('Mã vé', code, DiscoveryColors.neutral900),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: field('Ghế', seatsStr, DiscoveryColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: DiscoveryColors.divider),
          const SizedBox(height: 8),
          Text(
            'Tổng tiền',
            textAlign: TextAlign.end,
            style: DiscoveryTextStyles.caption.copyWith(
              color: DiscoveryColors.neutral500,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.format(ticket.finalAmount),
            textAlign: TextAlign.end,
            style: DiscoveryTextStyles.price.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ticket.status == TicketStatus.cancelled
                  ? DiscoveryColors.neutral500
                  : DiscoveryColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DiscoveryColors.errorLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: DiscoveryColors.error,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Lý do: ${ticket.cancelReason ?? "Đã hủy theo yêu cầu"}',
              style: DiscoveryTextStyles.caption.copyWith(
                color: DiscoveryColors.errorDark,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (ticket.refundAmount != null) ...[
            const SizedBox(width: 6),
            Text(
              'Hoàn: ${CurrencyFormatter.format(ticket.refundAmount!)}',
              style: DiscoveryTextStyles.caption.copyWith(
                color: DiscoveryColors.successDark,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DiscoveryColors.warningLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 15,
            color: DiscoveryColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            '${ticket.review!.rating}.0 (Đã đánh giá)',
            style: DiscoveryTextStyles.caption.copyWith(
              color: DiscoveryColors.warningDark,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final bool showCancel =
        ticket.status == TicketStatus.upcoming &&
        ticket.canCancel &&
        onCancel != null;
    final bool showReview =
        ticket.status == TicketStatus.completed &&
        ticket.review == null &&
        onReview != null;

    final Widget primaryBtn = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: ticket.status == TicketStatus.cancelled
              ? DiscoveryColors.neutral200
              : DiscoveryColors.primary,
          foregroundColor: ticket.status == TicketStatus.cancelled
              ? DiscoveryColors.neutral700
              : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ticket.status == TicketStatus.cancelled
                  ? Icons.receipt_long_rounded
                  : (ticket.canShowQr
                        ? Icons.qr_code_2_rounded
                        : Icons.arrow_forward_rounded),
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                ticket.canShowQr ? 'Xem vé & QR' : 'Xem chi tiết',
                style: DiscoveryTextStyles.button.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ticket.status == TicketStatus.cancelled
                      ? DiscoveryColors.neutral700
                      : Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    if (showCancel) {
      return Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: DiscoveryColors.error,
                side: const BorderSide(color: DiscoveryColors.errorLight),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Hủy vé',
                style: DiscoveryTextStyles.button.copyWith(
                  color: DiscoveryColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: primaryBtn),
        ],
      );
    }

    if (showReview) {
      return Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: OutlinedButton.icon(
              onPressed: onReview,
              icon: const Icon(
                Icons.star_outline_rounded,
                size: 16,
                color: DiscoveryColors.secondary,
              ),
              label: Text(
                'Đánh giá',
                style: DiscoveryTextStyles.button.copyWith(
                  color: DiscoveryColors.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: DiscoveryColors.secondary,
                side: const BorderSide(color: DiscoveryColors.secondaryLight),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: primaryBtn),
        ],
      );
    }

    return SizedBox(width: double.infinity, child: primaryBtn);
  }

  Color _getBorderColor() {
    switch (ticket.status) {
      case TicketStatus.upcoming:
        return DiscoveryColors.primary.withValues(alpha: 0.25);
      case TicketStatus.completed:
        return DiscoveryColors.neutral200;
      case TicketStatus.cancelled:
        return DiscoveryColors.neutral200;
    }
  }
}
