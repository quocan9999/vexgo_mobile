import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:vexgo_app/data/models/cargo_settlement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/data/models/booking_cargo_model.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/bloc/luggage_cubit.dart';
import '../widgets/booking_cargo_section_card.dart';
import '../widgets/booking_luggage_section_card.dart';
import '../widgets/seat_hold_countdown_bar.dart';
import '../widgets/voucher_selection_sheet.dart';
import '../widgets/promotion_code_sheet.dart';

class Step5TripSummary extends StatelessWidget {
  final BookingFlowState state;
  final BookingFlowBloc bloc;
  final bool showInlineCountdown;
  final LuggageCubit? luggageCubit;
  final String? luggageSeatChangeNotice;
  final VoidCallback? onDismissLuggageSeatChangeNotice;
  final Future<void> Function(BookingCargoDraft? draft)? onSyncBookingCargo;

  const Step5TripSummary({
    super.key,
    required this.state,
    required this.bloc,
    this.showInlineCountdown = false,
    this.luggageCubit,
    this.luggageSeatChangeNotice,
    this.onDismissLuggageSeatChangeNotice,
    this.onSyncBookingCargo,
  });

  @override
  Widget build(BuildContext context) {
    final trip = state.trip;
    final dateStr = state.date != null
        ? DateFormatter.formatFullDate(state.date!)
        : '';
    final seatNames = state.selectedSeats.map((s) => s.name).join(', ');
    final promotionCode = state.requestedPromotionCode.trim().toUpperCase();
    final promotionAccepted = state.requiresAuthoritativeQuote
        ? state.hasUsableQuote &&
              promotionCode.isNotEmpty &&
              state.quote?.appliedPromotionCode?.toUpperCase() == promotionCode
        : state.appliedVoucher != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showInlineCountdown && state.seatHold != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SeatHoldCountdownBar(
                remainingSeconds: state.countdownSeconds,
                compact: true,
                seatCodes: state.selectedSeats.map((s) => s.name).toList(),
              ),
            ),

