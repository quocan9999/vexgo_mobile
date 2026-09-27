import 'package:equatable/equatable.dart';

class VoucherModel extends Equatable {
  final String code;
  final String title;
  final String description;
  final int discountAmount;
  final int discountPercent;
  final int? maxDiscount;
  final int minOrderAmount;
  final String expiryDate;
  final bool isApplicable;

  const VoucherModel({
    required this.code,
    required this.title,
    required this.description,
    required this.discountAmount,
    required this.discountPercent,
    this.maxDiscount,
    required this.minOrderAmount,
    required this.expiryDate,
    required this.isApplicable,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      discountAmount: json['discountAmount'] as int? ?? 0,
      discountPercent: json['discountPercent'] as int? ?? 0,
      maxDiscount: json['maxDiscount'] as int?,
      minOrderAmount: json['minOrderAmount'] as int? ?? 0,
      expiryDate: json['expiryDate'] as String? ?? '',
      isApplicable: json['isApplicable'] as bool? ?? true,
    );
  }

  int calculateDiscount(int orderTotal) {
    if (orderTotal < minOrderAmount) return 0;
    if (discountAmount > 0) return discountAmount;
    if (discountPercent > 0) {
      final calculated = (orderTotal * discountPercent / 100).round();
      if (maxDiscount != null && calculated > maxDiscount!) {
        return maxDiscount!;
      }
      return calculated;
    }
    return 0;
  }

  @override
  List<Object?> get props => [code, discountAmount, discountPercent, minOrderAmount];
}
