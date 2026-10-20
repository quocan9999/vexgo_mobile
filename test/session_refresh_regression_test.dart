import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:vexgo_app/core/network/token_storage.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response rotated() => jsonResponse({
  'data': {'accessToken': 'rotated-access', 'refreshToken': 'rotated-refresh'},
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    ApiConfig.resetBaseUrl();
    await TokenStorage.saveTokens(
      accessToken: 'expired-access',
      refreshToken: 'old-refresh',
    );
  });
  tearDown(TokenStorage.resetStorageAdapter);

  test(
    'protected mutation rotates native refresh token and replays exactly once',
    () async {
      var mutations = 0;
      var refreshes = 0;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            refreshes++;
            expect(jsonDecode(request.body), {'refreshToken': 'old-refresh'});
            expect(request.headers.containsKey('authorization'), isFalse);
            return rotated();
          }
          mutations++;
          expect(jsonDecode(request.body), {'fullName': 'Tên thật'});
          if (request.headers['authorization'] == 'Bearer expired-access') {
            return jsonResponse({'error': 'ACCESS_TOKEN_INVALID'}, 401);
          }
          expect(request.headers['authorization'], 'Bearer rotated-access');
          return jsonResponse({
            'data': {'fullName': 'Tên thật'},
          });
        }),
      );
      final version = TokenStorage.sessionVersion;
      final response = await client.patch(
        '/me',
        body: {'fullName': 'Tên thật'},
        requiresAuth: true,
      );
      expect(response['data']['fullName'], 'Tên thật');
      expect(mutations, 2);
      expect(refreshes, 1);
      expect(TokenStorage.sessionVersion, version);
      expect(await TokenStorage.getRefreshToken(), 'rotated-refresh');
    },
  );

  test(
    'concurrent clients share one rotation and all receive authenticated data',
    () async {
      final bothArrived = Completer<void>();
      var oldRequests = 0;
      var refreshes = 0;
      Future<http.Response> handle(http.Request request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return rotated();
        }
        if (request.headers['authorization'] == 'Bearer expired-access') {
          if (++oldRequests == 2) bothArrived.complete();
          await bothArrived.future;
          return jsonResponse({'error': 'ACCESS_TOKEN_INVALID'}, 401);
        }
        return jsonResponse({'data': request.url.path});
      }

      final a = ApiClient(httpClient: MockClient(handle));
      final b = ApiClient(httpClient: MockClient(handle));
      final responses = await Future.wait([
        a.get('/tickets', requiresAuth: true),
        b.get('/notifications', requiresAuth: true),
      ]);
      expect(responses, hasLength(2));
      expect(refreshes, 1);
    },
  );

  test(
    'late old-token 401 reuses rotated token without another rotation',
    () async {
      final rotatedSignal = Completer<void>();
      var refreshes = 0;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            refreshes++;
            return rotated();
          }
          if (request.headers['authorization'] == 'Bearer expired-access') {
            if (request.url.path.endsWith('/slow')) await rotatedSignal.future;
            return jsonResponse({'error': 'ACCESS_TOKEN_INVALID'}, 401);
          }
          if (!rotatedSignal.isCompleted) rotatedSignal.complete();
          return jsonResponse({'data': true});
        }),
      );
      await Future.wait([
        client.get('/fast', requiresAuth: true),
        client.get('/slow', requiresAuth: true),
      ]);
      expect(refreshes, 1);
    },
  );

  test(
    'terminal refresh error clears both credentials and emits invalidation',
    () async {
      var invalidated = 0;
      final subscription = TokenStorage.sessionInvalidations.listen(
        (_) => invalidated++,
      );
      final client = ApiClient(
        httpClient: MockClient(
          (request) async => jsonResponse({
            'error': request.url.path.endsWith('/auth/refresh')
                ? 'REFRESH_TOKEN_INVALID'
                : 'ACCESS_TOKEN_INVALID',
          }, 401),
        ),
      );
      await expectLater(
        client.get('/tickets', requiresAuth: true),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(await TokenStorage.getAccessToken(), isNull);
      expect(await TokenStorage.getRefreshToken(), isNull);
      expect(invalidated, 1);
      await subscription.cancel();
    },
  );

  test(
    'refresh network failure preserves credentials and never replays mutation',
    () async {
      var mutations = 0;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            throw http.ClientException('offline');
          }
          mutations++;
          return jsonResponse({'error': 'ACCESS_TOKEN_INVALID'}, 401);
        }),
      );
      await expectLater(
        client.post('/bookings', body: {'tripId': 7}, requiresAuth: true),
        throwsA(isA<NetworkException>()),
      );
      expect(mutations, 1);
      expect(await TokenStorage.getAccessToken(), 'expired-access');
      expect(await TokenStorage.getRefreshToken(), 'old-refresh');
    },
  );

  test('network mutation failure is never retried automatically', () async {
    var calls = 0;
    final client = ApiClient(
      httpClient: MockClient((request) async {
        calls++;
        throw http.ClientException('offline');
      }),
    );
    await expectLater(
      client.post('/bookings', body: {'tripId': 7}, requiresAuth: true),
      throwsA(isA<NetworkException>()),
    );
    expect(calls, 1);
  });

  test('replayed 401 stops without refresh recursion', () async {
    var refreshes = 0;
    var requests = 0;
    final client = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          refreshes++;
          return rotated();
        }
        requests++;
        return jsonResponse({'error': 'ACCESS_TOKEN_INVALID'}, 401);
      }),
    );
    await expectLater(
      client.get('/tickets', requiresAuth: true),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(refreshes, 1);
    expect(requests, 2);
    expect(await TokenStorage.hasAccessToken(), isFalse);
  });

  test('public login 401 never refreshes an existing session', () async {
    var calls = 0;
    final client = ApiClient(
      httpClient: MockClient((request) async {
        calls++;
        expect(request.url.path, endsWith('/auth/login'));
        return jsonResponse({'error': 'INVALID_CREDENTIALS'}, 401);
      }),
    );
    await expectLater(
      client.post('/auth/login', body: {'password': 'wrong'}),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(calls, 1);
    expect(await TokenStorage.getRefreshToken(), 'old-refresh');
  });

  test(
    'logout while refresh is in flight discards tokens and skips replay',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      var protectedCalls = 0;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            started.complete();
            await release.future;
            return rotated();
          }
          protectedCalls++;
          return jsonResponse({'error': 'ACCESS_TOKEN_INVALID'}, 401);
        }),
      );
      final pending = client.get('/tickets', requiresAuth: true);
      final result = expectLater(
        pending,
        throwsA(isA<UnauthorizedException>()),
      );
      await started.future;
      await TokenStorage.clearTokens();
      release.complete();
      await result;
      expect(protectedCalls, 1);
      expect(await TokenStorage.getAccessToken(), isNull);
      expect(await TokenStorage.getRefreshToken(), isNull);
    },
  );

  test('account switch rejects stale successful protected responses', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    final client = ApiClient(
      httpClient: MockClient((request) async {
        started.complete();
        await release.future;
        return jsonResponse({
          'data': ['private account A ticket'],
        });
      }),
    );
    final result = expectLater(
      client.get('/tickets', requiresAuth: true),
      throwsA(isA<UnauthorizedException>()),
    );
    await started.future;
    await TokenStorage.saveTokens(
      accessToken: 'account-B',
      refreshToken: 'refresh-B',
    );
    release.complete();
    await result;
    expect(await TokenStorage.getAccessToken(), 'account-B');
  });

  test(
    'login without refresh token cannot inherit previous account credential',
    () async {
      await TokenStorage.saveAccessToken('new-account-access');
      expect(await TokenStorage.getRefreshToken(), isNull);
    },
  );

  test(
    'malformed refresh success cannot authenticate or retain old credentials',
    () async {
      final client = ApiClient(
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/auth/refresh')) {
            return jsonResponse({
              'data': {'accessToken': ''},
            });
          }
          return jsonResponse({'error': 'ACCESS_TOKEN_INVALID'}, 401);
        }),
      );
      await expectLater(
        client.get('/tickets', requiresAuth: true),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(await TokenStorage.hasAccessToken(), isFalse);
      expect(await TokenStorage.getRefreshToken(), isNull);
    },
  );
}
