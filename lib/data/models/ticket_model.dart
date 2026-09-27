import 'package:equatable/equatable.dart';
import 'review_model.dart';

enum TicketStatus { upcoming, completed, cancelled }

class PassengerInfo extends Equatable {
  final String fullName;
  final String phone;
  final String email;

  const PassengerInfo({
    required this.fullName,
    required this.phone,
    required this.email,
  });

  factory PassengerInfo.fromJson(Map<String, dynamic> json) {
    return PassengerInfo(
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'phone': phone,
    'email': email,
  };

  @override
  List<Object?> get props => [fullName, phone, email];
}

class TicketTripSummary extends Equatable {
  final String id;
  final String operatorName;
  final String vehicleType;
  final String departureTime;
  final String departureDate;
  final String arrivalTime;
  final String arrivalDate;
  final String fromCity;
  final String toCity;
  final String pickupPoint;
  final String pickupAddress;
  final String dropoffPoint;
  final String dropoffAddress;

  const TicketTripSummary({
    required this.id,
    required this.operatorName,
    required this.vehicleType,
    required this.departureTime,
    required this.departureDate,
    required this.arrivalTime,
    required this.arrivalDate,
    required this.fromCity,
    required this.toCity,
    required this.pickupPoint,
    required this.pickupAddress,
    required this.dropoffPoint,
    required this.dropoffAddress,
  });

  factory TicketTripSummary.fromJson(Map<String, dynamic> json) {
    return TicketTripSummary(
      id: json['id'] as String? ?? '',
      operatorName: json['operatorName'] as String? ?? '',
      vehicleType: json['vehicleType'] as String? ?? '',
      departureTime: json['departureTime'] as String? ?? '',
      departureDate: json['departureDate'] as String? ?? '',
      arrivalTime: json['arrivalTime'] as String? ?? '',
      arrivalDate: json['arrivalDate'] as String? ?? '',
      fromCity: json['fromCity'] as String? ?? '',
      toCity: json['toCity'] as String? ?? '',
      pickupPoint: json['pickupPoint'] as String? ?? '',
      pickupAddress: json['pickupAddress'] as String? ?? '',
      dropoffPoint: json['dropoffPoint'] as String? ?? '',
      dropoffAddress: json['dropoffAddress'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'operatorName': operatorName,
    'vehicleType': vehicleType,
    'departureTime': departureTime,
    'departureDate': departureDate,
    'arrivalTime': arrivalTime,
    'arrivalDate': arrivalDate,
    'fromCity': fromCity,
    'toCity': toCity,
    'pickupPoint': pickupPoint,
    'pickupAddress': pickupAddress,
    'dropoffPoint': dropoffPoint,
    'dropoffAddress': dropoffAddress,
  };

  @override
  List<Object?> get props => [id, operatorName, departureTime, departureDate];
}

class TicketModel extends Equatable {
  final String id;
  final String ticketCode;
  final TicketStatus status;
  final String bookingDate;
  final TicketTripSummary trip;
  final List<String> seats;
  final int totalAmount;
  final int discountAmount;
  final int finalAmount;
  final String paymentMethod;
  final PassengerInfo passenger;
  final String? licensePlate;
  final String? driverPhone;
  final String? cancelReason;
  final int? refundAmount;
  final ReviewModel? review;

  const TicketModel({
    required this.id,
    required this.ticketCode,
    required this.status,
    required this.bookingDate,
    required this.trip,
    required this.seats,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.paymentMethod,
    required this.passenger,
    this.licensePlate,
    this.driverPhone,
    this.cancelReason,
    this.refundAmount,
    this.review,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    TicketStatus parseStatus(String? statusStr) {
      switch (statusStr?.toUpperCase()) {
        case 'COMPLETED':
          return TicketStatus.completed;
        case 'CANCELLED':
          return TicketStatus.cancelled;
        case 'UPCOMING':
        default:
          return TicketStatus.upcoming;
      }
    }

    return TicketModel(
      id: json['id'] as String? ?? '',
      ticketCode: json['ticketCode'] as String? ?? '',
      status: parseStatus(json['status'] as String?),
      bookingDate: json['bookingDate'] as String? ?? '',
      trip: TicketTripSummary.fromJson(json['trip'] as Map<String, dynamic>? ?? {}),
      seats: (json['seats'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      totalAmount: json['totalAmount'] as int? ?? 0,
      discountAmount: json['discountAmount'] as int? ?? 0,
      finalAmount: json['finalAmount'] as int? ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      passenger: PassengerInfo.fromJson(json['passenger'] as Map<String, dynamic>? ?? {}),
      licensePlate: json['licensePlate'] as String?,
      driverPhone: json['driverPhone'] as String?,
      cancelReason: json['cancelReason'] as String?,
      refundAmount: json['refundAmount'] as int?,
      review: json['review'] != null ? ReviewModel.fromJson(json['review'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticketCode': ticketCode,
    'status': status.name.toUpperCase(),
    'bookingDate': bookingDate,
    'trip': trip.toJson(),
    'seats': seats,
    'totalAmount': totalAmount,
    'discountAmount': discountAmount,
    'finalAmount': finalAmount,
    'paymentMethod': paymentMethod,
    'passenger': passenger.toJson(),
    'licensePlate': licensePlate,
    'driverPhone': driverPhone,
    'cancelReason': cancelReason,
    'refundAmount': refundAmount,
    'review': review?.toJson(),
  };

  TicketModel copyWith({
    String? id,
    String? ticketCode,
    TicketStatus? status,
    String? bookingDate,
    TicketTripSummary? trip,
    List<String>? seats,
    int? totalAmount,
    int? discountAmount,
    int? finalAmount,
    String? paymentMethod,
    PassengerInfo? passenger,
    String? licensePlate,
    String? driverPhone,
    String? cancelReason,
    int? refundAmount,
    ReviewModel? review,
  }) {
    return TicketModel(
      id: id ?? this.id,
      ticketCode: ticketCode ?? this.ticketCode,
      status: status ?? this.status,
      bookingDate: bookingDate ?? this.bookingDate,
      trip: trip ?? this.trip,
      seats: seats ?? this.seats,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      passenger: passenger ?? this.passenger,
      licensePlate: licensePlate ?? this.licensePlate,
      driverPhone: driverPhone ?? this.driverPhone,
      cancelReason: cancelReason ?? this.cancelReason,
      refundAmount: refundAmount ?? this.refundAmount,
      review: review ?? this.review,
    );
  }

  /// Parse departure date and time into a DateTime object
  DateTime? get departureDateTime {
    try {
      final dateParts = trip.departureDate.split('/');
      final timeParts = trip.departureTime.split(':');
      if (dateParts.length == 3 && timeParts.length >= 2) {
        final day = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final year = int.parse(dateParts[2]);
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        return DateTime(year, month, day, hour, minute);
      }
    } catch (_) {
      // Fallback
    }
    return null;
  }

  /// Calculates hours remaining until departure
  double get hoursUntilDeparture {
    final dep = departureDateTime;
    if (dep == null) return 24.0; // Default allow
    final diff = dep.difference(DateTime.now());
    return diff.inMinutes / 60.0;
  }

  /// Business Rule sub_uc_huy_ve: cancellation permitted if departure is >= 3 hours away
  bool get canCancel => status == TicketStatus.upcoming && hoursUntilDeparture >= 3.0;

  @override
  List<Object?> get props => [id, ticketCode, status, finalAmount, review, cancelReason];
}
