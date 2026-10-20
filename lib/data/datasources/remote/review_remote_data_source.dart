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
    if (data is! Map<String, dynamic> || data['rating'] != rating) {
      throw const FormatException('Máy chủ chưa xác nhận đánh giá hợp lệ.');
    }
    // Only fields confirmed by the review API; tags are not persisted by it.
    return ReviewModel.fromServerJson(data, tripId: tripId);
  }
}
