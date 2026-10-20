import 'package:equatable/equatable.dart';
import 'review_model.dart';
import '../../core/network/api_config.dart';

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
      phone: json['phone'] as String? ?? json['phoneNumber'] as String? ?? '',
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

class CancellationQuote extends Equatable {
  final bool eligible;
  final String? reason;
  final double cancelFeeRate;
  final int cancelFee;
  final int refundAmount;

  const CancellationQuote({
    required this.eligible,
    this.reason,
    required this.cancelFeeRate,
    required this.cancelFee,
    required this.refundAmount,
  });

  factory CancellationQuote.fromJson(Map<String, dynamic> json) {
    final rate = json['cancelFeeRate'];
    final fee = json['cancelFee'];
    final refund = json['refundAmount'];
    if (json['eligible'] is! bool ||
        rate is! num ||
        !rate.isFinite ||
        rate < 0 ||
        rate > 1 ||
        fee is! num ||
        !fee.isFinite ||
        fee < 0 ||
        fee != fee.roundToDouble() ||
        refund is! num ||
        !refund.isFinite ||
        refund < 0 ||
        refund != refund.roundToDouble()) {
      throw const FormatException('Thông tin phí hủy vé không hợp lệ.');
    }
    return CancellationQuote(
      eligible: json['eligible'] as bool,
      reason: json['reason'] as String?,
      cancelFeeRate: rate.toDouble(),
      cancelFee: fee.toInt(),
      refundAmount: refund.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'eligible': eligible,
    if (reason != null) 'reason': reason,
    'cancelFeeRate': cancelFeeRate,
    'cancelFee': cancelFee,
    'refundAmount': refundAmount,
  };

  @override
  List<Object?> get props => [
    eligible,
    reason,
    cancelFeeRate,
    cancelFee,
    refundAmount,
  ];
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
  final CancellationQuote? cancellation;
  final String? seatNumber;
  final String? seatPosition;
  final dynamic bookingId;
  final String? bookingCode;
  final String? bookingStatus;
  final String? paymentStatus;
  final String? rawStatus;

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
    this.cancellation,
    this.seatNumber,
    this.seatPosition,
    this.bookingId,
    this.bookingCode,
    this.bookingStatus,
    this.paymentStatus,
    this.rawStatus,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    TicketStatus parseStatus(String? statusStr) {
      final s = statusStr?.toUpperCase() ?? '';
      if (s == 'COMPLETED' ||
          s == 'HOAN_THANH' ||
          s == 'HOAN_TAT' ||
          s == 'DA_SU_DUNG') {
        return TicketStatus.completed;
      }
      if (s == 'CANCELLED' || s == 'HUY' || s == 'DA_HUY' || s == 'HET_HAN') {
        return TicketStatus.cancelled;
      }
      return TicketStatus.upcoming;
    }

    final id = json['ticketId']?.toString() ?? json['id']?.toString() ?? '';
    final ticketCode =
        json['ticketCode'] as String? ?? json['maVe'] as String? ?? '';

    // Parse Trip info: support both nested mock schema and flat backend schema
    TicketTripSummary tripSummary;
    if (json['trip'] is Map<String, dynamic>) {
      tripSummary = TicketTripSummary.fromJson(
        json['trip'] as Map<String, dynamic>,
      );
    } else {
      final depTimeRaw = json['departureTime'] as String? ?? '';
      final arrTimeRaw = json['arrivalTime'] as String? ?? '';

      String depTime = '';
      String depDate = '';
      if (depTimeRaw.contains('T')) {
        final dt = DateTime.tryParse(depTimeRaw);
        if (dt != null) {
          final vn = dt.isUtc ? dt.add(const Duration(hours: 7)) : dt;
          depTime =
              '${vn.hour.toString().padLeft(2, '0')}:${vn.minute.toString().padLeft(2, '0')}';
          depDate =
              '${vn.day.toString().padLeft(2, '0')}/${vn.month.toString().padLeft(2, '0')}/${vn.year}';
        }
      } else {
        depTime = depTimeRaw;
      }

      String arrTime = '';
      String arrDate = '';
      if (arrTimeRaw.contains('T')) {
        final dt = DateTime.tryParse(arrTimeRaw);
        if (dt != null) {
          final vn = dt.isUtc ? dt.add(const Duration(hours: 7)) : dt;
          arrTime =
              '${vn.hour.toString().padLeft(2, '0')}:${vn.minute.toString().padLeft(2, '0')}';
          arrDate =
              '${vn.day.toString().padLeft(2, '0')}/${vn.month.toString().padLeft(2, '0')}/${vn.year}';
        }
      } else {
        arrTime = arrTimeRaw;
      }

      tripSummary = TicketTripSummary(
        id: json['tripId']?.toString() ?? '',
        operatorName:
            json['busCompanyName'] as String? ??
            json['operatorName'] as String? ??
            '',
        vehicleType: json['vehicleType'] as String? ?? '',
        departureTime: depTime,
        departureDate: depDate,
        arrivalTime: arrTime,
        arrivalDate: arrDate,
        fromCity:
            json['origin'] as String? ?? json['fromCity'] as String? ?? '',
        toCity:
            json['destination'] as String? ?? json['toCity'] as String? ?? '',
        pickupPoint:
            json['pickup'] as String? ?? json['pickupPoint'] as String? ?? '',
        pickupAddress: json['pickupAddress'] as String? ?? '',
        dropoffPoint:
            json['dropoff'] as String? ?? json['dropoffPoint'] as String? ?? '',
        dropoffAddress: json['dropoffAddress'] as String? ?? '',
      );
    }

    // Seats list: support both string list or single seatNumber from backend
    List<String> seatsList = [];
    if (json['seats'] is List) {
      seatsList = (json['seats'] as List).map((e) => e.toString()).toList();
    } else if (json['seatNumber'] != null) {
      seatsList = [json['seatNumber'].toString()];
    }

    // Passenger info: support nested passenger or flat backend fields
    PassengerInfo passengerInfo;
    if (json['passenger'] is Map<String, dynamic>) {
      passengerInfo = PassengerInfo.fromJson(
        json['passenger'] as Map<String, dynamic>,
      );
    } else {
      passengerInfo = PassengerInfo(
        fullName: json['passengerName'] as String? ?? '',
        phone: json['passengerPhone'] as String? ?? '',
        email: json['passengerEmail'] as String? ?? '',
      );
    }

    // Pricing
    final price =
        (json['price'] as num?)?.toInt() ??
        (json['finalAmount'] as num?)?.toInt() ??
        0;
    final totalAmount = (json['totalAmount'] as num?)?.toInt() ?? price;
    final discountAmount = (json['discountAmount'] as num?)?.toInt() ?? 0;
    final finalAmount = (json['finalAmount'] as num?)?.toInt() ?? price;

    // Booking date
    String bookingDateStr = json['bookingDate'] as String? ?? '';
    if (bookingDateStr.isEmpty && json['createdAt'] != null) {
      final dt = DateTime.tryParse(json['createdAt'].toString());
      if (dt != null) {
        final vn = dt.isUtc ? dt.add(const Duration(hours: 7)) : dt;
        bookingDateStr =
            '${vn.day.toString().padLeft(2, '0')}/${vn.month.toString().padLeft(2, '0')}/${vn.year} ${vn.hour.toString().padLeft(2, '0')}:${vn.minute.toString().padLeft(2, '0')}';
      }
    }

    // Cancellation quote from backend
    final cancellation = json['cancellation'] is Map<String, dynamic>
        ? CancellationQuote.fromJson(
            json['cancellation'] as Map<String, dynamic>,
          )
        : null;

    return TicketModel(
      id: id,
      ticketCode: ticketCode,
      status: parseStatus(json['status'] as String?),
      bookingDate: bookingDateStr,
      trip: tripSummary,
      seats: seatsList,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      finalAmount: finalAmount,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      passenger: passengerInfo,
      licensePlate: json['licensePlate'] as String?,
      driverPhone: json['driverPhone'] as String?,
      cancelReason: json['cancelReason'] as String?,
      refundAmount: json['refundAmount'] as int?,
      review: json['review'] != null
          ? ReviewModel.fromJson(json['review'] as Map<String, dynamic>)
          : null,
      cancellation: cancellation,
      seatNumber: json['seatNumber']?.toString(),
      seatPosition: json['seatPosition'] as String?,
      bookingId: json['bookingId'],
      bookingCode: json['bookingCode'] as String?,
      bookingStatus: json['bookingStatus'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      rawStatus: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticketCode': ticketCode,
    'status': rawStatus ?? status.name.toUpperCase(),
    'bookingDate': bookingDate,
    'trip': trip.toJson(),
    'seats': seats,
    'totalAmount': totalAmount,
    'discountAmount': discountAmount,
    'finalAmount': finalAmount,
    'paymentMethod': paymentMethod,
    'passenger': passenger.toJson(),
    if (licensePlate != null) 'licensePlate': licensePlate,
    if (driverPhone != null) 'driverPhone': driverPhone,
    if (cancelReason != null) 'cancelReason': cancelReason,
    if (refundAmount != null) 'refundAmount': refundAmount,
    if (review != null) 'review': review?.toJson(),
    if (cancellation != null) 'cancellation': cancellation?.toJson(),
    if (seatNumber != null) 'seatNumber': seatNumber,
    if (seatPosition != null) 'seatPosition': seatPosition,
    if (bookingId != null) 'bookingId': bookingId,
    if (bookingCode != null) 'bookingCode': bookingCode,
    if (bookingStatus != null) 'bookingStatus': bookingStatus,
    if (paymentStatus != null) 'paymentStatus': paymentStatus,
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
    CancellationQuote? cancellation,
    String? seatNumber,
    String? seatPosition,
    dynamic bookingId,
    String? bookingCode,
    String? bookingStatus,
    String? paymentStatus,
    String? rawStatus,
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
      cancellation: cancellation ?? this.cancellation,
      seatNumber: seatNumber ?? this.seatNumber,
      seatPosition: seatPosition ?? this.seatPosition,
      bookingId: bookingId ?? this.bookingId,
      bookingCode: bookingCode ?? this.bookingCode,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      rawStatus: rawStatus ?? this.rawStatus,
    );
  }

  /// A reserved seat (DA_DAT) is created before payment. Only authoritative
  /// booking AND order settlement permits a boarding credential.
  bool get isPaid =>
      ApiConfig.isDemoMode ||
      (bookingStatus?.toUpperCase() == 'DA_THANH_TOAN' &&
          paymentStatus?.toUpperCase() == 'DA_THANH_TOAN');

  bool get canShowQr =>
      isPaid &&
      status == TicketStatus.upcoming &&
      (ApiConfig.isDemoMode ||
          ((int.tryParse(id) ?? 0) > 0 &&
              const [
                'DA_DAT',
                'DA_THANH_TOAN',
              ].contains(rawStatus?.toUpperCase()))) &&
      ticketCode.trim().isNotEmpty;

  bool get hasFullDetails =>
      (int.tryParse(id) ?? 0) > 0 &&
      ticketCode.trim().isNotEmpty &&
      trip.operatorName.isNotEmpty &&
      trip.fromCity.isNotEmpty &&
      trip.toCity.isNotEmpty &&
      trip.departureDate.isNotEmpty &&
      trip.departureTime.isNotEmpty &&
      seats.isNotEmpty &&
      passenger.fullName.isNotEmpty &&
      passenger.phone.isNotEmpty &&
      cancellation != null &&
      finalAmount >= 0;

  /// Parse departure date and time into a DateTime object
  DateTime? get departureDateTime {
    try {
      if (trip.departureDate.contains('/')) {
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
      } else if (trip.departureDate.contains('-')) {
        final dateParts = trip.departureDate.split('-');
        final timeParts = trip.departureTime.split(':');
        if (dateParts.length == 3 && timeParts.length >= 2) {
          final year = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final day = int.parse(dateParts[2]);
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          return DateTime(year, month, day, hour, minute);
        }
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

  /// Cancellation permitted per backend quote, or if hoursUntilDeparture >= 12.0
  bool get canCancel {
    if (status != TicketStatus.upcoming) return false;
    if (cancellation != null) {
      return cancellation!.eligible;
    }
    return hoursUntilDeparture >= 12.0;
  }

  /// Cancellation fee rate: 0.1 (10%) if > 24h, 0.2 (20%) if 12h - 24h
  double get cancelFeeRate {
    if (cancellation != null) {
      return cancellation!.cancelFeeRate;
    }
    if (hoursUntilDeparture > 24.0) return 0.1;
    if (hoursUntilDeparture >= 12.0) return 0.2;
    return 0.0;
  }

  /// Calculated refund amount
  int get calculatedRefundAmount {
    if (cancellation != null && cancellation!.refundAmount > 0) {
      return cancellation!.refundAmount;
    }
    final rate = cancelFeeRate;
    return (finalAmount * (1.0 - rate)).round();
  }

  @override
  List<Object?> get props => [
    id,
    ticketCode,
    status,
    finalAmount,
    review,
    cancelReason,
    bookingStatus,
    paymentStatus,
    rawStatus,
    cancellation,
  ];
}
