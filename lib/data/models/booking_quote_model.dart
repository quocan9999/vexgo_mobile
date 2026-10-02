import 'package:equatable/equatable.dart';

/// Model representing a booking quote preview calculated by backend per rule-api.md
class BookingQuoteModel extends Equatable {
  final int unitPrice;
  final int seatCount;
  final int originalTotal;
  final int discountAmount;
  final int serviceFee;
  final int finalTotal;
  final String currency;
  final String? appliedPromotionCode;
  final String? promotionDescription;

  const BookingQuoteModel({
    required this.unitPrice,
    required this.seatCount,
    required this.originalTotal,
    required this.discountAmount,
    this.serviceFee = 0,
    required this.finalTotal,
    this.currency = 'VND',
    this.appliedPromotionCode,
    this.promotionDescription,
  });

  BookingQuoteModel copyWith({
    int? unitPrice,
    int? seatCount,
    int? originalTotal,
    int? discountAmount,
    int? serviceFee,
    int? finalTotal,
    String? currency,
    String? appliedPromotionCode,
    String? promotionDescription,
  }) {
    return BookingQuoteModel(
      unitPrice: unitPrice ?? this.unitPrice,
      seatCount: seatCount ?? this.seatCount,
      originalTotal: originalTotal ?? this.originalTotal,
      discountAmount: discountAmount ?? this.discountAmount,
      serviceFee: serviceFee ?? this.serviceFee,
      finalTotal: finalTotal ?? this.finalTotal,
      currency: currency ?? this.currency,
      appliedPromotionCode: appliedPromotionCode ?? this.appliedPromotionCode,
      promotionDescription: promotionDescription ?? this.promotionDescription,
    );
  }

  factory BookingQuoteModel.fromJson(Map<String, dynamic> json) {
    final unitPrice = (json['unitPrice'] as num?)?.toInt() ?? 0;
    final seatCount = (json['seatCount'] as num?)?.toInt() ?? 0;
    final originalTotal =
        (json['originalTotal'] as num?)?.toInt() ?? (unitPrice * seatCount);
    final discountAmount = (json['discountAmount'] as num?)?.toInt() ?? 0;
    final serviceFee = (json['serviceFee'] as num?)?.toInt() ?? 0;
    final finalTotal =
        (json['finalTotal'] as num?)?.toInt() ??
        (originalTotal - discountAmount + serviceFee);

    return BookingQuoteModel(
      unitPrice: unitPrice,
      seatCount: seatCount,
      originalTotal: originalTotal,
      discountAmount: discountAmount,
      serviceFee: serviceFee,
      finalTotal: finalTotal,
      currency: json['currency'] as String? ?? 'VND',
      appliedPromotionCode:
          json['appliedPromotionCode'] as String? ??
          json['promotionCode'] as String?,
      promotionDescription: json['promotionDescription'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'unitPrice': unitPrice,
    'seatCount': seatCount,
    'originalTotal': originalTotal,
    'discountAmount': discountAmount,
    'serviceFee': serviceFee,
    'finalTotal': finalTotal,
    'currency': currency,
    if (appliedPromotionCode != null)
      'appliedPromotionCode': appliedPromotionCode,
    if (promotionDescription != null)
      'promotionDescription': promotionDescription,
  };

  @override
  List<Object?> get props => [
    unitPrice,
    seatCount,
    originalTotal,
    discountAmount,
    serviceFee,
    finalTotal,
    currency,
    appliedPromotionCode,
  ];
}
