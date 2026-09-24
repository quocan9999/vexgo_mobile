import '../../core/utils/json_loader.dart';
import '../models/seat_model.dart';

abstract class SeatRepository {
  Future<SeatLayoutModel> getSeatLayout(String seatLayoutType);
}

class MockSeatRepository implements SeatRepository {
  Map<String, dynamic>? _cachedSeatsMap;

  @override
  Future<SeatLayoutModel> getSeatLayout(String seatLayoutType) async {
    _cachedSeatsMap ??=
        await JsonLoader.loadJsonMap('assets/mock_data/seats.json');

    final layoutData = _cachedSeatsMap![seatLayoutType] ?? _cachedSeatsMap!['SLEEPER_34'];
    return SeatLayoutModel.fromJson(layoutData as Map<String, dynamic>);
  }
}
