import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Contract for secure credential storage backed by KeyStore/Keychain
abstract class SecureStorageAdapter {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Production implementation using flutter_secure_storage
class FlutterSecureStorageAdapter implements SecureStorageAdapter {
  final FlutterSecureStorage _storage;

  FlutterSecureStorageAdapter([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// In-memory implementation for unit testing
class InMemorySecureStorageAdapter implements SecureStorageAdapter {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);
}

/// Manages authentication tokens with KeyStore/Keychain secure storage and in-memory cache
class TokenStorage {
  static const String _accessTokenKey = 'vexgo_access_token';
  static const String _refreshTokenKey = 'vexgo_refresh_token';

  static SecureStorageAdapter _secureStorage = FlutterSecureStorageAdapter();
  static String? _cachedAccessToken;
  static String? _cachedRefreshToken;
  static bool _refreshLoaded = false;
  static int _sessionVersion = 0;
  static bool _cleared = false;
  static Future<void> _writes = Future<void>.value();
  static final _invalidations = StreamController<void>.broadcast(sync: true);

  /// Changes on login/logout, but stays stable during refresh token rotation.
  static int get sessionVersion => _sessionVersion;
  static Stream<void> get sessionInvalidations => _invalidations.stream;

  static Future<void> _serialize(Future<void> Function() action) {
    final operation = _writes.then((_) => action());
    _writes = operation.catchError((Object _) {});
    return operation;
  }

  /// Visible for testing to inject mock/in-memory adapter
  static void setStorageAdapterForTesting(SecureStorageAdapter adapter) {
    _secureStorage = adapter;
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _refreshLoaded = false;
    _cleared = false;
    _sessionVersion++;
  }

  /// Reset to default storage adapter
  static void resetStorageAdapter() {
    _secureStorage = FlutterSecureStorageAdapter();
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _refreshLoaded = false;
    _cleared = false;
    _sessionVersion++;
  }

  /// Fast synchronous access to cached in-memory token
  static String? get currentToken => _cachedAccessToken;

  /// Initialize token from secure storage into in-memory cache
  static Future<void> init() async {
    await getAccessToken();
  }

  /// Get current access token
  static Future<String?> getAccessToken() async {
    if (_cleared) return null;
    if (_cachedAccessToken != null) return _cachedAccessToken;
    final version = _sessionVersion;
    try {
      final token = await _secureStorage.read(_accessTokenKey);
      if (version != _sessionVersion || _cleared) return _cachedAccessToken;
      _cachedAccessToken = token;
    } catch (_) {
      if (version == _sessionVersion) _cachedAccessToken = null;
    }
    return _cachedAccessToken;
  }

  /// Get current refresh token securely from KeyStore / Keychain
  static Future<String?> getRefreshToken() async {
    if (_cleared) return null;
    if (_refreshLoaded) return _cachedRefreshToken;
    final version = _sessionVersion;
    try {
      await _writes;
      final token = await _secureStorage.read(_refreshTokenKey);
      if (version != _sessionVersion || _cleared) return null;
      _cachedRefreshToken = token;
      _refreshLoaded = true;
      return token;
    } catch (_) {
      return null;
    }
  }

  /// Save access and refresh tokens securely
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final version = ++_sessionVersion;
    _cleared = false;
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    _refreshLoaded = true;
    final storage = _secureStorage;
    try {
      await _serialize(() async {
        if (version != _sessionVersion) return;
        await storage.write(_accessTokenKey, accessToken);
        if (refreshToken != null) {
          await storage.write(_refreshTokenKey, refreshToken);
        } else {
          // Never reuse another account's refresh token.
          await storage.delete(_refreshTokenKey);
        }
      });
    } catch (_) {
      if (version == _sessionVersion) await clearTokens();
      throw StateError(
        'Không thể lưu phiên đăng nhập an toàn. Vui lòng thử lại.',
      );
    }
  }

  /// A refresh response arriving after logout/account switch must be discarded.
  static Future<bool> rotateTokensIfCurrent({
    required int expectedVersion,
    required String accessToken,
    required String refreshToken,
  }) async {
    if (_cleared || expectedVersion != _sessionVersion) return false;
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    _refreshLoaded = true;
    final storage = _secureStorage;
    try {
      await _serialize(() async {
        if (_cleared || expectedVersion != _sessionVersion) return;
        await storage.write(_accessTokenKey, accessToken);
        await storage.write(_refreshTokenKey, refreshToken);
      });
    } catch (_) {
      if (expectedVersion == _sessionVersion) await clearTokens();
      return false;
    }
    return !_cleared && expectedVersion == _sessionVersion;
  }

  /// Check if user has an active access token
  static Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Convenience method to save access token
  static Future<void> saveAccessToken(String token) =>
      saveTokens(accessToken: token);

  /// Clear all stored tokens upon logout
  static Future<void> clearTokens() async {
    ++_sessionVersion;
    _cleared = true;
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _refreshLoaded = true;
    _invalidations.add(null);
    final storage = _secureStorage;
    await _serialize(() async {
      // Independent deletions ensure failure of one does not skip the other.
      for (final key in [_accessTokenKey, _refreshTokenKey]) {
        try {
          await storage.delete(key);
        } catch (_) {}
      }
    });
  }
}
