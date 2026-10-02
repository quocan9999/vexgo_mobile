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
  final String duration;
  final String pickupPoint;
  final String pickupAddress;
  final String dropoffPoint;
  final String dropoffAddress;
  final int originalPrice;
  final int discountPrice;
  final int availableSeats;
  final int totalSeats;
  final String seatLayoutType;
  final double rating;
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
    required this.duration,
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

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final defaultPickup = json['pickupPoint'] as String? ?? '';
    final defaultPickupAddress = json['pickupAddress'] as String? ?? '';
    final defaultDropoff = json['dropoffPoint'] as String? ?? '';
    final defaultDropoffAddress = json['dropoffAddress'] as String? ?? '';
    final departureTime = json['departureTime'] as String? ?? '';
    final arrivalTime = json['arrivalTime'] as String? ?? '';

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
    final routeId = json['routeId']?.toString() ?? routeMap?['id']?.toString();

    // Map operator/busCompany
    String operatorId =
        json['busCompanyId']?.toString() ??
        json['operatorId']?.toString() ??
        '';
    String operatorName =
        json['busCompanyName'] as String? ??
        json['operatorName'] as String? ??
        '';
    if (json['busCompany'] is Map<String, dynamic>) {
      final bc = json['busCompany'] as Map<String, dynamic>;
      if (operatorId.isEmpty) operatorId = bc['id']?.toString() ?? '';
      if (operatorName.isEmpty) operatorName = bc['name'] as String? ?? '';
    }

    // Map vehicle details
    final vehicleType =
        json['vehicleTypeName'] as String? ??
        json['vehicleType'] as String? ??
        vehicleMap?['type'] as String? ??
        '';
    final totalSeats =
        (json['totalSeats'] as num?)?.toInt() ??
        (vehicleMap?['capacity'] as num?)?.toInt() ??
        0;

    // Map route points
    final fromCityName =
        json['fromCityName'] as String? ?? routeMap?['origin'] as String? ?? '';
    final toCityName =
        json['toCityName'] as String? ??
        routeMap?['destination'] as String? ??
        '';
    final fromCityId =
        json['fromCityId']?.toString() ??
        routeMap?['originId']?.toString() ??
        fromCityName;
    final toCityId =
        json['toCityId']?.toString() ??
        routeMap?['destinationId']?.toString() ??
        toCityName;

    String duration = json['duration'] as String? ?? '';
    if (duration.isEmpty && routeMap?['durationHours'] != null) {
      duration = '${routeMap!['durationHours']} giờ';
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
        (json['amenities'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (vehicleMap?['amenities'] as List<dynamic>?)
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
      duration: duration,
      pickupPoint: defaultPickup,
      pickupAddress: defaultPickupAddress,
      dropoffPoint: defaultDropoff,
      dropoffAddress: defaultDropoffAddress,
      originalPrice: originalPrice,
      discountPrice: discountPrice,
      availableSeats: json['availableSeats'] as int? ?? 0,
      totalSeats: totalSeats,
      seatLayoutType: json['seatLayoutType'] as String? ?? 'SLEEPER_34',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
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
    'duration': duration,
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
  ];
}
