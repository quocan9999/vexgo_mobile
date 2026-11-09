import 'package:vexgo_app/core/localization/client_labels.dart';
import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:vexgo_app/data/models/cargo_settlement.dart';
import 'booking_evidence_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../data/models/booking_receipt_model.dart';
import '../../../../data/repositories/booking_receipt_repository.dart';
import '../bloc/booking_receipt_cubit.dart';

class BookingReceiptScreen extends StatefulWidget {
  final ReceiptLookupRequest? initialRequest;
  const BookingReceiptScreen({super.key, this.initialRequest});
  @override
  State<BookingReceiptScreen> createState() => _BookingReceiptScreenState();
}

class _BookingReceiptScreenState extends State<BookingReceiptScreen>
    with WidgetsBindingObserver {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _phone;
  late final BookingReceiptCubit _reader;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final request = widget.initialRequest;
    final validRequest =
        !ApiConfig.isDemoMode &&
        (request == null ||
            request.sessionVersion == TokenStorage.sessionVersion);
    _code = TextEditingController(text: validRequest ? request?.code : null);
    _phone = TextEditingController(text: validRequest ? request?.phone : null);
    _reader = BookingReceiptCubit(context.read<BookingReceiptRepository>());
    if (!validRequest) {
      _reader.invalidate();
    } else if (_code.text.trim().isNotEmpty && _phone.text.trim().isNotEmpty) {
      _reader.lookup(_code.text, _phone.text);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _reader.state.status == ReceiptStatus.loaded) {
      _reader.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reader.close();
    _code.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _lookup() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _reader.lookup(_code.text, _phone.text);
  }

  @override
  Widget build(BuildContext context) => ApiConfig.isDemoMode
      ? Scaffold(
          appBar: CustomAppBar(title: context.l10n.uiPaymentReceipt),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                context.l10n.uiReceiptLookupIsAvailableOnlyWhenConnectedTo,
              ),
            ),
          ),
        )
      : Scaffold(
          backgroundColor: AppColors.background,
          appBar: CustomAppBar(title: context.l10n.uiPaymentReceipt),
          body: BlocConsumer<BookingReceiptCubit, BookingReceiptState>(
            bloc: _reader,
            listener: (_, state) {
              if (state.status == ReceiptStatus.invalidated) {
                _code.clear();
                _phone.clear();
              }
            },
            builder: (context, state) {
              final invalid =
                  !_reader.isCurrent ||
                  state.status == ReceiptStatus.invalidated;
              final busy = state.status == ReceiptStatus.loading;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    context.l10n.uiLookUpBookingReceipt,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(context.l10n.uiEnterTheTicketOrBookingCodeAndBooking),
                  const SizedBox(height: 16),
                  Form(
                    key: _form,
                    child: Column(
                      children: [
                        TextFormField(
                          key: const Key('receipt-code'),
                          controller: _code,
                          enabled: !busy && !invalid,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: context.l10n.uiTicketOrBookingCode,
                          ),
                          onChanged: (_) => _reader.clear(),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? context.l10n.uiEnterATicketOrBookingCode
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('receipt-phone'),
                          controller: _phone,
                          enabled: !busy && !invalid,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: context.l10n.uiBookingPhoneNumber,
                          ),
                          onChanged: (_) => _reader.clear(),
                          validator: (value) =>
                              RegExp(
                                r'^(?:\+84|0)(?:3[2-9]|5[689]|7[06-9]|8[1-9]|9\d)\d{7}$',
                              ).hasMatch(value?.trim() ?? '')
                              ? null
                              : context.l10n.uiInvalidPhoneNumber,
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: context.l10n.uiLookUpReceipt,
                          isLoading: busy,
                          onPressed: invalid || busy ? null : _lookup,
                          width: double.infinity,
                        ),
                      ],
                    ),
                  ),
                  if (state.error != null || invalid)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          localizedClientLabel(
                            context,
                            invalid
                                ? context
                                      .l10n
                                      .uiYourSessionHasChangedCloseAndReopenReceipt
                                : state.error!,
                          ),
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  if (state.status == ReceiptStatus.failure && !invalid)
                    TextButton(
                      onPressed: _lookup,
                      child: Text(context.l10n.uiTryAgain),
                    ),
                  if (state.receipt != null && !invalid) ...[
                    const SizedBox(height: 20),
                    _ReceiptContent(state.receipt!),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _reader.refresh,
                      child: Text(context.l10n.uiRefreshReceipt),
                    ),
                  ],
                ],
              );
            },
          ),
        );
}

