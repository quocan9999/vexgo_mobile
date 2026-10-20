import 'package:equatable/equatable.dart';
import 'stop_point_model.dart';

class TripModel extends Equatable {
  final String id;
  final String? routeId;
  final String operatorId;
  final String operatorName;
  final String vehicleType;
  final String fromCityId;
  final String fromCityName;
  final String toCityId;
  final String toCityName;
  final String departureTime;
  final String arrivalTime;
  final String? rawDepartureTime;
  final String? rawArrivalTime;
  final String duration;
  final int? durationMinutes;
  final String pickupPoint;
  final String pickupAddress;
  final String dropoffPoint;
  final String dropoffAddress;
  final int originalPrice;
  final int discountPrice;
  final int availableSeats;
  final int totalSeats;
  final String seatLayoutType;
  final double? rating;
  final int reviewCount;
  final List<String> amenities;
  final List<String> images;
  final List<StopPointModel> pickupPoints;
  final List<StopPointModel> dropoffPoints;

  const TripModel({
    required this.id,
    this.routeId,
    required this.operatorId,
    required this.operatorName,
    required this.vehicleType,
    required this.fromCityId,
    required this.fromCityName,
    required this.toCityId,
    required this.toCityName,
    required this.departureTime,
    required this.arrivalTime,
    this.rawDepartureTime,
    this.rawArrivalTime,
    required this.duration,
    this.durationMinutes,
    required this.pickupPoint,
    required this.pickupAddress,
    required this.dropoffPoint,
    required this.dropoffAddress,
    required this.originalPrice,
    required this.discountPrice,
    required this.availableSeats,
    required this.totalSeats,
    required this.seatLayoutType,
    required this.rating,
    required this.reviewCount,
    this.amenities = const [],
    this.images = const [],
    this.pickupPoints = const [],
    this.dropoffPoints = const [],
  });

  /// Normalizes departure/arrival time from ISO-8601 (e.g. 2026-10-10T07:00:00.000Z) or HH:mm:ss to HH:mm
  static String normalizeTime(String rawTime) {
    if (rawTime.isEmpty) return rawTime;
    if (rawTime.contains('T')) {
      final parsed = DateTime.tryParse(rawTime);
      if (parsed != null) {
        // Backend stores business time zone (Vietnam ICT: UTC+7).
        final vnTime = parsed.isUtc
            ? parsed.add(const Duration(hours: 7))
            : parsed;
        return '${vnTime.hour.toString().padLeft(2, '0')}:${vnTime.minute.toString().padLeft(2, '0')}';
      }
    }
    if (rawTime.contains(':')) {
      final parts = rawTime.split(':');
      if (parts.length >= 2) {
        final hh = parts[0].trim().padLeft(2, '0');
        final mm = parts[1].trim().padLeft(2, '0');
        if (int.tryParse(hh) != null && int.tryParse(mm) != null) {
          return '$hh:$mm';
        }
      }
    }
    return rawTime;
  }

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final defaultPickup = json['pickupPoint'] as String? ?? '';
    final defaultPickupAddress = json['pickupAddress'] as String? ?? '';
    final defaultDropoff = json['dropoffPoint'] as String? ?? '';
    final defaultDropoffAddress = json['dropoffAddress'] as String? ?? '';
    final rawDepartureTime =
        json['rawDepartureTime'] as String? ??
        json['departureTime'] as String? ??
        '';
    final rawArrivalTime =
        json['rawArrivalTime'] as String? ??
        json['arrivalTime'] as String? ??
        '';
    final departureTime = normalizeTime(rawDepartureTime);
    final arrivalTime = normalizeTime(rawArrivalTime);

