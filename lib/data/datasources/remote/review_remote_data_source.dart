import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/token_storage.dart';
import '../../models/review_model.dart';

abstract class ReviewRemoteDataSource {
  Future<ReviewModel> createReview({
    required int tripId,
    required int rating,
    String? comment,
  });
  Future<List<ReviewModel>> getMyReviews() =>
      throw UnsupportedError('Review read is unavailable');
  Future<ReviewModel> updateReview({
    required int reviewId,
    required int tripId,
    required int rating,
    required String comment,
  }) => throw UnsupportedError('Review update is unavailable');
  Future<void> deleteReview({required int reviewId, required int tripId}) =>
      throw UnsupportedError('Review delete is unavailable');
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final ApiClient client;

  ReviewRemoteDataSourceImpl({required this.client});

  @override
  Future<ReviewModel> createReview({
    required int tripId,
    required int rating,
    String? comment,
  }) async {
    _validate(rating, comment ?? '');
    final body = <String, dynamic>{'tripId': tripId, 'rating': rating};
    if (comment != null && comment.isNotEmpty) {
      body['comment'] = comment;
    }

    final res = await client.post(
      ApiConfig.reviews,
      body: body,
      requiresAuth: true,
    );

    final data = res is Map<String, dynamic> ? res['data'] ?? res : null;
    if (data is! Map<String, dynamic> || data['rating'] != rating) {
      throw const FormatException('Máy chủ chưa xác nhận đánh giá hợp lệ.');
    }
    // Only fields confirmed by the review API; tags are not persisted by it.
    return ReviewModel.fromServerJson(data, tripId: tripId);
  }

  void _validate(int rating, String comment) {
    if (rating < 1 || rating > 5 || comment.trim().length > 1000) {
      throw ArgumentError('Chọn 1–5 sao và nội dung tối đa 1.000 ký tự.');
    }
  }

  dynamic _data(dynamic response) =>
      response is Map ? response['data'] ?? response : null;

  @override
  Future<List<ReviewModel>> getMyReviews() async {
    final data = _data(
      await client.get('${ApiConfig.reviews}/my', requiresAuth: true),
    );
    if (data is! Map || data['reviews'] is! List) {
      throw const FormatException('Danh sách đánh giá chưa hợp lệ.');
    }
    final result = <ReviewModel>[];
    final ids = <int>{};
    for (final item in data['reviews'] as List) {
      if (item is! Map<String, dynamic> || item['tripId'] is! int) {
        throw const FormatException('Thiếu mã chuyến trong đánh giá.');
      }
      final review = ReviewModel.fromServerJson(
        item,
        tripId: item['tripId'] as int,
      );
      if (!ids.add(review.reviewId!)) {
        throw const FormatException('Mã đánh giá bị trùng.');
      }
      result.add(review);
    }
    return List.unmodifiable(result);
  }

  @override
  Future<ReviewModel> updateReview({
    required int reviewId,
    required int tripId,
    required int rating,
    required String comment,
  }) async {
    final session = TokenStorage.sessionVersion;
    _validate(rating, comment);
    if (reviewId <= 0 || tripId <= 0) {
      throw ArgumentError('Thiếu mã đánh giá/chuyến xe.');
    }
    final data = _data(
      await client.patch(
        '${ApiConfig.reviews}/$reviewId',
        requiresAuth: true,
        body: {'rating': rating, 'comment': comment.trim()},
      ),
    );
    if (data is! Map ||
        data['success'] != true ||
        data['review'] is! Map ||
        data['review']['id'] != reviewId ||
        data['review']['tripId'] != tripId ||
        data['review']['rating'] != rating ||
        (data['review']['comment'] ?? '') != comment.trim()) {
      throw const FormatException(
        'Máy chủ chưa xác nhận nội dung sửa đánh giá.',
      );
    }
    if (session != TokenStorage.sessionVersion) {
      throw StateError('Phiên đăng nhập đã thay đổi.');
    }
    final mine = await getMyReviews();
    final confirmed = mine
        .where(
          (r) =>
              r.reviewId == reviewId &&
              r.tripId == tripId &&
              r.rating == rating &&
              r.comment == comment.trim(),
        )
        .toList();
    if (confirmed.length != 1) {
      throw const FormatException('Chưa đọc lại được đánh giá đã sửa.');
    }
    return confirmed.single;
  }

  @override
  Future<void> deleteReview({
    required int reviewId,
    required int tripId,
  }) async {
    final session = TokenStorage.sessionVersion;
    if (reviewId <= 0 || tripId <= 0) {
      throw ArgumentError('Thiếu mã đánh giá/chuyến xe.');
    }
    final data = _data(
      await client.delete('${ApiConfig.reviews}/$reviewId', requiresAuth: true),
    );
    if (data is! Map || data['success'] != true) {
      throw const FormatException('Chưa xác nhận xóa đánh giá.');
    }
    if (session != TokenStorage.sessionVersion) {
      throw StateError('Phiên đăng nhập đã thay đổi.');
    }
    final mine = await getMyReviews();
    if (mine.any((r) => r.reviewId == reviewId || r.tripId == tripId)) {
      throw const FormatException('Đánh giá vẫn tồn tại sau yêu cầu xóa.');
    }
  }
}
