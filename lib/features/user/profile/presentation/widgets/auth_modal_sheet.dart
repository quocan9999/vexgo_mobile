import 'dart:async';
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

class AuthModalSheet extends StatefulWidget {
  final bool initialIsRegister;

  const AuthModalSheet({
    super.key,
    this.initialIsRegister = false,
  });

  static void show(BuildContext context, {bool isRegister = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AuthModalSheet(initialIsRegister: isRegister),
    );
  }

  @override
  State<AuthModalSheet> createState() => _AuthModalSheetState();
}

class _AuthModalSheetState extends State<AuthModalSheet> {
  late bool _isRegister;
  final TextEditingController _phoneController = TextEditingController(text: '0987654321');
  final TextEditingController _nameController = TextEditingController(text: 'Phạm Minh Tài');
  final TextEditingController _passwordController = TextEditingController(text: '123456');
  final TextEditingController _otpController = TextEditingController();

  bool _isObscurePassword = true;
  bool _isVerifyingOtp = false;
  int _otpCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialIsRegister;
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    final pass = _passwordController.text.trim();
    if (phone.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ Số điện thoại và Mật khẩu')),
      );
      return;
    }

    context.read<AuthBloc>().add(LoginWithPhoneEvent(phone: phone, password: pass));
    Navigator.of(context).pop();
  }

  void _onRequestOtp() {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final pass = _passwordController.text.trim();

    if (phone.isEmpty || name.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin đăng ký')),
      );
      return;
    }

    context.read<AuthBloc>().add(RequestRegisterOtpEvent(
          phone: phone,
          fullName: name,
          password: pass,
        ));

    setState(() {
      _isVerifyingOtp = true;
      _otpController.text = '123456'; // Default mock code for convenience
    });
    _startTimer();
  }

  void _onVerifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số mã OTP')),
      );
      return;
    }

    context.read<AuthBloc>().add(VerifyOtpAndRegisterEvent(
          phone: _phoneController.text.trim(),
          otp: otp,
          fullName: _nameController.text.trim(),
          password: _passwordController.text.trim(),
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
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
                _isRegister ? 'Đăng ký tài khoản VexGo' : 'Đăng nhập VexGo',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: AppColors.neutral600),
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
                  onTap: () => setState(() => _isRegister = false),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isRegister ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      boxShadow: !_isRegister
                          ? const [BoxShadow(color: Color(0x0F000000), blurRadius: 4)]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Đăng nhập',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: !_isRegister ? FontWeight.w700 : FontWeight.w500,
                          color: !_isRegister ? AppColors.primary : AppColors.neutral600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isRegister = true),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _isRegister ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      boxShadow: _isRegister
                          ? const [BoxShadow(color: Color(0x0F000000), blurRadius: 4)]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Đăng ký mới',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: _isRegister ? FontWeight.w700 : FontWeight.w500,
                          color: _isRegister ? AppColors.primary : AppColors.neutral600,
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
            'Họ và tên *',
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppDimensions.xs),
          CustomTextField(
            controller: _nameController,
            hintText: 'Nhập họ và tên đầy đủ',
            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.neutral500),
          ),
          const SizedBox(height: AppDimensions.sm),
        ],

        // Số điện thoại
        Text(
          'Số điện thoại *',
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppDimensions.xs),
        CustomTextField(
          controller: _phoneController,
          hintText: 'Ví dụ: 0987654321',
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.neutral500),
        ),

        const SizedBox(height: AppDimensions.sm),

        // Mật khẩu
        Text(
          'Mật khẩu *',
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppDimensions.xs),
        CustomTextField(
          controller: _passwordController,
          hintText: 'Nhập mật khẩu',
          obscureText: _isObscurePassword,
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.neutral500),
          suffixIcon: IconButton(
            icon: Icon(
              _isObscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: AppColors.neutral500,
              size: 20,
            ),
            onPressed: () => setState(() => _isObscurePassword = !_isObscurePassword),
          ),
        ),

        const SizedBox(height: AppDimensions.lg),

        // Action button
        CustomButton(
          text: _isRegister ? 'TIẾP TỤC (XÁC THỰC OTP)' : 'ĐĂNG NHẬP NGAY',
          width: double.infinity,
          type: ButtonType.primary,
          onPressed: _isRegister ? _onRequestOtp : _onLogin,
        ),

        const SizedBox(height: AppDimensions.md),

        Center(
          child: Text(
            'Bằng việc tiếp tục, bạn đồng ý với Điều khoản sử dụng của VexGo',
            style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontSize: 11),
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
          child: const Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: AppDimensions.md),

        Text(
          'Xác thực mã OTP',
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        const SizedBox(height: AppDimensions.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
          child: Text(
            'Mã xác thực gồm 6 chữ số đã được gửi đến số điện thoại ${_phoneController.text.trim()}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral600),
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
        Text(
          '(Gợi ý mã thử nghiệm: 123456)',
          style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontStyle: FontStyle.italic),
        ),

        const SizedBox(height: AppDimensions.md),

        // Countdown and Resend button
        if (_otpCountdown > 0)
          Text(
            'Gửi lại mã sau $_otpCountdown giây',
            style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
          )
        else
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(RequestRegisterOtpEvent(
                    phone: _phoneController.text.trim(),
                    fullName: _nameController.text.trim(),
                    password: _passwordController.text.trim(),
                  ));
              _startTimer();
            },
            child: const Text('Gửi lại mã OTP'),
          ),

        const SizedBox(height: AppDimensions.lg),

        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'QUAY LẠI',
                type: ButtonType.outline,
                onPressed: () => setState(() => _isVerifyingOtp = false),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: CustomButton(
                text: 'XÁC NHẬN',
                type: ButtonType.primary,
                onPressed: _onVerifyOtp,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
