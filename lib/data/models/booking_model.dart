import 'package:equatable/equatable.dart';
import 'ticket_model.dart';

enum BookingStatus {
  pending, // CHO_THANH_TOAN
  paid, // DA_THANH_TOAN
  cancelled, // DA_HUY
}

/// Model representing a booking order created on backend per rule-api.md
class BookingModel extends Equatable {
  final int bookingId;
  final String bookingCode;
  final int tripId;
  final BookingStatus status;
  final PassengerInfo contact;
  final String pickupPoint;
  final String dropoffPoint;
  final List<String> seats;
  final List<int> seatIds;
  final int totalAmount;
  final int originalAmount;
  final int discountAmount;
  final String? promotionCode;
  final String? holdToken;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const BookingModel({
    required this.bookingId,
    required this.bookingCode,
    required this.tripId,
    required this.status,
    required this.contact,
    required this.pickupPoint,
    required this.dropoffPoint,
    required this.seats,
    required this.seatIds,
    required this.totalAmount,
    this.originalAmount = 0,
    this.discountAmount = 0,
    this.promotionCode,
    this.holdToken,
    this.createdAt,
    this.expiresAt,
  });

  BookingModel copyWith({
    int? bookingId,
    String? bookingCode,
    int? tripId,
    BookingStatus? status,
    PassengerInfo? contact,
    String? pickupPoint,
    String? dropoffPoint,
    List<String>? seats,
    List<int>? seatIds,
    int? totalAmount,
    int? originalAmount,
    int? discountAmount,
    String? promotionCode,
    String? holdToken,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      bookingCode: bookingCode ?? this.bookingCode,
      tripId: tripId ?? this.tripId,
      status: status ?? this.status,
      contact: contact ?? this.contact,
      pickupPoint: pickupPoint ?? this.pickupPoint,
      dropoffPoint: dropoffPoint ?? this.dropoffPoint,
      seats: seats ?? this.seats,
      seatIds: seatIds ?? this.seatIds,
      totalAmount: totalAmount ?? this.totalAmount,
      originalAmount: originalAmount ?? this.originalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      promotionCode: promotionCode ?? this.promotionCode,
      holdToken: holdToken ?? this.holdToken,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    BookingStatus parseStatus(String? statusStr) {
      switch (statusStr?.toUpperCase()) {
        case 'DA_THANH_TOAN':
        case 'PAID':
        case 'SUCCESS':
          return BookingStatus.paid;
        case 'DA_HUY':
        case 'CANCELLED':
        case 'CANCELED':
          return BookingStatus.cancelled;
        case 'CHO_THANH_TOAN':
        case 'PENDING':
        default:
          return BookingStatus.pending;
      }
    }

    // Parse seats (names)
    List<String> parsedSeats = [];
    if (json['seats'] is List) {
      parsedSeats = (json['seats'] as List).map((e) => e.toString()).toList();
    }

    // Parse seatIds
    List<int> parsedSeatIds = [];
    if (json['seatIds'] is List) {
      parsedSeatIds = (json['seatIds'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }

    // Parse contact
    PassengerInfo parsedContact;
    if (json['contact'] is Map<String, dynamic>) {
      parsedContact = PassengerInfo.fromJson(
        json['contact'] as Map<String, dynamic>,
      );
    } else if (json['passenger'] is Map<String, dynamic>) {
      parsedContact = PassengerInfo.fromJson(
        json['passenger'] as Map<String, dynamic>,
      );
    } else {
      parsedContact = PassengerInfo(
        fullName: json['customerName'] as String? ?? '',
        phone: json['customerPhone'] as String? ?? '',
        email: json['customerEmail'] as String? ?? '',
      );
    }

    final totalAmount = (json['totalAmount'] as num?)?.toInt() ?? 0;
    final originalAmount =
        (json['originalAmount'] as num?)?.toInt() ?? totalAmount;
    final discountAmount = (json['discountAmount'] as num?)?.toInt() ?? 0;

    return BookingModel(
      bookingId:
          (json['bookingId'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,
      bookingCode:
          json['bookingCode'] as String? ?? json['code'] as String? ?? '',
      tripId: (json['tripId'] as num?)?.toInt() ?? 0,
      status: parseStatus(json['status'] as String?),
      contact: parsedContact,
      pickupPoint: json['pickupPoint'] as String? ?? '',
      dropoffPoint: json['dropoffPoint'] as String? ?? '',
      seats: parsedSeats,
      seatIds: parsedSeatIds,
      totalAmount: totalAmount,
      originalAmount: originalAmount,
      discountAmount: discountAmount,
      promotionCode: json['promotionCode'] as String?,
      holdToken: json['holdToken'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'bookingId': bookingId,
    'bookingCode': bookingCode,
    'tripId': tripId,
    'status': status == BookingStatus.paid
        ? 'DA_THANH_TOAN'
        : (status == BookingStatus.cancelled ? 'DA_HUY' : 'CHO_THANH_TOAN'),
    'contact': contact.toJson(),
    'pickupPoint': pickupPoint,
    'dropoffPoint': dropoffPoint,
    'seats': seats,
    'seatIds': seatIds,
    'totalAmount': totalAmount,
    'originalAmount': originalAmount,
    'discountAmount': discountAmount,
    if (promotionCode != null) 'promotionCode': promotionCode,
    if (holdToken != null) 'holdToken': holdToken,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
  };

  /// Status helpers
  bool get isPending => status == BookingStatus.pending;
  bool get isPaid => status == BookingStatus.paid;
  bool get isCancelled => status == BookingStatus.cancelled;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  @override
  List<Object?> get props => [
    bookingId,
    bookingCode,
    tripId,
    status,
    totalAmount,
    seatIds,
  ];
}
