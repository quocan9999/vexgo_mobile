import 'package:equatable/equatable.dart';

class PopularRouteModel extends Equatable {
  final String id;
  final String? fromCityId;
  final String fromCityName;
  final String? toCityId;
  final String toCityName;
  final int? minPrice;
  final String distance;
  final String duration;
  final String imageUrl;

  const PopularRouteModel({
    required this.id,
    this.fromCityId,
    required this.fromCityName,
    this.toCityId,
    required this.toCityName,
    this.minPrice,
    required this.distance,
    required this.duration,
    required this.imageUrl,
  });

  static String? _resolveCityId(String cityName) {
    if (cityName.isEmpty) return null;
    final lower = cityName.toLowerCase();
    if (lower.contains('hồ chí minh') ||
        lower.contains('sài gòn') ||
        lower.contains('sg')) {
      return 'HCM';
    }
    if (lower.contains('đà lạt') || lower.contains('da lat')) {
      return 'DL';
    }
    if (lower.contains('hà nội') ||
        lower.contains('ha nội') ||
        lower.contains('ha noi')) {
      return 'HN';
    }
    if (lower.contains('đà nẵng') || lower.contains('da nang')) {
      return 'DN';
    }
    if (lower.contains('vũng tàu') || lower.contains('vung tau')) {
      return 'VT';
    }
    if (lower.contains('nha trang')) {
      return 'NT';
    }
    if (lower.contains('cần thơ') || lower.contains('can tho')) {
      return 'CT';
    }
    if (lower.contains('huế') || lower.contains('hue')) {
      return 'HUE';
    }
    return null;
  }

  factory PopularRouteModel.fromJson(Map<String, dynamic> json) {
    final id = json['routeId']?.toString() ?? json['id']?.toString() ?? '';
    final origin =
        json['origin'] as String? ?? json['fromCityName'] as String? ?? '';
    final dest =
        json['destination'] as String? ?? json['toCityName'] as String? ?? '';

    final fromId = json['fromCityId'] as String? ?? _resolveCityId(origin);
    final toId = json['toCityId'] as String? ?? _resolveCityId(dest);

    String durationStr = json['duration'] as String? ?? '';
    if (durationStr.isEmpty && json['durationMinutes'] != null) {
      final mins = (json['durationMinutes'] as num).toInt();
      final hours = mins ~/ 60;
      final rem = mins % 60;
      durationStr = rem > 0 ? '$hours.${(rem / 6).round()} giờ' : '$hours giờ';
    }

    final image = json['imageUrl'] as String? ?? '';

    return PopularRouteModel(
      id: id,
      fromCityId: fromId,
      fromCityName: origin,
      toCityId: toId,
      toCityName: dest,
      minPrice: (json['minPrice'] as num?)?.toInt(),
      distance:
          json['distance'] as String? ??
          (json['distanceKm'] != null ? '${json['distanceKm']} km' : ''),
      duration: durationStr,
      imageUrl: image.isNotEmpty
          ? image
          : 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=600&auto=format&fit=crop',
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
