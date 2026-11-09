import 'package:vexgo_app/core/localization/client_labels.dart';
import 'package:vexgo_app/core/localization/locale_controller.dart';
import '../../../booking/presentation/widgets/booking_rate_limit_view.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/app/routes.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/booking_cargo_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/cargo_repository.dart';
import 'package:vexgo_app/data/repositories/luggage_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/bloc/luggage_cubit.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/seat_legend.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/seat_map_view.dart';
import 'package:vexgo_app/features/user/booking/presentation/widgets/stop_point_selection.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_checkout_cubit.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';
import '../widgets/round_trip_leg_header.dart';
import '../widgets/round_trip_passenger_step.dart';
import '../widgets/round_trip_payment_view.dart';
import '../widgets/round_trip_success_view.dart';
import '../widgets/round_trip_summary_step.dart';

class RoundTripBookingScreen extends StatelessWidget {
  final RoundTripSelection? selection;
  final RoundTripCheckoutCubit? cubit;
  final LuggageRepository? luggageRepository;
  final DateTime Function()? now;

  const RoundTripBookingScreen({
    super.key,
    required this.selection,
    this.cubit,
    this.luggageRepository,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    if (selection == null) {
      return DiscoveryTheme(
        child: Scaffold(
          backgroundColor: DiscoveryColors.background,
          appBar: AppBar(
            backgroundColor: DiscoveryColors.header,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.home),
            ),
            title: Text(
              context.l10n.uiBookARoundTrip,
              style: DiscoveryTextStyles.titleMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 56,
                    color: DiscoveryColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.uiTripDetailsMissing,
                    style: DiscoveryTextStyles.h1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.uiTheSelectedTripPairCouldNotBeFound,
                    style: DiscoveryTextStyles.bodyMedium.copyWith(
                      color: DiscoveryColors.neutral600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DiscoveryColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(180, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.home),
                    child: Text(context.l10n.uiBackToSearch),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final view = _RoundTripBookingView(
      selection: selection!,
      luggageRepository: luggageRepository,
      now: now,
    );
    return DiscoveryTheme(
      child: cubit != null
          ? BlocProvider<RoundTripCheckoutCubit>.value(
              value: cubit!,
              child: view,
            )
          : BlocProvider<RoundTripCheckoutCubit>(
              create: (context) {
                final c = RoundTripCheckoutCubit(
                  request: selection!.request,
                  outbound: selection!.outbound,
                  inbound: selection!.inbound,
                  seatRepository: context.read<SeatRepository>(),
                  bookingRepository: context.read<BookingRepository>(),
                  cargoRepository: context.read<CargoRepository?>(),
                );
                // Hydrate user info from AuthBloc if logged in
                final auth = context.read<AuthBloc?>()?.state;
                if (auth != null && auth.isAuthenticated && auth.user != null) {
                  final u = auth.user!;
                  c.updatePassenger(
                    UpdatePassengerInfoEvent(
                      name: u.hoTen,
                      phone: u.soDienThoai,
                      email: u.email ?? '',
                    ),
                  );
                }
                return c;
              },
              child: view,
            ),
    );
  }
}

class _RoundTripBookingView extends StatefulWidget {
  final RoundTripSelection selection;
  final LuggageRepository? luggageRepository;
  final DateTime Function()? now;

  const _RoundTripBookingView({
    required this.selection,
    this.luggageRepository,
    this.now,
  });

  @override
  State<_RoundTripBookingView> createState() => _RoundTripBookingViewState();
}

class _RoundTripBookingViewState extends State<_RoundTripBookingView> {
  TripLeg _activeLeg = TripLeg.outbound;
  final Map<TripLeg, LuggageCubit?> _luggageCubits = {};
  final Map<TripLeg, int?> _luggageTripIds = {};
  final Map<TripLeg, int?> _luggagePassengerCounts = {};
  final Map<TripLeg, int?> _luggageSessionVersions = {};
  final Map<TripLeg, String?> _luggageSeatChangeNotices = {};

  @override
  void dispose() {
    for (final c in _luggageCubits.values) {
      c?.close();
    }
    super.dispose();
  }

  LuggageRepository _resolveLuggageRepository(BuildContext context) {
    return widget.luggageRepository ??
        context.read<LuggageRepository?>() ??
        RealLuggageRepository(
          cargoRepository: context.read<CargoRepository?>(),
        );
  }

  void _ensureLegLuggageCubits(
    RoundTripCheckoutCubit checkoutCubit,
    RoundTripCheckoutState state,
  ) {
    final sessionVersion = TokenStorage.sessionVersion;
    for (final leg in TripLeg.values) {
      final legState = state.leg(leg);
      final tripId =
          legState.trip?.numericTripId ?? int.tryParse(legState.trip?.id ?? '');
      final passengerCount = legState.selectedSeats.length;

      if (tripId == null ||
          tripId <= 0 ||
          passengerCount < 1 ||
          passengerCount > 5) {
        if (_luggageCubits[leg] != null) {
          unawaited(_luggageCubits[leg]!.close());
          _luggageCubits[leg] = null;
          _luggageTripIds[leg] = null;
          _luggagePassengerCounts[leg] = null;
        }
        continue;
      }

      if (_luggageCubits[leg] != null &&
          _luggageTripIds[leg] == tripId &&
          _luggagePassengerCounts[leg] == passengerCount &&
          _luggageSessionVersions[leg] == sessionVersion) {
        continue;
      }

      if (_luggageCubits[leg] != null) {
        final oldCubit = _luggageCubits[leg]!;
        final hadLuggage =
            oldCubit.state.phase != LuggagePhase.idle ||
            oldCubit.state.selection.carryOn.isNotEmpty ||
            oldCubit.state.selection.checked.isNotEmpty ||
            legState.cargo.enabled;
        if (_luggageTripIds[leg] == tripId &&
            _luggagePassengerCounts[leg] != null &&
            _luggagePassengerCounts[leg] != passengerCount &&
            hadLuggage) {
          _luggageSeatChangeNotices[leg] = context.l10n
              .uiSeatCountForChangedPassengersCheckTheLuggage(
                leg == TripLeg.outbound
                    ? context.l10n.uiOutbound
                    : context.l10n.uiReturn,
                _luggagePassengerCounts[leg] ?? 0,
                passengerCount,
              );
          if (legState.cargo.enabled && !legState.isCheckoutLocked) {
            checkoutCubit.dispatch(
              leg,
              const SetBookingCargoEnabledEvent(false),
            );
          }
        }
        unawaited(oldCubit.close());
      }

      _luggageTripIds[leg] = tripId;
      _luggagePassengerCounts[leg] = passengerCount;
      _luggageSessionVersions[leg] = sessionVersion;
      _luggageCubits[leg] = LuggageCubit(
        tripId: tripId,
        passengerCount: passengerCount,
        repository: _resolveLuggageRepository(context),
        now: widget.now,
      );
    }
  }

  Future<void> _syncLegLuggage(
    RoundTripCheckoutCubit checkoutCubit,
    TripLeg leg,
    BookingCargoDraft? _,
  ) async {
    final legCubit = _luggageCubits[leg];
    final legState = checkoutCubit.state.leg(leg);
    final tripId =
        legState.trip?.numericTripId ?? int.tryParse(legState.trip?.id ?? '');
    final passengerCount = legState.selectedSeats.length;
    if (legCubit == null || tripId == null || passengerCount < 1) return;
    final draft = legCubit.exportForBooking(
      expectedTripId: tripId,
      expectedPassengerCount: passengerCount,
    );
    checkoutCubit.dispatch(
      leg,
      SetBookingCargoEnabledEvent(draft != null, initialDraft: draft),
    );
    while (!checkoutCubit.isClosed && checkoutCubit.state.busy) {
      await Future<void>.delayed(const Duration(milliseconds: 15));
    }
  }

  Future<bool> _handlePop(
    BuildContext context,
    RoundTripCheckoutState state,
  ) async {
    final cubit = context.read<RoundTripCheckoutCubit>();
    if (state.busy) return false;

    // After orders are created: confirm without auto cancelling
    if (state.hasAnyOrder) {
      final exit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.uiLeavePayment),
          content: Text(
            context.l10n.uiYourBookingHasBeenRecordedLeavingWillNot,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(context.l10n.uiStay),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                context.l10n.uiLeave,
                style: TextStyle(color: DiscoveryColors.error),
              ),
            ),
          ],
        ),
      );
      return exit ?? false;
    }

    // Step backwards through the flow
    final bothAtSummaryOrPayment =
        state.outbound.step.index >= BookingStep.tripSummary.index &&
        state.inbound.step.index >= BookingStep.tripSummary.index;
    if (bothAtSummaryOrPayment) {
      if (state.outbound.pendingBookingId == null) {
        cubit.dispatch(
          TripLeg.outbound,
          GoToStepEvent(BookingStep.passengerInfo.index),
        );
      }
      if (state.inbound.pendingBookingId == null) {
        cubit.dispatch(
          TripLeg.inbound,
          GoToStepEvent(BookingStep.passengerInfo.index),
        );
      }
      return false;
    }

    final bothAtPassenger =
        state.outbound.step.index >= BookingStep.passengerInfo.index &&
        state.inbound.step.index >= BookingStep.passengerInfo.index;
    if (bothAtPassenger) {
      final targetLeg = state.leg(_activeLeg).pendingBookingId == null
          ? _activeLeg
          : (_activeLeg == TripLeg.outbound
                ? TripLeg.inbound
                : TripLeg.outbound);
      cubit.dispatch(targetLeg, GoToStepEvent(BookingStep.dropoffPoint.index));
      return false;
    }

    final activeState = state.leg(_activeLeg);
    if (activeState.step.index > 0) {
      cubit.dispatch(_activeLeg, const PreviousStepEvent());
      return false;
    }

    if (_activeLeg == TripLeg.inbound) {
      setState(() => _activeLeg = TripLeg.outbound);
      return false;
    }

    // At the very beginning of outbound: confirm release of holds
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.uiLeaveRoundTripBooking),
        content: Text(context.l10n.uiLeaveThisBookingYourHeldSeatsWillBea1380d),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.uiContinueBooking),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              context.l10n.uiLeave,
              style: TextStyle(color: DiscoveryColors.error),
            ),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  Future<void> _handleProceedToPayment(RoundTripCheckoutCubit cubit) async {
    for (final leg in TripLeg.values) {
      final legCubit = _luggageCubits[leg];
      if (legCubit != null &&
          cubit.state.leg(leg).pendingBookingId == null &&
          legCubit.state.phase == LuggagePhase.ready) {
        if (legCubit.validationError != null || !legCubit.policyIsFresh) {
          return;
        }
        await _syncLegLuggage(cubit, leg, null);
      }
    }

    if (cubit.state.outbound.pendingBookingId == null &&
        cubit.state.outbound.step == BookingStep.tripSummary) {
      cubit.dispatch(TripLeg.outbound, const NextStepEvent());
    }
    if (cubit.state.inbound.pendingBookingId == null &&
        cubit.state.inbound.step == BookingStep.tripSummary) {
      cubit.dispatch(TripLeg.inbound, const NextStepEvent());
    }

    // Wait until pending draft transitions settle
    while (!cubit.isClosed && cubit.state.busy) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    if (!cubit.isClosed &&
        cubit.state.outbound.step == BookingStep.payment &&
        cubit.state.inbound.step == BookingStep.payment) {
      await cubit.submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoundTripCheckoutCubit>();

    return BlocConsumer<RoundTripCheckoutCubit, RoundTripCheckoutState>(
      listener: (context, state) {
        if (state.error != null && state.rateLimit == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizedClientLabel(context, state.error!)),
              backgroundColor: DiscoveryColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.invalidated) {
          return _buildSessionInvalidatedView(context);
        }

        if (state.rateLimit != null) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final canExit = await _handlePop(context, state);
              if (canExit && context.mounted) Navigator.of(context).pop();
            },
            child: BookingRateLimitView(
              notice: state.rateLimit!,
              busy: state.busy,
              hasAnyOrder: state.hasAnyOrder,
              onResume: () => cubit.resumeAfterRateLimit(),
              onReviewOrders: () => context.push(AppRoutes.myTickets),
              onSupport: () => context.push(AppRoutes.supportChat),
            ),
          );
        }

        if (state.isComplete) {
          return RoundTripSuccessView(
            request: widget.selection.request,
            outbound: state.outbound,
            inbound: state.inbound,
            onOpenMyTickets: () => context.go(AppRoutes.myTickets),
            onOpenHome: () => context.go(AppRoutes.home),
          );
        }

        final isEditingUncreatedLeg =
            state.hasAnyOrder &&
            !state.hasUnknownOutcome &&
            ((state.outbound.pendingBookingId == null &&
                    state.outbound.step != BookingStep.payment) ||
                (state.inbound.pendingBookingId == null &&
                    state.inbound.step != BookingStep.payment));

        final showPayment =
            !isEditingUncreatedLeg &&
            (state.hasAnyOrder ||
                state.hasUnknownOutcome ||
                state.phase == RoundTripPhase.paymentPending ||
                state.phase == RoundTripPhase.partiallyPaid ||
                state.phase == RoundTripPhase.partiallyCreated ||
                state.phase == RoundTripPhase.verificationRequired);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final canExit = await _handlePop(context, state);
            if (canExit && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: DiscoveryColors.background,
            body: Column(
              children: [
                RoundTripLegHeader(
                  request: widget.selection.request,
                  activeLeg: _activeLeg,
                  outboundState: state.outbound,
                  inboundState: state.inbound,
                  onLegChanged: (leg) => setState(() => _activeLeg = leg),
                  onBack: () async {
                    final canExit = await _handlePop(context, state);
                    if (canExit && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  busy: state.busy,
                ),
                Expanded(
                  child: showPayment
                      ? RoundTripPaymentView(
                          request: widget.selection.request,
                          state: state,
                          onRecheck: (leg) => cubit.recheck(leg),
                          onRecheckAll: () => cubit.recheckAll(),
                          onRetrySubmitMissing: () => cubit.submit(),
                          onEditMissingLeg: (leg) {
                            cubit.dispatch(
                              leg,
                              GoToStepEvent(BookingStep.seatSelection.index),
                            );
                            setState(() => _activeLeg = leg);
                          },
                          onOpenMyTickets: () =>
                              context.push(AppRoutes.myTickets),
                          onOpenSupport: () =>
                              context.push(AppRoutes.supportChat),
                        )
                      : _buildEditingStepContent(context, cubit, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditingStepContent(
    BuildContext context,
    RoundTripCheckoutCubit cubit,
    RoundTripCheckoutState state,
  ) {
    _ensureLegLuggageCubits(cubit, state);
    final bothAtSummary =
        state.outbound.step.index >= BookingStep.tripSummary.index &&
        state.inbound.step.index >= BookingStep.tripSummary.index;
    if (bothAtSummary) {
      return RoundTripSummaryStep(
        request: widget.selection.request,
        outbound: state.outbound,
        inbound: state.inbound,
        totalAmount: state.totalAmount,
        busy: state.busy,
        error: state.error,
        onApplyOutboundVoucher: (code) {
          if (state.outbound.step == BookingStep.payment) {
            cubit.dispatch(
              TripLeg.outbound,
              GoToStepEvent(BookingStep.tripSummary.index),
            );
          }
          cubit.dispatch(TripLeg.outbound, ApplyPromotionCodeEvent(code));
        },
        onRemoveOutboundVoucher: () {
          if (state.outbound.step == BookingStep.payment) {
            cubit.dispatch(
              TripLeg.outbound,
              GoToStepEvent(BookingStep.tripSummary.index),
            );
          }
          cubit.dispatch(TripLeg.outbound, const RemoveVoucherEvent());
        },
        onApplyInboundVoucher: (code) {
          if (state.inbound.step == BookingStep.payment) {
            cubit.dispatch(
              TripLeg.inbound,
              GoToStepEvent(BookingStep.tripSummary.index),
            );
          }
          cubit.dispatch(TripLeg.inbound, ApplyPromotionCodeEvent(code));
        },
        onRemoveInboundVoucher: () {
          if (state.inbound.step == BookingStep.payment) {
            cubit.dispatch(
              TripLeg.inbound,
              GoToStepEvent(BookingStep.tripSummary.index),
            );
          }
          cubit.dispatch(TripLeg.inbound, const RemoveVoucherEvent());
        },
        onEditLeg: (leg) {
          cubit.dispatch(leg, GoToStepEvent(BookingStep.seatSelection.index));
          setState(() => _activeLeg = leg);
        },
        onDispatchCargo: (leg, event) => cubit.dispatch(leg, event),
        outboundLuggageCubit: _luggageCubits[TripLeg.outbound],
        inboundLuggageCubit: _luggageCubits[TripLeg.inbound],
        outboundSeatChangeNotice: _luggageSeatChangeNotices[TripLeg.outbound],
        inboundSeatChangeNotice: _luggageSeatChangeNotices[TripLeg.inbound],
        onDismissOutboundSeatChangeNotice: () =>
            setState(() => _luggageSeatChangeNotices[TripLeg.outbound] = null),
        onDismissInboundSeatChangeNotice: () =>
            setState(() => _luggageSeatChangeNotices[TripLeg.inbound] = null),
        onSyncLuggage: (leg, draft) => _syncLegLuggage(cubit, leg, draft),
        onSubmit: () => _handleProceedToPayment(cubit),
        onBack: () {
          if (state.outbound.pendingBookingId == null) {
            cubit.dispatch(
              TripLeg.outbound,
              GoToStepEvent(BookingStep.passengerInfo.index),
            );
          }
          if (state.inbound.pendingBookingId == null) {
            cubit.dispatch(
              TripLeg.inbound,
              GoToStepEvent(BookingStep.passengerInfo.index),
            );
          }
        },
      );
    }

    final bothAtPassenger =
        state.outbound.step.index >= BookingStep.passengerInfo.index &&
        state.inbound.step.index >= BookingStep.passengerInfo.index;
    if (bothAtPassenger) {
      return RoundTripPassengerStep(
        readOnly: state.hasAnyOrder,
        initialName: state.outbound.passengerName,
        initialPhone: state.outbound.passengerPhone,
        initialEmail: state.outbound.passengerEmail,
        initialNote: state.outbound.passengerNote,
        outboundState: state.outbound,
        inboundState: state.inbound,
        onDispatchCargo: (leg, event) => cubit.dispatch(leg, event),
        outboundLuggageCubit: _luggageCubits[TripLeg.outbound],
        inboundLuggageCubit: _luggageCubits[TripLeg.inbound],
        outboundSeatChangeNotice: _luggageSeatChangeNotices[TripLeg.outbound],
        inboundSeatChangeNotice: _luggageSeatChangeNotices[TripLeg.inbound],
        onDismissOutboundSeatChangeNotice: () =>
            setState(() => _luggageSeatChangeNotices[TripLeg.outbound] = null),
        onDismissInboundSeatChangeNotice: () =>
            setState(() => _luggageSeatChangeNotices[TripLeg.inbound] = null),
        onSyncLuggage: (leg, draft) => _syncLegLuggage(cubit, leg, draft),
        isValid:
            state.outbound.isPassengerValid &&
            state.inbound.isPassengerValid &&
            state.outbound.cargo.isValid &&
            state.inbound.cargo.isValid,
        busy: state.busy,
        onUpdate: (event) => cubit.updatePassenger(event),
        onNext: () async {
          for (final leg in TripLeg.values) {
            final legCubit = _luggageCubits[leg];
            if (legCubit != null &&
                state.leg(leg).pendingBookingId == null &&
                legCubit.state.phase == LuggagePhase.ready) {
              if (legCubit.validationError != null || !legCubit.policyIsFresh) {
                return;
              }
              await _syncLegLuggage(cubit, leg, null);
            }
          }
          if (cubit.state.outbound.step == BookingStep.passengerInfo) {
            cubit.dispatch(TripLeg.outbound, const NextStepEvent());
          }
          if (cubit.state.inbound.step == BookingStep.passengerInfo) {
            cubit.dispatch(TripLeg.inbound, const NextStepEvent());
          }
        },
        onBack: () {
          final targetLeg = state.leg(_activeLeg).pendingBookingId == null
              ? _activeLeg
              : (_activeLeg == TripLeg.outbound
                    ? TripLeg.inbound
                    : TripLeg.outbound);
          cubit.dispatch(
            targetLeg,
            GoToStepEvent(BookingStep.dropoffPoint.index),
          );
        },
      );
    }

    // Otherwise, configure the active leg
    final activeState = state.leg(_activeLeg);
    return _buildActiveLegConfig(context, cubit, state, activeState);
  }

  Widget _buildActiveLegConfig(
    BuildContext context,
    RoundTripCheckoutCubit cubit,
    RoundTripCheckoutState state,
    BookingFlowState activeState,
  ) {
    if (activeState.step.index >= BookingStep.passengerInfo.index) {
      final otherLeg = _activeLeg == TripLeg.outbound
          ? TripLeg.inbound
          : TripLeg.outbound;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 56,
                color: DiscoveryColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.uiCompletedb1ec0b(
                  _activeLeg == TripLeg.outbound
                      ? context.l10n.uiOutbound
                      : context.l10n.uiReturn,
                ),
                style: DiscoveryTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.uiSelectSeatsAndStopsForToContinue(
                  otherLeg == TripLeg.outbound
                      ? context.l10n.uiOutbound
                      : context.l10n.uiReturn,
                ),
                style: DiscoveryTextStyles.bodyMedium.copyWith(
                  color: DiscoveryColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiscoveryColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(
                  context.l10n.uiSwitchTo(
                    otherLeg == TripLeg.outbound
                        ? context.l10n.uiOutbound
                        : context.l10n.uiReturn,
                  ),
                ),
                onPressed: () => setState(() => _activeLeg = otherLeg),
              ),
            ],
          ),
        ),
      );
    }

    switch (activeState.step) {
      case BookingStep.seatSelection:
        return _buildSeatStep(context, cubit, state, activeState);
      case BookingStep.pickupPoint:
        return _buildPickupStep(context, cubit, state, activeState);
      case BookingStep.dropoffPoint:
        return _buildDropoffStep(context, cubit, state, activeState);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSeatStep(
    BuildContext context,
    RoundTripCheckoutCubit cubit,
    RoundTripCheckoutState state,
    BookingFlowState activeState,
  ) {
    final layout = activeState.seatLayout;
    if (activeState.status == BookingFlowStatus.loading || layout == null) {
      return const Center(
        child: CircularProgressIndicator(color: DiscoveryColors.primary),
      );
    }

    final canContinue = activeState.isSeatsValid && !state.busy;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SeatLegend(),
                const SizedBox(height: 14),
                SeatMapView(
                  layout: layout,
                  selectedFloor: activeState.selectedFloor,
                  selectedSeats: activeState.selectedSeats,
                  onFloorChanged: (floor) =>
                      cubit.dispatch(_activeLeg, ChangeFloorEvent(floor)),
                  onSeatToggled: (seat) =>
                      cubit.dispatch(_activeLeg, ToggleSeatEvent(seat)),
                ),
              ],
            ),
          ),
        ),
        _buildBottomSelectionBar(
          context: context,
          seatCount: activeState.selectedSeats.length,
          seatNames: activeState.selectedSeats.map((s) => s.name).join(', '),
          totalPrice: activeState.finalAmount ?? 0,
          canContinue: canContinue,
          onNext: () {
            cubit.dispatch(_activeLeg, const NextStepEvent());
          },
        ),
      ],
    );
  }

  Widget _buildPickupStep(
    BuildContext context,
    RoundTripCheckoutCubit cubit,
    RoundTripCheckoutState state,
    BookingFlowState activeState,
  ) {
    final canContinue = activeState.isPickupValid && !state.busy;

    return Column(
      children: [
        Expanded(
          child: StopPointSelection(
            title: context.l10n.uiSelectPickUp(
              _activeLeg == TripLeg.outbound
                  ? context.l10n.uiOutbound
                  : context.l10n.uiReturn,
            ),
            points: activeState.availablePickupPoints,
            selected: activeState.selectedPickupPoint,
            onSelected: (p) =>
                cubit.dispatch(_activeLeg, SelectPickupPointEvent(p)),
          ),
        ),
        _buildBottomSelectionBar(
          context: context,
          seatCount: activeState.selectedSeats.length,
          seatNames: activeState.selectedSeats.map((s) => s.name).join(', '),
          totalPrice: activeState.finalAmount ?? 0,
          canContinue: canContinue,
          onNext: () => cubit.dispatch(_activeLeg, const NextStepEvent()),
        ),
      ],
    );
  }

  Widget _buildDropoffStep(
    BuildContext context,
    RoundTripCheckoutCubit cubit,
    RoundTripCheckoutState state,
    BookingFlowState activeState,
  ) {
    final canContinue = activeState.isDropoffValid && !state.busy;

    return Column(
      children: [
        Expanded(
          child: StopPointSelection(
            title: context.l10n.uiSelectDropOff9938e9(
              _activeLeg == TripLeg.outbound
                  ? context.l10n.uiOutbound
                  : context.l10n.uiReturn,
            ),
            points: activeState.availableDropoffPoints,
            selected: activeState.selectedDropoffPoint,
            onSelected: (p) =>
                cubit.dispatch(_activeLeg, SelectDropoffPointEvent(p)),
          ),
        ),
        _buildBottomSelectionBar(
          context: context,
          seatCount: activeState.selectedSeats.length,
          seatNames: activeState.selectedSeats.map((s) => s.name).join(', '),
          totalPrice: activeState.finalAmount ?? 0,
          canContinue: canContinue,
          onNext: () {
            cubit.dispatch(_activeLeg, const NextStepEvent());
            // If the other leg is still selecting seats, automatically switch to it
            final otherLeg = _activeLeg == TripLeg.outbound
                ? TripLeg.inbound
                : TripLeg.outbound;
            if (state.leg(otherLeg).step == BookingStep.seatSelection) {
              setState(() => _activeLeg = otherLeg);
            }
          },
        ),
      ],
    );
  }

  Widget _buildBottomSelectionBar({
    required BuildContext context,
    required int seatCount,
    required String seatNames,
    required int totalPrice,
    required bool canContinue,
    required VoidCallback onNext,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
        border: Border(top: BorderSide(color: DiscoveryColors.neutral200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seatCount > 0
                        ? context.l10n.uiSelected3e13f1(seatNames)
                        : context.l10n.uiNoSeatsSelected,
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral700,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(totalPrice),
                    style: DiscoveryTextStyles.titleMedium.copyWith(
                      color: DiscoveryColors.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              key: const ValueKey('round-trip-step-next-btn'),
              onPressed: canContinue ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: DiscoveryColors.secondary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: DiscoveryColors.neutral300,
                minimumSize: const Size(120, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                context.l10n.uiContinue,
                style: DiscoveryTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInvalidatedView(BuildContext context) {
    return Scaffold(
      backgroundColor: DiscoveryColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_reset_rounded,
                size: 64,
                color: DiscoveryColors.warningDark,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.uiSignInSessionChanged,
                style: DiscoveryTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.uiYouHaveSignedOutOrYourSessionHas,
                style: DiscoveryTextStyles.bodyMedium.copyWith(
                  color: DiscoveryColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiscoveryColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.home_rounded),
                label: Text(context.l10n.uiGoToHome8a211a),
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
