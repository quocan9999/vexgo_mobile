import 'dart:convert';
import 'dart:io';
import 'package:vexgo_app/data/models/seat_layout_resolver.dart';
import 'package:vexgo_app/data/models/seat_model.dart';

/// Read-only smoke check: real local HTTP -> production parser/layout resolver.
/// Does not authenticate, hold seats, create bookings, or write to the database.
Future<void> main() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  Future<Map<String, dynamic>> get(String path) async {
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:4002/api/v1/$path'),
    );
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode != 200) {
      throw StateError('HTTP ${response.statusCode}: $path');
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  try {
    final results = <Map<String, Object?>>[];
    for (final id in [766, 767, 768]) {
      final trip = (await get('trips/$id'))['data'] as Map<String, dynamic>;
      final type = (trip['vehicle'] as Map<String, dynamic>)['type'] as String;
      final data = (await get('trips/$id/seats'))['data'] as List;
      final seats = data
          .map((json) => SeatModel.fromJson(json as Map<String, dynamic>))
          .toList();
      final layout = resolveSeatLayout(vehicleType: type, seats: seats);
      final resolved = [...layout.lowerFloor, ...layout.upperFloor];
      if (resolved.length != seats.length ||
          resolved.map((s) => s.id).toSet().length != seats.length ||
          resolved.map((s) => (s.floor, s.row, s.col)).toSet().length !=
              seats.length) {
        throw StateError('Trip $id lost seats or has overlapping cells');
      }
      for (final seat in seats) {
        final mapped = resolved.singleWhere((s) => s.id == seat.id);
        if (seat.name != mapped.name ||
            seat.price != mapped.price ||
            seat.status != mapped.status) {
          throw StateError('Trip $id changed authoritative seat data');
        }
      }
      if (id == 768 &&
          (layout.columnCount != 4 ||
              layout.upperFloor.isNotEmpty ||
              layout.aisleAfterColumn != 2)) {
        throw StateError('Seated left/right layout is incorrect');
      }
      if (id != 768 &&
          (layout.columnCount != 3 ||
              layout.lowerFloor.isEmpty ||
              layout.upperFloor.isEmpty)) {
        throw StateError('Sleeper floor layout is incorrect');
      }
      results.add({
        'tripId': id,
        'vehicleType': type,
        'seatCount': resolved.length,
        'lowerFloor': layout.lowerFloor.length,
        'upperFloor': layout.upperFloor.length,
        'columns': layout.columnCount,
        'aisleAfterColumn': layout.aisleAfterColumn,
        'uniqueCells': true,
        'authoritativeSeatDataPreserved': true,
      });
    }
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(results));
  } finally {
    client.close(force: true);
  }
}
