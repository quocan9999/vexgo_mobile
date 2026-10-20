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
  final int? orderId;
  final String? orderCode;
  final int ticketCount;
  final String? route;
  final String? origin;
  final String? destination;
  final String? departureTime;
  final String? busCompanyName;
  final String? vehicleType;
  final String? paymentStatus;
  final String? paymentMethod;
  final List<TicketModel> tickets;

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
    this.orderId,
    this.orderCode,
    this.ticketCount = 0,
    this.route,
    this.origin,
    this.destination,
    this.departureTime,
    this.busCompanyName,
    this.vehicleType,
    this.paymentStatus,
    this.paymentMethod,
    this.tickets = const [],
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
    int? orderId,
    String? orderCode,
    int? ticketCount,
    String? route,
    String? origin,
    String? destination,
    String? departureTime,
    String? busCompanyName,
    String? vehicleType,
    String? paymentStatus,
    String? paymentMethod,
    List<TicketModel>? tickets,
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
      orderId: orderId ?? this.orderId,
      orderCode: orderCode ?? this.orderCode,
      ticketCount: ticketCount ?? this.ticketCount,
      route: route ?? this.route,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureTime: departureTime ?? this.departureTime,
      busCompanyName: busCompanyName ?? this.busCompanyName,
      vehicleType: vehicleType ?? this.vehicleType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      tickets: tickets ?? this.tickets,
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
    if (json['seatNumbers'] is List) {
      parsedSeats = (json['seatNumbers'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (json['seats'] is List) {
      parsedSeats = (json['seats'] as List).map((e) => e.toString()).toList();
    }

    // Parse seatIds
    List<int> parsedSeatIds = [];
    if (json['seatIds'] is List) {
      parsedSeatIds = (json['seatIds'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }

    // Parse route and endpoints
    final origin = json['origin'] as String? ?? json['fromCityName'] as String?;
    final destination =
        json['destination'] as String? ?? json['toCityName'] as String?;
    final route =
        json['route'] as String? ??
        ((origin != null && destination != null)
            ? '$origin - $destination'
            : null);

    // Parse tickets
    List<TicketModel> parsedTickets = [];
    if (json['tickets'] is List) {
      parsedTickets = (json['tickets'] as List)
          .whereType<Map<String, dynamic>>()
          .map((t) => TicketModel.fromJson(t))
          .toList();
    }

    // Parse pickup and dropoff with fallback
    String pickupPoint = json['pickupPoint'] as String? ?? '';
    if (pickupPoint.isEmpty &&
        json['tickets'] is List &&
        (json['tickets'] as List).isNotEmpty) {
      final first = (json['tickets'] as List).first;
      if (first is Map<String, dynamic>) {
        pickupPoint =
            first['pickup'] as String? ?? first['diemDon'] as String? ?? '';
      }
    }
    String dropoffPoint = json['dropoffPoint'] as String? ?? destination ?? '';

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
    final ticketCount =
        (json['ticketCount'] as num?)?.toInt() ?? parsedTickets.length;

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
      pickupPoint: pickupPoint,
      dropoffPoint: dropoffPoint,
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
      expiresAt: (json['paymentExpiresAt'] ?? json['expiresAt']) != null
          ? DateTime.tryParse(
              (json['paymentExpiresAt'] ?? json['expiresAt']) as String,
            )
          : null,
      orderId: (json['orderId'] as num?)?.toInt(),
      orderCode: json['orderCode'] as String?,
      ticketCount: ticketCount > 0 ? ticketCount : parsedSeats.length,
      route: route,
      origin: origin,
      destination: destination,
      departureTime: json['departureTime'] as String?,
      busCompanyName:
          json['busCompanyName'] as String? ?? json['operatorName'] as String?,
      vehicleType: json['vehicleType'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      tickets: parsedTickets,
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
