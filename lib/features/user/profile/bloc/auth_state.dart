import 'package:equatable/equatable.dart';
import 'package:vexgo_app/data/models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpRequired,
  failure,
}

enum PasswordChangeStatus { idle, submitting, success, failure }

enum ProfileUpdateStatus { idle, submitting, success, failure }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final String? successMessage;
  final String? pendingPhone;
  final String? pendingFullName;
  final String? pendingPassword;
  final String? pendingChallengeId;
  final String language; // 'vi' or 'en'
  final bool pushEnabled;
  final PasswordChangeStatus passwordChangeStatus;
  final String? passwordChangeError;
  final ProfileUpdateStatus profileUpdateStatus;
  final String? profileUpdateError;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.successMessage,
    this.pendingPhone,
    this.pendingFullName,
    this.pendingPassword,
    this.pendingChallengeId,
    this.language = 'vi',
    this.pushEnabled = true,
    this.passwordChangeStatus = PasswordChangeStatus.idle,
    this.passwordChangeError,
    this.profileUpdateStatus = ProfileUpdateStatus.idle,
    this.profileUpdateError,
  });

  bool get isAuthenticated =>
      user != null && status != AuthStatus.unauthenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    bool clearUser = false,
    String? errorMessage,
    String? successMessage,
    String? pendingPhone,
    String? pendingFullName,
    String? pendingPassword,
    String? pendingChallengeId,
    bool clearPendingRegistration = false,
    String? language,
    bool? pushEnabled,
    bool clearMessages = false,
    PasswordChangeStatus? passwordChangeStatus,
    String? passwordChangeError,
    ProfileUpdateStatus? profileUpdateStatus,
    String? profileUpdateError,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
      pendingPhone: clearPendingRegistration
          ? null
          : (pendingPhone ?? this.pendingPhone),
      pendingFullName: clearPendingRegistration
          ? null
          : (pendingFullName ?? this.pendingFullName),
      pendingPassword: clearPendingRegistration
          ? null
          : (pendingPassword ?? this.pendingPassword),
      pendingChallengeId: clearPendingRegistration
          ? null
          : (pendingChallengeId ?? this.pendingChallengeId),
      language: language ?? this.language,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      passwordChangeStatus: clearUser
          ? PasswordChangeStatus.idle
          : (passwordChangeStatus ?? this.passwordChangeStatus),
      passwordChangeError: passwordChangeError,
      profileUpdateStatus: clearUser
          ? ProfileUpdateStatus.idle
          : profileUpdateStatus ?? this.profileUpdateStatus,
      profileUpdateError: profileUpdateError,
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
    pendingChallengeId,
    language,
    pushEnabled,
    passwordChangeStatus,
    passwordChangeError,
    profileUpdateStatus,
    profileUpdateError,
  ];
}