class _ReceiptContent extends StatelessWidget {
  final BookingReceipt receipt;
  const _ReceiptContent(this.receipt);
  String display(String value) =>
      value.isEmpty ? LocaleController.strings.uiNotProvided05547c : value;
  String date(DateTime value) => DateFormat(
    'HH:mm dd/MM/yyyy',
  ).format(value.toUtc().add(const Duration(hours: 7)));
  Widget row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.neutral600, fontSize: 12),
        ),
        SelectableText(display(value)),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.uiPaid,
            style: TextStyle(
              color: AppColors.successDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          row(context.l10n.uiBookingCoded4f872, receipt.bookingCode),
          row(context.l10n.uiTransactionCode, receipt.orderCode),
          row(context.l10n.uiBookingDateVietnamTime, date(receipt.createdAt)),
          const Divider(),
          row(context.l10n.uiPassengerbd8a66, receipt.passengerName),
          row(context.l10n.uiPhoneNumber, receipt.passengerPhone),
          if (receipt.passengerEmail.isNotEmpty)
            row('Email', receipt.passengerEmail),
          const Divider(),
          row(context.l10n.uiBusOperator, receipt.company),
          row(context.l10n.uiRoute, receipt.route),
          row(context.l10n.uiVehicleType9fc822, receipt.vehicle),
          if (receipt.departureAt != null)
            row(
              context.l10n.uiDepartureVietnamTime,
              date(receipt.departureAt!),
            ),
          row(context.l10n.uiPickUpcdcaa5, receipt.pickup),
          StopSnapshotDetails(
            snapshot: receipt.pickupSnapshot,
            departure: receipt.departureAt,
            pickup: true,
            showAddress: true,
          ),
          row(context.l10n.uiDropOffa7cf52, receipt.dropoff),
          StopSnapshotDetails(
            snapshot: receipt.dropoffSnapshot,
            departure: receipt.departureAt,
            pickup: false,
            showAddress: true,
          ),
          const Divider(),
          Text(
            context.l10n.uiTicketsInBooking(receipt.tickets.length),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final ticket in receipt.tickets)
            row(
              context.l10n.uiSeatba07d4(
                display(ticket.seat),
                switch (ticket.status) {
                  'DA_THANH_TOAN' => context.l10n.uiPaid,
                  'DA_DAT' => context.l10n.uiBooked,
                  'HOAN_TAT' || 'DA_SU_DUNG' => context.l10n.uiUsed,
                  'HUY' || 'DA_HUY' => context.l10n.uiCancelled,
                  _ => context.l10n.uiTicketStatusUnverified,
                },
              ),
              '${ticket.code}\n${CurrencyFormatter.format(ticket.price)}',
            ),
          if (receipt.cargo.isNotEmpty) ...[
            const Divider(),
            OrderCargoDetails(
              items: receipt.cargo,
              showFee: false,
              settlement: receipt.cargoPayment,
            ),
          ],
          const Divider(),
          row(
            context.l10n.uiFareBeforeDiscounts,
            CurrencyFormatter.format(receipt.originalSubtotal),
          ),
          if (receipt.promotionCode.isNotEmpty)
            row(context.l10n.uiPromoCode5683b7, receipt.promotionCode),
          row(
            context.l10n.uiDiscount,
            CurrencyFormatter.format(receipt.discount),
          ),
          row(
            context.l10n.uiFareAfterDiscounts4a0d51,
            CurrencyFormatter.format(receipt.ticketSubtotal),
          ),
          row(
            cargoSettlementLabel(receipt.cargoPayment),
            CurrencyFormatter.format(receipt.cargoFee),
          ),
          row(
            context.l10n.uiTotalPayment43f8d6,
            CurrencyFormatter.format(receipt.total),
          ),
          row(context.l10n.uiPaymentMethodc216d3, receipt.paymentMethod),
          const SizedBox(height: 12),
          Text(
            context.l10n.uiThisIsABookingPaymentReceiptNotA,
            style: TextStyle(fontSize: 12, color: AppColors.neutral600),
          ),
        ],
      ),
    ),
  );
}
