import 'package:vexgo_app/core/localization/client_labels.dart';
import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'dart:async';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/core/widgets/custom_text_field.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../screens/forgot_password_screen.dart';

class AuthModalSheet extends StatefulWidget {
  final bool initialIsRegister;

  const AuthModalSheet({super.key, this.initialIsRegister = false});

  static void show(BuildContext context, {bool isRegister = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AuthModalSheet(initialIsRegister: isRegister),
    );
  }

  @override
  State<AuthModalSheet> createState() => _AuthModalSheetState();
}

class _AuthModalSheetState extends State<AuthModalSheet> {
  late bool _isRegister;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isObscurePassword = true;
  bool _isVerifyingOtp = false;
  int _otpCountdown = 60;
  Timer? _timer;
  late AuthBloc _authBloc;
  bool _busy = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialIsRegister;
    _authBloc = context.read<AuthBloc>();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_finished && !_authBloc.isClosed) {
      _authBloc.add(const ClearPendingRegistrationEvent());
    }
    _phoneController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _otpCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCountdown > 0) {
        setState(() => _otpCountdown--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _onLogin() {
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text;
    if (phone.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.uiEnterYourPhoneNumberAndPassword)),
      );
      return;
    }

    context.read<AuthBloc>().add(
      LoginWithPhoneEvent(phone: phone, password: pass),
    );
    setState(() => _busy = true);
  }

  void _onRequestOtp() {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final pass = _passwordController.text;

    if (phone.isEmpty || name.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.uiCompleteAllRegistrationFields)),
      );
      return;
    }

    context.read<AuthBloc>().add(
      RequestRegisterOtpEvent(phone: phone, fullName: name, password: pass),
    );

    setState(() => _busy = true);
  }

  void _onVerifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.uiEnterTheFull6DigitVerificationCode),
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      VerifyOtpAndRegisterEvent(
        phone: _phoneController.text.trim(),
        otp: otp,
        fullName: _nameController.text.trim(),
        password: _passwordController.text,
      ),
    );
    setState(() => _busy = true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.otpRequired) {
          setState(() {
            _busy = false;
            _isVerifyingOtp = true;
            _otpController.clear();
          });
          _startTimer();
        }
        if (state.status == AuthStatus.authenticated && _busy) {
          _finished = true;
          Navigator.of(context).pop();
        }
        if (state.status == AuthStatus.failure && state.errorMessage != null) {
          setState(() => _busy = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizedClientLabel(context, state.errorMessage!)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) => PopScope(
        canPop: !_busy,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusXl),
                topRight: Radius.circular(AppDimensions.radiusXl),
              ),
            ),
            child: SingleChildScrollView(
              child: _isVerifyingOtp ? _buildOtpView() : _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.md),

        // Title and toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _isRegister
                    ? context.l10n.uiCreateAVexgoAccount
                    : context.l10n.uiSignInToVexgo,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: AppDimensions.sm),

        // Tabs toggle: Đăng nhập vs Đăng ký
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _busy
                      ? null
                      : () => setState(() => _isRegister = false),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isRegister ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                      boxShadow: !_isRegister
                          ? const [
                              BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        context.l10n.uiSignIn,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: !_isRegister
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: !_isRegister
                              ? AppColors.primary
                              : AppColors.neutral600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: _busy
                      ? null
                      : () => setState(() => _isRegister = true),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _isRegister ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                      boxShadow: _isRegister
                          ? const [
                              BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        context.l10n.uiCreateAccount,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: _isRegister
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _isRegister
                              ? AppColors.primary
                              : AppColors.neutral600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.md),

        // If register, ask for Full name
        if (_isRegister) ...[
          Text(
            context.l10n.uiFullName,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppDimensions.xs),
          CustomTextField(
            controller: _nameController,
            hintText: context.l10n.uiEnterYourFullName,
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
        ],

        // Số điện thoại
        Text(
          context.l10n.uiPhoneNumber42d534,
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppDimensions.xs),
        CustomTextField(
          controller: _phoneController,
          hintText: context.l10n.uiExample0987654321,
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(
            Icons.phone_iphone_rounded,
            color: AppColors.neutral500,
          ),
        ),

        const SizedBox(height: AppDimensions.sm),

        // Mật khẩu
        Text(
          context.l10n.uiPassword,
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppDimensions.xs),
        CustomTextField(
          controller: _passwordController,
          hintText: context.l10n.uiEnterPassword,
          obscureText: _isObscurePassword,
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.neutral500,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _isObscurePassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: AppColors.neutral500,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _isObscurePassword = !_isObscurePassword),
          ),
        ),

        if (!_isRegister)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      FocusScope.of(context).unfocus();
                      _passwordController.clear();
                      final reset =
                          await Navigator.of(
                            context,
                            rootNavigator: true,
                          ).push<String>(
                            MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen(
                                initialPhone: _phoneController.text,
                              ),
                            ),
                          );
                      if (!mounted) return;
                      if (reset != null) {
                        _phoneController.text = reset;
                        _passwordController.clear();
                      }
                    },
              child: Text(context.l10n.uiForgotPassword1630fc),
            ),
          ),
        const SizedBox(height: AppDimensions.lg),

        // Action button
        CustomButton(
          text: _isRegister
              ? context.l10n.uiContinueVerifyPhone
              : context.l10n.uiSignInfe480c,
          width: double.infinity,
          type: ButtonType.primary,
          isLoading: _busy,
          onPressed: _busy ? null : (_isRegister ? _onRequestOtp : _onLogin),
        ),

        const SizedBox(height: AppDimensions.md),

        Center(
          child: Text(
            context.l10n.uiByContinuingYouAgreeToVexgoSTerms,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.neutral500,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Drag handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.neutral300,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
        ),
        const SizedBox(height: AppDimensions.md),

        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: AppDimensions.md),

        Text(
          context.l10n.uiVerifyYourCode,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
          child: Text(
            context.l10n.uiA6DigitVerificationCodeWasSentTo(
              _phoneController.text.trim(),
            ),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutral600,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: AppDimensions.lg),

        // OTP Input Field
        SizedBox(
          width: 220,
          child: CustomTextField(
            controller: _otpController,
            hintText: '123456',
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: AppDimensions.sm),
        if (ApiConfig.isDemoMode)
          Text(
            context.l10n.uiTestCodeHint123456,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.neutral500,
              fontStyle: FontStyle.italic,
            ),
          ),

        const SizedBox(height: AppDimensions.md),

        // Countdown and Resend button
        if (_otpCountdown > 0)
          Text(
            context.l10n.uiResendCodeInSeconds(_otpCountdown),
            style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
          )
        else
          TextButton(
            onPressed: _busy
                ? null
                : () {
                    setState(() => _busy = true);
                    context.read<AuthBloc>().add(
                      RequestRegisterOtpEvent(
                        phone: _phoneController.text.trim(),
                        fullName: _nameController.text.trim(),
                        password: _passwordController.text,
                      ),
                    );
                  },
            child: Text(context.l10n.uiResendCode),
          ),

        const SizedBox(height: AppDimensions.lg),

        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: context.l10n.uiBackb26cc0,
                type: ButtonType.outline,
                onPressed: _busy
                    ? null
                    : () {
                        context.read<AuthBloc>().add(
                          const ClearPendingRegistrationEvent(),
                        );
                        setState(() => _isVerifyingOtp = false);
                      },
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: CustomButton(
                text: context.l10n.uiConfirm592364,
                type: ButtonType.primary,
                isLoading: _busy,
                onPressed: _busy ? null : _onVerifyOtp,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
