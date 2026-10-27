import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import '../../bloc/my_tickets_bloc.dart';
import '../../bloc/ticket_read_cubit.dart';
import 'ticket_qr_modal.dart';

class BoardingPassCard extends StatefulWidget {
  final TicketModel ticket;
  final TicketReadCubit? ticketReader;

  const BoardingPassCard({super.key, required this.ticket, this.ticketReader});

  @override
  State<BoardingPassCard> createState() => _BoardingPassCardState();
}

class _BoardingPassCardState extends State<BoardingPassCard> {
  late final int _tokenVersion;
  late final MyTicketsBloc? _owner;
  int? _sessionGeneration;
  bool _invalidated = false;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  TicketModel get ticket => widget.ticket;
  TicketReadCubit? get ticketReader => widget.ticketReader;

  bool get _sessionAuthorized {
    final owner = _owner;
    final reader = ticketReader;
    return !_invalidated &&
        _tokenVersion == TokenStorage.sessionVersion &&
        (owner == null ||
            (!owner.isClosed &&
                owner.sessionGeneration == _sessionGeneration)) &&
        (reader == null ||
            (!reader.isClosed &&
                reader.state.status != TicketReadStatus.invalidated));
  }

  bool get _authorized =>
      _sessionAuthorized &&
      (ticketReader == null ||
          (ticketReader!.state.status == TicketReadStatus.loaded &&
              identical(ticketReader!.state.ticket, ticket)));

  @override
  void initState() {
    super.initState();
    _tokenVersion = TokenStorage.sessionVersion;
    _owner = ticketReader?.owner ?? context.read<MyTicketsBloc?>();
    _sessionGeneration = _owner?.sessionGeneration;
    _subscriptions.add(
      TokenStorage.sessionInvalidations.listen((_) => _checkAuthorization()),
    );
    final reader = ticketReader;
    if (reader != null) {
      _subscriptions.add(
        reader.stream.listen(
          (_) => _checkAuthorization(),
          onDone: _checkAuthorization,
        ),
      );
    }
    final owner = _owner;
    if (owner != null) {
      _subscriptions.add(
        owner.stream.listen(
          (_) => _checkAuthorization(),
          onDone: _checkAuthorization,
        ),
      );
    }
  }

