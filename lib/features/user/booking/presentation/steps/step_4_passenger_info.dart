import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import '../widgets/booking_cargo_section_card.dart';
import '../widgets/seat_hold_countdown_bar.dart';

class Step4PassengerInfo extends StatefulWidget {
  final BookingFlowState state;
  final BookingFlowBloc bloc;
  final ValueListenable<int>? validationTrigger;
  final bool showInlineCountdown;

  const Step4PassengerInfo({
    super.key,
    required this.state,
    required this.bloc,
    this.validationTrigger,
    this.showInlineCountdown = false,
  });

  static String? validateName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Vui lòng nhập họ và tên hành khách';
    }
    if (trimmed.length < 2) {
      return 'Họ và tên cần ít nhất 2 ký tự';
    }
    return null;
  }

  static String? validatePhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Vui lòng nhập số điện thoại liên hệ';
    }
    if (!RegExp(r'^(?:0|\+84)[35789][0-9]{8}$').hasMatch(trimmed)) {
      return 'Số điện thoại không hợp lệ (ví dụ: 0912345678 hoặc +84912345678)';
    }
    return null;
  }

  static String? validateEmail(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed)) {
      return 'Email không đúng định dạng (ví dụ: ten@email.com)';
    }
    return null;
  }

  @override
  State<Step4PassengerInfo> createState() => _Step4PassengerInfoState();
}

