import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_loader.dart';
import '../datasources/remote/seat_remote_data_source.dart';
import '../models/seat_hold_model.dart';
import '../models/seat_model.dart';

abstract class SeatRepository {
  Future<SeatLayoutModel> getSeatLayout(String seatLayoutType);
  Future<List<SeatModel>> getTripSeats(dynamic tripId);
  Future<SeatHoldModel> createSeatHold({
    required int tripId,
    required List<int> seatIds,
  });
  Future<bool> releaseSeatHold(String holdToken);
}

class MockSeatRepository implements SeatRepository {
  Map<String, dynamic>? _cachedSeatsMap;

  @override
  Future<SeatLayoutModel> getSeatLayout(String seatLayoutType) async {
    _cachedSeatsMap ??= await JsonLoader.loadJsonMap(
      'assets/mock_data/seats.json',
    );

    final upperKey = seatLayoutType.toUpperCase();
    String matchedKey = 'SLEEPER_34';
    if (_cachedSeatsMap!.containsKey(seatLayoutType)) {
      matchedKey = seatLayoutType;
    } else if (upperKey.contains('LIMO') ||
        upperKey.contains('GHẾ') ||
        upperKey.contains('SEAT')) {
      matchedKey = 'LIMOUSINE_9';
    } else if (upperKey.contains('CABIN')) {
      matchedKey = 'CABIN_22';
    } else if (upperKey.contains('40')) {
      matchedKey = 'SLEEPER_40';
    }

    final layoutData =
        _cachedSeatsMap![matchedKey] ?? _cachedSeatsMap!['SLEEPER_34'];
    return SeatLayoutModel.fromJson(layoutData as Map<String, dynamic>);
  }

  @override
  Future<List<SeatModel>> getTripSeats(dynamic tripId) async {
    final layout = await getSeatLayout('SLEEPER_34');
    return [...layout.lowerFloor, ...layout.upperFloor];
  }

  @override
  Future<SeatHoldModel> createSeatHold({
    required int tripId,
    required List<int> seatIds,
  }) async {
    // Generate mock 10-minute hold for offline testing
    return SeatHoldModel(
      holdToken: 'mock-hold-${DateTime.now().millisecondsSinceEpoch}',
      tripId: tripId,
      seatIds: seatIds,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<bool> releaseSeatHold(String holdToken) async {
    return true;
  }
}

/// Hybrid repository: interacts with backend seat hold API, fallback to mock when offline
class HybridSeatRepository implements SeatRepository {
  final SeatRemoteDataSource remoteDataSource;
  final MockSeatRepository mockFallback;

  HybridSeatRepository({
    SeatRemoteDataSource? remoteDataSource,
    MockSeatRepository? mockFallback,
  }) : remoteDataSource =
           remoteDataSource ?? SeatRemoteDataSourceImpl(client: ApiClient()),
       mockFallback = mockFallback ?? MockSeatRepository();

  @override
  Future<SeatLayoutModel> getSeatLayout(String seatLayoutType) {
    return mockFallback.getSeatLayout(seatLayoutType);
  }

  @override
  Future<List<SeatModel>> getTripSeats(dynamic tripId) async {
    try {
      return await remoteDataSource.getTripSeats(tripId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HybridSeatRepository] Remote getTripSeats failed: $e');
      }
      rethrow;
    }
  }

  @override
  Future<SeatHoldModel> createSeatHold({
    required int tripId,
    required List<int> seatIds,
  }) async {
    try {
      return await remoteDataSource.createSeatHold(
        tripId: tripId,
        seatIds: seatIds,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HybridSeatRepository] Remote createSeatHold failed: $e');
      }
      rethrow;
    }
  }

  @override
  Future<bool> releaseSeatHold(String holdToken) async {
    try {
      return await remoteDataSource.releaseSeatHold(holdToken);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HybridSeatRepository] Remote releaseSeatHold failed: $e');
      }
      return false;
    }
  }
}
