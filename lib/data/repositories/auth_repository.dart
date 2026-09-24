import 'package:vexgo_app/core/utils/json_loader.dart';
import '../models/point_transaction_model.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> login({required String phone, required String password});
  Future<void> sendOtp({required String phone});
  Future<UserModel> verifyOtpAndRegister({
    required String phone,
    required String otp,
    required String fullName,
    required String password,
  });
  Future<UserModel> updateProfile(UserModel updatedUser);
  Future<UserModel> redeemPoints({
    required int pointsToRedeem,
    required String rewardTitle,
  });
  Future<void> logout();
}

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;

  @override
  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    try {
      final jsonMap = await JsonLoader.loadJsonMap('assets/mock_data/user_profile.json');
      _currentUser = UserModel.fromJson(jsonMap);
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel> login({required String phone, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (phone.isEmpty || password.isEmpty) {
      throw Exception('Số điện thoại và mật khẩu không được để trống.');
    }
    // Load default profile or create one for phone
    final user = await getCurrentUser();
    if (user != null) {
      _currentUser = user.copyWith(soDienThoai: phone);
      return _currentUser!;
    }
    _currentUser = UserModel(
      taiKhoanId: 101,
      maKhachHang: 'KH-VEXGO-${phone.substring(phone.length >= 4 ? phone.length - 4 : 0)}',
      hoTen: 'Phạm Minh Tài',
      soDienThoai: phone,
      email: 'nguyen221205@gmail.com',
      diemTichLuy: 1450,
      hangThanhVien: 'VÀNG',
    );
    return _currentUser!;
  }

  @override
  Future<void> sendOtp({required String phone}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (phone.length < 9) {
      throw Exception('Số điện thoại không hợp lệ.');
    }
    // In mock, OTP is always sent (e.g. 123456)
  }

  @override
  Future<UserModel> verifyOtpAndRegister({
    required String phone,
    required String otp,
    required String fullName,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (otp != '123456' && otp.length != 6) {
      throw Exception('Mã OTP không chính xác hoặc đã hết hạn.');
    }
    _currentUser = UserModel(
      taiKhoanId: DateTime.now().millisecondsSinceEpoch % 10000,
      maKhachHang: 'KH-NEW-${phone.substring(phone.length >= 4 ? phone.length - 4 : 0)}',
      hoTen: fullName.isNotEmpty ? fullName : 'Khách hàng mới',
      soDienThoai: phone,
      email: null,
      diemTichLuy: 100, // Tặng 100 điểm chào mừng
      hangThanhVien: 'BẠC',
      pointHistory: [
        PointTransactionModel(
          id: 'PT-WELCOME',
          title: 'Thưởng 100 điểm chào mừng thành viên mới',
          points: 100,
          type: PointTransactionType.bonus,
          createdAt: DateTime.now(),
        ),
      ],
    );
    return _currentUser!;
  }

  @override
  Future<UserModel> updateProfile(UserModel updatedUser) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = updatedUser;
    return _currentUser!;
  }

  @override
  Future<UserModel> redeemPoints({
    required int pointsToRedeem,
    required String rewardTitle,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (_currentUser == null) throw Exception('Người dùng chưa đăng nhập.');
    if (_currentUser!.diemTichLuy < pointsToRedeem) {
      throw Exception('Số điểm tích lũy không đủ để đổi ưu đãi này.');
    }

    final newPoints = _currentUser!.diemTichLuy - pointsToRedeem;
    final newTx = PointTransactionModel(
      id: 'PT-${DateTime.now().millisecondsSinceEpoch % 10000}',
      title: rewardTitle,
      points: -pointsToRedeem,
      type: PointTransactionType.redeem,
      createdAt: DateTime.now(),
    );

    final newHistory = [newTx, ..._currentUser!.pointHistory];
    _currentUser = _currentUser!.copyWith(
      diemTichLuy: newPoints,
      pointHistory: newHistory,
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }
}