          if (state.quoteLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LinearProgressIndicator(
                    color: DiscoveryColors.primary,
                    backgroundColor: DiscoveryColors.primaryLight,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.uiUpdatingFaresOffers,
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),

          if (state.quoteError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DiscoveryColors.errorLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DiscoveryColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: DiscoveryColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.quoteError!,
                          style: DiscoveryTextStyles.bodySmall.copyWith(
                            color: DiscoveryColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: state.quoteLoading
                              ? null
                              : () =>
                                    bloc.add(const RefreshBookingQuoteEvent()),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.refresh_rounded,
                                size: 16,
                                color: DiscoveryColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.l10n.uiUpdateFare,
                                style: DiscoveryTextStyles.caption.copyWith(
                                  color: DiscoveryColors.primary,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
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

          // Section Title
          Text(context.l10n.uiReviewYourBooking, style: DiscoveryTextStyles.h4),
          const SizedBox(height: 4),
          Text(
            context.l10n.uiCheckYourJourneyAndPassengerDetailsBeforeProceeding,
            style: DiscoveryTextStyles.caption.copyWith(
              color: DiscoveryColors.neutral500,
            ),
          ),
          const SizedBox(height: 14),

          // 1. Trip & Route Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final stack = constraints.maxWidth < 280 && textScale > 1.3;

                    final titleSection = Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip?.operatorName ??
                                    context.l10n.uiBusOperator,
                                style: DiscoveryTextStyles.titleMedium.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${trip?.vehicleType ?? ""} • $dateStr',
                                style: DiscoveryTextStyles.caption.copyWith(
                                  color: DiscoveryColors.neutral500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final editBtn = _buildEditButton(
                      label: context.l10n.uiEditPickUpDropOff,
                      onPressed: state.isCheckoutLocked
                          ? null
                          : () => bloc.add(const GoToStepEvent(1)),
                    );

                    if (stack) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [titleSection, editBtn],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: titleSection),
                        const SizedBox(width: 8),
                        editBtn,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: DiscoveryColors.divider),
                const SizedBox(height: 12),

                // Pickup & Dropoff timeline
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(
                          Icons.radio_button_checked,
                          size: 16,
                          color: DiscoveryColors.primary,
                        ),
                        Container(
                          width: 2,
                          height: 38,
                          color: DiscoveryColors.neutral300,
                        ),
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: DiscoveryColors.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pickup
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 48,
                                child: Text(
                                  state.selectedPickupPoint?.time ??
                                      trip?.departureTime ??
                                      '',
                                  style: DiscoveryTextStyles.bodyMedium
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.selectedPickupPoint?.name ??
                                          trip?.pickupPoint ??
                                          '',
                                      style: DiscoveryTextStyles.bodyMedium
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      state.selectedPickupPoint?.address ??
                                          trip?.pickupAddress ??
                                          '',
                                      style: DiscoveryTextStyles.caption
                                          .copyWith(
                                            color: DiscoveryColors.neutral500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Dropoff
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 48,
                                child: Text(
                                  state.selectedDropoffPoint?.time ??
                                      trip?.arrivalTime ??
                                      '',
                                  style: DiscoveryTextStyles.bodyMedium
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.selectedDropoffPoint?.name ??
                                          trip?.dropoffPoint ??
                                          '',
                                      style: DiscoveryTextStyles.bodyMedium
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      state.selectedDropoffPoint?.address ??
                                          trip?.dropoffAddress ??
                                          '',
                                      style: DiscoveryTextStyles.caption
                                          .copyWith(
                                            color: DiscoveryColors.neutral500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Seats Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final stack = constraints.maxWidth < 280 && textScale > 1.3;

                    final titleSection = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: DiscoveryColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.airline_seat_recline_extra_rounded,
                            color: DiscoveryColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            context.l10n.uiSelectedSeats,
                            overflow: TextOverflow.ellipsis,
                            style: DiscoveryTextStyles.titleMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DiscoveryColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            context.l10n.uiSeats4f4448(
                              state.selectedSeats.length,
                            ),
                            style: DiscoveryTextStyles.caption.copyWith(
                              color: DiscoveryColors.primaryDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    );

                    final editBtn = _buildEditButton(
                      label: context.l10n.uiChangeSeats,
                      onPressed: state.isCheckoutLocked
                          ? null
                          : () => bloc.add(const GoToStepEvent(0)),
                    );

                    if (stack) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [titleSection, editBtn],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: titleSection),
                        const SizedBox(width: 8),
                        editBtn,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: DiscoveryColors.divider),
                const SizedBox(height: 10),

                // Seat Chips list
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final seat in state.selectedSeats)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: DiscoveryColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: DiscoveryColors.primary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              seat.name,
                              style: DiscoveryTextStyles.bodySmall.copyWith(
                                color: DiscoveryColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (seat.price != null && seat.price! > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${seat.price! ~/ 1000}k)',
                                style: DiscoveryTextStyles.caption.copyWith(
                                  color: DiscoveryColors.neutral600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
                // Expose explicit comma-separated text string for accessibility and test matchers
                Semantics(
                  label: context.l10n.uiSeats9c637d(seatNames),
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        context.l10n.uiSeatLocations(seatNames),
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.neutral500,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Passenger Info Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final stack = constraints.maxWidth < 280 && textScale > 1.3;

                    final titleSection = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: DiscoveryColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: DiscoveryColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            context.l10n.uiPassengerInformation,
                            overflow: TextOverflow.ellipsis,
                            style: DiscoveryTextStyles.titleMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    );

                    final editBtn = _buildEditButton(
                      label: context.l10n.uiEdit,
                      onPressed: state.isCheckoutLocked
                          ? null
                          : () => bloc.add(const GoToStepEvent(3)),
                    );

                    if (stack) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [titleSection, editBtn],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: titleSection),
                        const SizedBox(width: 8),
                        editBtn,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: DiscoveryColors.divider),
                const SizedBox(height: 10),

                _buildRowInfo(
                  icon: Icons.person_rounded,
                  label: context.l10n.uiFullName3da3c8,
                  value: state.passengerName.isNotEmpty
                      ? state.passengerName
                      : context.l10n.uiNotEntered,
                  isBold: true,
                ),
                const SizedBox(height: 8),
                _buildRowInfo(
                  icon: Icons.phone_iphone_rounded,
                  label: context.l10n.uiPhoneNumber,
                  value: state.passengerPhone.isNotEmpty
                      ? state.passengerPhone
                      : context.l10n.uiNotEntered,
                ),
                const SizedBox(height: 8),
                _buildRowInfo(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: state.passengerEmail.isNotEmpty
                      ? state.passengerEmail
                      : context.l10n.uiNotProvidedOptional,
                  valueColor: state.passengerEmail.isNotEmpty
                      ? null
                      : DiscoveryColors.neutral500,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3b. Luggage / Cargo Card
          if (luggageCubit != null)
            BookingLuggageSectionCard(
              cubit: luggageCubit!,
              locked: state.isCheckoutLocked,
              scopeKey: 'oneway',
              seatChangeNotice: luggageSeatChangeNotice,
              onDismissSeatChangeNotice: onDismissLuggageSeatChangeNotice,
              onSyncBookingCargo: onSyncBookingCargo,
            )
          else
            BookingCargoSectionCard(
              cargo: state.cargo,
              locked: state.isCheckoutLocked,
              scopeKey: 'oneway',
              onToggleEnabled: (enabled) =>
                  bloc.add(SetBookingCargoEnabledEvent(enabled)),
              onRefresh: () => bloc.add(const RefreshBookingCargoEvent()),
              onUpdateDraft: (draft) =>
                  bloc.add(UpdateBookingCargoEvent(draft)),
            ),
          const SizedBox(height: 12),

          // 4. Voucher / Promotion Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.secondaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.discount_outlined,
                        color: DiscoveryColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.uiPromoCodesOffers,
                        style: DiscoveryTextStyles.titleMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: DiscoveryColors.divider),
                const SizedBox(height: 10),

                if (!promotionAccepted && promotionCode.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      state.quoteLoading
                          ? context.l10n.uiCheckingCode(promotionCode)
                          : context.l10n.uiCodeNotConfirmed(promotionCode),
                      style: DiscoveryTextStyles.bodySmall,
                    ),
                  ),
                if (promotionAccepted)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DiscoveryColors.successLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: DiscoveryColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: DiscoveryColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.uiAppliedCode(
                                  state.appliedVoucher?.code ??
                                      state.requestedPromotionCode,
                                ),
                                style: DiscoveryTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: DiscoveryColors.successDark,
                                ),
                              ),
                              Text(
                                state.discountAmount > 0
                                    ? context.l10n.uiYouSave(
                                        CurrencyFormatter.format(
                                          state.discountAmount,
                                        ),
                                      )
                                    : context.l10n.uiValidCode,
                                style: DiscoveryTextStyles.caption.copyWith(
                                  color: DiscoveryColors.successDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed:
                              state.isCheckoutLocked || state.quoteLoading
                              ? null
                              : () => bloc.add(const RemoveVoucherEvent()),
                          child: Text(
                            context.l10n.uiRemoveCode,
                            style: DiscoveryTextStyles.bodySmall.copyWith(
                              color: DiscoveryColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: state.isCheckoutLocked || state.quoteLoading
                        ? null
                        : () {
                            if (state.requiresAuthoritativeQuote) {
                              _enterPromotion(context);
                              return;
                            }
                            VoucherSelectionSheet.show(
                              context,
                              vouchers: state.availableVouchers,
                              currentVoucher: state.appliedVoucher,
                              currentOrderAmount: state.seatsTotalAmount ?? 0,
                              onVoucherSelected: (v) =>
                                  bloc.add(ApplyVoucherEvent(v)),
                              onVoucherRemoved: () =>
                                  bloc.add(const RemoveVoucherEvent()),
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.neutral50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DiscoveryColors.neutral300),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_offer_outlined,
                            size: 18,
                            color: DiscoveryColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.uiSelectOrEnterAPromoCode,
                                  style: DiscoveryTextStyles.bodyMedium
                                      .copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: DiscoveryColors.neutral800,
                                      ),
                                ),
                                Text(
                                  context.l10n.uiEnterACodeToCheckEligibility,
                                  style: DiscoveryTextStyles.caption.copyWith(
                                    color: DiscoveryColors.neutral500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: DiscoveryColors.neutral400,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 5. Price Breakdown Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: DiscoveryColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.uiPaymentDetails,
                        style: DiscoveryTextStyles.titleMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPriceRow(
                  label: context.l10n.uiFareSeats(state.selectedSeats.length),
                  value: state.quotedSubtotal != null
                      ? CurrencyFormatter.format(state.quotedSubtotal!)
                      : (state.seatsTotalAmount != null
                            ? CurrencyFormatter.format(state.seatsTotalAmount!)
                            : context.l10n.uiFareUnavailable),
                ),
                const SizedBox(height: 8),
                _buildPriceRow(
                  label: context.l10n.uiServiceFee,
                  value: state.quotedServiceFee == null
                      ? (state.requiresAuthoritativeQuote
                            ? context.l10n.uiVerifying
                            : context.l10n.uiFree)
                      : (state.quotedServiceFee == 0
                            ? context.l10n.uiFree
                            : CurrencyFormatter.format(
                                state.quotedServiceFee!,
                              )),
                  valueColor: DiscoveryColors.success,
                ),
                if (state.discountAmount > 0) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    label: context.l10n.uiPromotionalDiscount,
                    value: '-${CurrencyFormatter.format(state.discountAmount)}',
                    valueColor: DiscoveryColors.secondary,
                  ),
                ],
                if (luggageCubit != null)
                  BlocBuilder<LuggageCubit, LuggageState>(
                    bloc: luggageCubit,
                    builder: (context, _) {
                      final refFee = luggageCubit!.referenceFee;
                      if (refFee == null ||
                          refFee <= 0 ||
                          state.checkoutBooking?.shippingFee != null) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildPriceRow(
                          label: context.l10n.uiEstimatedLuggageFee,
                          value: context.l10n.uiNotAddedToBooking(
                            CurrencyFormatter.format(refFee),
                          ),
                          valueColor: DiscoveryColors.neutral700,
                        ),
                      );
                    },
                  ),
                if (BookingCargoSummaryBox.hasCargo(state: state)) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    label: context.l10n.uiFareAfterDiscounts,
                    value: state.ticketFinalAmount != null
                        ? CurrencyFormatter.format(state.ticketFinalAmount!)
                        : context.l10n.uiFareUnavailable,
                  ),
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    label: cargoSettlementLabel(
                      state.checkoutBooking?.cargoPayment ??
                          CargoSettlement.atStation,
                    ),
                    value: state.checkoutBooking?.shippingFee != null
                        ? CurrencyFormatter.format(
                            state.checkoutBooking!.shippingFee!,
                          )
                        : context.l10n.uiItemFeesArePaidSeparatelyAtTheStation,
                    valueColor: state.checkoutBooking?.shippingFee != null
                        ? DiscoveryColors.neutral900
                        : DiscoveryColors.secondary,
                  ),
                ],
                const SizedBox(height: 10),
                const Divider(height: 1, color: DiscoveryColors.divider),
                const SizedBox(height: 10),
                _buildPriceRow(
                  label: context.l10n.uiTotalDue,
                  value: state.finalAmount != null
                      ? CurrencyFormatter.format(state.finalAmount!)
                      : (state.cargo.enabled
                            ? context.l10n.uiCalculatedWhenBookingIsCreated
                            : context.l10n.uiFareUnavailable),
                  valueColor: DiscoveryColors.secondary,
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 6. Guarantee Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DiscoveryColors.successLight.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DiscoveryColors.success.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: DiscoveryColors.success,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.uiFaresAndOffersAreConfirmedBasedOnYour,
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enterPromotion(BuildContext context) =>
      PromotionCodeSheet.show(context, bloc);

  Widget _buildEditButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: DiscoveryColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(48, 48),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: DiscoveryTextStyles.bodySmall.copyWith(
          color: DiscoveryColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DiscoveryColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildRowInfo({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    double labelWidth = 90,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Icon(icon, size: 16, color: DiscoveryColors.neutral500),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: DiscoveryTextStyles.bodySmall.copyWith(
              color: DiscoveryColors.neutral600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: DiscoveryTextStyles.bodySmall.copyWith(
              color: valueColor ?? DiscoveryColors.neutral900,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isTotal = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stack = constraints.maxWidth < 280 && textScale > 1.3;

        final labelWidget = Text(
          label,
          style: isTotal
              ? DiscoveryTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                )
              : DiscoveryTextStyles.bodySmall.copyWith(
                  color: DiscoveryColors.neutral600,
                ),
        );

        final valueWidget = Text(
          value,
          textAlign: stack ? TextAlign.start : TextAlign.end,
          style: isTotal
              ? DiscoveryTextStyles.titleMedium.copyWith(
                  color: valueColor ?? DiscoveryColors.secondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                )
              : DiscoveryTextStyles.bodySmall.copyWith(
                  color: valueColor ?? DiscoveryColors.neutral900,
                  fontWeight: FontWeight.w600,
                ),
        );

        if (stack) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelWidget, const SizedBox(height: 2), valueWidget],
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: labelWidget),
            const SizedBox(width: 8),
            Flexible(child: valueWidget),
          ],
        );
      },
    );
  }
}
