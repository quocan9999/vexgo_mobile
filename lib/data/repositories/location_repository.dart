import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../models/city_model.dart';

/// City selectors share the server catalogue, never a bundled real-mode fallback.
class LocationRepository {
  final ApiClient client;
  final DateTime Function() now;
  List<CityModel>? _cache;
  DateTime? _loadedAt;
  Future<List<CityModel>>? _pending;

  LocationRepository({ApiClient? client, DateTime Function()? now})
    : client = client ?? ApiClient(),
      now = now ?? DateTime.now;

  Future<List<CityModel>> getCities() async {
    if (_cache != null &&
        _loadedAt != null &&
        now().difference(_loadedAt!) < const Duration(minutes: 5)) {
      return _cache!;
    }
    if (_pending != null) return _pending!;
    final request = _load();
    _pending = request;
    try {
      return await request;
    } finally {
      if (identical(_pending, request)) _pending = null;
    }
  }

  Future<List<CityModel>> _load() async {
    final response = await client.get(ApiConfig.locations);
    if (response is! Map || response['data'] is! List) {
      throw const FormatException('Danh mục địa điểm không hợp lệ.');
    }
    final cities = <CityModel>[];
    final ids = <String>{};
    for (final raw in response['data'] as List) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Địa điểm không hợp lệ.');
      }
      final city = CityModel.fromLocationJson(raw);
      // These controls choose route cities. Actual boarding/shipping stations
      // remain separate selections attached to a selected trip/route.
      if (!const ['province', 'city', 'district'].contains(city.kind)) continue;
      if (!ids.add(city.id)) {
        throw const FormatException('Danh mục trùng mã địa điểm.');
      }
      cities.add(city);
    }
    if (cities.isEmpty) {
      throw const FormatException('Chưa có tỉnh/thành phố khả dụng.');
    }
    final result = List<CityModel>.unmodifiable(cities);
    _cache = result;
    _loadedAt = now();
    return result;
  }
}
