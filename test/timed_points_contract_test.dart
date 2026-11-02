import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/datasources/remote/booking_remote_data_source.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
  });
  tearDown(() async {
    await TokenStorage.clearTokens();
    TokenStorage.resetStorageAdapter();
  });
  test('trip point identity and surcharge survive serialization', () {
    final p = StopPointModel.fromJson({
      'id': 15,
      'name': 'Bến A',
      'diemDonTraChuyenXeId': 15,
      'phuPhi': 20000,
    });
    expect(p.id, '15');
    expect(p.tripPointId, 15);
    expect(p.surcharge, 20000);
    expect(StopPointModel.fromJson(p.toJson()), p);
    expect(StopPointModel.fromJson({'id': 'PU_DEFAULT'}).tripPointId, isNull);
  });
  test(
    'quote and booking send identical point IDs and keep server total',
    () async {
      final bodies = <Map<String, dynamic>>[];
      final remote = BookingRemoteDataSourceImpl(
        client: ApiClient(
          httpClient: MockClient((r) async {
            bodies.add(jsonDecode(r.body) as Map<String, dynamic>);
            return http.Response(
              jsonEncode({
                'data': r.url.path.endsWith('/quote')
                    ? {
                        'unitPrice': '230000.00',
                        'seatCount': 1,
                        'originalTotal': '230000.00',
                        'finalTotal': '230000.00',
                      }
                    : {
                        'bookingId': 8,
                        'bookingCode': 'uuid-booking',
                        'tripId': 101,
                        'totalAmount': 230000,
                      },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );
      final q = await remote.getBookingQuote(
        tripId: 101,
        seatIds: [7],
        pickupTripPointId: 15,
        dropoffTripPointId: 16,
      );
      expect(q.finalTotal, 230000);
      await remote.createBooking(
        tripId: 101,
        seatIds: [7],
        pickupPoint: 'Bến A',
        dropoffPoint: 'Bến B',
        pickupTripPointId: 15,
        dropoffTripPointId: 16,
        holdToken: 'valid-hold',
        contact: const PassengerInfo(
          fullName: 'QA',
          phone: '0901234567',
          email: 'qa@example.test',
        ),
      );
      expect(bodies, hasLength(2));
      for (final b in bodies) {
        expect(b['diemDonChuyenXeId'], 15);
        expect(b['diemTraChuyenXeId'], 16);
      }
    },
  );
}
