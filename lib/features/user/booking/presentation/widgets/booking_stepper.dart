import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';

/// Shared compact red booking header with Row 1 (Back | Operator & Trip summary | Chi tiết xe)
/// and Row 2 (6-step horizontal BookingStepperCompact) unified across Steps 1–4.
class BookingCompactHeader extends StatelessWidget {
  final BookingFlowState state;
  final VoidCallback onBack;
  final ValueChanged<int>? onStep;
  final VoidCallback? onDetails;
  final bool busy;
  final bool compact;

  const BookingCompactHeader({
    super.key,
    required this.state,
    required this.onBack,
    this.onStep,
    this.onDetails,
    this.busy = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final trip = state.trip;
    final date = state.date;

    return ColoredBox(
      key: const ValueKey('booking-compact-header'),
      color: DiscoveryColors.header,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(6, compact ? 2 : 4, 14, compact ? 4 : 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row 1: Back | Operator & Route/Time | Inline "Chi tiết xe"
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    constraints: BoxConstraints(
                      minWidth: 48,
                      minHeight: compact ? 40 : 48,
                    ),
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
                            fontSize: compact ? 14 : 16,
                          ),
                        ),
                        if (trip != null) ...[
                          SizedBox(height: compact ? 1 : 2),
                          Text(
                            '${trip.departureTime}${date == null ? '' : ' • ${DateFormatter.formatShortDate(date)}'} • ${trip.fromCityName} → ${trip.toCityName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DiscoveryTextStyles.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: compact ? 11.5 : 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onDetails != null) ...[
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Semantics(
                        button: true,
                        enabled: !busy,
                        label: 'Chi tiết xe',
                        child: TextButton(
                          onPressed: busy ? null : onDetails,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            minimumSize: Size(48, compact ? 40 : 48),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Chi tiết xe',
                              style: DiscoveryTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: compact ? 11.5 : 12.5,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: compact ? 2 : 4),
              // Row 2: 6-step horizontal stepper inside the same red header surface
              BookingStepperCompact(
                currentStepIndex: state.step.index,
                onStepTapped: busy ? null : onStep,
                enabled: !busy,
                compact: compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact visual stepper with circle badges for all 6 booking steps.
/// Automatically scrolls the active step into the horizontal viewport when mounted
/// or when [currentStepIndex] changes, without resetting scroll position on countdown ticks.
class BookingStepperCompact extends StatefulWidget {
  final int currentStepIndex;
  final ValueChanged<int>? onStepTapped;
  final bool enabled;
  final bool compact;

  static const List<String> stepTitles = [
    'Chọn chỗ',
    'Điểm đón',
    'Điểm trả',
    'Thông tin',
    'Xác nhận',
    'Thanh toán',
  ];

  const BookingStepperCompact({
    super.key,
    required this.currentStepIndex,
    this.onStepTapped,
    this.enabled = true,
    this.compact = false,
  });

  @override
  State<BookingStepperCompact> createState() => BookingStepperCompactState();
}

class BookingStepperCompactState extends State<BookingStepperCompact> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _stepKeys = List<GlobalKey>.generate(
    BookingStepperCompact.stepTitles.length,
    (_) => GlobalKey(),
  );
  bool _scrollScheduled = false;
  (double, double, TextDirection, bool)? _layoutGeometry;

  ScrollController get scrollController => _scrollController;

  @override
  void initState() {
    super.initState();
    _scheduleScrollToCurrentStep(animate: false);
  }

  @override
  void didUpdateWidget(covariant BookingStepperCompact oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStepIndex != widget.currentStepIndex) {
      _scheduleScrollToCurrentStep(animate: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleScrollToCurrentStep({required bool animate}) {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!mounted) return;
      _scrollToCurrentStep(animate: animate);
    });
  }

  void _scrollToCurrentStep({required bool animate}) {
    final index = widget.currentStepIndex;
    if (index < 0 || index >= _stepKeys.length) return;
    final itemContext = _stepKeys[index].currentContext;
    if (itemContext == null || !_scrollController.hasClients) return;
    final target = itemContext.findRenderObject();
    if (target == null || !target.attached) return;
    // Reveal only along this horizontal strip; do not move an ancestor's
    // vertical scroll away from the passenger field currently being edited.
    _scrollController.position.ensureVisible(
      target,
      alignment: 0.5,
      duration: animate ? const Duration(milliseconds: 40) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = (
          constraints.maxWidth,
          MediaQuery.textScalerOf(context).scale(widget.compact ? 11.5 : 12.5),
          Directionality.of(context),
          widget.compact,
        );
        if (_layoutGeometry != geometry) {
          _layoutGeometry = geometry;
          _scheduleScrollToCurrentStep(animate: false);
        }
        return _buildScrollView();
      },
    );
  }

  Widget _buildScrollView() {
    const stepTitles = BookingStepperCompact.stepTitles;

    return SingleChildScrollView(
      key: const ValueKey('booking-stepper-scroll'),
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < stepTitles.length; i++) ...[
              if (i > 0)
                Container(
                  width: 14,
                  height: 1.5,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i <= widget.currentStepIndex
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              _buildStepItem(
                index: i,
                title: stepTitles[i],
                isActive: i == widget.currentStepIndex,
                isPassed: i < widget.currentStepIndex,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required int index,
    required String title,
    required bool isActive,
    required bool isPassed,
  }) {
    final canTap = widget.enabled && isPassed && widget.onStepTapped != null;
    final statusText = isActive
        ? 'đang chọn'
        : isPassed
        ? 'đã hoàn thành'
        : 'chưa tới';

    final badgeChild = isPassed
        ? const Icon(Icons.check, size: 12, color: Colors.white)
        : Text(
            '${index + 1}',
            style: DiscoveryTextStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.0,
              color: isActive
                  ? DiscoveryColors.header
                  : Colors.white.withValues(alpha: 0.85),
            ),
          );

    final badgeDecoration = BoxDecoration(
      color: isActive
          ? Colors.white
          : isPassed
          ? Colors.white.withValues(alpha: 0.32)
          : Colors.transparent,
      shape: BoxShape.circle,
      border: isActive || isPassed
          ? null
          : Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.4),
      boxShadow: isActive
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ]
          : null,
    );

    final labelStyle = DiscoveryTextStyles.bodySmall.copyWith(
      fontSize: widget.compact ? 11.5 : 12.5,
      fontWeight: isActive
          ? FontWeight.w800
          : isPassed
          ? FontWeight.w600
          : FontWeight.w500,
      color: isActive
          ? Colors.white
          : isPassed
          ? Colors.white.withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.72),
    );

    return KeyedSubtree(
      key: _stepKeys[index],
      child: Semantics(
        key: ValueKey('booking-stepper-item-$index'),
        container: true,
        button: isPassed,
        enabled: canTap,
        selected: isActive,
        label:
            'Bước ${index + 1}/${BookingStepperCompact.stepTitles.length}: $title, $statusText',
        onTap: canTap ? () => widget.onStepTapped!(index) : null,
        child: InkWell(
          onTap: canTap ? () => widget.onStepTapped!(index) : null,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 48,
              minHeight: widget.compact ? 40 : 48,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 20,
                      height: 20,
                      padding: const EdgeInsets.all(2.5),
                      alignment: Alignment.center,
                      decoration: badgeDecoration,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: badgeChild,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ExcludeSemantics(child: Text(title, style: labelStyle)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Legacy multi-step stepper retained for subsequent checkout steps if needed
class BookingStepper extends StatelessWidget {
  final BookingStep currentStep;
  final Function(int) onStepTapped;

  const BookingStepper({
    super.key,
    required this.currentStep,
    required this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    final currentIdx = currentStep.index;
    final totalSteps = BookingStep.values.length;
    final progress = (currentIdx + 1) / totalSteps;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.base,
        AppDimensions.sm,
        AppDimensions.base,
        AppDimensions.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Bước ${currentStep.stepNumber}/$totalSteps',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Text(
                    currentStep.title,
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.neutral900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.neutral200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(totalSteps, (index) {
                final step = BookingStep.values[index];
                final isCurrent = index == currentIdx;
                final isPassed = index < currentIdx;

                Color bgColor = AppColors.neutral100;
                Color textColor = AppColors.neutral500;
                Color borderColor = AppColors.neutral300;

                if (isCurrent) {
                  bgColor = AppColors.primary;
                  textColor = Colors.white;
                  borderColor = AppColors.primary;
                } else if (isPassed) {
                  bgColor = AppColors.primaryLight;
                  textColor = AppColors.primary;
                  borderColor = AppColors.primary.withValues(alpha: 0.3);
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: isPassed ? () => onStepTapped(index) : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        step.title,
                        style: AppTextStyles.caption.copyWith(
                          color: textColor,
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
