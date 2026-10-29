import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vexgo_app/features/user/receipts/presentation/receipt_entry_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/booking_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/booking_cargo_section_card.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';

class BookingSuccessScreen extends StatefulWidget {
  final TicketModel ticket;
  final List<TicketModel> tickets;
  final BookingModel? booking;

  const BookingSuccessScreen({
    super.key,
    required this.ticket,
    this.tickets = const [],
    this.booking,
  });

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen> {
  late final int _tokenSessionVersion;
  StreamSubscription<void>? _sessionSubscription;
  StreamSubscription<dynamic>? _ticketsSubscription;
  MyTicketsBloc? _owner;
  int? _ownerGeneration;

  bool get _sessionCurrent =>
      TokenStorage.sessionVersion == _tokenSessionVersion &&
      (_owner == null || _owner!.sessionGeneration == _ownerGeneration);

  void _onSessionChange() {
    if (mounted && !_sessionCurrent) {
      ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _tokenSessionVersion = TokenStorage.sessionVersion;
    _sessionSubscription = TokenStorage.sessionChanges.listen(
      (_) => _onSessionChange(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sessionCurrent) return;
      final owner = _owner;
      if (owner != null) {
        final ticketsToRegister = widget.tickets.isEmpty
            ? [widget.ticket]
            : widget.tickets;
        for (final t in ticketsToRegister) {
          owner.add(
            AddNewTicketEvent(
              t,
              sessionGeneration: _ownerGeneration,
              tokenSessionVersion: _tokenSessionVersion,
            ),
          );
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_owner != null) return;
    try {
      _owner = context.read<MyTicketsBloc>();
      _ownerGeneration = _owner!.sessionGeneration;
      _ticketsSubscription = _owner!.stream.listen((_) => _onSessionChange());
    } on ProviderNotFoundException {
      // Guest success routes can render without a tickets cache provider.
    }
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _ticketsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _copyTicketCode(String code) async {
    if (!_sessionCurrent) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted || !_sessionCurrent) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép mã vé vào bộ nhớ tạm!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  BookingModel? _resolvedBooking(BuildContext context) {
    if (widget.booking != null) return widget.booking;
    try {
      final extra = GoRouterState.of(context).extra;
      if (extra is Map<String, dynamic> && extra['booking'] is BookingModel) {
        return extra['booking'] as BookingModel;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionCurrent) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) context.go('/');
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Thông tin vé')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Phiên đã thay đổi. Vui lòng mở lại vé của bạn.'),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Về trang chủ'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final ticket = widget.ticket;
    final trip = ticket.trip;
    final ticketList = widget.tickets.isEmpty ? [ticket] : widget.tickets;
    final booking = _resolvedBooking(context);
    final confirmedOrderTotal =
        booking != null &&
            booking.isPaid &&
            ticketList.every(
              (issued) =>
                  issued.bookingId?.toString() == booking.bookingId.toString(),
            )
        ? booking.totalAmount
        : null;

    // Collect all seats across tickets for group summary
    final allSeatsList = <String>[];
    for (final t in ticketList) {
      for (final s in t.seats) {
        if (!allSeatsList.contains(s)) {
          allSeatsList.add(s);
        }
      }
    }
    final allSeatsStr = allSeatsList.isEmpty
        ? ticket.seats.join(', ')
        : allSeatsList.join(', ');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        backgroundColor: DiscoveryColors.background,
        appBar: AppBar(
          backgroundColor: DiscoveryColors.header,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Về trang chủ',
            onPressed: () => context.go('/'),
          ),
          title: Text(
            'Vé điện tử VexGo',
            style: DiscoveryTextStyles.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.base,
            vertical: AppDimensions.base,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card 1: Success Header & Booking Code Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.base),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: DiscoveryColors.neutral200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: DiscoveryColors.successLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: DiscoveryColors.success,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text(
                      'Đặt vé thành công!',
                      style: DiscoveryTextStyles.h2.copyWith(
                        color: DiscoveryColors.successDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Giao dịch đã được hệ thống xác nhận',
                      style: DiscoveryTextStyles.bodyMedium.copyWith(
                        color: DiscoveryColors.neutral600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.base),

                    // Ticket Code Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.neutral50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DiscoveryColors.neutral200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mã vé:',
                                  style: DiscoveryTextStyles.caption.copyWith(
                                    color: DiscoveryColors.neutral600,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ticket.ticketCode,
                                  softWrap: true,
                                  style: DiscoveryTextStyles.h4.copyWith(
                                    color: DiscoveryColors.primary,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Semantics(
                            button: true,
                            label: 'Sao chép mã vé',
                            child: IconButton(
                              tooltip: 'Sao chép mã vé',
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              onPressed: () =>
                                  _copyTicketCode(ticket.ticketCode),
                              icon: const Icon(
                                Icons.copy_rounded,
                                size: 18,
                                color: DiscoveryColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.base),

              // Card 2: Trip Details Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.base),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: DiscoveryColors.neutral200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                            trip.operatorName,
                            style: DiscoveryTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: DiscoveryColors.successLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Đã thanh toán',
                          style: DiscoveryTextStyles.caption.copyWith(
                            color: DiscoveryColors.successDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${trip.fromCity} -> ${trip.toCity} • ${trip.vehicleType}',
                      style: DiscoveryTextStyles.caption.copyWith(
                        color: DiscoveryColors.neutral500,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    const Divider(height: 1, color: DiscoveryColors.neutral200),
                    const SizedBox(height: AppDimensions.md),
                    _buildInfoRow('Ngày đi:', trip.departureDate),
                    const SizedBox(height: 8),
                    _buildInfoRow('Giờ đón:', trip.departureTime),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Điểm đón:',
                      _locationText(trip.pickupPoint, trip.pickupAddress),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Điểm trả:',
                      _locationText(trip.dropoffPoint, trip.dropoffAddress),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Chỗ ngồi:',
                      allSeatsStr,
                      valueColor: DiscoveryColors.primary,
                      isBold: true,
                    ),
                    if (ticketList.length == 1) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Tổng thanh toán:',
                        CurrencyFormatter.format(
                          confirmedOrderTotal ?? ticket.finalAmount,
                        ),
                        valueColor: DiscoveryColors.secondary,
                        isBold: true,
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Số lượng vé:',
                        '${ticketList.length} vé',
                        isBold: true,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.base),

              // Card 3: Boarding QR Pass Cards
              ...ticketList.map((issued) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppDimensions.base),
                  padding: const EdgeInsets.all(AppDimensions.base),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: DiscoveryColors.neutral200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: DiscoveryColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.event_seat_rounded,
                                    size: 14,
                                    color: DiscoveryColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Ghế ${issued.seats.join(', ')}',
                                      style: DiscoveryTextStyles.caption
                                          .copyWith(
                                            color: DiscoveryColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (issued.finalAmount > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.format(issued.finalAmount),
                              style: DiscoveryTextStyles.bodyMedium.copyWith(
                                color: DiscoveryColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppDimensions.md),

                      if (issued.canShowQr) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: DiscoveryColors.neutral200,
                            ),
                          ),
                          child: QrImageView(
                            data: 'VEXGO:${issued.ticketCode}:${issued.id}',
                            version: QrVersions.auto,
                            size: 160,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${issued.ticketCode} • ${issued.seats.join(', ')}',
                          style: DiscoveryTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: DiscoveryColors.neutral800,
                          ),
                        ),
                        TextButton.icon(
                          key: ValueKey('copy-ticket-${issued.id}'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: () => _copyTicketCode(issued.ticketCode),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Sao chép mã vé'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Đưa mã này cho phụ xe khi lên xe',
                          style: DiscoveryTextStyles.caption.copyWith(
                            color: DiscoveryColors.neutral500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.md),
                          decoration: BoxDecoration(
                            color: DiscoveryColors.neutral50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: DiscoveryColors.neutral200,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: DiscoveryColors.warningDark,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Chưa có xác nhận thanh toán để hiển thị mã lên xe.',
                                  style: DiscoveryTextStyles.caption.copyWith(
                                    color: DiscoveryColors.neutral700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),

              // Card 4: Passenger Contact Information
              Container(
                padding: const EdgeInsets.all(AppDimensions.base),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: DiscoveryColors.neutral200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          color: DiscoveryColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Thông tin hành khách',
                            style: DiscoveryTextStyles.titleSmall.copyWith(
                              color: DiscoveryColors.neutral900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    const Divider(height: 1, color: DiscoveryColors.neutral200),
                    const SizedBox(height: AppDimensions.sm),
                    _buildInfoRow('Họ tên:', ticket.passenger.fullName),
                    const SizedBox(height: 8),
                    _buildInfoRow('Số điện thoại:', ticket.passenger.phone),
                    if (ticket.passenger.email.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow('Email:', ticket.passenger.email),
                    ],
                  ],
                ),
              ),

              if (BookingCargoSummaryBox.hasCargo(
                booking: _resolvedBooking(context),
              )) ...[
                const SizedBox(height: AppDimensions.base),
                BookingCargoSummaryBox(
                  booking: _resolvedBooking(context),
                  scopeKey: 'oneway-success',
                ),
              ],

              const SizedBox(height: AppDimensions.base),

              // Card 5: Retrieval instructions
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: DiscoveryColors.primaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: DiscoveryColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.confirmation_number_outlined,
                      color: DiscoveryColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Text(
                        'Lưu mã vé và số điện thoại đã dùng khi đặt vé để tra cứu vé không cần đăng nhập.',
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.neutral700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.lg),

              // Action Buttons
              ReceiptEntryButton(ticket: ticket),
              const SizedBox(height: AppDimensions.sm),
              DiscoveryButton(
                text: 'Xem vé của tôi',
                width: double.infinity,
                prefixIcon: const Icon(
                  Icons.confirmation_number_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => context.go('/my-tickets'),
              ),
              const SizedBox(height: AppDimensions.sm),
              DiscoveryButton(
                text: 'Về trang chủ',
                width: double.infinity,
                type: ButtonType.outline,
                prefixIcon: const Icon(
                  Icons.home_rounded,
                  color: DiscoveryColors.primary,
                  size: 20,
                ),
                onPressed: () => context.go('/'),
              ),

              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
    );
  }

  String _locationText(String point, String address) {
    final name = point.trim();
    final detail = address.trim();
    if (detail.isEmpty) return name.isEmpty ? 'Chưa cập nhật' : name;
    return name.isEmpty ? detail : '$name ($detail)';
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: DiscoveryTextStyles.bodySmall.copyWith(
              color: DiscoveryColors.neutral500,
              fontWeight: FontWeight.w500,
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
          ),
        ),
      ],
    );
  }
}
