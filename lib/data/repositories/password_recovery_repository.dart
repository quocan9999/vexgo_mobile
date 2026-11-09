import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/network/token_storage.dart';

class RecoveryChallenge {
  final String id;
  final DateTime expiresAt;
  final DateTime resendAfter;
  const RecoveryChallenge(this.id, this.expiresAt, this.resendAfter);
}

class RecoveryProof {
  final String value;
  final DateTime expiresAt;
  const RecoveryProof(this.value, this.expiresAt);
}

/// Public recovery endpoints. Never stores passwords/proofs or creates a session.
class PasswordRecoveryRepository {
  final ApiClient client;
  PasswordRecoveryRepository({ApiClient? client})
    : client = client ?? ApiClient();

  static String normalizePhone(String value) {
    final phone = value.trim();
    final normalized = phone.startsWith('0')
        ? '+84${phone.substring(1)}'
        : phone;
    if (!RegExp(r'^\+84\d{9}$').hasMatch(normalized)) {
      throw const FormatException('Nhập số điện thoại Việt Nam hợp lệ.');
    }
    return normalized;
  }

  static String? validatePassword(String value) {
    final bytes = utf8.encode(value).length;
    return bytes < 8 || bytes > 72
        ? 'Mật khẩu phải dài từ 8 đến 72 byte UTF-8.'
        : null;
  }

  Map<String, dynamic> _data(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response.containsKey('data') ? response['data'] : response;
      if (data is Map<String, dynamic>) return data;
    }
    throw const FormatException('Phản hồi khôi phục mật khẩu không hợp lệ.');
  }

  String _string(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Phản hồi khôi phục mật khẩu không đầy đủ.');
    }
    return value;
  }

  DateTime _date(Map<String, dynamic> data, String key) {
    final raw = _string(data, key);
    // Require an explicit timezone; never interpret a server deadline as local.
    if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(raw)) {
      throw const FormatException('Thời hạn xác thực không hợp lệ.');
    }
    final value = DateTime.tryParse(raw);
    if (value == null) {
      throw const FormatException('Thời hạn xác thực không hợp lệ.');
    }
    return value;
  }

  Future<RecoveryChallenge> request(String phone) async {
    final data = _data(
      await client.post(
        ApiConfig.forgotPasswordRequest,
        expectedSessionVersion: TokenStorage.sessionVersion,
        body: {'phoneNumber': normalizePhone(phone)},
        requiresAuth: false,
      ),
    );
    return RecoveryChallenge(
      _string(data, 'challengeId'),
      _date(data, 'expiresAt'),
      _date(data, 'resendAfter'),
    );
  }

  Future<RecoveryProof> verify(
    String phone,
    RecoveryChallenge challenge,
    String otp,
  ) async {
    if (!RegExp(r'^\d{6}$').hasMatch(otp.trim())) {
      throw const FormatException('Mã OTP phải gồm 6 chữ số.');
    }
    final data = _data(
      await client.post(
        ApiConfig.forgotPasswordVerify,
        expectedSessionVersion: TokenStorage.sessionVersion,
        body: {
          'phoneNumber': normalizePhone(phone),
          'challengeId': challenge.id,
          'otp': otp.trim(),
        },
        requiresAuth: false,
      ),
    );
    return RecoveryProof(_string(data, 'otpProof'), _date(data, 'expiresAt'));
  }

  Future<void> reset(String phone, RecoveryProof proof, String password) async {
    final error = validatePassword(password);
    if (error != null) throw FormatException(error);
    final data = _data(
      await client.post(
        ApiConfig.forgotPasswordReset,
        expectedSessionVersion: TokenStorage.sessionVersion,
        body: {
          'phoneNumber': normalizePhone(phone),
          'otpProof': proof.value,
          'newPassword': password,
        },
        requiresAuth: false,
      ),
    );
    _string(data, 'message');
  }
}