  void _checkAuthorization() {
    if (!mounted || _invalidated) return;
    setState(() {
      // Loading and a fresh ticket object are temporary read states. Only
      // actual session loss/reader invalidation permanently revokes this card.
      if (!_sessionAuthorized) _invalidated = true;
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionAuthorized) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.base),
        decoration: BoxDecoration(
          color: DiscoveryColors.errorLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: DiscoveryColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: DiscoveryColors.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Phiên đã thay đổi. Vui lòng mở lại thông tin vé.',
                style: DiscoveryTextStyles.bodySmall.copyWith(
                  color: DiscoveryColors.errorDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Do not expose the old payload while a fresh read is pending or has failed.
    if (!_authorized) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: DiscoveryColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DiscoveryColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: DiscoveryColors.neutral900.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Upper Section: Header, Route, QR Code
          Padding(
            padding: const EdgeInsets.all(AppDimensions.base),
            child: Column(
              children: [
                // Operator Name & Status Badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: DiscoveryColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: DiscoveryColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
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
                          const SizedBox(height: 2),
                          Text(
                            ticket.trip.vehicleType.isNotEmpty
                                ? ticket.trip.vehicleType
                                : 'Xe khách chất lượng cao',
                            style: DiscoveryTextStyles.bodySmall.copyWith(
                              color: DiscoveryColors.neutral500,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadges(),
                  ],
                ),

                const SizedBox(height: 16),

                // Cities Flow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Điểm đi',
                            style: DiscoveryTextStyles.caption.copyWith(
                              color: DiscoveryColors.neutral500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.trip.fromCity,
                            style: DiscoveryTextStyles.h3.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: DiscoveryColors.neutral900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.trip.departureTime,
                            style: DiscoveryTextStyles.bodyMedium.copyWith(
                              color: DiscoveryColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.neutral100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: DiscoveryColors.primary,
                        size: 18,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Điểm đến',
                            style: DiscoveryTextStyles.caption.copyWith(
                              color: DiscoveryColors.neutral500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.trip.toCity,
                            style: DiscoveryTextStyles.h3.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: DiscoveryColors.neutral900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.trip.arrivalTime,
                            style: DiscoveryTextStyles.bodyMedium.copyWith(
                              color: DiscoveryColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // QR Code / Gate Box
                if (ticket.canShowQr)
                  Semantics(
                    button: true,
                    label: 'Mã QR lên xe, chạm để phóng to',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => TicketQrModal.show(
                          context,
                          ticket,
                          ticketReader: ticketReader,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: DiscoveryColors.neutral50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: DiscoveryColors.neutral200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: DiscoveryColors.divider,
                                  ),
                                ),
                                child: QrImageView(
                                  data:
                                      'VEXGO:${ticket.ticketCode}:${ticket.id}',
                                  version: QrVersions.auto,
                                  size: 72.0,
                                  backgroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mã vé: ${ticket.ticketCode}',
                                      style: DiscoveryTextStyles.titleSmall
                                          .copyWith(
                                            color: DiscoveryColors.primary,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.fullscreen_rounded,
                                          size: 16,
                                          color: DiscoveryColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Chạm để phóng to mã QR',
                                            style: DiscoveryTextStyles.caption
                                                .copyWith(
                                                  color:
                                                      DiscoveryColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Dùng mã này khi lên xe tại điểm đón',
                                      style: DiscoveryTextStyles.bodySmall
                                          .copyWith(
                                            color: DiscoveryColors.neutral500,
                                            fontSize: 11,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: DiscoveryColors.neutral100.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DiscoveryColors.neutral200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: DiscoveryColors.neutral200.withValues(
                              alpha: 0.5,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_clock,
                            size: 22,
                            color: DiscoveryColors.neutral500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mã vé: ${ticket.ticketCode}',
                                style: DiscoveryTextStyles.titleSmall.copyWith(
                                  color: DiscoveryColors.neutral800,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getQrUnavailableReason(),
                                style: DiscoveryTextStyles.caption.copyWith(
                                  color: DiscoveryColors.neutral600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Perforated Tear Line with Cutouts
          _buildTearLine(),

          // Lower Section: Journey Details, Seats, Payment
          Padding(
            padding: const EdgeInsets.all(AppDimensions.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seats and Date Key Info
                Row(
                  children: [
                    Expanded(
                      child: _buildPassDetailBlock(
                        title: 'Chỗ ngồi',
                        value: ticket.seats.join(', '),
                        valueColor: DiscoveryColors.primary,
                        isHighlight: true,
                      ),
                    ),
                    Expanded(
                      child: _buildPassDetailBlock(
                        title: 'Ngày khởi hành',
                        value: ticket.trip.departureDate,
                      ),
                    ),
                    if (ticket.licensePlate != null)
                      Expanded(
                        child: _buildPassDetailBlock(
                          title: 'Biển số xe',
                          value: ticket.licensePlate!,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: AppDimensions.base),
                const Divider(height: 1, color: DiscoveryColors.divider),
                const SizedBox(height: AppDimensions.base),

                // Pickup Point
                _buildTimelinePoint(
                  time: ticket.trip.departureTime,
                  title: ticket.trip.pickupPoint,
                  address: ticket.trip.pickupAddress,
                  isStart: true,
                ),

                const SizedBox(height: AppDimensions.md),

                // Dropoff Point
                _buildTimelinePoint(
                  time: ticket.trip.arrivalTime,
                  title: ticket.trip.dropoffPoint,
                  address: ticket.trip.dropoffAddress,
                  isStart: false,
                ),

                const SizedBox(height: AppDimensions.base),
                const Divider(height: 1, color: DiscoveryColors.divider),
                const SizedBox(height: AppDimensions.base),

                // Passenger and Contact
                _buildInfoLine(
                  label: 'Hành khách:',
                  value:
                      '${ticket.passenger.fullName} · ${ticket.passenger.phone}',
                ),
                _buildInfoLine(
                  label: 'Email nhận vé:',
                  value: ticket.passenger.email,
                ),
                _buildInfoLine(
                  label: 'Thanh toán qua:',
                  value: ticket.paymentMethod,
                ),
                _buildInfoLine(
                  label: 'Tổng tiền vé:',
                  value: CurrencyFormatter.format(ticket.finalAmount),
                  valueColor: ticket.status == TicketStatus.cancelled
                      ? DiscoveryColors.neutral500
                      : DiscoveryColors.secondary,
                  isBold: true,
                ),

                if (ticket.status == TicketStatus.cancelled) ...[
                  _buildInfoLine(
                    label: 'Số tiền hoàn (chưa xác nhận):',
                    value: ticket.refundAmount != null
                        ? CurrencyFormatter.format(ticket.refundAmount!)
                        : 'Chưa có dữ liệu',
                    valueColor: DiscoveryColors.successDark,
                    isBold: true,
                  ),
                  _buildInfoLine(
                    label: 'Lý do hủy:',
                    value: ticket.cancelReason ?? 'Hủy theo yêu cầu',
                    valueColor: DiscoveryColors.error,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getQrUnavailableReason() {
    if (ticket.status == TicketStatus.cancelled) {
      return 'Vé đã bị hủy. Mã QR không khả dụng.';
    }
    if (ticket.status == TicketStatus.completed) {
      return 'Chuyến đi đã hoàn thành.';
    }
    if (!ticket.isPaid) {
      return 'Chưa có xác nhận thanh toán';
    }
    return 'Mã QR chưa khả dụng cho vé này.';
  }

  Widget _buildTearLine() {
    return SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dashed line
          LayoutBuilder(
            builder: (context, constraints) {
              const dashWidth = 6.0;
              const dashSpace = 4.0;
              final dashCount = (constraints.maxWidth / (dashWidth + dashSpace))
                  .floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(dashCount, (_) {
                  return Container(
                    width: dashWidth,
                    height: 1.5,
                    color: DiscoveryColors.neutral300,
                    margin: const EdgeInsets.symmetric(
                      horizontal: dashSpace / 2,
                    ),
                  );
                }),
              );
            },
          ),
          // Left cutout
          Positioned(
            left: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: DiscoveryColors.background,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Right cutout
          Positioned(
            right: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: DiscoveryColors.background,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelinePoint({
    required String time,
    required String title,
    required String address,
    required bool isStart,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isStart ? Icons.radio_button_checked : Icons.location_on,
          size: 16,
          color: isStart ? DiscoveryColors.primary : DiscoveryColors.secondary,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            time,
            style: DiscoveryTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: DiscoveryColors.neutral900,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DiscoveryTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: DiscoveryColors.neutral900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: DiscoveryTextStyles.caption.copyWith(
                  color: DiscoveryColors.neutral500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPassDetailBlock({
    required String title,
    required String value,
    Color? valueColor,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DiscoveryTextStyles.caption.copyWith(
            color: DiscoveryColors.neutral500,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: DiscoveryTextStyles.bodyMedium.copyWith(
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? DiscoveryColors.neutral900,
            fontSize: isHighlight ? 15 : 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInfoLine({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: DiscoveryTextStyles.caption.copyWith(
                color: DiscoveryColors.neutral600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: DiscoveryTextStyles.bodySmall.copyWith(
                color: valueColor ?? DiscoveryColors.neutral900,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
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
      mainAxisSize: MainAxisSize.min,
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
}
