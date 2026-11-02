import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/notifications/push_notifications.dart';

class FakePush implements PushGateway {
  bool permitted = true;
  int deletes = 0;
  Completer<String?>? gate;
  final tokenController = StreamController<String>.broadcast();
  final messageController = StreamController<bool>.broadcast();
  @override
  Future<bool> requestPermission() async => permitted;
  @override
  Future<String?> getToken() async =>
      gate != null ? await gate!.future : 'abcdefghijklmnopqrstuv';
  @override
  Future<void> deleteToken() async {
    deletes++;
  }

  @override
  Stream<String> get tokenChanges => tokenController.stream;
  @override
  Stream<bool> get messages => messageController.stream;
  @override
  Future<bool> getInitialOpen() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakePush gateway;
  late PushNotificationsService service;
  late List<http.Request> requests;
  setUp(() async {
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(accessToken: 'owner-token');
    gateway = FakePush();
    requests = [];
    service = PushNotificationsService(
      configured: true,
      gateway: gateway,
      storage: InMemorySecureStorageAdapter(),
      client: ApiClient(
        httpClient: MockClient((r) async {
          requests.add(r);
          return http.Response(
            jsonEncode({
              'data': {'registered': r.method == 'POST'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );
  });
  tearDown(() async {
    await service.dispose();
    await gateway.tokenController.close();
    await gateway.messageController.close();
    await TokenStorage.clearTokens();
    TokenStorage.resetStorageAdapter();
  });
  test(
    'registers with JWT and unregisters before clearing the device session',
    () async {
      expect(await service.setSession(1), isTrue);
      expect(requests.single.headers['Authorization'], 'Bearer owner-token');
      expect(
        jsonDecode(requests.single.body)['token'],
        'abcdefghijklmnopqrstuv',
      );
      await service.clearSession();
      expect(requests.last.method, 'DELETE');
      final posts = requests.where((r) => r.method == 'POST').length;
      gateway.tokenController.add('zyxwvutsrqponmlkjihgfe');
      await Future<void>.delayed(Duration.zero);
      expect(requests.where((r) => r.method == 'POST').length, posts);
    },
  );
  test('denied OS permission never registers a device', () async {
    gateway.permitted = false;
    expect(await service.setSession(1), isFalse);
    expect(requests, isEmpty);
  });
  test('late FID read is discarded after logout', () async {
    gateway.gate = Completer<String?>();
    final pending = service.setSession(1);
    await Future<void>.delayed(Duration.zero);
    await service.clearSession();
    gateway.gate!.complete('abcdefghijklmnopqrstuv');
    await pending;
    expect(requests, isEmpty);
  });
  test(
    'an unauthenticated session invalidates registration still in flight',
    () async {
      gateway.gate = Completer<String?>();
      final pending = service.setSession(1);
      await Future<void>.delayed(Duration.zero);
      await service.setSession(null);
      gateway.gate!.complete('abcdefghijklmnopqrstuv');
      await pending;
      expect(requests, isEmpty);
    },
  );
  test(
    'refresh rotation rebinds registration without changing account session version',
    () async {
      await service.setSession(1);
      final version = TokenStorage.sessionVersion;
      await TokenStorage.rotateTokensIfCurrent(
        expectedVersion: version,
        accessToken: 'rotated-token',
        refreshToken: 'rotated-refresh',
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(requests.last.headers['Authorization'], 'Bearer rotated-token');
      expect(TokenStorage.sessionVersion, version);
    },
  );
  test('push signal after account logout is discarded', () async {
    final signals = <PushSignal>[];
    final subscription = service.signals.listen(signals.add);
    await service.setSession(1);
    gateway.messageController.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(signals, isNotEmpty);
    signals.clear();
    await service.clearSession();
    gateway.messageController.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(signals, isEmpty);
    await subscription.cancel();
  });
}
