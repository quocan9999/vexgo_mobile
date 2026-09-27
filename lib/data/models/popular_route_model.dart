import 'package:equatable/equatable.dart';

class PopularRouteModel extends Equatable {
  final String id;
  final String fromCityId;
  final String fromCityName;
  final String toCityId;
  final String toCityName;
  final int minPrice;
  final String distance;
  final String duration;
  final String imageUrl;

  const PopularRouteModel({
    required this.id,
    required this.fromCityId,
    required this.fromCityName,
    required this.toCityId,
    required this.toCityName,
    required this.minPrice,
    required this.distance,
    required this.duration,
    required this.imageUrl,
  });

  factory PopularRouteModel.fromJson(Map<String, dynamic> json) {
    return PopularRouteModel(
      id: json['id'] as String? ?? '',
      fromCityId: json['fromCityId'] as String? ?? '',
      fromCityName: json['fromCityName'] as String? ?? '',
      toCityId: json['toCityId'] as String? ?? '',
      toCityName: json['toCityName'] as String? ?? '',
      minPrice: json['minPrice'] as int? ?? 0,
      distance: json['distance'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromCityId': fromCityId,
    'fromCityName': fromCityName,
    'toCityId': toCityId,
    'toCityName': toCityName,
    'minPrice': minPrice,
    'distance': distance,
    'duration': duration,
    'imageUrl': imageUrl,
  };

  @override
  List<Object?> get props => [id, fromCityId, toCityId, minPrice];
}
