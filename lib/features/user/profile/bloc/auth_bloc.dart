import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginWithPhoneEvent>(_onLoginWithPhone);
    on<RequestRegisterOtpEvent>(_onRequestRegisterOtp);
    on<VerifyOtpAndRegisterEvent>(_onVerifyOtpAndRegister);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<RedeemPointsEvent>(_onRedeemPoints);
    on<ToggleLanguageEvent>(_onToggleLanguage);
    on<TogglePushNotificationEvent>(_onTogglePushNotification);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearMessages: true,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          clearMessages: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoginWithPhone(
    LoginWithPhoneEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    try {
      final user = await authRepository.login(
        phone: event.phone,
        password: event.password,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        successMessage: 'Đăng nhập thành công! Chào mừng ${user.hoTen}',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRequestRegisterOtp(
    RequestRegisterOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    try {
      await authRepository.sendOtp(phone: event.phone);
      emit(state.copyWith(
        status: AuthStatus.otpRequired,
        pendingPhone: event.phone,
        pendingFullName: event.fullName,
        pendingPassword: event.password,
        successMessage: 'Mã xác thực OTP đã được gửi đến số ${event.phone}',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onVerifyOtpAndRegister(
    VerifyOtpAndRegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    try {
      final user = await authRepository.verifyOtpAndRegister(
        phone: event.phone,
        otp: event.otp,
        fullName: event.fullName,
        password: event.password,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        successMessage: 'Đăng ký thành công! Bạn nhận được 100 điểm VexGo thưởng.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    try {
      final updated = await authRepository.updateProfile(event.updatedUser);
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: updated,
        successMessage: 'Cập nhật thông tin cá nhân thành công!',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRedeemPoints(
    RedeemPointsEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    try {
      final updated = await authRepository.redeemPoints(
        pointsToRedeem: event.points,
        rewardTitle: event.rewardTitle,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: updated,
        successMessage: 'Đổi thành công: ${event.rewardTitle}',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  void _onToggleLanguage(
    ToggleLanguageEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      language: event.languageCode,
      successMessage: event.languageCode == 'en' ? 'Switched to English' : 'Đã đổi sang Tiếng Việt',
    ));
  }

  void _onTogglePushNotification(
    TogglePushNotificationEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      pushEnabled: event.enabled,
      successMessage: event.enabled ? 'Đã bật thông báo đẩy' : 'Đã tắt thông báo đẩy',
    ));
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    await authRepository.logout();
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
      successMessage: 'Đã đăng xuất tài khoản an toàn.',
    ));
  }
}
