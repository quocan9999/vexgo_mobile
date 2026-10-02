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

  /// Visible for testing to inject mock/in-memory adapter
  static void setStorageAdapterForTesting(SecureStorageAdapter adapter) {
    _secureStorage = adapter;
  }

  /// Reset to default storage adapter
  static void resetStorageAdapter() {
    _secureStorage = FlutterSecureStorageAdapter();
    _cachedAccessToken = null;
  }

  /// Fast synchronous access to cached in-memory token
  static String? get currentToken => _cachedAccessToken;

  /// Initialize token from secure storage into in-memory cache
  static Future<void> init() async {
    try {
      _cachedAccessToken = await _secureStorage.read(_accessTokenKey);
    } catch (_) {
      _cachedAccessToken = null;
    }
  }

  /// Get current access token
  static Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) return _cachedAccessToken;
    try {
      _cachedAccessToken = await _secureStorage.read(_accessTokenKey);
    } catch (_) {
      _cachedAccessToken = null;
    }
    return _cachedAccessToken;
  }

  /// Get current refresh token securely from KeyStore / Keychain
  static Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(_refreshTokenKey);
    } catch (_) {
      return null;
    }
  }

  /// Save access and refresh tokens securely
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _cachedAccessToken = accessToken;
    try {
      await _secureStorage.write(_accessTokenKey, accessToken);
      if (refreshToken != null) {
        await _secureStorage.write(_refreshTokenKey, refreshToken);
      }
    } catch (_) {
      // In-memory cache still holds accessToken if persistence temporarily fails
    }
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
    _cachedAccessToken = null;
    try {
      await _secureStorage.delete(_accessTokenKey);
      await _secureStorage.delete(_refreshTokenKey);
    } catch (_) {}
  }
}
