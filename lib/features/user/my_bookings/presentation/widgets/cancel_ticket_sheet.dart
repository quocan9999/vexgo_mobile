import 'package:vexgo_app/core/localization/client_labels.dart';
import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import '../../bloc/my_tickets_bloc.dart';
import '../../bloc/my_tickets_event.dart';
import '../../bloc/my_tickets_state.dart';
import '../../bloc/cancellation_policy.dart';

class CancelTicketSheet extends StatefulWidget {
  final TicketModel ticket;
  final MyTicketsBloc bloc;

  const CancelTicketSheet({
    super.key,
    required this.ticket,
    required this.bloc,
  });

  static Future<void> show(
    BuildContext context,
    TicketModel ticket,
    MyTicketsBloc bloc,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CancelTicketSheet(ticket: ticket, bloc: bloc),
    );
  }

  @override
  State<CancelTicketSheet> createState() => _CancelTicketSheetState();
}

class _CancelTicketSheetState extends State<CancelTicketSheet> {
  String _selectedReason = 'Thay đổi kế hoạch cá nhân';
  final TextEditingController _customReasonController = TextEditingController();
  bool _agreedToPolicy = false;
  bool _isSubmitting = false;
  late TicketModel _ticket;
  late final int _session;
  late final int _tokenVersion;
  StreamSubscription<dynamic>? _ownerChanges;
  StreamSubscription<void>? _tokenChanges;
  bool _invalidated = false;
  bool _loadingQuote = true;
  bool _uncertain = false;
  String? _readError;
  String? _operationError;
  int _readRequest = 0;

