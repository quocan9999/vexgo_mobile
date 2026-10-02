import '../../models/seat_model.dart';
import '../../models/seat_hold_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

abstract class SeatRemoteDataSource {
  Future<List<SeatModel>> getTripSeats(dynamic tripId);
  Future<SeatHoldModel> createSeatHold({
    required int tripId,
    required List<int> seatIds,
  });
  Future<bool> releaseSeatHold(String holdToken);
}

class SeatRemoteDataSourceImpl implements SeatRemoteDataSource {
  final ApiClient client;

  SeatRemoteDataSourceImpl({required this.client});

  @override
  Future<List<SeatModel>> getTripSeats(dynamic tripId) async {
    final res = await client.get(ApiConfig.tripSeats(tripId));
    if (res is Map<String, dynamic> && res['data'] is List) {
      final list = res['data'] as List;
      return list
          .map((item) => SeatModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<SeatHoldModel> createSeatHold({
    required int tripId,
    required List<int> seatIds,
  }) async {
    final body = {'tripId': tripId, 'seatIds': seatIds};
    final res = await client.post(ApiConfig.seatHolds, body: body);
    if (res is Map<String, dynamic>) {
      final data = res['data'] ?? res;
      return SeatHoldModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Invalid seat hold response');
  }

  @override
  Future<bool> releaseSeatHold(String holdToken) async {
    try {
      await client.delete(ApiConfig.seatHoldRelease(holdToken));
      return true;
    } catch (_) {
      return false;
    }
  }
}