class _Step4PassengerInfoState extends State<Step4PassengerInfo> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  late final FocusNode _nameFocusNode;
  late final FocusNode _phoneFocusNode;
  late final FocusNode _emailFocusNode;

  final GlobalKey _nameFieldKey = GlobalKey();
  final GlobalKey _phoneFieldKey = GlobalKey();
  final GlobalKey _emailFieldKey = GlobalKey();

  bool _nameTouched = false;
  bool _phoneTouched = false;
  bool _emailTouched = false;
  bool _nameHadFocus = false;
  bool _phoneHadFocus = false;
  bool _emailHadFocus = false;

  bool get _isLocked =>
      widget.state.isCheckoutLocked ||
      widget.state.status == BookingFlowStatus.loading ||
      widget.state.status == BookingFlowStatus.submitting;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.passengerName);
    _phoneController = TextEditingController(text: widget.state.passengerPhone);
    _emailController = TextEditingController(text: widget.state.passengerEmail);

    _nameFocusNode = FocusNode()..addListener(_onNameFocusChanged);
    _phoneFocusNode = FocusNode()..addListener(_onPhoneFocusChanged);
    _emailFocusNode = FocusNode()..addListener(_onEmailFocusChanged);

    widget.validationTrigger?.addListener(_onValidationTriggered);
  }

  @override
  void didUpdateWidget(covariant Step4PassengerInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.validationTrigger != widget.validationTrigger) {
      oldWidget.validationTrigger?.removeListener(_onValidationTriggered);
      widget.validationTrigger?.addListener(_onValidationTriggered);
    }

    var externalReset = false;
    if (widget.state.passengerName != oldWidget.state.passengerName &&
        widget.state.passengerName != _nameController.text) {
      _setControllerTextPreservingNothing(
        _nameController,
        widget.state.passengerName,
      );
      if (widget.state.passengerName.isEmpty) externalReset = true;
    }
    if (widget.state.passengerPhone != oldWidget.state.passengerPhone &&
        widget.state.passengerPhone != _phoneController.text) {
      _setControllerTextPreservingNothing(
        _phoneController,
        widget.state.passengerPhone,
      );
      if (widget.state.passengerPhone.isEmpty) externalReset = true;
    }
    if (widget.state.passengerEmail != oldWidget.state.passengerEmail &&
        widget.state.passengerEmail != _emailController.text) {
      _setControllerTextPreservingNothing(
        _emailController,
        widget.state.passengerEmail,
      );
      if (widget.state.passengerEmail.isEmpty) externalReset = true;
    }

    if (externalReset &&
        widget.state.passengerName.isEmpty &&
        widget.state.passengerPhone.isEmpty &&
        widget.state.passengerEmail.isEmpty) {
      _nameTouched = false;
      _phoneTouched = false;
      _emailTouched = false;
    }
  }

  void _setControllerTextPreservingNothing(
    TextEditingController controller,
    String nextText,
  ) {
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
  }

  void _onValidationTriggered() {
    if (!mounted) return;
    setState(() {
      _nameTouched = true;
      _phoneTouched = true;
      _emailTouched = true;
    });
    _focusFirstInvalidField();
  }

  void _focusFirstInvalidField() {
    if (_isLocked) return;
    if (Step4PassengerInfo.validateName(_nameController.text) != null) {
      _nameFocusNode.requestFocus();
      _ensureFieldVisible(_nameFieldKey);
      return;
    }
    if (Step4PassengerInfo.validatePhone(_phoneController.text) != null) {
      _phoneFocusNode.requestFocus();
      _ensureFieldVisible(_phoneFieldKey);
      return;
    }
    if (Step4PassengerInfo.validateEmail(_emailController.text) != null) {
      _emailFocusNode.requestFocus();
      _ensureFieldVisible(_emailFieldKey);
    }
  }

  void _onNameFocusChanged() {
    if (_nameFocusNode.hasFocus) {
      _nameHadFocus = true;
      _ensureFieldVisible(_nameFieldKey);
    } else if (_nameHadFocus && mounted) {
      setState(() => _nameTouched = true);
    }
  }

  void _onPhoneFocusChanged() {
    if (_phoneFocusNode.hasFocus) {
      _phoneHadFocus = true;
      _ensureFieldVisible(_phoneFieldKey);
    } else if (_phoneHadFocus && mounted) {
      setState(() => _phoneTouched = true);
    }
  }

  void _onEmailFocusChanged() {
    if (_emailFocusNode.hasFocus) {
      _emailHadFocus = true;
      _ensureFieldVisible(_emailFieldKey);
    } else if (_emailHadFocus && mounted) {
      setState(() => _emailTouched = true);
    }
  }

  void _ensureFieldVisible(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  @override
  void dispose() {
    widget.validationTrigger?.removeListener(_onValidationTriggered);
    _nameFocusNode
      ..removeListener(_onNameFocusChanged)
      ..dispose();
    _phoneFocusNode
      ..removeListener(_onPhoneFocusChanged)
      ..dispose();
    _emailFocusNode
      ..removeListener(_onEmailFocusChanged)
      ..dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _syncData() {
    if (_isLocked) return;
    widget.bloc.add(
      UpdatePassengerInfoEvent(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        note: widget.state.passengerNote,
        saveInfo: ApiConfig.isDemoMode && widget.state.savePassengerInfo,
      ),
    );
  }

  String? get _nameError {
    final show = _nameTouched || _nameController.text.isNotEmpty;
    if (!show) return null;
    return Step4PassengerInfo.validateName(_nameController.text);
  }

  String? get _phoneError {
    final show = _phoneTouched || _phoneController.text.isNotEmpty;
    if (!show) return null;
    return Step4PassengerInfo.validatePhone(_phoneController.text);
  }

  String? get _emailError {
    final show = _emailTouched || _emailController.text.isNotEmpty;
    if (!show) return null;
    return Step4PassengerInfo.validateEmail(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final seatNames = widget.state.selectedSeats.map((s) => s.name).join(', ');
    final pickupName = widget.state.selectedPickupPoint?.name;
    final dropoffName = widget.state.selectedDropoffPoint?.name;

    return DiscoveryTheme(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showInlineCountdown &&
                widget.state.seatHold != null) ...[
              SeatHoldCountdownBar(
                remainingSeconds: widget.state.countdownSeconds,
                compact: true,
                seatCodes: widget.state.selectedSeats
                    .map((s) => s.name)
                    .toList(),
              ),
              const SizedBox(height: 10),
            ],
            if (seatNames.isNotEmpty ||
                pickupName != null ||
                dropoffName != null) ...[
              _buildSelectionContextStrip(
                seatNames: seatNames,
                pickupName: pickupName,
                dropoffName: dropoffName,
              ),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DiscoveryColors.surface,
                borderRadius: BorderRadius.circular(12),
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
                  Text(
                    'Thông tin liên hệ cho đơn đặt vé',
                    style: DiscoveryTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: DiscoveryColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dùng để xác nhận thông tin đặt chỗ và liên hệ đón trả trong chuyến đi này.',
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      color: DiscoveryColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Họ và tên (Bắt buộc)
                  _PassengerContactField(
                    key: _nameFieldKey,
                    fieldKey: const ValueKey('passenger-name-input'),
                    label: 'Họ và tên',
                    isRequired: true,
                    hintText: 'Ví dụ: Nguyễn Văn An',
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    enabled: !_isLocked,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    prefixIcon: Icons.person_outline_rounded,
                    errorText: _nameError,
                    onChanged: (_) {
                      setState(() => _nameTouched = true);
                      _syncData();
                    },
                    onSubmitted: (_) {
                      setState(() => _nameTouched = true);
                      _phoneFocusNode.requestFocus();
                    },
                  ),

                  const SizedBox(height: 14),

                  // 2. Số điện thoại (Bắt buộc)
                  _PassengerContactField(
                    key: _phoneFieldKey,
                    fieldKey: const ValueKey('passenger-phone-input'),
                    label: 'Số điện thoại',
                    isRequired: true,
                    hintText: 'Ví dụ: 0987654321',
                    helperText:
                        'Hỗ trợ số di động Việt Nam bắt đầu bằng 0 hoặc +84.',
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    enabled: !_isLocked,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    prefixIcon: Icons.phone_iphone_rounded,
                    errorText: _phoneError,
                    onChanged: (_) {
                      setState(() => _phoneTouched = true);
                      _syncData();
                    },
                    onSubmitted: (_) {
                      setState(() => _phoneTouched = true);
                      _emailFocusNode.requestFocus();
                    },
                  ),

                  const SizedBox(height: 14),

                  // 3. Email (Tùy chọn)
                  _PassengerContactField(
                    key: _emailFieldKey,
                    fieldKey: const ValueKey('passenger-email-input'),
                    label: 'Email (tùy chọn)',
                    isRequired: false,
                    hintText: 'Ví dụ: nguyenvanan@gmail.com',
                    helperText:
                        'Không bắt buộc. Nếu nhập, vui lòng dùng đúng định dạng email.',
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    enabled: !_isLocked,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    prefixIcon: Icons.email_outlined,
                    errorText: _emailError,
                    onChanged: (_) {
                      setState(() => _emailTouched = true);
                      _syncData();
                    },
                    onSubmitted: (_) {
                      setState(() {
                        _nameTouched = true;
                        _phoneTouched = true;
                        _emailTouched = true;
                      });
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BookingCargoSectionCard(
              cargo: widget.state.cargo,
              locked: _isLocked,
              scopeKey: 'oneway',
              onToggleEnabled: (enabled) =>
                  widget.bloc.add(SetBookingCargoEnabledEvent(enabled)),
              onRefresh: () =>
                  widget.bloc.add(const RefreshBookingCargoEvent()),
              onUpdateDraft: (draft) =>
                  widget.bloc.add(UpdateBookingCargoEvent(draft)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionContextStrip({
    required String seatNames,
    required String? pickupName,
    required String? dropoffName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DiscoveryColors.primaryLight.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DiscoveryColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (seatNames.isNotEmpty)
            Text(
              'Ghế: $seatNames',
              style: DiscoveryTextStyles.bodySmall.copyWith(
                color: DiscoveryColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (pickupName != null && pickupName.isNotEmpty)
            Text(
              'Đón: $pickupName',
              style: DiscoveryTextStyles.caption.copyWith(
                color: DiscoveryColors.neutral700,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (dropoffName != null && dropoffName.isNotEmpty)
            Text(
              'Trả: $dropoffName',
              style: DiscoveryTextStyles.caption.copyWith(
                color: DiscoveryColors.neutral700,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _PassengerContactField extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final bool isRequired;
  final String hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final IconData prefixIcon;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _PassengerContactField({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.isRequired,
    required this.hintText,
    this.helperText,
    this.errorText,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    required this.textInputAction,
    this.autofillHints,
    required this.prefixIcon,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    final semanticLabel = isRequired ? '$label, bắt buộc' : label;

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: RichText(
              textScaler: MediaQuery.textScalerOf(context),
              text: TextSpan(
                style: DiscoveryTextStyles.titleSmall.copyWith(
                  color: DiscoveryColors.neutral800,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(text: label),
                  if (isRequired)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: DiscoveryColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: fieldKey,
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            readOnly: !enabled,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            textInputAction: textInputAction,
            autofillHints: enabled ? autofillHints : null,
            scrollPadding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            style: DiscoveryTextStyles.bodyMedium.copyWith(
              color: enabled
                  ? DiscoveryColors.neutral900
                  : DiscoveryColors.neutral500,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: DiscoveryTextStyles.bodyMedium.copyWith(
                color: DiscoveryColors.neutral400,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: ExcludeSemantics(
                child: Icon(
                  prefixIcon,
                  size: 20,
                  color: hasError
                      ? DiscoveryColors.error
                      : DiscoveryColors.primary,
                ),
              ),
              constraints: const BoxConstraints(minHeight: 48),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              filled: true,
              fillColor: enabled
                  ? DiscoveryColors.surface
                  : DiscoveryColors.neutral100,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: hasError
                      ? DiscoveryColors.error
                      : DiscoveryColors.neutral300,
                  width: hasError ? 1.5 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: hasError
                      ? DiscoveryColors.error
                      : DiscoveryColors.primary,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: DiscoveryColors.neutral200,
                  width: 1,
                ),
              ),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ExcludeSemantics(
                    child: Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 15,
                        color: DiscoveryColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      errorText!,
                      style: DiscoveryTextStyles.caption.copyWith(
                        color: DiscoveryColors.error,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (helperText != null) ...[
            const SizedBox(height: 5),
            Text(
              helperText!,
              style: DiscoveryTextStyles.caption.copyWith(
                color: DiscoveryColors.neutral500,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
