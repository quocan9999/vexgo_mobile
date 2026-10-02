import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/token_storage.dart';
import '../../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String phone, required String password});
  Future<void> sendOtp({required String phone});
  Future<UserModel> verifyOtpAndRegister({
    required String phone,
    required String otp,
    required String fullName,
    required String password,
  });
  Future<UserModel?> getCurrentUser();
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
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

      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      final userJson = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : data;
      return UserModel.fromJson(userJson);
    }
    throw Exception('Phản hồi đăng nhập không hợp lệ');
  }

  @override
  Future<void> sendOtp({required String phone}) async {
    final formattedPhone = phone.startsWith('0')
        ? '+84${phone.substring(1)}'
        : phone;
    await client.post(
      ApiConfig.authRequestOtp,
      body: {'phoneNumber': formattedPhone},
      requiresAuth: false,
    );
  }

  @override
  Future<UserModel> verifyOtpAndRegister({
    required String phone,
    required String otp,
    required String fullName,
    required String password,
  }) async {
    final formattedPhone = phone.startsWith('0')
        ? '+84${phone.substring(1)}'
        : phone;
    final verifyRes = await client.post(
      ApiConfig.authVerifyOtp,
      body: {'phoneNumber': formattedPhone, 'otp': otp},
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
      if (accessToken != null && accessToken.isNotEmpty) {
        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }
      final userJson = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : data;
      return UserModel.fromJson(userJson);
    }
    throw Exception('Phản hồi đăng ký không hợp lệ');
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final hasToken = await TokenStorage.hasAccessToken();
    if (!hasToken) return null;

    try {
      final res = await client.get(ApiConfig.authSession, requiresAuth: true);
      if (res is Map<String, dynamic>) {
        final data = res['data'] is Map<String, dynamic>
            ? res['data'] as Map<String, dynamic>
            : res;
        final userJson = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : data;
        return UserModel.fromJson(userJson);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await client.post(ApiConfig.authLogout, requiresAuth: true);
    } catch (_) {}
    await TokenStorage.clearTokens();
  }
}
