import 'package:equatable/equatable.dart';
import '../adapters/city_search_adapter.dart';

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

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'address': address};

  @override
  List<Object?> get props => [id, name, address];
}

class CityModel extends Equatable {
  final String id;
  final String name;
  final String region;
  final bool isPopular;
  final List<StationModel> stations;
  final String? backendValue;
  final List<String> aliases;
  final bool isLegacy;
  final String? legacyNote;
  final String kind;

  String get searchValue =>
      backendValue ?? CitySearchAdapter.resolveBackendSearchCity(id);

  const CityModel({
    required this.id,
    required this.name,
    required this.region,
    required this.isPopular,
    this.stations = const [],
    this.backendValue,
    this.aliases = const [],
    this.isLegacy = false,
    this.legacyNote,
    this.kind = 'city',
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      region: json['region'] as String? ?? '',
      isPopular: json['isPopular'] as bool? ?? false,
      backendValue: json['backendValue'] as String?,
      aliases: (json['aliases'] as List?)?.cast<String>() ?? const [],
      isLegacy: json['isLegacy'] as bool? ?? false,
      legacyNote: json['legacyNote'] as String?,
      kind: json['kind'] as String? ?? 'city',
      stations:
          (json['stations'] as List<dynamic>?)
              ?.map(
                (item) => StationModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  factory CityModel.fromLocationJson(Map<String, dynamic> json) {
    String requiredText(String field) {
      final value = json[field];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Địa điểm thiếu $field hợp lệ.');
      }
      return value.trim();
    }

    final aliases = json['aliases'];
    if (aliases is! List || aliases.any((item) => item is! String)) {
      throw const FormatException('Tên gọi địa điểm không hợp lệ.');
    }
    return CityModel(
      id: requiredText('id'),
      name: requiredText('name'),
      backendValue: requiredText('value'),
      kind: requiredText('kind'),
      region:
          json['province'] as String? ?? json['parentName'] as String? ?? '',
      isPopular: json['popular'] as bool? ?? false,
      aliases: List.unmodifiable(aliases.cast<String>()),
      isLegacy: json['isLegacy'] as bool? ?? false,
      legacyNote: json['mergedFromText'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'region': region,
    'isPopular': isPopular,
    'stations': stations.map((s) => s.toJson()).toList(),
    if (backendValue != null) 'backendValue': backendValue,
    'aliases': aliases,
    'isLegacy': isLegacy,
    if (legacyNote != null) 'legacyNote': legacyNote,
    'kind': kind,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    region,
    isPopular,
    stations,
    backendValue,
    aliases,
    isLegacy,
    legacyNote,
    kind,
  ];
}
