import 'dart:async';
import 'dart:convert';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  int _generation = 0;
  late final StreamSubscription<void> _invalidations;

  AuthBloc({required this.authRepository}) : super(const AuthState()) {
    _invalidations = TokenStorage.sessionInvalidations.listen((_) {
      _generation++;
      if (!isClosed) {
        // Token invalidation must clear the session before any pending response.
        // ignore: invalid_use_of_visible_for_testing_member
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearUser: true,
            clearPendingRegistration: true,
            clearMessages: true,
          ),
        );
      }
    });
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginWithPhoneEvent>(_onLoginWithPhone);
    on<RequestRegisterOtpEvent>(_onRequestRegisterOtp);
    on<VerifyOtpAndRegisterEvent>(_onVerifyOtpAndRegister);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<ChangePasswordEvent>(_onChangePassword);
    on<RedeemPointsEvent>(_onRedeemPoints);
    on<ToggleLanguageEvent>(_onToggleLanguage);
    on<TogglePushNotificationEvent>(_onTogglePushNotification);
    on<LogoutEvent>(_onLogout);
    on<ClearPendingRegistrationEvent>(_onClearPendingRegistration);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    final generation = ++_generation;
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await authRepository.getCurrentUser();
      if (generation != _generation) return;
      if (user != null) {
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            clearPendingRegistration: true,
            clearMessages: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearUser: true,
            clearPendingRegistration: true,
            clearMessages: true,
          ),
        );
      }
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: e is UnauthorizedException
              ? AuthStatus.unauthenticated
              : AuthStatus.failure,
          clearUser: true,
          clearPendingRegistration: true,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoginWithPhone(
    LoginWithPhoneEvent event,
    Emitter<AuthState> emit,
  ) async {
    final generation = ++_generation;
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    try {
      final user = await authRepository.login(
        phone: event.phone,
        password: event.password,
      );
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearPendingRegistration: true,
          successMessage: 'Đăng nhập thành công! Chào mừng ${user.hoTen}',
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onRequestRegisterOtp(
    RequestRegisterOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    final generation = ++_generation;
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    try {
      final challengeId = await authRepository.sendOtp(phone: event.phone);
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: AuthStatus.otpRequired,
          pendingPhone: event.phone,
          pendingFullName: event.fullName,
          pendingPassword: event.password,
          pendingChallengeId: challengeId.isNotEmpty ? challengeId : null,
          successMessage:
              'Yêu cầu xác thực OTP đã được tạo cho số ${event.phone}',
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onVerifyOtpAndRegister(
    VerifyOtpAndRegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    final generation = ++_generation;
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    try {
      final user = await authRepository.verifyOtpAndRegister(
        phone: event.phone,
        otp: event.otp,
        fullName: event.fullName,
        password: event.password,
        challengeId: event.challengeId ?? state.pendingChallengeId,
      );
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearPendingRegistration: true,
          successMessage: 'Đăng ký tài khoản thành công!',
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (!state.isAuthenticated ||
        state.profileUpdateStatus == ProfileUpdateStatus.submitting ||
        event.updatedUser.taiKhoanId != state.user!.taiKhoanId) {
      return;
    }
    final generation = _generation;
    final sessionVersion = TokenStorage.sessionVersion;
    final accountId = state.user!.taiKhoanId;
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        profileUpdateStatus: ProfileUpdateStatus.submitting,
        clearMessages: true,
      ),
    );
    try {
      final updated = await authRepository.updateProfile(event.updatedUser);
      if (generation != _generation ||
          sessionVersion != TokenStorage.sessionVersion) {
        return;
      }
      if (updated.taiKhoanId != accountId) {
        throw const FormatException('Hồ sơ trả về không khớp tài khoản.');
      }
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: updated,
          profileUpdateStatus: ProfileUpdateStatus.success,
          successMessage: 'Cập nhật thông tin cá nhân thành công!',
        ),
      );
    } catch (e) {
      if (generation != _generation ||
          sessionVersion != TokenStorage.sessionVersion) {
        return;
      }
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          profileUpdateStatus: ProfileUpdateStatus.failure,
          profileUpdateError: e.toString().replaceAll('Exception: ', ''),
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onRedeemPoints(
    RedeemPointsEvent event,
    Emitter<AuthState> emit,
  ) async {
    final generation = _generation;
    emit(state.copyWith(status: AuthStatus.loading, clearMessages: true));
    try {
      final updated = await authRepository.redeemPoints(
        pointsToRedeem: event.points,
        rewardTitle: event.rewardTitle,
      );
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: updated,
          successMessage: 'Đổi thành công: ${event.rewardTitle}',
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (!state.isAuthenticated ||
        state.passwordChangeStatus == PasswordChangeStatus.submitting) {
      return;
    }
    final bytes = utf8.encode(event.newPassword).length;
    if (event.oldPassword.isEmpty ||
        bytes < 8 ||
        bytes > 72 ||
        event.oldPassword == event.newPassword) {
      emit(
        state.copyWith(
          passwordChangeStatus: PasswordChangeStatus.failure,
          passwordChangeError:
              'Nhập mật khẩu cũ và mật khẩu mới khác, dài 8–72 byte UTF-8.',
        ),
      );
      return;
    }
    final generation = _generation;
    final sessionVersion = TokenStorage.sessionVersion;
    emit(state.copyWith(passwordChangeStatus: PasswordChangeStatus.submitting));
    try {
      await authRepository.changePassword(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
      );
      if (generation != _generation ||
          sessionVersion != TokenStorage.sessionVersion) {
        return;
      }
      emit(state.copyWith(passwordChangeStatus: PasswordChangeStatus.success));
    } catch (e) {
      if (generation != _generation ||
          sessionVersion != TokenStorage.sessionVersion) {
        return;
      }
      emit(
        state.copyWith(
          passwordChangeStatus: PasswordChangeStatus.failure,
          passwordChangeError: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _invalidations.cancel();
    return super.close();
  }

  void _onToggleLanguage(ToggleLanguageEvent event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        language: event.languageCode,
        successMessage: event.languageCode == 'en'
            ? 'Switched to English'
            : 'Đã đổi sang Tiếng Việt',
      ),
    );
  }

  void _onTogglePushNotification(
    TogglePushNotificationEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(
      state.copyWith(
        pushEnabled: event.enabled,
        successMessage: event.enabled
            ? 'Đã bật thông báo đẩy'
            : 'Đã tắt thông báo đẩy',
      ),
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    _generation++;
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        clearPendingRegistration: true,
        clearMessages: true,
      ),
    );
    await authRepository.logout();
  }

  void _onClearPendingRegistration(
    ClearPendingRegistrationEvent event,
    Emitter<AuthState> emit,
  ) {
    _generation++;
    emit(
      state.copyWith(
        status: state.user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        clearPendingRegistration: true,
        clearMessages: true,
      ),
    );
  }
}
