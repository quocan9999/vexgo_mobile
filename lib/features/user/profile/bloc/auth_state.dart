import 'package:equatable/equatable.dart';
import 'package:vexgo_app/data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, otpRequired, failure }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final String? successMessage;
  final String? pendingPhone;
  final String? pendingFullName;
  final String? pendingPassword;
  final String language; // 'vi' or 'en'
  final bool pushEnabled;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.successMessage,
    this.pendingPhone,
    this.pendingFullName,
    this.pendingPassword,
    this.language = 'vi',
    this.pushEnabled = true,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    String? successMessage,
    String? pendingPhone,
    String? pendingFullName,
    String? pendingPassword,
    String? language,
    bool? pushEnabled,
    bool clearMessages = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      pendingPhone: pendingPhone ?? this.pendingPhone,
      pendingFullName: pendingFullName ?? this.pendingFullName,
      pendingPassword: pendingPassword ?? this.pendingPassword,
      language: language ?? this.language,
      pushEnabled: pushEnabled ?? this.pushEnabled,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        errorMessage,
        successMessage,
        pendingPhone,
        pendingFullName,
        pendingPassword,
        language,
        pushEnabled,
      ];
}
