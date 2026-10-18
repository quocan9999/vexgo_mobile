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
  final bool identityChecked;
  final bool phoneEligibilityChecked;
  final bool requiresPhoneBeforeBooking;

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
    this.identityChecked = false,
    this.phoneEligibilityChecked = false,
    this.requiresPhoneBeforeBooking = false,
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
    bool? identityChecked,
    bool? phoneEligibilityChecked,
    bool? requiresPhoneBeforeBooking,
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
      identityChecked: identityChecked ?? this.identityChecked,
      phoneEligibilityChecked:
          phoneEligibilityChecked ?? this.phoneEligibilityChecked,
      requiresPhoneBeforeBooking:
          requiresPhoneBeforeBooking ?? this.requiresPhoneBeforeBooking,
    );
  }

  factory BookingQuoteModel.fromJson(Map<String, dynamic> json) {
    int amount(String key, {int? fallback}) {
      final raw = json[key];
      final value = raw is num
          ? raw
          : raw is String
          ? num.tryParse(raw)
          : null;
      if (value == null && fallback != null && raw == null) return fallback;
      if (value == null ||
          !value.isFinite ||
          value < 0 ||
          value != value.round()) {
        throw FormatException('Invalid booking quote $key');
      }
      return value.toInt();
    }

    final unitPrice = amount('unitPrice');
    final seatCount = amount('seatCount');
    final originalTotal = amount(
      'originalTotal',
      fallback: unitPrice * seatCount,
    );
    final discountAmount = amount('discountAmount', fallback: 0);
    final serviceFee = amount('serviceFee', fallback: 0);
    final finalTotal = amount('finalTotal');
    if (seatCount <= 0 ||
        originalTotal != unitPrice * seatCount ||
        discountAmount > originalTotal ||
        finalTotal != originalTotal - discountAmount + serviceFee ||
        (json['currency'] != null && json['currency'] != 'VND')) {
      throw const FormatException('Inconsistent booking quote totals');
    }

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
      identityChecked: json['identityChecked'] == true,
      phoneEligibilityChecked: json['phoneEligibilityChecked'] == true,
      requiresPhoneBeforeBooking: json['requiresPhoneBeforeBooking'] == true,
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
    'identityChecked': identityChecked,
    'phoneEligibilityChecked': phoneEligibilityChecked,
    'requiresPhoneBeforeBooking': requiresPhoneBeforeBooking,
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
    identityChecked,
    phoneEligibilityChecked,
    requiresPhoneBeforeBooking,
  ];
}
