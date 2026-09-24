import 'package:vexgo_app/core/utils/json_loader.dart';
import '../models/city_model.dart';
import '../models/operator_model.dart';
import '../models/popular_route_model.dart';
import '../models/trip_model.dart';

abstract class TripRepository {
  Future<List<CityModel>> getCities();
  Future<List<PopularRouteModel>> getPopularRoutes();
  Future<List<OperatorModel>> getOperators();
  Future<List<TripModel>> searchTrips({
    required String fromCityId,
    required String toCityId,
    String? date,
  });
  Future<TripModel?> getTripById(String id);
}

class MockTripRepository implements TripRepository {
  List<CityModel>? _cachedCities;
  List<PopularRouteModel>? _cachedRoutes;
  List<OperatorModel>? _cachedOperators;
  List<TripModel>? _cachedTrips;

  @override
  Future<List<CityModel>> getCities() async {
    if (_cachedCities != null) return _cachedCities!;
    final List<Map<String, dynamic>> rawList =
        await JsonLoader.loadJsonList('assets/mock_data/cities.json');
    _cachedCities = rawList.map((item) => CityModel.fromJson(item)).toList();
    return _cachedCities!;
  }

  @override
  Future<List<PopularRouteModel>> getPopularRoutes() async {
    if (_cachedRoutes != null) return _cachedRoutes!;
    final List<Map<String, dynamic>> rawList =
        await JsonLoader.loadJsonList('assets/mock_data/popular_routes.json');
    _cachedRoutes = rawList.map((item) => PopularRouteModel.fromJson(item)).toList();
    return _cachedRoutes!;
  }

  @override
  Future<List<OperatorModel>> getOperators() async {
    if (_cachedOperators != null) return _cachedOperators!;
    final List<Map<String, dynamic>> rawList =
        await JsonLoader.loadJsonList('assets/mock_data/operators.json');
    _cachedOperators = rawList.map((item) => OperatorModel.fromJson(item)).toList();
    return _cachedOperators!;
  }

  @override
  Future<List<TripModel>> searchTrips({
    required String fromCityId,
    required String toCityId,
    String? date,
  }) async {
    if (_cachedTrips == null) {
      final List<Map<String, dynamic>> rawList =
          await JsonLoader.loadJsonList('assets/mock_data/trips.json');
      _cachedTrips = rawList.map((item) => TripModel.fromJson(item)).toList();
    }

    final matchedTrips = _cachedTrips!.where((trip) {
      final matchFrom = fromCityId.isEmpty || trip.fromCityId == fromCityId;
      final matchTo = toCityId.isEmpty || trip.toCityId == toCityId;
      return matchFrom && matchTo;
    }).toList();

    if (matchedTrips.isEmpty) {
      return _cachedTrips!;
    }

    return matchedTrips;
  }

  @override
  Future<TripModel?> getTripById(String id) async {
    if (_cachedTrips == null) {
      final List<Map<String, dynamic>> rawList =
          await JsonLoader.loadJsonList('assets/mock_data/trips.json');
      _cachedTrips = rawList.map((item) => TripModel.fromJson(item)).toList();
    }
    try {
      return _cachedTrips!.firstWhere((trip) => trip.id == id);
    } catch (_) {
      return null;
    }
  }
}
