import 'package:equatable/equatable.dart';

enum PaymentProvider { momo, vnpay, zalopay, cash }

enum PaymentStatus { pending, success, failed, cancelled }

/// Model representing an online payment transaction per endpoint-api.md 5.7
class PaymentTransactionModel extends Equatable {
  final int paymentId;
  final int bookingId;
  final PaymentProvider provider;
  final int amount;
  final String? paymentUrl;
  final String? deeplink;
  final String? qrCodeUrl;
  final PaymentStatus status;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? paidAt;
  final String? transactionCode;
  final String? failureReason;

  const PaymentTransactionModel({
    required this.paymentId,
    required this.bookingId,
    required this.provider,
    required this.amount,
    this.paymentUrl,
    this.deeplink,
    this.qrCodeUrl,
    required this.status,
    this.createdAt,
    this.expiresAt,
    this.paidAt,
    this.transactionCode,
    this.failureReason,
  });

  PaymentTransactionModel copyWith({
    int? paymentId,
    int? bookingId,
    PaymentProvider? provider,
    int? amount,
    String? paymentUrl,
    String? deeplink,
    String? qrCodeUrl,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? paidAt,
    String? transactionCode,
    String? failureReason,
  }) {
    return PaymentTransactionModel(
      paymentId: paymentId ?? this.paymentId,
      bookingId: bookingId ?? this.bookingId,
      provider: provider ?? this.provider,
      amount: amount ?? this.amount,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      deeplink: deeplink ?? this.deeplink,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      paidAt: paidAt ?? this.paidAt,
      transactionCode: transactionCode ?? this.transactionCode,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    PaymentProvider parseProvider(String? str) {
      switch (str?.toUpperCase()) {
        case 'MOMO':
          return PaymentProvider.momo;
        case 'VNPAY':
          return PaymentProvider.vnpay;
        case 'ZALOPAY':
          return PaymentProvider.zalopay;
        case 'CASH':
        default:
          return PaymentProvider.cash;
      }
    }

    PaymentStatus parseStatus(String? str) {
      switch (str?.toUpperCase()) {
        case 'SUCCESS':
        case 'PAID':
        case 'COMPLETED':
          return PaymentStatus.success;
        case 'FAILED':
        case 'ERROR':
          return PaymentStatus.failed;
        case 'CANCELLED':
        case 'CANCELED':
          return PaymentStatus.cancelled;
        case 'PENDING':
        default:
          return PaymentStatus.pending;
      }
    }

    return PaymentTransactionModel(
      paymentId:
          (json['paymentId'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,
      bookingId: (json['bookingId'] as num?)?.toInt() ?? 0,
      provider: parseProvider(json['provider'] as String?),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      paymentUrl: json['paymentUrl'] as String? ?? json['payUrl'] as String?,
      deeplink: json['deeplink'] as String? ?? json['deeplinkUrl'] as String?,
      qrCodeUrl: json['qrCodeUrl'] as String?,
      status: parseStatus(json['status'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'] as String)
          : null,
      transactionCode: json['transactionCode'] as String?,
      failureReason:
          json['failureReason'] as String? ?? json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'paymentId': paymentId,
    'bookingId': bookingId,
    'provider': provider.name.toUpperCase(),
    'amount': amount,
    if (paymentUrl != null) 'paymentUrl': paymentUrl,
    if (deeplink != null) 'deeplink': deeplink,
    if (qrCodeUrl != null) 'qrCodeUrl': qrCodeUrl,
    'status': status.name.toUpperCase(),
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    if (paidAt != null) 'paidAt': paidAt!.toIso8601String(),
    if (transactionCode != null) 'transactionCode': transactionCode,
    if (failureReason != null) 'failureReason': failureReason,
  };

  /// Status helpers
  bool get isPending => status == PaymentStatus.pending;
  bool get isSuccess => status == PaymentStatus.success;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  @override
  List<Object?> get props => [
    paymentId,
    bookingId,
    provider,
    amount,
    status,
    transactionCode,
  ];
}
