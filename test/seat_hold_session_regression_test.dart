import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/datasources/remote/seat_remote_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
  });
  tearDown(TokenStorage.resetStorageAdapter);

  for (final authenticated in [true, false]) {
    test(
      'seat hold preserves ${authenticated ? 'customer' : 'guest'} ownership',
      () async {
        if (authenticated) {
          await TokenStorage.saveAccessToken('customer-access-token');
        }
        final transport = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/seat-holds');
          expect(
            request.headers['authorization'],
            authenticated ? 'Bearer customer-access-token' : isNull,
          );
          expect(jsonDecode(request.body), {
            'tripId': 765,
            'seatIds': [7266],
          });
          return http.Response(
            jsonEncode({
              'data': {
                'holdToken': 'server-issued-hold',
                'tripId': 765,
                'seatIds': [7266],
                'expiresAt': DateTime.now()
                    .add(const Duration(minutes: 10))
                    .toUtc()
                    .toIso8601String(),
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        });
        final source = SeatRemoteDataSourceImpl(
          client: ApiClient(httpClient: transport),
        );
        final hold = await source.createSeatHold(tripId: 765, seatIds: [7266]);
        expect(hold.holdToken, 'server-issued-hold');
        expect(hold.seatIds, [7266]);
        transport.close();
      },
    );
  }
}
