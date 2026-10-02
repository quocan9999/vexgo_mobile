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

  ApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

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
      final token = await TokenStorage.getAccessToken();
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
        debugPrint('[API GET] $uri');
      }
      final response = await _httpClient
          .get(uri, headers: reqHeaders)
          .timeout(ApiConfig.connectTimeout);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Không thể kết nối đến máy chủ ($uri)',
        originalError: e,
      );
    } on TimeoutException catch (e) {
      throw NetworkException(
        message: 'Kết nối mạng quá hạn. Vui lòng thử lại.',
        originalError: e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Lỗi kết nối client: ${e.message}',
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
        debugPrint('[API POST] $uri$payloadSize');
      }
      final response = await _httpClient
          .post(uri, headers: reqHeaders, body: encodedBody)
          .timeout(ApiConfig.receiveTimeout);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Không thể kết nối đến máy chủ ($uri)',
        originalError: e,
      );
    } on TimeoutException catch (e) {
      throw NetworkException(
        message: 'Yêu cầu quá hạn. Vui lòng thử lại.',
        originalError: e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Lỗi kết nối client: ${e.message}',
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
        debugPrint('[API DELETE] $uri');
      }
      final response = await _httpClient
          .delete(uri, headers: reqHeaders, body: encodedBody)
          .timeout(ApiConfig.connectTimeout);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Không thể kết nối đến máy chủ ($uri)',
        originalError: e,
      );
    } on TimeoutException catch (e) {
      throw NetworkException(message: 'Yêu cầu quá hạn.', originalError: e);
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Lỗi kết nối client: ${e.message}',
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
