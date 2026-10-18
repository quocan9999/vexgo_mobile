import '../../models/trip_model.dart';
import '../../models/popular_route_model.dart';
import '../../models/operator_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

abstract class TripRemoteDataSource {
  Future<List<TripModel>> searchTrips({
    String? from,
    String? to,
    String? departureDate,
    int? busCompanyId,
    int page = 1,
    int pageSize = 10,
    String? sortBy,
    String? sortDirection,
  });

  Future<TripModel> getTripById(dynamic tripId);

  Future<List<PopularRouteModel>> getPopularRoutes();

  Future<List<OperatorModel>> getBusCompanies();
}

class TripRemoteDataSourceImpl implements TripRemoteDataSource {
  final ApiClient client;

  TripRemoteDataSourceImpl({required this.client});

  @override
  Future<List<TripModel>> searchTrips({
    String? from,
    String? to,
    String? departureDate,
    int? busCompanyId,
    int page = 1,
    int pageSize = 10,
    String? sortBy,
    String? sortDirection,
  }) async {
    final query = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (from != null && from.isNotEmpty) query['from'] = from;
    if (to != null && to.isNotEmpty) query['to'] = to;
    if (departureDate != null && departureDate.isNotEmpty) {
      query['departureDate'] = departureDate;
    }
    if (busCompanyId != null) query['busCompanyId'] = busCompanyId;
    if (sortBy != null) query['sortBy'] = sortBy;
    if (sortDirection != null) query['sortDirection'] = sortDirection;

    final trips = <String, TripModel>{};
    var currentPage = page;
    while (true) {
      query['page'] = currentPage;
      final res = await client.get(ApiConfig.tripsSearch, queryParams: query);
      if (res is! Map<String, dynamic> || res['data'] is! List) {
        throw const FormatException('Danh sách chuyến xe không hợp lệ.');
      }
      final data = res['data'] as List;
      for (final item in data) {
        final trip = TripModel.fromJson(item as Map<String, dynamic>);
        if (trip.id.isEmpty) {
          throw const FormatException('Chuyến xe thiếu mã.');
        }
        trips[trip.id] = trip;
      }
      final meta = res['meta'];
      final totalPages = meta is Map
          ? (meta['totalPages'] as num?)?.toInt()
          : null;
      if (totalPages == null || currentPage >= totalPages) break;
      if (data.isEmpty) {
        throw const FormatException('Trang kết quả chuyến xe bị thiếu.');
      }
      currentPage++;
    }
    return trips.values.toList();
  }

  @override
  Future<TripModel> getTripById(dynamic tripId) async {
    final res = await client.get(ApiConfig.tripDetail(tripId));
    if (res is Map<String, dynamic>) {
      final data = res['data'] ?? res;
      return TripModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Invalid trip data response');
  }

  @override
  Future<List<PopularRouteModel>> getPopularRoutes() async {
    final res = await client.get(ApiConfig.routes);
    if (res is Map<String, dynamic> && res['data'] is List) {
      final list = res['data'] as List;
      return list
          .map(
            (item) => PopularRouteModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } else if (res is List) {
      return res
          .map(
            (item) => PopularRouteModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<List<OperatorModel>> getBusCompanies() async {
    final res = await client.get(ApiConfig.busCompanies);
    if (res is Map<String, dynamic> && res['data'] is List) {
      final list = res['data'] as List;
      return list
          .map((item) => OperatorModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (res is List) {
      return res
          .map((item) => OperatorModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
