import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_cargo_section_card.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';

/// Success screen displayed only when both legs are completely confirmed and tickets hydrated.
class RoundTripSuccessView extends StatelessWidget {
  final RoundTripRequest request;
  final BookingFlowState outbound;
  final BookingFlowState inbound;
  final VoidCallback onOpenMyTickets;
  final VoidCallback onOpenHome;

  const RoundTripSuccessView({
    super.key,
    required this.request,
    required this.outbound,
    required this.inbound,
    required this.onOpenMyTickets,
    required this.onOpenHome,
  });

  @override
  Widget build(BuildContext context) {
    final outTickets = outbound.createdTickets.isNotEmpty
        ? outbound.createdTickets
        : (outbound.createdTicket != null
              ? [outbound.createdTicket!]
              : <TicketModel>[]);
    final inTickets = inbound.createdTickets.isNotEmpty
        ? inbound.createdTickets
        : (inbound.createdTicket != null
              ? [inbound.createdTicket!]
              : <TicketModel>[]);

    return Scaffold(
      backgroundColor: DiscoveryColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Icon & Title
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: DiscoveryColors.successLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: DiscoveryColors.success,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Đặt vé khứ hồi thành công!',
                style: DiscoveryTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Cả 2 chặng đã được xác nhận thanh toán và xuất vé điện tử.',
                style: DiscoveryTextStyles.bodyMedium.copyWith(
                  color: DiscoveryColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Outbound tickets
              _buildLegTicketsCard(
                title:
                    'Lượt đi: ${request.origin.name} → ${request.destination.name}',
                tickets: outTickets,
                operatorName: outbound.trip?.operatorName ?? 'Nhà xe',
                state: outbound,
                scopeKey: 'outbound-success',
              ),

              const SizedBox(height: 16),

              // Inbound tickets
              _buildLegTicketsCard(
                title:
                    'Lượt về: ${request.destination.name} → ${request.origin.name}',
                tickets: inTickets,
                operatorName: inbound.trip?.operatorName ?? 'Nhà xe',
                state: inbound,
                scopeKey: 'inbound-success',
              ),

              const SizedBox(height: 28),

              // Action buttons
              ElevatedButton.icon(
                key: const ValueKey('view-my-tickets-btn'),
                onPressed: onOpenMyTickets,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiscoveryColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.confirmation_number_outlined),
                label: Text(
                  'Xem vé của tôi',
                  style: DiscoveryTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('back-to-home-btn'),
                onPressed: onOpenHome,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: DiscoveryColors.neutral300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.home_outlined),
                label: Text(
                  'Về Trang chủ',
                  style: DiscoveryTextStyles.bodyMedium.copyWith(
                    color: DiscoveryColors.neutral700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegTicketsCard({
    required String title,
    required List<TicketModel> tickets,
    required String operatorName,
    required BookingFlowState state,
    required String scopeKey,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DiscoveryColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_bus_rounded,
                color: DiscoveryColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: DiscoveryTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            operatorName,
            style: DiscoveryTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (final t in tickets) ...[
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: DiscoveryColors.neutral100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mã vé: ${t.ticketCode}',
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Ghế ${t.seatNumber}',
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      color: DiscoveryColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (BookingCargoSummaryBox.hasCargo(
            state: state,
            booking: state.checkoutBooking,
          )) ...[
            const SizedBox(height: 10),
            BookingCargoSummaryBox(
              state: state,
              booking: state.checkoutBooking,
              scopeKey: scopeKey,
            ),
          ],
        ],
      ),
    );
  }
}
