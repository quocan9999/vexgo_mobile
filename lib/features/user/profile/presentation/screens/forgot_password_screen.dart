import 'package:vexgo_app/core/localization/client_labels.dart';
import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/api_exceptions.dart';
import '../../../../../core/network/token_storage.dart';
import '../../../../../data/repositories/password_recovery_repository.dart';

enum _RecoveryStep { phone, otp, password, done }

class ForgotPasswordScreen extends StatefulWidget {
  final String initialPhone;
  final PasswordRecoveryRepository? repository;
  const ForgotPasswordScreen({
    super.key,
    this.initialPhone = '',
    this.repository,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final PasswordRecoveryRepository _repository;
  late final int _session;
  StreamSubscription<void>? _sessionSubscription;
  Timer? _timer;
  _RecoveryStep _step = _RecoveryStep.phone;
  RecoveryChallenge? _challenge;
  RecoveryProof? _proof;
  bool _busy = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _revoked = false;
  String? _error;

  bool get _active =>
      mounted && !_revoked && _session == TokenStorage.sessionVersion;
  int get _resendSeconds {
    final millis = (_challenge?.resendAfter ?? DateTime.now())
        .difference(DateTime.now())
        .inMilliseconds;
    return millis <= 0 ? 0 : (millis / 1000).ceil();
  }

  @override
  void initState() {
    super.initState();
    _phone.text = widget.initialPhone;
    _repository = widget.repository ?? PasswordRecoveryRepository();
    _session = TokenStorage.sessionVersion;
    _sessionSubscription = TokenStorage.sessionChanges.listen((_) {
      _revoked = true;
      _clearSecrets();
      if (mounted) {
        setState(() {
          _busy = false;
          _error = context.l10n.uiYourSessionHasChangedOpenForgotPasswordAgain;
        });
      }
    });
    // Render countdown from absolute deadlines, including after background/resume.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _step == _RecoveryStep.otp) setState(() {});
    });
  }

  void _clearSecrets() {
    _challenge = null;
    _proof = null;
    _otp.clear();
    _password.clear();
    _confirm.clear();
  }

