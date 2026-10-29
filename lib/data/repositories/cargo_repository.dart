import '../../core/network/api_client.dart';
import '../models/booking_cargo_model.dart';

abstract class CargoRepository {
  Future<CargoOptions> loadOptions(int tripId);
}

/// Read-only discovery. Cargo is created exclusively inside POST /bookings.
class RealCargoRepository implements CargoRepository {
  final ApiClient client;
  RealCargoRepository({ApiClient? client}) : client = client ?? ApiClient();
  Future<Object?> _data(String path) async {
    final response = await client.get(path);
    if (response is! Map || !response.containsKey('data')) {
      throw const FormatException('Missing cargo response');
    }
    return response['data'];
  }

  @override
  Future<CargoOptions> loadOptions(int tripId) async {
    if (tripId <= 0) throw ArgumentError('Invalid trip ID');
    final results = await Future.wait([
      _data('/shipments/categories'),
      _data('/trips/$tripId/cargo-capacity'),
    ]);
    if (results[0] is! List || results[1] is! Map) {
      throw const FormatException('Invalid cargo options');
    }
    final categories = (results[0] as List)
        .map((v) => CargoCategory.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
    if (categories.map((v) => v.id).toSet().length != categories.length) {
      throw const FormatException('Duplicate cargo categories');
    }
    final capacity = CargoCapacity.fromJson(
      Map<String, dynamic>.from(results[1] as Map),
    );
    CargoRoutePoints? points;
    if (capacity.acceptsShipments) {
      final raw = await _data('/shipments/trips/$tripId/route-points');
      if (raw is! Map) throw const FormatException('Invalid cargo points');
      points = CargoRoutePoints.fromJson(Map<String, dynamic>.from(raw));
      if (points.tripId != tripId) {
        throw const FormatException('Cargo points belong to another trip');
      }
    }
    return CargoOptions(
      tripId: tripId,
      categories: categories,
      capacity: capacity,
      points: points,
    );
  }
}
