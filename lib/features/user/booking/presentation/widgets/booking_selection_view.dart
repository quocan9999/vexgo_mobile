import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'booking_stepper.dart';
import 'seat_hold_countdown_bar.dart';

/// Scoped to seat selection, pickup, and dropoff steps with compact header & visual stepper.
class BookingSelectionView extends StatelessWidget {
  final BookingFlowState state;
  final Widget child;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onDetails;
  final VoidCallback onRetry;
  final ValueChanged<int> onStep;

  const BookingSelectionView({
    super.key,
    required this.state,
    required this.child,
    required this.onBack,
    required this.onNext,
    required this.onDetails,
    required this.onRetry,
    required this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    final busy =
        state.status == BookingFlowStatus.loading ||
        state.status == BookingFlowStatus.submitting;
    final failed =
        state.status == BookingFlowStatus.failure && state.seatLayout == null;

    return DiscoveryTheme(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(child: _header(context, busy)),
          ],
          body: Column(
            children: [
              if (state.seatHold != null &&
                  state.step != BookingStep.seatSelection)
                SeatHoldCountdownBar(
                  remainingSeconds: state.countdownSeconds,
                  compact: true,
                ),
              Expanded(
                child: failed
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, size: 36),
                            const SizedBox(height: 12),
                            const Text(
                              'Không thể tải sơ đồ ghế. Vui lòng thử lại.',
                            ),
                            const SizedBox(height: 16),
                            DiscoveryButton(
                              text: 'Thử lại',
                              onPressed: onRetry,
                            ),
                          ],
                        ),
                      )
                    : busy && state.seatLayout == null
                    ? const Center(child: CircularProgressIndicator())
                    : child,
              ),
            ],
          ),
        ),
        bottomNavigationBar: state.seatLayout == null
            ? null
            : BookingSelectionDock(
                state: state,
                onNext: onNext,
                onBack: onBack,
              ),
      ),
    );
  }

  Widget _header(BuildContext context, bool busy) {
    final trip = state.trip;

    return ColoredBox(
      color: DiscoveryColors.header,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 14, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Back | Operator & Route/Time | Inline "Chi tiết xe"
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    onPressed: busy ? null : onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          trip?.operatorName ?? 'Đặt vé',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DiscoveryTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (trip != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${trip.departureTime}${state.date == null ? '' : ' • ${DateFormatter.formatShortDate(state.date!)}'} • ${trip.fromCityName} → ${trip.toCityName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DiscoveryTextStyles.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: TextButton(
                      onPressed: busy ? null : onDetails,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        minimumSize: const Size(48, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Chi tiết xe',
                          style: DiscoveryTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Row 2: Compact Stepper with badges & connectors
              BookingStepperCompact(
                currentStepIndex: state.step.index,
                onStepTapped: busy ? null : onStep,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookingSelectionDock extends StatelessWidget {
  final BookingFlowState state;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const BookingSelectionDock({
    super.key,
    required this.state,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final seats = state.step == BookingStep.seatSelection;
    final busy =
        state.status == BookingFlowStatus.loading || state.isCheckoutLocked;
    final expired =
        !seats && (state.seatHold == null || state.countdownSeconds <= 0);
    final enabled = state.canProceed && !busy && !expired;

    return Material(
      color: Colors.white,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .48,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stack =
                    MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                    constraints.maxWidth < 300;

                final summary = seats
                    ? InkWell(
                        onTap: state.selectedSeats.isEmpty
                            ? null
                            : () => _showBreakdown(context),
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.selectedSeats.isEmpty
                                    ? 'Vui lòng chọn chỗ'
                                    : 'Đã chọn ${state.selectedSeats.length} chỗ: ${state.selectedSeats.map((s) => s.name).join(', ')}',
                                style: DiscoveryTextStyles.bodySmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.selectedSeats.isEmpty
                                    ? CurrencyFormatter.format(0)
                                    : state.seatsTotalAmount == null
                                    ? 'Chưa có giá vé'
                                    : '${CurrencyFormatter.format(state.seatsTotalAmount)} ⌃',
                                style: DiscoveryTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : DiscoveryButton(
                        text: state.step == BookingStep.pickupPoint
                            ? 'Đổi ghế'
                            : 'Điểm đón',
                        type: ButtonType.outline,
                        onPressed: busy ? null : onBack,
                      );

                final next = DiscoveryButton(
                  text: 'Tiếp tục',
                  type: ButtonType.secondary,
                  isLoading: busy,
                  width: double.infinity,
                  onPressed: enabled ? onNext : null,
                );

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stack) ...[
                      summary,
                      const SizedBox(height: 10),
                      next,
                    ] else
                      Row(
                        children: [
                          Expanded(child: summary),
                          const SizedBox(width: 12),
                          Expanded(child: next),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Text(
                      seats
                          ? 'Bạn sẽ chọn điểm đón/trả ở bước tiếp theo'
                          : state.step == BookingStep.pickupPoint
                          ? 'Tiếp theo: chọn điểm trả'
                          : 'Tiếp theo: thông tin hành khách',
                      textAlign: TextAlign.center,
                      style: DiscoveryTextStyles.caption,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showBreakdown(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => DiscoveryTheme(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Chi tiết ghế đã chọn',
                        style: DiscoveryTextStyles.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                for (final seat in state.selectedSeats)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Ghế ${seat.name} • Tầng ${seat.floor}',
                          style: DiscoveryTextStyles.bodyMedium,
                        ),
                        Text(
                          seat.price == null
                              ? 'Chưa có giá vé'
                              : CurrencyFormatter.format(seat.price),
                          style: DiscoveryTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                Text(
                  state.seatsTotalAmount == null
                      ? 'Chưa xác định tổng tiền'
                      : 'Tạm tính: ${CurrencyFormatter.format(state.seatsTotalAmount)}',
                  style: DiscoveryTextStyles.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
