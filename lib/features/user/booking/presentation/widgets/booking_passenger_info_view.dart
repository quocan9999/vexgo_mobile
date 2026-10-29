import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import '../steps/step_4_passenger_info.dart';
import 'booking_stepper.dart';
import 'seat_hold_countdown_bar.dart';

/// Scoped shell for Step 4 (Thông tin hành khách) sharing BookingCompactHeader & Stepper with Steps 1–3.
class BookingPassengerInfoView extends StatefulWidget {
  final BookingFlowState state;
  final BookingFlowBloc bloc;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final ValueChanged<int>? onStep;
  final VoidCallback? onDetails;

  const BookingPassengerInfoView({
    super.key,
    required this.state,
    required this.bloc,
    required this.onBack,
    required this.onNext,
    this.onStep,
    this.onDetails,
  });

  @override
  State<BookingPassengerInfoView> createState() =>
      _BookingPassengerInfoViewState();
}

class _BookingPassengerInfoViewState extends State<BookingPassengerInfoView> {
  final ValueNotifier<int> _validationTrigger = ValueNotifier<int>(0);

  @override
  void dispose() {
    _validationTrigger.dispose();
    super.dispose();
  }

  void _triggerValidationFeedback() {
    _validationTrigger.value++;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final busy =
        state.status == BookingFlowStatus.loading ||
        state.status == BookingFlowStatus.submitting ||
        state.isCheckoutLocked;
    final mediaQuery = MediaQuery.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final isShortViewport =
        mediaQuery.size.height < 420 || availableHeight < 380;
    final inlineCountdown =
        isShortViewport || textScale > 1.35 || mediaQuery.viewInsets.bottom > 0;

    final header = BookingCompactHeader(
      state: state,
      onBack: widget.onBack,
      onStep: widget.onStep ?? (index) => widget.bloc.add(GoToStepEvent(index)),
      onDetails: widget.onDetails,
      busy: busy,
      compact: isShortViewport,
    );

    final formStep = Step4PassengerInfo(
      key: const ValueKey('step_4_passenger'),
      state: state,
      bloc: widget.bloc,
      validationTrigger: _validationTrigger,
      showInlineCountdown: state.seatHold != null && inlineCountdown,
    );

    return DiscoveryTheme(
      child: Scaffold(
        backgroundColor: DiscoveryColors.background,
        // Keep the form at the same element location as the keyboard/viewport
        // changes. Switching between Column and NestedScrollView disposes its
        // controllers and focus nodes while the user is typing.
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  header,
                  if (state.seatHold != null && !inlineCountdown)
                    SeatHoldCountdownBar(
                      remainingSeconds: state.countdownSeconds,
                      compact: true,
                      seatCodes: state.selectedSeats
                          .map((s) => s.name)
                          .toList(),
                    ),
                ],
              ),
            ),
          ],
          body: formStep,
        ),
        bottomNavigationBar: BookingPassengerDock(
          state: state,
          onBack: widget.onBack,
          onNext: widget.onNext,
          onInvalidAttempt: _triggerValidationFeedback,
        ),
      ),
    );
  }
}

class BookingPassengerDock extends StatelessWidget {
  final BookingFlowState state;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback? onInvalidAttempt;

  const BookingPassengerDock({
    super.key,
    required this.state,
    required this.onBack,
    required this.onNext,
    this.onInvalidAttempt,
  });

  @override
  Widget build(BuildContext context) {
    final busy =
        state.status == BookingFlowStatus.loading ||
        state.status == BookingFlowStatus.submitting ||
        state.isCheckoutLocked;
    final expired = state.seatHold == null || state.countdownSeconds <= 0;
    final enabled =
        state.canProceed && state.cargo.isValid && !busy && !expired;

    final mediaQuery = MediaQuery.of(context);
    final keyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final isShortViewport = mediaQuery.size.height < 420;
    final compactDock = keyboardOpen || isShortViewport;

    return Material(
      color: Colors.white,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * (compactDock ? 0.34 : 0.44),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              compactDock ? 8 : 10,
              16,
              compactDock ? 8 : 12,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final stack =
                    constraints.maxWidth < 340 &&
                    (textScale > 1.3 || constraints.maxWidth < 280);

                final backBtn = DiscoveryButton(
                  text: 'Quay lại',
                  type: ButtonType.outline,
                  width: double.infinity,
                  onPressed: busy ? null : onBack,
                );

                Widget nextBtn = DiscoveryButton(
                  text: 'Tiếp tục',
                  type: ButtonType.secondary,
                  isLoading:
                      state.status == BookingFlowStatus.loading ||
                      state.status == BookingFlowStatus.submitting,
                  width: double.infinity,
                  onPressed: enabled ? onNext : null,
                );

                if (!enabled && !busy && !expired && onInvalidAttempt != null) {
                  nextBtn = GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: onInvalidAttempt,
                    child: nextBtn,
                  );
                }

                final helperText = expired
                    ? 'Thời gian giữ ghế đã hết. Vui lòng chọn lại ghế.'
                    : !state.isPassengerValid
                    ? 'Nhập họ tên và số điện thoại hợp lệ để tiếp tục'
                    : !state.cargo.isValid
                    ? (state.cargo.validationError ??
                          'Hoàn tất thông tin gửi hàng hoặc tắt gửi hàng để tiếp tục')
                    : 'Tiếp theo: xem lại đặt vé & mã ưu đãi';

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stack) ...[
                      backBtn,
                      const SizedBox(height: 8),
                      nextBtn,
                    ] else
                      Row(
                        children: [
                          Expanded(flex: 1, child: backBtn),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: nextBtn),
                        ],
                      ),
                    if (!compactDock) ...[
                      const SizedBox(height: 6),
                      Text(
                        helperText,
                        textAlign: TextAlign.center,
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: expired
                              ? DiscoveryColors.error
                              : DiscoveryColors.neutral500,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
