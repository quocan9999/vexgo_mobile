import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/token_storage.dart';
import '../../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String phone, required String password});
  Future<String> sendOtp({required String phone});
  Future<UserModel> verifyOtpAndRegister({
    required String phone,
    required String otp,
    required String fullName,
    required String password,
    String? challengeId,
  });
  Future<UserModel?> getCurrentUser();
  Future<UserModel> updateProfile({
    String? fullName,
    String? dateOfBirth,
    String? email,
    String? citizenId,
  });
  Future<void> logout();
  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient client;
  int _generation = 0;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    final generation = ++_generation;
    final sessionVersion = TokenStorage.sessionVersion;
    final formattedPhone = phone.startsWith('0')
        ? '+84${phone.substring(1)}'
        : phone;
    final body = {'phoneNumber': formattedPhone, 'password': password};

    final res = await client.post(
      ApiConfig.authLogin,
      body: body,
      requiresAuth: false,
    );

    if (res is Map<String, dynamic>) {
      final data = res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : res;
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;

      if (generation != _generation ||
          sessionVersion != TokenStorage.sessionVersion) {
        throw StateError('Phiên đăng nhập đã thay đổi.');
      }
      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        throw const FormatException('Phản hồi xác thực thiếu thông tin phiên.');
      }
      if (accessToken.isNotEmpty) {
        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      if (generation != _generation) {
        throw StateError('Phiên đăng nhập đã thay đổi.');
      }
      return _loadAuthenticatedProfile(generation);
    }
    throw Exception('Phản hồi đăng nhập không hợp lệ');
  }

  @override
  Future<String> sendOtp({required String phone}) async {
    final formattedPhone = phone.startsWith('0')
        ? '+84${phone.substring(1)}'
        : phone;
    final res = await client.post(
      ApiConfig.authRequestOtp,
      body: {'phoneNumber': formattedPhone},
      requiresAuth: false,
    );
    if (res is Map<String, dynamic>) {
      final challengeId =
          res['challengeId'] as String? ??
          (res['data'] is Map<String, dynamic>
              ? res['data']['challengeId'] as String?
              : null);
      if (challengeId != null && challengeId.isNotEmpty) {
        return challengeId;
      }
    }
    throw const FormatException('Máy chủ không cấp mã yêu cầu OTP.');
  }

  @override
  Future<UserModel> verifyOtpAndRegister({
    required String phone,
    required String otp,
    required String fullName,
    required String password,
    String? challengeId,
  }) async {
    final generation = ++_generation;
    final sessionVersion = TokenStorage.sessionVersion;
    final formattedPhone = phone.startsWith('0')
        ? '+84${phone.substring(1)}'
        : phone;
    final verifyBody = <String, dynamic>{
      'phoneNumber': formattedPhone,
      'otp': otp,
    };
    if (challengeId != null && challengeId.isNotEmpty) {
      verifyBody['challengeId'] = challengeId;
    }
    final verifyRes = await client.post(
      ApiConfig.authVerifyOtp,
      body: verifyBody,
      requiresAuth: false,
    );

    String otpProof = '';
    if (verifyRes is Map<String, dynamic>) {
      otpProof =
          verifyRes['otpProof'] as String? ??
          (verifyRes['data'] is Map<String, dynamic>
              ? verifyRes['data']['otpProof'] as String? ?? ''
              : '');
    }

    if (otpProof.isEmpty) {
      throw const FormatException('Máy chủ không cấp bằng chứng OTP.');
    }
    if (generation != _generation) throw StateError('Đăng ký đã bị hủy.');
    final registerRes = await client.post(
      ApiConfig.authRegister,
      body: {
        'fullName': fullName,
        'phoneNumber': formattedPhone,
        'password': password,
        'otpProof': otpProof,
      },
      requiresAuth: false,
    );

    if (registerRes is Map<String, dynamic>) {
      final data = registerRes['data'] is Map<String, dynamic>
          ? registerRes['data'] as Map<String, dynamic>
          : registerRes;
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      if (generation != _generation ||
          sessionVersion != TokenStorage.sessionVersion) {
        throw StateError('Đăng ký đã bị hủy.');
      }
      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        throw const FormatException('Phản hồi xác thực thiếu thông tin phiên.');
      }
      if (accessToken.isNotEmpty) {
        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }
      if (generation != _generation) {
        throw StateError('Phiên đăng nhập đã thay đổi.');
      }
      return _loadAuthenticatedProfile(generation);
    }
    throw Exception('Phản hồi đăng ký không hợp lệ');
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final hasToken = await TokenStorage.hasAccessToken();
    if (!hasToken) return null;

    return _loadAuthenticatedProfile(_generation);
  }

  Future<UserModel> _loadAuthenticatedProfile(int generation) async {
    final sessionVersion = TokenStorage.sessionVersion;
    final res = await client.get(ApiConfig.me, requiresAuth: true);
    if (generation != _generation ||
        sessionVersion != TokenStorage.sessionVersion) {
      throw StateError('Phiên đăng nhập đã thay đổi.');
    }
    if (res is! Map<String, dynamic>) {
      throw const FormatException('Hồ sơ không hợp lệ.');
    }
    final data = res['data'] is Map<String, dynamic>
        ? res['data'] as Map<String, dynamic>
        : res;
    final user = UserModel.fromJson(data);
    if (user.taiKhoanId <= 0 || user.soDienThoai.isEmpty) {
      throw const FormatException('Hồ sơ không đầy đủ.');
    }
    return user;
  }

  @override
  Future<UserModel> updateProfile({
    String? fullName,
    String? dateOfBirth,
    String? email,
    String? citizenId,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    body['dateOfBirth'] = dateOfBirth;
    body['email'] = email;
    body['citizenId'] = citizenId;
    final res = await client.patch(
      ApiConfig.me,
      body: body,
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      final data = res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : res;
      return UserModel.fromJson(data);
    }
    throw Exception('Phản hồi cập nhật thông tin không hợp lệ');
  }

  @override
  Future<void> logout() async {
    _generation++;
    final refreshToken = await TokenStorage.getRefreshToken();
    await TokenStorage.clearTokens();
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await client.post(
          ApiConfig.authLogout,
          body: {'refreshToken': refreshToken},
          requiresAuth: false,
        );
      }
    } catch (_) {
      // Local logout is complete even when remote revocation is unavailable.
    }
  }

  @override
  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final generation = _generation;
    final sessionVersion = TokenStorage.sessionVersion;
    final res = await client.post(
      ApiConfig.authChangePassword,
      body: {'oldPassword': oldPassword, 'newPassword': newPassword},
      requiresAuth: true,
    );
    if (generation != _generation ||
        sessionVersion != TokenStorage.sessionVersion) {
      throw StateError('Phiên đăng nhập đã thay đổi.');
    }
    final data =
        res is Map<String, dynamic> && res['data'] is Map<String, dynamic>
        ? res['data'] as Map<String, dynamic>
        : res;
    if (data is! Map<String, dynamic> ||
        data['message'] is! String ||
        (data['message'] as String).trim().isEmpty) {
      throw const FormatException('Máy chủ chưa xác nhận đổi mật khẩu.');
    }
    return data['message'] as String;
  }
}
