import 'package:equatable/equatable.dart';
import 'stop_point_model.dart';

class TripModel extends Equatable {
  final String id;
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

    return TripModel(
      id: json['id'] as String? ?? '',
      operatorId: json['operatorId'] as String? ?? '',
      operatorName: json['operatorName'] as String? ?? '',
      vehicleType: json['vehicleType'] as String? ?? '',
      fromCityId: json['fromCityId'] as String? ?? '',
      fromCityName: json['fromCityName'] as String? ?? '',
      toCityId: json['toCityId'] as String? ?? '',
      toCityName: json['toCityName'] as String? ?? '',
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      duration: json['duration'] as String? ?? '',
      pickupPoint: defaultPickup,
      pickupAddress: defaultPickupAddress,
      dropoffPoint: defaultDropoff,
      dropoffAddress: defaultDropoffAddress,
      originalPrice: json['originalPrice'] as int? ?? 0,
      discountPrice: json['discountPrice'] as int? ?? 0,
      availableSeats: json['availableSeats'] as int? ?? 0,
      totalSeats: json['totalSeats'] as int? ?? 0,
      seatLayoutType: json['seatLayoutType'] as String? ?? 'SLEEPER_34',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      pickupPoints: parsedPickupPoints,
      dropoffPoints: parsedDropoffPoints,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'operatorId': operatorId,
    'operatorName': operatorName,
    'vehicleType': vehicleType,
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

  @override
  List<Object?> get props => [id, operatorId, departureTime, discountPrice];
}