  void _startOver() {
    if (_busy || !_active) return;
    _clearSecrets();
    setState(() {
      _step = _RecoveryStep.phone;
      _error = null;
    });
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy || !_active) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (!_active) return;
      setState(() {
        _error = switch (error) {
          ApiException e => e.message,
          NetworkException _ =>
            context.l10n.uiTheServerResultCouldNotBeConfirmedTry,
          FormatException e => e.message,
          _ => context.l10n.uiUnableToCompletePleaseTryAgain,
        };
        // Proof is single use: never automatically replay a reset after an
        // uncertain response or a failed/expired proof. Obtain a new OTP.
        if (_step == _RecoveryStep.password) {
          _clearSecrets();
          _step = _RecoveryStep.phone;
        }
      });
    } finally {
      if (_active) setState(() => _busy = false);
    }
  }

  Future<void> _request({bool resend = false}) async {
    if (!resend && !_form.currentState!.validate()) return;
    if (resend && _resendSeconds > 0) return;
    await _perform(() async {
      final challenge = await _repository.request(_phone.text);
      if (!_active) return;
      setState(() {
        _challenge = challenge;
        _proof = null;
        _otp.clear();
        _step = _RecoveryStep.otp;
      });
    });
  }

  Future<void> _verify() async {
    if (!_form.currentState!.validate()) return;
    final challenge = _challenge;
    if (challenge == null || !challenge.expiresAt.isAfter(DateTime.now())) {
      setState(() => _error = context.l10n.uiThisCodeHasExpiredRequestANewCode);
      return;
    }
    await _perform(() async {
      final proof = await _repository.verify(_phone.text, challenge, _otp.text);
      if (!_active) return;
      setState(() {
        _proof = proof;
        _otp.clear();
        _step = _RecoveryStep.password;
      });
    });
  }

  Future<void> _reset() async {
    if (!_form.currentState!.validate()) return;
    final proof = _proof;
    if (proof == null || !proof.expiresAt.isAfter(DateTime.now())) {
      _startOver();
      setState(
        () => _error = context.l10n.uiVerificationHasExpiredRequestANewCode,
      );
      return;
    }
    await _perform(() async {
      await _repository.reset(_phone.text, proof, _password.text);
      if (!_active) return;
      _clearSecrets();
      setState(() => _step = _RecoveryStep.done);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionSubscription?.cancel();
    _clearSecrets();
    _phone.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Widget _passwordField(
    TextEditingController controller, {
    required bool confirm,
  }) {
    final visible = confirm ? _showConfirm : _showPassword;
    return TextFormField(
      controller: controller,
      enabled: !_busy && !_revoked,
      obscureText: !visible,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: TextInputType.visiblePassword,
      decoration: InputDecoration(
        labelText: confirm
            ? context.l10n.uiConfirmNewPassword
            : context.l10n.uiNewPassword,
        helperText: confirm
            ? null
            : context.l10n.uiLabel872Utf8BytesAccentedCharactersMay,
        helperMaxLines: 3,
        errorMaxLines: 3,
        suffixIcon: IconButton(
          tooltip: visible
              ? context.l10n.uiHidePassword
              : context.l10n.uiShowPassword,
          onPressed: _busy
              ? null
              : () => setState(() {
                  if (confirm) {
                    _showConfirm = !visible;
                  } else {
                    _showPassword = !visible;
                  }
                }),
          icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
        ),
      ),
      validator: (value) => confirm
          ? (value != _password.text
                ? context.l10n.uiPasswordsDoNotMatchYet
                : null)
          : localizedClientValidation(
              context,
              PasswordRecoveryRepository.validatePassword(value ?? ''),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _busy || _revoked;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.uiForgotPassword),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(switch (_step) {
                      _RecoveryStep.phone => context.l10n.uiRecoverYourAccount,
                      _RecoveryStep.otp => context.l10n.uiVerifyPhoneNumber,
                      _RecoveryStep.password => context.l10n.uiSetANewPassword,
                      _RecoveryStep.done =>
                        context.l10n.uiPasswordResetSuccessfully,
                    }, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    if (_step == _RecoveryStep.phone) ...[
                      Text(
                        context.l10n.uiEnterYourRegisteredPhoneNumberToRequestA,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _phone,
                        enabled: !disabled,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [
                          AutofillHints.telephoneNumberNational,
                        ],
                        decoration: InputDecoration(
                          labelText: context.l10n.uiPhoneNumber,
                          hintText: context.l10n.uiExample0912345678,
                          errorMaxLines: 3,
                        ),
                        validator: (value) {
                          try {
                            PasswordRecoveryRepository.normalizePhone(
                              value ?? '',
                            );
                            return null;
                          } on FormatException catch (e) {
                            return localizedClientLabel(context, e.message);
                          }
                        },
                      ),
                    ],
                    if (_step == _RecoveryStep.otp) ...[
                      Text(
                        context.l10n.uiEnterThe6DigitVerificationCodeFor(
                          _phone.text.trim(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _otp,
                        enabled: !disabled,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: InputDecoration(
                          labelText: context.l10n.uiVerificationCode,
                          errorMaxLines: 3,
                        ),
                        validator: (value) =>
                            RegExp(r'^\d{6}$').hasMatch(value ?? '')
                            ? null
                            : context.l10n.uiEnterAll6Digits,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: disabled || _resendSeconds > 0
                            ? null
                            : () => _request(resend: true),
                        child: Text(
                          _resendSeconds > 0
                              ? context.l10n.uiResendCodeInSeconds(
                                  _resendSeconds,
                                )
                              : context.l10n.uiResendCode,
                        ),
                      ),
                    ],
                    if (_step == _RecoveryStep.password) ...[
                      Text(
                        context
                            .l10n
                            .uiResettingYourPasswordWillEndYourExistingSign,
                      ),
                      const SizedBox(height: 24),
                      _passwordField(_password, confirm: false),
                      const SizedBox(height: 20),
                      _passwordField(_confirm, confirm: true),
                    ],
                    if (_step == _RecoveryStep.done)
                      Text(context.l10n.uiSignInWithYourNewPasswordToContinue),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          localizedClientLabel(context, _error!),
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: disabled
                          ? null
                          : switch (_step) {
                              _RecoveryStep.phone => () => _request(),
                              _RecoveryStep.otp => _verify,
                              _RecoveryStep.password => _reset,
                              _RecoveryStep.done => () => Navigator.of(
                                context,
                              ).pop(_phone.text.trim()),
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: _busy
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(switch (_step) {
                                _RecoveryStep.phone =>
                                  context.l10n.uiRequestCode,
                                _RecoveryStep.otp => context.l10n.uiVerifyCode,
                                _RecoveryStep.password =>
                                  context.l10n.uiResetPassword,
                                _RecoveryStep.done =>
                                  context.l10n.uiBackToSignIn,
                              }),
                      ),
                    ),
                    if (_step == _RecoveryStep.otp ||
                        _step == _RecoveryStep.password)
                      TextButton(
                        onPressed: disabled ? null : _startOver,
                        child: Text(context.l10n.uiChangePhoneNumberStartAgain),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
