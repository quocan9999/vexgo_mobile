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
          _error = 'Phiên đã thay đổi. Vui lòng mở lại Quên mật khẩu.';
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
            'Chưa xác nhận được kết quả từ máy chủ. Nếu vừa đặt lại mật khẩu, hãy thử đăng nhập bằng mật khẩu mới; nếu chưa được, yêu cầu OTP mới.',
          FormatException e => e.message,
          _ => 'Không thể hoàn tất. Vui lòng thử lại.',
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
      setState(() => _error = 'Mã OTP đã hết hạn. Vui lòng gửi lại mã.');
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
      setState(() => _error = 'Xác thực đã hết hạn. Vui lòng yêu cầu OTP mới.');
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
        labelText: confirm ? 'Xác nhận mật khẩu mới' : 'Mật khẩu mới',
        helperText: confirm
            ? null
            : '8–72 byte UTF-8; ký tự có dấu có thể chiếm nhiều byte.',
        helperMaxLines: 3,
        errorMaxLines: 3,
        suffixIcon: IconButton(
          tooltip: visible ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
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
          ? (value != _password.text ? 'Hai mật khẩu chưa khớp.' : null)
          : PasswordRecoveryRepository.validatePassword(value ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _busy || _revoked;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
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
                      _RecoveryStep.phone => 'Lấy lại quyền truy cập',
                      _RecoveryStep.otp => 'Xác thực số điện thoại',
                      _RecoveryStep.password => 'Đặt mật khẩu mới',
                      _RecoveryStep.done => 'Đặt lại mật khẩu thành công',
                    }, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    if (_step == _RecoveryStep.phone) ...[
                      const Text(
                        'Nhập số điện thoại đã đăng ký để yêu cầu mã xác thực.',
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _phone,
                        enabled: !disabled,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [
                          AutofillHints.telephoneNumberNational,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          hintText: 'Ví dụ: 0912345678',
                          errorMaxLines: 3,
                        ),
                        validator: (value) {
                          try {
                            PasswordRecoveryRepository.normalizePhone(
                              value ?? '',
                            );
                            return null;
                          } on FormatException catch (e) {
                            return e.message;
                          }
                        },
                      ),
                    ],
                    if (_step == _RecoveryStep.otp) ...[
                      Text(
                        'Nhập mã OTP gồm 6 chữ số cho ${_phone.text.trim()}.',
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
                        decoration: const InputDecoration(
                          labelText: 'Mã OTP',
                          errorMaxLines: 3,
                        ),
                        validator: (value) =>
                            RegExp(r'^\d{6}$').hasMatch(value ?? '')
                            ? null
                            : 'Nhập đủ 6 chữ số.',
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: disabled || _resendSeconds > 0
                            ? null
                            : () => _request(resend: true),
                        child: Text(
                          _resendSeconds > 0
                              ? 'Gửi lại mã sau $_resendSeconds giây'
                              : 'Gửi lại mã OTP',
                        ),
                      ),
                    ],
                    if (_step == _RecoveryStep.password) ...[
                      const Text(
                        'Sau khi đặt lại mật khẩu, các phiên đăng nhập cũ sẽ hết hiệu lực.',
                      ),
                      const SizedBox(height: 24),
                      _passwordField(_password, confirm: false),
                      const SizedBox(height: 20),
                      _passwordField(_confirm, confirm: true),
                    ],
                    if (_step == _RecoveryStep.done)
                      const Text(
                        'Vui lòng đăng nhập bằng mật khẩu mới để tiếp tục.',
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
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
                                _RecoveryStep.phone => 'Yêu cầu mã OTP',
                                _RecoveryStep.otp => 'Xác nhận OTP',
                                _RecoveryStep.password => 'Đặt lại mật khẩu',
                                _RecoveryStep.done => 'Về đăng nhập',
                              }),
                      ),
                    ),
                    if (_step == _RecoveryStep.otp ||
                        _step == _RecoveryStep.password)
                      TextButton(
                        onPressed: disabled ? null : _startOver,
                        child: const Text('Đổi số điện thoại / Bắt đầu lại'),
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
