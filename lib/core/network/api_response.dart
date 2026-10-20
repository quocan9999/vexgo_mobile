import 'package:equatable/equatable.dart';

/// Pagination metadata standard per rule-api.md
class ApiPaginationMeta extends Equatable {
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  const ApiPaginationMeta({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory ApiPaginationMeta.fromJson(Map<String, dynamic> json) {
    return ApiPaginationMeta(
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      totalItems: json['totalItems'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'page': page,
    'pageSize': pageSize,
    'totalItems': totalItems,
    'totalPages': totalPages,
  };

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  @override
  List<Object?> get props => [page, pageSize, totalItems, totalPages];
}

/// Standard detail for validation error field per rule-api.md
class ApiValidationErrorDetail extends Equatable {
  final String field;
  final String message;

  const ApiValidationErrorDetail({required this.field, required this.message});

  factory ApiValidationErrorDetail.fromJson(Map<String, dynamic> json) {
    return ApiValidationErrorDetail(
      field: json['field'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'field': field, 'message': message};

  @override
  List<Object?> get props => [field, message];
}

/// Standard API Error model per rule-api.md
class ApiError extends Equatable {
  final int statusCode;
  final String errorCode;
  final String message;
  final List<ApiValidationErrorDetail> details;

  const ApiError({
    required this.statusCode,
    required this.errorCode,
    required this.message,
    this.details = const [],
  });

  factory ApiError.fromJson(
    Map<String, dynamic> json, [
    int fallbackStatusCode = 500,
  ]) {
    final status = json['statusCode'] as int? ?? fallbackStatusCode;

    // Handle error field as String ("SEAT_UNAVAILABLE") or Map ({"code": "SEAT_UNAVAILABLE", ...})
    String code = 'UNKNOWN_ERROR';
    String msg =
        json['message'] as String? ?? 'Đã có lỗi xảy ra. Vui lòng thử lại sau.';

    if (json['error'] is String) {
      code = json['error'] as String;
    } else if (json['error'] is Map<String, dynamic>) {
      final errMap = json['error'] as Map<String, dynamic>;
      code = errMap['code'] as String? ?? code;
      if (errMap['message'] != null) {
        msg = errMap['message'] as String;
      }
    }

    final detailsList = <ApiValidationErrorDetail>[];
    if (json['details'] is List) {
      for (final item in json['details'] as List) {
        if (item is Map<String, dynamic>) {
          detailsList.add(ApiValidationErrorDetail.fromJson(item));
        } else if (item is String) {
          detailsList.add(ApiValidationErrorDetail(field: '', message: item));
        }
      }
    }

    return ApiError(
      statusCode: status,
      errorCode: code,
      message: msg,
      details: detailsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'statusCode': statusCode,
    'error': errorCode,
    'message': message,
    'details': details.map((e) => e.toJson()).toList(),
  };

  @override
  List<Object?> get props => [statusCode, errorCode, message, details];
}

/// Standard single resource response envelope { "data": T }
class ApiResponse<T> extends Equatable {
  final T? data;
  final ApiError? error;

  const ApiResponse({this.data, this.error});

  bool get isSuccess => error == null && data != null;
  bool get hasError => error != null;

  factory ApiResponse.success(T data) => ApiResponse(data: data);
  factory ApiResponse.failure(ApiError error) => ApiResponse(error: error);

  @override
  List<Object?> get props => [data, error];
}

/// Standard paginated list response envelope { "data": [T], "meta": ApiPaginationMeta }
class ApiPaginatedResponse<T> extends Equatable {
  final List<T> data;
  final ApiPaginationMeta meta;
  final ApiError? error;

  const ApiPaginatedResponse({
    this.data = const [],
    required this.meta,
    this.error,
  });

  bool get isSuccess => error == null;
  bool get hasError => error != null;

  factory ApiPaginatedResponse.success(List<T> data, ApiPaginationMeta meta) =>
      ApiPaginatedResponse(data: data, meta: meta);

  factory ApiPaginatedResponse.failure(ApiError error) => ApiPaginatedResponse(
    data: const [],
    meta: const ApiPaginationMeta(
      page: 1,
      pageSize: 10,
      totalItems: 0,
      totalPages: 0,
    ),
    error: error,
  );

  @override
  List<Object?> get props => [data, meta, error];
}
