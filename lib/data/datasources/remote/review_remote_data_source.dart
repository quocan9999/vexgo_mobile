import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../models/review_model.dart';

abstract class ReviewRemoteDataSource {
  Future<ReviewModel> createReview({
    required int tripId,
    required int rating,
    String? comment,
  });
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
    if (data is! Map<String, dynamic> ||
        data['reviewId'] is! int ||
        (data['reviewId'] as int) <= 0 ||
        data['tripId'] != tripId ||
        data['rating'] is! int ||
        data['rating'] != rating ||
        rating < 1 ||
        rating > 5 ||
        (data['comment'] != null && data['comment'] is! String) ||
        data['createdAt'] is! String ||
        DateTime.tryParse(data['createdAt'] as String) == null) {
      throw const FormatException('Máy chủ chưa xác nhận đánh giá hợp lệ.');
    }
    // Only fields confirmed by the review API; tags are not persisted by it.
    return ReviewModel(
      rating: data['rating'] as int,
      comment: data['comment'] as String? ?? '',
      createdAt: data['createdAt'] as String,
    );
  }
}
