import '../../core/network/api_client.dart';
import '../models/booking_cargo_model.dart';
import '../models/luggage_policy.dart';
import 'cargo_repository.dart';

class LuggageOptions {
  final LuggagePolicy policy;
  final CargoOptions cargo;
  const LuggageOptions(this.policy, this.cargo);
}

abstract class LuggageRepository {
  Future<LuggageOptions> load(int tripId);
}

class RealLuggageRepository implements LuggageRepository {
  final ApiClient client;
  late final CargoRepository cargoRepository;
  RealLuggageRepository({ApiClient? client, CargoRepository? cargoRepository})
    : client = client ?? ApiClient() {
    this.cargoRepository =
        cargoRepository ?? RealCargoRepository(client: this.client);
  }

  @override
  Future<LuggageOptions> load(int tripId) async {
    if (tripId <= 0) throw ArgumentError('Mã chuyến không hợp lệ.');
    final result = await Future.wait<Object?>([
      client.get('/bus-companies/trips/$tripId/luggage-packages'),
      cargoRepository.loadOptions(tripId),
    ]);
    final response = result[0];
    if (response is! Map || response['data'] is! Map<String, dynamic>) {
      throw const FormatException('Không đọc được chính sách hành lý từ API.');
    }
    final policy = LuggagePolicy.fromJson(
      response['data'] as Map<String, dynamic>,
    );
    final cargo = result[1] as CargoOptions;
    if (policy.tripId != tripId ||
        cargo.tripId != tripId ||
        (cargo.points != null && cargo.points!.tripId != tripId)) {
      throw const FormatException(
        'Chính sách hoặc điểm hành lý không thuộc chuyến hiện tại.',
      );
    }
    return LuggageOptions(policy, cargo);
  }
}