  bool get _current =>
      mounted &&
      !_invalidated &&
      !widget.bloc.isClosed &&
      _session == widget.bloc.sessionGeneration &&
      _tokenVersion == TokenStorage.sessionVersion &&
      !widget.bloc.state.requiresLogin;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _session = widget.bloc.sessionGeneration;
    _tokenVersion = TokenStorage.sessionVersion;
    _uncertain = widget.bloc.cancellationUncertain(_ticket.id);
    if (_uncertain) {
      _operationError = LocaleController
          .strings
          .uiThePreviousCancellationResultIsUnconfirmedCheckIts;
    }
    _isSubmitting =
        widget.bloc.state.cancellationTicketId == _ticket.id &&
        widget.bloc.state.cancellationStatus ==
            TicketCancellationStatus.submitting;
    _ownerChanges = widget.bloc.stream.listen(
      _onOwnerState,
      onDone: _invalidate,
    );
    _tokenChanges = TokenStorage.sessionChanges.listen((_) {
      if (!_current) _invalidate();
    });
    _reloadQuote();
  }

  void _invalidate() {
    if (!mounted || _invalidated) return;
    setState(() {
      _invalidated = true;
      _agreedToPolicy = false;
      _isSubmitting = false;
    });
  }

  Future<void> _reloadQuote() async {
    if (!_current) return;
    final request = ++_readRequest;
    setState(() {
      _loadingQuote = true;
      _agreedToPolicy = false;
      _readError = null;
    });
    try {
      final fresh = await widget.bloc.bookingRepository.getTicketById(
        widget.ticket.id,
      );
      if (!_current || request != _readRequest) return;
      if (fresh == null ||
          !fresh.hasFullDetails ||
          fresh.id != widget.ticket.id ||
          fresh.ticketCode != widget.ticket.ticketCode ||
          fresh.cancellation == null) {
        throw StateError(
          LocaleController.strings.uiNoValidCancellationFeeIsAvailable,
        );
      }
      setState(() {
        _ticket = fresh;
        _loadingQuote = false;
      });
    } catch (_) {
      if (!_current || request != _readRequest) return;
      setState(() {
        _loadingQuote = false;
        _readError =
            context.l10n.uiUnableToLoadTicketDetailsAndCancellationFees;
      });
    }
  }

  void _onOwnerState(MyTicketsState state) {
    if (!_current) {
      _invalidate();
      return;
    }
    if (_isSubmitting &&
        state.cancellationTicketId == _ticket.id &&
        state.cancellationStatus != TicketCancellationStatus.submitting) {
      if (state.cancellationStatus == TicketCancellationStatus.succeeded) {
        setState(() {
          _isSubmitting = false;
          final updated = state.tickets.where((t) => t.id == _ticket.id);
          if (updated.isNotEmpty) _ticket = updated.first;
        });
        _closeIfCurrent();
        return;
      }
      setState(() {
        _isSubmitting = false;
        _agreedToPolicy = false;
        _uncertain =
            state.cancellationStatus == TicketCancellationStatus.uncertain;
        _operationError = state.cancellationMessage;
      });
      if (!_uncertain) _reloadQuote();
    } else {
      setState(() {});
    }
  }

  void _closeIfCurrent() {
    if (mounted && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pop();
    }
  }

  Widget _readState(String message, {bool retry = false}) => Container(
    decoration: const BoxDecoration(
      color: DiscoveryColors.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loadingQuote && !_invalidated)
              const CircularProgressIndicator(),
            Text(message),
            if (retry)
              TextButton(
                onPressed: _reloadQuote,
                child: Text(context.l10n.uiTryAgain),
              ),
            TextButton(
              onPressed: _closeIfCurrent,
              child: Text(context.l10n.uiClose),
            ),
          ],
        ),
      ),
    ),
  );

  final List<String> _reasons = [
    'Thay đổi kế hoạch cá nhân',
    'Đặt nhầm ngày/giờ khởi hành',
    'Tìm được phương tiện di chuyển khác',
    'Lý do sức khỏe / việc bận đột xuất',
    'Khác',
  ];

  @override
  void dispose() {
    _ownerChanges?.cancel();
    _tokenChanges?.cancel();
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_current) {
      return _readState(
        context.l10n.uiYourSessionHasChangedOpenTicketDetailsAgain,
      );
    }
    if (_loadingQuote) {
      return _readState(context.l10n.uiLoadingCurrentCancellationFee);
    }
    if (_readError != null) return _readState(_readError!, retry: true);
    final ticket = _ticket;
    final quote = ticket.cancellation;
    final canCancel = hasUsableCancellationQuote(ticket);
    final cancelFeeRate = (quote?.cancelFeeRate.isFinite ?? false)
        ? quote!.cancelFeeRate
        : 0.0;
    final cancellationFee = quote?.cancelFee ?? 0;
    final refundAmount = quote?.refundAmount ?? 0;
    final feePercent = (cancelFeeRate * 100).round();

    return Container(
      decoration: const BoxDecoration(
        color: DiscoveryColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.base,
        AppDimensions.base,
        AppDimensions.base,
        MediaQuery.of(context).viewInsets.bottom + AppDimensions.base,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DiscoveryColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.base),

              // Title and Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: canCancel
                          ? DiscoveryColors.errorLight
                          : DiscoveryColors.warningLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      canCancel
                          ? Icons.cancel_outlined
                          : Icons.warning_amber_rounded,
                      color: canCancel
                          ? DiscoveryColors.error
                          : DiscoveryColors.warningDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          canCancel
                              ? context.l10n.uiCancelBusTicket
                              : context.l10n.uiUnableToCancelTicket,
                          style: DiscoveryTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: DiscoveryColors.neutral900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.uiTicketCode628257(ticket.ticketCode),
                          style: DiscoveryTextStyles.caption.copyWith(
                            color: DiscoveryColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: context.l10n.uiClose,
                    onPressed: () => _closeIfCurrent(),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.base),

              if (_operationError != null) ...[
                Text(
                  localizedClientLabel(context, _operationError!),
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    color: DiscoveryColors.error,
                  ),
                ),
                if (_uncertain)
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            if (!_current) return;
                            setState(() => _isSubmitting = true);
                            widget.bloc.add(CheckCancellationEvent(ticket.id));
                          },
                    child: Text(context.l10n.uiCheckStatus),
                  ),
                const SizedBox(height: 12),
              ],
              // Ticket Summary Strip
              Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: BoxDecoration(
                  color: DiscoveryColors.neutral50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DiscoveryColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_bus_rounded,
                          size: 16,
                          color: DiscoveryColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${ticket.trip.operatorName} · ${ticket.trip.vehicleType}',
                            style: DiscoveryTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: DiscoveryColors.neutral700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.ui56e768(
                        ticket.trip.fromCity,
                        ticket.trip.toCity,
                      ),
                      style: DiscoveryTextStyles.h4.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DiscoveryColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${ticket.trip.departureTime} · ${ticket.trip.departureDate}',
                          style: DiscoveryTextStyles.bodySmall.copyWith(
                            color: DiscoveryColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          context.l10n.uiSeatscfb411(ticket.seats.join(', ')),
                          style: DiscoveryTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: DiscoveryColors.neutral800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.base),

              // CASE 1: Cannot Cancel
              if (!canCancel) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.base),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.errorLight.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DiscoveryColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: DiscoveryColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context
                                  .l10n
                                  .uiThisTicketIsNotEligibleForOnlineCancellation,
                              style: DiscoveryTextStyles.bodyMedium.copyWith(
                                color: DiscoveryColors.errorDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizedClientLabel(
                          context,
                          cancellationReasonText(quote?.reason),
                        ),
                        style: DiscoveryTextStyles.bodySmall.copyWith(
                          color: DiscoveryColors.neutral800,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.uiThisTripDepartsAtOnContactTheOperator(
                          ticket.trip.departureTime,
                          ticket.trip.departureDate,
                        ),
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.errorDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                if (ticket.driverPhone != null &&
                    ticket.driverPhone!.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: DiscoveryColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: DiscoveryColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone_rounded,
                          size: 18,
                          color: DiscoveryColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.uiContactPhone(ticket.driverPhone!),
                            style: DiscoveryTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: DiscoveryColors.neutral900,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            if (!_current) return;
                            await Clipboard.setData(
                              ClipboardData(text: ticket.driverPhone!),
                            );
                            if (!context.mounted || !_current) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.l10n.uiContactNumberCopied,
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(context.l10n.uiCopy),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppDimensions.lg),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _closeIfCurrent(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(context.l10n.uiGotItClose),
                  ),
                ),
              ],

              // CASE 2: Can Cancel
              if (canCancel) ...[
                // Refund Breakdown Card
                Container(
                  padding: const EdgeInsets.all(AppDimensions.base),
                  decoration: BoxDecoration(
                    color: DiscoveryColors.neutral50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DiscoveryColors.neutral200),
                  ),
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 260;
                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.isPaid
                                      ? context.l10n.uiTicketAmountPaid
                                      : context.l10n.uiTicketValue,
                                  style: DiscoveryTextStyles.bodySmall.copyWith(
                                    color: DiscoveryColors.neutral700,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(ticket.finalAmount),
                                  style: DiscoveryTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: DiscoveryColors.neutral900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  context.l10n.uiCancellationFee(feePercent),
                                  style: DiscoveryTextStyles.caption.copyWith(
                                    color: DiscoveryColors.error,
                                  ),
                                ),
                                Text(
                                  '- ${CurrencyFormatter.format(cancellationFee)}',
                                  style: DiscoveryTextStyles.caption.copyWith(
                                    color: DiscoveryColors.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Divider(
                                  height: 16,
                                  color: DiscoveryColors.divider,
                                ),
                                Text(
                                  context.l10n.uiEstimatedRefundAmount,
                                  style: DiscoveryTextStyles.bodyMedium
                                      .copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: DiscoveryColors.neutral900,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(refundAmount),
                                  style: DiscoveryTextStyles.h4.copyWith(
                                    color: DiscoveryColors.successDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      ticket.isPaid
                                          ? context.l10n.uiTicketAmountPaid
                                          : context.l10n.uiTicketValue,
                                      style: DiscoveryTextStyles.bodySmall
                                          .copyWith(
                                            color: DiscoveryColors.neutral700,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    CurrencyFormatter.format(
                                      ticket.finalAmount,
                                    ),
                                    style: DiscoveryTextStyles.bodySmall
                                        .copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: DiscoveryColors.neutral900,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      context.l10n.uiCancellationFee(
                                        feePercent,
                                      ),
                                      style: DiscoveryTextStyles.caption
                                          .copyWith(
                                            color: DiscoveryColors.error,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '- ${CurrencyFormatter.format(cancellationFee)}',
                                    style: DiscoveryTextStyles.caption.copyWith(
                                      color: DiscoveryColors.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                height: 16,
                                color: DiscoveryColors.divider,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      context.l10n.uiEstimatedRefundAmount,
                                      style: DiscoveryTextStyles.bodyMedium
                                          .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: DiscoveryColors.neutral900,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    CurrencyFormatter.format(refundAmount),
                                    style: DiscoveryTextStyles.h4.copyWith(
                                      color: DiscoveryColors.successDark,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: DiscoveryColors.neutral100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: DiscoveryColors.neutral600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context
                                    .l10n
                                    .uiOnlineRefundsAreNotAvailableAfterCancellingContact,
                                style: DiscoveryTextStyles.caption.copyWith(
                                  color: DiscoveryColors.neutral600,
                                  fontSize: 11,
                                  height: 1.3,
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

                // Cancellation Reason
                Text(
                  context.l10n.uiSelectCancellationReason,
                  style: DiscoveryTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: DiscoveryColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                RadioGroup<String>(
                  groupValue: _selectedReason,
                  onChanged: (val) {
                    if (_isSubmitting || !_current) return;
                    if (val != null) setState(() => _selectedReason = val);
                  },
                  child: Column(
                    children: _reasons.map((r) {
                      return RadioListTile<String>(
                        value: r,
                        title: Text(
                          localizedClientLabel(context, r),
                          style: DiscoveryTextStyles.bodySmall,
                        ),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        activeColor: DiscoveryColors.primary,
                      );
                    }).toList(),
                  ),
                ),

                if (_selectedReason == 'Khác') ...[
                  const SizedBox(height: 4),
                  TextField(
                    controller: _customReasonController,
                    enabled: !_isSubmitting,
                    maxLength: 250,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: context.l10n.uiEnterASpecificReason,
                      hintText:
                          context.l10n.uiPleaseDescribeYourReasonForCancelling,
                      labelStyle: DiscoveryTextStyles.bodySmall,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppDimensions.xs),

                // Agreement checkbox
                CheckboxListTile(
                  value: _agreedToPolicy,
                  onChanged: (val) =>
                      setState(() => _agreedToPolicy = val ?? false),
                  title: Text(
                    context.l10n.uiIAgreeToCancelAndAcceptTheCancellation(
                      feePercent,
                      CurrencyFormatter.format(cancellationFee),
                    ),
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral800,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: DiscoveryColors.primary,
                ),

                const SizedBox(height: AppDimensions.base),

                // Action buttons
                LayoutBuilder(
                  builder: (context, constraints) {
                    final canSubmit =
                        _agreedToPolicy &&
                        !_isSubmitting &&
                        !_uncertain &&
                        widget.bloc.state.cancellationStatus !=
                            TicketCancellationStatus.submitting &&
                        (_selectedReason != 'Khác' ||
                            _customReasonController.text.trim().isNotEmpty);

                    final submitBtn = FilledButton(
                      onPressed: canSubmit
                          ? () {
                              if (_isSubmitting ||
                                  !_current ||
                                  _uncertain ||
                                  widget.bloc.state.cancellationStatus ==
                                      TicketCancellationStatus.submitting ||
                                  !sameCancellationQuote(ticket, _ticket)) {
                                return;
                              }
                              setState(() => _isSubmitting = true);

                              final effectiveReason = _selectedReason == 'Khác'
                                  ? _customReasonController.text.trim()
                                  : _selectedReason;

                              widget.bloc.add(
                                CancelTicketEvent(
                                  ticketId: ticket.id,
                                  reason: effectiveReason,
                                  refundAmount: refundAmount,
                                  quotedTicket: ticket,
                                  sessionGeneration: _session,
                                  tokenSessionVersion: _tokenVersion,
                                ),
                              );
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: DiscoveryColors.error,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: DiscoveryColors.neutral300,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              context.l10n.uiConfirmCancellation,
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    );

                    final cancelBtn = OutlinedButton(
                      onPressed: () => _closeIfCurrent(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(context.l10n.uiKeepTicketClose),
                    );

                    if (constraints.maxWidth < 280) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          submitBtn,
                          const SizedBox(height: AppDimensions.sm),
                          cancelBtn,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: cancelBtn),
                        const SizedBox(width: AppDimensions.sm),
                        Expanded(child: submitBtn),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
