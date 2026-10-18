import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_exceptions.dart';
import 'api_response.dart';
import 'token_storage.dart';

/// Central HTTP Client for VexGo Mobile per rule-api.md
class ApiClient {
  final http.Client _httpClient;
  static Future<void>? _refreshInFlight;
  static int? _refreshVersion;
  static String? _refreshBaseUrl;

  ApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<void> _refreshAccessToken(int version) async {
    final baseUrl = ApiConfig.baseUrl;
    if (_refreshInFlight != null &&
        _refreshVersion == version &&
        _refreshBaseUrl == baseUrl) {
      return _refreshInFlight;
    }
    final future = _rotateRefreshToken(version, baseUrl);
    _refreshInFlight = future;
    _refreshVersion = version;
    _refreshBaseUrl = baseUrl;
    try {
      await future;
    } finally {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
        _refreshVersion = null;
        _refreshBaseUrl = null;
      }
    }
  }

  Future<void> _rotateRefreshToken(int version, String baseUrl) async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (version != TokenStorage.sessionVersion) {
      throw UnauthorizedException();
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      await TokenStorage.clearTokens();
      throw UnauthorizedException();
    }
    try {
      // Use the raw transport: refresh must never recursively refresh itself.
      final response = await _httpClient
          .post(
            Uri.parse('$baseUrl${ApiConfig.authRefresh}'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(ApiConfig.receiveTimeout);
      if (version != TokenStorage.sessionVersion) {
        throw UnauthorizedException();
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        await TokenStorage.clearTokens();
      }
      final res = _processResponse(response);
      final data = res is Map<String, dynamic> && res['data'] is Map
          ? res['data']
          : res;
      final access = data is Map ? data['accessToken'] : null;
      final refresh = data is Map ? data['refreshToken'] : null;
      if (access is! String ||
          access.isEmpty ||
          refresh is! String ||
          refresh.isEmpty) {
        await TokenStorage.clearTokens();
        throw UnauthorizedException(
          message: 'Phản hồi làm mới phiên không hợp lệ.',
        );
      }
      final saved = await TokenStorage.rotateTokensIfCurrent(
        expectedVersion: version,
        accessToken: access,
        refreshToken: refresh,
      );
      if (!saved) throw UnauthorizedException();
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException(
        message: 'Làm mới phiên quá hạn. Vui lòng thử lại.',
      );
    } on http.ClientException {
      throw const NetworkException();
    }
  }

  Future<http.Response> _withRefresh({
    required Map<String, String> headers,
    required bool requiresAuth,
    required Future<http.Response> Function(Map<String, String>) send,
  }) async {
    final version = TokenStorage.sessionVersion;
    final usedToken = headers['Authorization'];
    if (requiresAuth && usedToken != 'Bearer ${TokenStorage.currentToken}') {
      throw UnauthorizedException();
    }
    var response = await send(headers);
    if (!requiresAuth) return response;
    if (version != TokenStorage.sessionVersion) throw UnauthorizedException();
    if (response.statusCode != 401) return response;

    // Another client may already have rotated the token while this call waited.
    if (usedToken == 'Bearer ${TokenStorage.currentToken}') {
      await _refreshAccessToken(version);
    }
    if (version != TokenStorage.sessionVersion) throw UnauthorizedException();
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) throw UnauthorizedException();
    response = await send({...headers, 'Authorization': 'Bearer $token'});
    if (version != TokenStorage.sessionVersion) throw UnauthorizedException();
    if (response.statusCode == 401) await TokenStorage.clearTokens();
    return response;
  }

  /// Build URI from path and optional query parameters
  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final baseUrl = ApiConfig.baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$baseUrl$cleanPath';

    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      // Remove null values and stringify
      final cleanParams = <String, String>{};
      queryParams.forEach((key, value) {
        if (value != null) {
          cleanParams[key] = value.toString();
        }
      });
      return uri.replace(queryParameters: cleanParams);
    }
    return uri;
  }

  /// Sanitize URI to prevent leaking tokens, secrets, or keys in debug logs and error messages
  static String sanitizeUriForLog(Uri uri) {
    bool hasSensitiveSegment = false;
    for (final s in uri.pathSegments) {
      if (s.length > 20 ||
          s.contains('.') ||
          s.toLowerCase().contains('token')) {
        hasSensitiveSegment = true;
        break;
      }
    }

    if (!uri.hasQuery && !hasSensitiveSegment) {
      return uri.toString();
    }

    final cleanParams = Map<String, String>.from(uri.queryParameters);
    for (final key in cleanParams.keys.toList()) {
      final lower = key.toLowerCase();
      if (lower.contains('token') ||
          lower.contains('secret') ||
          lower.contains('key') ||
          lower.contains('auth') ||
          lower.contains('password') ||
          lower.contains('code') ||
          lower.contains('otp')) {
        cleanParams[key] = '***REDACTED***';
      }
    }

    final cleanSegments = uri.pathSegments.map((s) {
      if (s.length > 20 ||
          s.contains('.') ||
          s.toLowerCase().contains('token')) {
        return '***REDACTED***';
      }
      return s;
    }).toList();

    return uri
        .replace(
          pathSegments: cleanSegments,
          queryParameters: cleanParams.isEmpty ? null : cleanParams,
        )
        .toString();
  }

  /// Construct default headers with Bearer token if required or optional
  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? extraHeaders,
    bool requiresAuth = false,
    bool optionalAuth = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      var token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        await _refreshAccessToken(TokenStorage.sessionVersion);
        token = await TokenStorage.getAccessToken();
      }
      if (token == null || token.isEmpty) {
        throw UnauthorizedException(
          message: 'Yêu cầu đăng nhập để thực hiện tác vụ này.',
        );
      }
      headers['Authorization'] = 'Bearer $token';
    } else if (optionalAuth) {
      final token = await TokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  /// Execute GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    bool requiresAuth = false,
  }) async {
    final uri = _buildUri(path, queryParams);
    final reqHeaders = await _buildHeaders(
      extraHeaders: headers,
      requiresAuth: requiresAuth,
    );

    try {
      if (kDebugMode) {
        debugPrint('[API GET] ${sanitizeUriForLog(uri)}');
      }
      final response = await _withRefresh(
        headers: reqHeaders,
        requiresAuth: requiresAuth,
        send: (h) =>
            _httpClient.get(uri, headers: h).timeout(ApiConfig.connectTimeout),
      );
      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Không thể kết nối đến máy chủ (${sanitizeUriForLog(uri)})',
        originalError: e,
      );
    } on TimeoutException catch (e) {
      throw NetworkException(
        message: 'Kết nối mạng quá hạn. Vui lòng thử lại.',
        originalError: e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Không thể kết nối đến máy chủ.',
        originalError: e,
      );
    }
  }

  /// Execute POST request
  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    bool requiresAuth = false,
  }) async {
    final uri = _buildUri(path, queryParams);
    final reqHeaders = await _buildHeaders(
      extraHeaders: headers,
      requiresAuth: requiresAuth,
    );

    try {
      final encodedBody = body != null ? jsonEncode(body) : null;
      if (kDebugMode) {
        final payloadSize = encodedBody != null
            ? ' (${encodedBody.length} bytes)'
            : '';
        debugPrint('[API POST] ${sanitizeUriForLog(uri)}$payloadSize');
      }
      final response = await _withRefresh(
        headers: reqHeaders,
        requiresAuth: requiresAuth,
        send: (h) => _httpClient
            .post(uri, headers: h, body: encodedBody)
            .timeout(ApiConfig.receiveTimeout),
      );
      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Không thể kết nối đến máy chủ (${sanitizeUriForLog(uri)})',
        originalError: e,
      );
    } on TimeoutException catch (e) {
      throw NetworkException(
        message: 'Yêu cầu quá hạn. Vui lòng thử lại.',
        originalError: e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Không thể kết nối đến máy chủ.',
        originalError: e,
      );
    }
  }

  /// Execute PUT request
  Future<dynamic> put(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    bool requiresAuth = false,
  }) async {
    final uri = _buildUri(path, queryParams);
    final reqHeaders = await _buildHeaders(
      extraHeaders: headers,
      requiresAuth: requiresAuth,
    );

    try {
      final encodedBody = body != null ? jsonEncode(body) : null;
      if (kDebugMode) {
        final payloadSize = encodedBody != null
            ? ' (${encodedBody.length} bytes)'
            : '';
        debugPrint('[API PUT] ${sanitizeUriForLog(uri)}$payloadSize');
      }
      final response = await _withRefresh(
        headers: reqHeaders,
        requiresAuth: requiresAuth,
        send: (h) => _httpClient
            .put(uri, headers: h, body: encodedBody)
            .timeout(ApiConfig.receiveTimeout),
      );
      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Không thể kết nối đến máy chủ (${sanitizeUriForLog(uri)})',
        originalError: e,
      );
    } on TimeoutException catch (e) {
      throw NetworkException(
        message: 'Yêu cầu quá hạn. Vui lòng thử lại.',
        originalError: e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Không thể kết nối đến máy chủ.',
        originalError: e,
      );
    }
  }

  /// Execute PATCH request
  Future<dynamic> patch(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    bool requiresAuth = false,
  }) async {
    final uri = _buildUri(path, queryParams);
    final reqHeaders = await _buildHeaders(
      extraHeaders: headers,
      requiresAuth: requiresAuth,
    );

    try {
      final encodedBody = body != null ? jsonEncode(body) : null;
      if (kDebugMode) {
        final payloadSize = encodedBody != null
            ? ' (${encodedBody.length} bytes)'
            : '';
        debugPrint('[API PATCH] ${sanitizeUriForLog(uri)}$payloadSize');
      }
      final response = await _withRefresh(
        headers: reqHeaders,
        requiresAuth: requiresAuth,
        send: (h) => _httpClient
            .patch(uri, headers: h, body: encodedBody)
            .timeout(ApiConfig.receiveTimeout),
      );
      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Không thể kết nối đến máy chủ (${sanitizeUriForLog(uri)})',
        originalError: e,
      );
    } on TimeoutException catch (e) {
      throw NetworkException(
        message: 'Yêu cầu quá hạn. Vui lòng thử lại.',
        originalError: e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Không thể kết nối đến máy chủ.',
        originalError: e,
      );
    }
  }

  /// Execute DELETE request
  Future<dynamic> delete(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    bool requiresAuth = false,
  }) async {
    final uri = _buildUri(path, queryParams);
    final reqHeaders = await _buildHeaders(
      extraHeaders: headers,
      requiresAuth: requiresAuth,
    );

    try {
      final encodedBody = body != null ? jsonEncode(body) : null;
      if (kDebugMode) {
        debugPrint('[API DELETE] ${sanitizeUriForLog(uri)}');
      }
      final response = await _withRefresh(
        headers: reqHeaders,
        requiresAuth: requiresAuth,
        send: (h) => _httpClient
            .delete(uri, headers: h, body: encodedBody)
            .timeout(ApiConfig.connectTimeout),
      );
      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Không thể kết nối đến máy chủ (${sanitizeUriForLog(uri)})',
        originalError: e,
      );
    } on TimeoutException catch (e) {
      throw NetworkException(message: 'Yêu cầu quá hạn.', originalError: e);
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Không thể kết nối đến máy chủ.',
        originalError: e,
      );
    }
  }

  /// Parse response body and handle standard status / error envelopes
  dynamic _processResponse(http.Response response) {
    String decodedBody;
    try {
      decodedBody = utf8.decode(response.bodyBytes);
    } catch (_) {
      decodedBody = response.body;
    }

    dynamic jsonBody;
    if (decodedBody.isNotEmpty) {
      try {
        jsonBody = jsonDecode(decodedBody);
      } catch (_) {
        jsonBody = decodedBody;
      }
    }

    if (kDebugMode) {
      final size = response.contentLength ?? decodedBody.length;
      debugPrint('[API RES] ${response.statusCode} | ($size bytes)');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    if (response.statusCode == 401) {
      String msg = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      String code = 'UNAUTHORIZED';
      if (jsonBody is Map<String, dynamic>) {
        msg = jsonBody['message'] as String? ?? msg;
        if (jsonBody['error'] is String) {
          code = jsonBody['error'] as String;
        }
      }
      throw UnauthorizedException(message: msg, errorCode: code);
    }

    // Process error response envelope per rule-api.md
    if (jsonBody is Map<String, dynamic>) {
      final apiError = ApiError.fromJson(jsonBody, response.statusCode);
      throw ApiException(apiError);
    }

    throw ApiException(
      ApiError(
        statusCode: response.statusCode,
        errorCode: 'HTTP_${response.statusCode}',
        message: 'Lỗi máy chủ (${response.statusCode})',
      ),
    );
  }
}
