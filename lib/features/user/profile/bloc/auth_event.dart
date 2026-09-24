import 'package:equatable/equatable.dart';
import '../../../../data/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class LoginWithPhoneEvent extends AuthEvent {
  final String phone;
  final String password;

  const LoginWithPhoneEvent({
    required this.phone,
    required this.password,
  });

  @override
  List<Object?> get props => [phone, password];
}

class RequestRegisterOtpEvent extends AuthEvent {
  final String phone;
  final String fullName;
  final String password;

  const RequestRegisterOtpEvent({
    required this.phone,
    required this.fullName,
    required this.password,
  });

  @override
  List<Object?> get props => [phone, fullName, password];
}

class VerifyOtpAndRegisterEvent extends AuthEvent {
  final String phone;
  final String otp;
  final String fullName;
  final String password;

  const VerifyOtpAndRegisterEvent({
    required this.phone,
    required this.otp,
    required this.fullName,
    required this.password,
  });

  @override
  List<Object?> get props => [phone, otp, fullName, password];
}

class UpdateProfileEvent extends AuthEvent {
  final UserModel updatedUser;

  const UpdateProfileEvent(this.updatedUser);

  @override
  List<Object?> get props => [updatedUser];
}

class RedeemPointsEvent extends AuthEvent {
  final int points;
  final String rewardTitle;

  const RedeemPointsEvent({
    required this.points,
    required this.rewardTitle,
  });

  @override
  List<Object?> get props => [points, rewardTitle];
}

class ToggleLanguageEvent extends AuthEvent {
  final String languageCode; // 'vi' or 'en'

  const ToggleLanguageEvent(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

class TogglePushNotificationEvent extends AuthEvent {
  final bool enabled;

  const TogglePushNotificationEvent(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}