    List<StopPointModel> parsedPickupPoints = [];
    if (json['pickupPoints'] != null) {
      parsedPickupPoints = (json['pickupPoints'] as List<dynamic>)
          .map((e) => StopPointModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (parsedPickupPoints.isEmpty && defaultPickup.isNotEmpty) {
      parsedPickupPoints = [
        StopPointModel(
          id: 'PU_DEFAULT',
          name: defaultPickup,
          time: departureTime,
          address: defaultPickupAddress,
          type: 'station',
          isDefault: true,
        ),
      ];
    }

    List<StopPointModel> parsedDropoffPoints = [];
    if (json['dropoffPoints'] != null) {
      parsedDropoffPoints = (json['dropoffPoints'] as List<dynamic>)
          .map((e) => StopPointModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (parsedDropoffPoints.isEmpty && defaultDropoff.isNotEmpty) {
      parsedDropoffPoints = [
        StopPointModel(
          id: 'DO_DEFAULT',
          name: defaultDropoff,
          time: arrivalTime,
          address: defaultDropoffAddress,
          type: 'station',
          isDefault: true,
        ),
      ];
    }

    final routeMap = json['route'] is Map<String, dynamic>
        ? json['route'] as Map<String, dynamic>
        : null;
    final vehicleMap = json['vehicle'] is Map<String, dynamic>
        ? json['vehicle'] as Map<String, dynamic>
        : null;

    final id = json['tripId']?.toString() ?? json['id']?.toString() ?? '';
    final routeId =
        routeMap?['id']?.toString() ??
        routeMap?['routeId']?.toString() ??
        json['routeId']?.toString();

    // Map operator/busCompany
    String operatorId = '';
    String operatorName = '';
    if (json['busCompany'] is Map<String, dynamic>) {
      final bc = json['busCompany'] as Map<String, dynamic>;
      operatorId = bc['id']?.toString() ?? bc['busCompanyId']?.toString() ?? '';
      operatorName = bc['name'] as String? ?? bc['tenNhaXe'] as String? ?? '';
    }
    if (operatorId.isEmpty) {
      operatorId =
          json['busCompanyId']?.toString() ??
          json['operatorId']?.toString() ??
          '';
    }
    if (operatorName.isEmpty) {
      operatorName =
          json['busCompanyName'] as String? ??
          json['operatorName'] as String? ??
          '';
    }

    // Map vehicle details
    final vehicleType =
        vehicleMap?['type'] as String? ??
        vehicleMap?['vehicleType'] as String? ??
        json['vehicleTypeName'] as String? ??
        json['vehicleType'] as String? ??
        '';
    final totalSeats =
        (vehicleMap?['capacity'] as num?)?.toInt() ??
        (json['totalSeats'] as num?)?.toInt() ??
        0;

    // Map route points
    final fromCityName =
        routeMap?['origin'] as String? ?? json['fromCityName'] as String? ?? '';
    final toCityName =
        routeMap?['destination'] as String? ??
        json['toCityName'] as String? ??
        '';
    final fromCityId =
        routeMap?['originId']?.toString() ??
        json['fromCityId']?.toString() ??
        fromCityName;
    final toCityId =
        routeMap?['destinationId']?.toString() ??
        json['toCityId']?.toString() ??
        toCityName;

    final durationMinutes =
        (routeMap?['durationMinutes'] as num?)?.toInt() ??
        (json['durationMinutes'] as num?)?.toInt() ??
        (routeMap?['durationHours'] != null
            ? ((routeMap!['durationHours'] as num).toInt() * 60)
            : null);

    String duration = json['duration'] as String? ?? '';
    if (duration.isEmpty && durationMinutes != null && durationMinutes > 0) {
      final hours = durationMinutes ~/ 60;
      final remainingMinutes = durationMinutes % 60;
      if (hours > 0 && remainingMinutes > 0) {
        duration = '$hours giờ $remainingMinutes phút';
      } else if (hours > 0) {
        duration = '$hours giờ';
      } else {
        duration = '$remainingMinutes phút';
      }
    }

    // Map pricing: support single 'price' from backend or original/discount pair
    final backendPrice = (json['price'] as num?)?.toInt();
    final originalPrice =
        (json['originalPrice'] as num?)?.toInt() ?? backendPrice ?? 0;
    final discountPrice =
        (json['discountPrice'] as num?)?.toInt() ??
        backendPrice ??
        originalPrice;

    final amenities =
        (vehicleMap?['amenities'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (json['amenities'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    return TripModel(
      id: id,
      routeId: routeId,
      operatorId: operatorId,
      operatorName: operatorName,
      vehicleType: vehicleType,
      fromCityId: fromCityId,
      fromCityName: fromCityName,
      toCityId: toCityId,
      toCityName: toCityName,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      rawDepartureTime: rawDepartureTime.isNotEmpty ? rawDepartureTime : null,
      rawArrivalTime: rawArrivalTime.isNotEmpty ? rawArrivalTime : null,
      duration: duration,
      durationMinutes: durationMinutes,
      pickupPoint: defaultPickup,
      pickupAddress: defaultPickupAddress,
      dropoffPoint: defaultDropoff,
      dropoffAddress: defaultDropoffAddress,
      originalPrice: originalPrice,
      discountPrice: discountPrice,
      availableSeats: json['availableSeats'] as int? ?? 0,
      totalSeats: totalSeats,
      seatLayoutType: json['seatLayoutType'] as String? ?? 'SLEEPER_34',
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int? ?? 0,
      amenities: amenities,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      pickupPoints: parsedPickupPoints,
      dropoffPoints: parsedDropoffPoints,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tripId': numericTripId,
    'routeId': routeId,
    'operatorId': operatorId,
    'operatorName': operatorName,
    'busCompanyId': numericOperatorId,
    'busCompanyName': operatorName,
    'vehicleType': vehicleType,
    'vehicleTypeName': vehicleType,
    'fromCityId': fromCityId,
    'fromCityName': fromCityName,
    'toCityId': toCityId,
    'toCityName': toCityName,
    'departureTime': departureTime,
    'arrivalTime': arrivalTime,
    if (rawDepartureTime != null) 'rawDepartureTime': rawDepartureTime,
    if (rawArrivalTime != null) 'rawArrivalTime': rawArrivalTime,
    'duration': duration,
    if (durationMinutes != null) 'durationMinutes': durationMinutes,
    'pickupPoint': pickupPoint,
    'pickupAddress': pickupAddress,
    'dropoffPoint': dropoffPoint,
    'dropoffAddress': dropoffAddress,
    'price': discountPrice,
    'originalPrice': originalPrice,
    'discountPrice': discountPrice,
    'availableSeats': availableSeats,
    'totalSeats': totalSeats,
    'seatLayoutType': seatLayoutType,
    'rating': rating,
    'reviewCount': reviewCount,
    'amenities': amenities,
    'images': images,
    'pickupPoints': pickupPoints.map((p) => p.toJson()).toList(),
    'dropoffPoints': dropoffPoints.map((p) => p.toJson()).toList(),
  };

  /// Helper getters for backend numeric IDs
  int? get numericTripId => int.tryParse(id);
  int? get numericOperatorId => int.tryParse(operatorId);
  int? get numericRouteId => routeId != null ? int.tryParse(routeId!) : null;
  String get busCompanyName => operatorName;
  String get busCompanyId => operatorId;

  @override
  List<Object?> get props => [
    id,
    operatorId,
    departureTime,
    discountPrice,
    routeId,
    durationMinutes,
    rating,
    reviewCount,
  ];
}
