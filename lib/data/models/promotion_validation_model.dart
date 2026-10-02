import 'package:equatable/equatable.dart';

/// Model representing promotion code validation result from backend
class PromotionValidationModel extends Equatable {
  final String code;
  final bool isValid;
  final int discountAmount;
  final int? discountPercent;
  final String? description;
  final String? reason;

  const PromotionValidationModel({
    required this.code,
    required this.isValid,
    required this.discountAmount,
    this.discountPercent,
    this.description,
    this.reason,
  });

  PromotionValidationModel copyWith({
    String? code,
    bool? isValid,
    int? discountAmount,
    int? discountPercent,
    String? description,
    String? reason,
  }) {
    return PromotionValidationModel(
      code: code ?? this.code,
      isValid: isValid ?? this.isValid,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercent: discountPercent ?? this.discountPercent,
      description: description ?? this.description,
      reason: reason ?? this.reason,
    );
  }

  factory PromotionValidationModel.fromJson(Map<String, dynamic> json) {
    return PromotionValidationModel(
      code: json['code'] as String? ?? '',
      isValid: json['isValid'] as bool? ?? (json['valid'] as bool? ?? false),
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toInt(),
      description: json['description'] as String?,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'isValid': isValid,
    'discountAmount': discountAmount,
    if (discountPercent != null) 'discountPercent': discountPercent,
    if (description != null) 'description': description,
    if (reason != null) 'reason': reason,
  };

  @override
  List<Object?> get props => [
    code,
    isValid,
    discountAmount,
    discountPercent,
    description,
    reason,
  ];
}
