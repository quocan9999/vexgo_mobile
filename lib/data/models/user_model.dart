import 'package:equatable/equatable.dart';
import 'point_transaction_model.dart';

enum MembershipTier { silver, gold, diamond }

const _unchangedProfileField = Object();

class UserModel extends Equatable {
  final int taiKhoanId;
  final String maKhachHang;
  final String hoTen;
  final String soDienThoai;
  final String? email;
  final String? cccd;
  final String? ngaySinh;
  final bool daXacThucSoDienThoai;
  final String trangThai;
  final int diemTichLuy;
  final String hangThanhVien;
  final int diemToiHangTiepTheo;
  final List<PointTransactionModel> pointHistory;

  const UserModel({
    required this.taiKhoanId,
    required this.maKhachHang,
    required this.hoTen,
    required this.soDienThoai,
    this.email,
    this.cccd,
    this.ngaySinh,
    this.daXacThucSoDienThoai = false,
    this.trangThai = 'HOAT_DONG',
    this.diemTichLuy = 0,
    this.hangThanhVien = '',
    this.diemToiHangTiepTheo = 1000,
    this.pointHistory = const [],
  });

  MembershipTier get tier {
    if (diemTichLuy >= 3000) return MembershipTier.diamond;
    if (diemTichLuy >= 1000) return MembershipTier.gold;
    return MembershipTier.silver;
  }

  String get tierName {
    if (hangThanhVien.isNotEmpty) return hangThanhVien;
    switch (tier) {
      case MembershipTier.diamond:
        return 'KIM CƯƠNG';
      case MembershipTier.gold:
        return 'VÀNG';
      case MembershipTier.silver:
        return 'BẠC';
    }
  }

  double get tierProgress {
    if (tier == MembershipTier.diamond) return 1.0;
    if (tier == MembershipTier.gold) {
      final progress = (diemTichLuy - 1000) / 2000.0;
      return progress.clamp(0.0, 1.0);
    }
    final progress = diemTichLuy / 1000.0;
    return progress.clamp(0.0, 1.0);
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final historyJson = json['pointHistory'] as List<dynamic>? ?? [];
    final accountId =
        (json['taiKhoanId'] ?? json['accountId'] ?? json['id'] as num?)
            ?.toInt() ??
        0;
    final customerCode =
        json['maKhachHang'] as String? ?? json['customerCode'] as String? ?? '';
    final fullName =
        json['hoTen'] as String? ?? json['fullName'] as String? ?? '';
    final phone =
        json['soDienThoai'] as String? ??
        json['phoneNumber'] as String? ??
        json['phone'] as String? ??
        '';
    final citizenId = json['cccd'] as String? ?? json['citizenId'] as String?;
    final dob = json['ngaySinh'] as String? ?? json['dateOfBirth'] as String?;
    final email = json['email'] as String?;
    final points =
        (json['diemTichLuy'] ?? json['loyaltyPoints'] as num?)?.toInt() ?? 0;
    final status =
        json['trangThai'] as String? ??
        json['status'] as String? ??
        'HOAT_DONG';

    return UserModel(
      taiKhoanId: accountId,
      maKhachHang: customerCode,
      hoTen: fullName,
      soDienThoai: phone,
      email: email,
      cccd: citizenId,
      ngaySinh: dob,
      daXacThucSoDienThoai:
          json['daXacThucSoDienThoai'] as bool? ??
          json['phoneVerified'] as bool? ??
          false,
      trangThai: status,
      diemTichLuy: points,
      hangThanhVien: json['hangThanhVien'] as String? ?? '',
      diemToiHangTiepTheo: json['diemToiHangTiepTheo'] as int? ?? 1000,
      pointHistory: historyJson
          .map(
            (item) =>
                PointTransactionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taiKhoanId': taiKhoanId,
      'maKhachHang': maKhachHang,
      'hoTen': hoTen,
      'soDienThoai': soDienThoai,
      'email': email,
      'cccd': cccd,
      'ngaySinh': ngaySinh,
      'daXacThucSoDienThoai': daXacThucSoDienThoai,
      'trangThai': trangThai,
      'diemTichLuy': diemTichLuy,
      'hangThanhVien': hangThanhVien,
      'diemToiHangTiepTheo': diemToiHangTiepTheo,
      'pointHistory': pointHistory.map((p) => p.toJson()).toList(),
    };
  }

  UserModel copyWith({
    int? taiKhoanId,
    String? maKhachHang,
    String? hoTen,
    String? soDienThoai,
    Object? email = _unchangedProfileField,
    Object? cccd = _unchangedProfileField,
    Object? ngaySinh = _unchangedProfileField,
    bool? daXacThucSoDienThoai,
    String? trangThai,
    int? diemTichLuy,
    String? hangThanhVien,
    int? diemToiHangTiepTheo,
    List<PointTransactionModel>? pointHistory,
  }) {
    return UserModel(
      taiKhoanId: taiKhoanId ?? this.taiKhoanId,
      maKhachHang: maKhachHang ?? this.maKhachHang,
      hoTen: hoTen ?? this.hoTen,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      email: identical(email, _unchangedProfileField)
          ? this.email
          : email as String?,
      cccd: identical(cccd, _unchangedProfileField)
          ? this.cccd
          : cccd as String?,
      ngaySinh: identical(ngaySinh, _unchangedProfileField)
          ? this.ngaySinh
          : ngaySinh as String?,
      daXacThucSoDienThoai: daXacThucSoDienThoai ?? this.daXacThucSoDienThoai,
      trangThai: trangThai ?? this.trangThai,
      diemTichLuy: diemTichLuy ?? this.diemTichLuy,
      hangThanhVien: hangThanhVien ?? this.hangThanhVien,
      diemToiHangTiepTheo: diemToiHangTiepTheo ?? this.diemToiHangTiepTheo,
      pointHistory: pointHistory ?? this.pointHistory,
    );
  }

  @override
  List<Object?> get props => [
    taiKhoanId,
    maKhachHang,
    hoTen,
    soDienThoai,
    email,
    cccd,
    ngaySinh,
    daXacThucSoDienThoai,
    trangThai,
    diemTichLuy,
    hangThanhVien,
    diemToiHangTiepTheo,
    pointHistory,
  ];
}
