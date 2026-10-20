import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import '../../bloc/ticket_read_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';

class TicketQrModal extends StatefulWidget {
  final TicketModel ticket;
  final TicketReadCubit? ticketReader;
  final MyTicketsBloc? owner;

  const TicketQrModal({
    super.key,
    required this.ticket,
    this.ticketReader,
    this.owner,
  });

  static void show(
    BuildContext context,
    TicketModel ticket, {
    TicketReadCubit? ticketReader,
  }) {
    if (!ticket.canShowQr ||
        (ticketReader != null &&
            (ticketReader.state.status != TicketReadStatus.loaded ||
                !identical(ticketReader.state.ticket, ticket)))) {
      return;
    }
    final owner = ticketReader?.owner ?? context.read<MyTicketsBloc?>();
    showDialog(
      context: context,
      builder: (ctx) => TicketQrModal(
        ticket: ticket,
        ticketReader: ticketReader,
        owner: owner,
      ),
    );
  }

  @override
  State<TicketQrModal> createState() => _TicketQrModalState();
}

class _TicketQrModalState extends State<TicketQrModal> {
  late final int _tokenVersion;
  int? _sessionGeneration;
  MyTicketsBloc? _owner;
  bool _invalidated = false;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  TicketModel get ticket => widget.ticket;

  bool get _authorized {
    final reader = widget.ticketReader;
    final owner = _owner;
    return !_invalidated &&
        _tokenVersion == TokenStorage.sessionVersion &&
        (owner == null ||
            (!owner.isClosed &&
                owner.sessionGeneration == _sessionGeneration)) &&
        (reader == null ||
            (!reader.isClosed &&
                reader.state.status == TicketReadStatus.loaded &&
                identical(reader.state.ticket, ticket) &&
                reader.state.ticket!.canShowQr));
  }

  @override
  void initState() {
    super.initState();
    _tokenVersion = TokenStorage.sessionVersion;
    final reader = widget.ticketReader;
    _owner = widget.owner ?? reader?.owner ?? context.read<MyTicketsBloc?>();
    _sessionGeneration = _owner?.sessionGeneration;
    _subscriptions.add(
      TokenStorage.sessionInvalidations.listen((_) => _checkAuthorization()),
    );
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
    if (!mounted || _authorized || _invalidated) return;
    // Blank credential content before removing the route, including when a
    // different dialog is now on top. Never pop an unrelated navigation page.
    setState(() => _invalidated = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route is PopupRoute && route.isActive) {
        route.navigator?.removeRoute(route);
      }
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
    if (!_authorized) return const SizedBox.shrink();
    if (!ticket.canShowQr) {
      return const AlertDialog(
        content: Text('Chưa có xác nhận thanh toán để hiển thị mã lên xe.'),
      );
    }
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mã vé điện tử (E-Ticket)',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral900,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.base),

            // QR Code Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neutral200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: QrImageView(
                data: 'VEXGO:${ticket.ticketCode}:${ticket.id}',
                version: QrVersions.auto,
                size: 220.0,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: AppDimensions.md),

            // Ticket Code & Copy
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mã vé: ',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutral700,
                    ),
                  ),
                  Text(
                    ticket.ticketCode,
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (!_authorized) {
                        _checkAuthorization();
                        return;
                      }
                      Clipboard.setData(ClipboardData(text: ticket.ticketCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép mã vé vào bộ nhớ tạm!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.sm),

            Text(
              'Đưa mã này cho Phụ xe hoặc Tài xế quét soát vé khi lên xe',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.neutral500,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppDimensions.md),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
