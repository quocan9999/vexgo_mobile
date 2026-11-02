import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/api_client.dart';
import '../network/token_storage.dart';

const pushConfigured = bool.fromEnvironment('PUSH_NOTIFICATIONS_ENABLED');

Future<void> initializePushFirebase() async {
  if (!pushConfigured) return;
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
      appId: String.fromEnvironment('FIREBASE_APP_ID'),
      messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
      projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    ),
  );
}

abstract class PushGateway {
  Future<bool> requestPermission();
  Future<String?> getToken();
  Future<void> deleteToken();
  Stream<String> get tokenChanges;
  Stream<bool> get messages; // true = user tapped an OS notification.
  Future<bool> getInitialOpen();
}

class FirebasePushGateway implements PushGateway {
  FirebaseMessaging get _sdk => FirebaseMessaging.instance;
  @override
  Future<bool> requestPermission() async {
    final settings = await _sdk.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => _sdk.getToken();

  @override
  Future<void> deleteToken() async {
    await _sdk.deleteToken();
  }

  @override
  Stream<String> get tokenChanges => _sdk.onTokenRefresh;
  @override
  Stream<bool> get messages {
    final controller = StreamController<bool>();
    final a = FirebaseMessaging.onMessage.listen((_) => controller.add(false));
    final b = FirebaseMessaging.onMessageOpenedApp.listen(
      (_) => controller.add(true),
    );
    controller.onCancel = () async {
      await a.cancel();
      await b.cancel();
    };
    return controller.stream;
  }

  @override
  Future<bool> getInitialOpen() async => await _sdk.getInitialMessage() != null;
}

class PushSignal {
  final int sessionVersion;
  final bool opened;
  const PushSignal(this.sessionVersion, this.opened);
}

class PushNotificationsService {
  static final instance = PushNotificationsService();
  final ApiClient client;
  final PushGateway gateway;
  final SecureStorageAdapter storage;
  final bool configured;
  PushNotificationsService({
    ApiClient? client,
    PushGateway? gateway,
    SecureStorageAdapter? storage,
    this.configured = pushConfigured,
  }) : client = client ?? ApiClient(),
       gateway = gateway ?? FirebasePushGateway(),
       storage = storage ?? FlutterSecureStorageAdapter();
  int? _accountId;
  String? _token;
  int _revision = 0;
  Future<void> _unregistering = Future<void>.value();
  bool _enabled = false;
  StreamSubscription<String>? _tokens;
  StreamSubscription<bool>? _messages;
  StreamSubscription<void>? _credentials;
  final _signals = StreamController<PushSignal>.broadcast();
  Stream<PushSignal> get signals => _signals.stream;
  static const _path = '/notifications/devices';

  Future<bool> setSession(int? accountId) async {
    if (!configured) return false;
    if (_accountId == accountId && accountId != null) return _enabled;
    // Restoring the same persisted login after process death must not unregister
    // FCM before consuming the notification that launched the app.
    final revision = _accountId == null && _token == null
        ? ++_revision
        : await clearSession();
    await _unregistering;
    if (revision != _revision) return false;
    _accountId = accountId;
    if (accountId == null) return false;
    _enabled = await storage.read('push_enabled_$accountId') != 'false';
    if (revision != _revision) return false;
    _tokens ??= gateway.tokenChanges.listen((id) {
      unawaited(_registerSafely(id));
    });
    _credentials ??= TokenStorage.credentialChanges.listen((_) {
      unawaited(_registerSafely());
    });
    _messages ??= gateway.messages.listen((opened) {
      if (_accountId != null && _enabled) {
        _signals.add(PushSignal(TokenStorage.sessionVersion, opened));
      }
    });
    final active = await setEnabled(accountId, _enabled);
    if (revision == _revision &&
        await gateway.getInitialOpen() &&
        _accountId != null) {
      _signals.add(PushSignal(TokenStorage.sessionVersion, true));
    }
    return active;
  }

  Future<bool> setEnabled(int accountId, bool enabled) async {
    if (!configured || _accountId != accountId) return false;
    final revision = _revision;
    try {
      final allowed = enabled && await gateway.requestPermission();
      if (revision != _revision) return false;
      _enabled = allowed;
      await storage.write('push_enabled_$accountId', allowed.toString());
      if (allowed) {
        await _registerSafely();
      } else {
        await _unregister();
      }
      return allowed;
    } catch (_) {
      return false;
    }
  }

  Future<void> _registerSafely([String? registeredId]) async {
    if (!configured || !_enabled || _accountId == null) return;
    final revision = _revision;
    final session = TokenStorage.sessionVersion;
    try {
      final token = registeredId ?? await gateway.getToken();
      if (token == null ||
          revision != _revision ||
          session != TokenStorage.sessionVersion ||
          !_enabled) {
        return;
      }
      await client.post(_path, body: {'token': token}, requiresAuth: true);
      if (revision == _revision && session == TokenStorage.sessionVersion) {
        _token = token;
      }
      // If logout raced a POST, backend also checks the revoked session at send time.
    } catch (_) {
      /* Inbox remains authoritative; retry on refresh/foreground. */
    }
  }

  Future<void> refreshRegistration() => _registerSafely();
  Future<void> _unregister() async {
    final token = _token;
    _token = null;
    final previous = _unregistering;
    final completion = Completer<void>();
    _unregistering = completion.future;
    await previous;
    try {
      if (token != null) {
        try {
          await client
              .delete(_path, body: {'token': token}, requiresAuth: true)
              .timeout(const Duration(seconds: 3));
        } catch (_) {}
      }
      try {
        await gateway.deleteToken();
      } catch (_) {}
    } finally {
      completion.complete();
    }
  }

  Future<int> clearSession() async {
    final revision = ++_revision;
    _accountId = null;
    _enabled = false;
    if (configured) await _unregister();
    return revision;
  }

  Future<void> dispose() async {
    await clearSession();
    await _tokens?.cancel();
    await _messages?.cancel();
    await _credentials?.cancel();
    await _signals.close();
  }
}
