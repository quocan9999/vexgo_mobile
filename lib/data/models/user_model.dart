import 'package:equatable/equatable.dart';
import 'point_transaction_model.dart';

enum MembershipTier { silver, gold, diamond }

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
    this.daXacThucSoDienThoai = true,
    this.trangThai = 'HOAT_DONG',
    this.diemTichLuy = 0,
    this.hangThanhVien = 'BẠC',
    this.diemToiHangTiepTheo = 1000,
    this.pointHistory = const [],
  });

  MembershipTier get tier {
    if (diemTichLuy >= 3000) return MembershipTier.diamond;
    if (diemTichLuy >= 1000) return MembershipTier.gold;
    return MembershipTier.silver;
  }

  String get tierName {
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
    return UserModel(
      taiKhoanId: json['taiKhoanId'] as int? ?? 1,
      maKhachHang: json['maKhachHang'] as String? ?? 'KH-001',
      hoTen: json['hoTen'] as String? ?? 'Khách Hàng',
      soDienThoai: json['soDienThoai'] as String? ?? '',
      email: json['email'] as String?,
      cccd: json['cccd'] as String?,
      ngaySinh: json['ngaySinh'] as String?,
      daXacThucSoDienThoai: json['daXacThucSoDienThoai'] as bool? ?? true,
      trangThai: json['trangThai'] as String? ?? 'HOAT_DONG',
      diemTichLuy: json['diemTichLuy'] as int? ?? 0,
      hangThanhVien: json['hangThanhVien'] as String? ?? 'BẠC',
      diemToiHangTiepTheo: json['diemToiHangTiepTheo'] as int? ?? 1000,
      pointHistory: historyJson
          .map((item) => PointTransactionModel.fromJson(item as Map<String, dynamic>))
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
    String? email,
    String? cccd,
    String? ngaySinh,
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
      email: email ?? this.email,
      cccd: cccd ?? this.cccd,
      ngaySinh: ngaySinh ?? this.ngaySinh,
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
