import 'package:equatable/equatable.dart';

class StationModel extends Equatable {
  final String id;
  final String name;
  final String address;

  const StationModel({
    required this.id,
    required this.name,
    required this.address,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
  };

  @override
  List<Object?> get props => [id, name, address];
}

class CityModel extends Equatable {
  final String id;
  final String name;
  final String region;
  final bool isPopular;
  final List<StationModel> stations;

  const CityModel({
    required this.id,
    required this.name,
    required this.region,
    required this.isPopular,
    this.stations = const [],
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      region: json['region'] as String? ?? '',
      isPopular: json['isPopular'] as bool? ?? false,
      stations: (json['stations'] as List<dynamic>?)
              ?.map((item) => StationModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'region': region,
    'isPopular': isPopular,
    'stations': stations.map((s) => s.toJson()).toList(),
  };

  @override
  List<Object?> get props => [id, name, region, isPopular, stations];
}
