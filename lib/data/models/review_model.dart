import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final int rating; // 1 to 5
  final String comment;
  final List<String>
  tags; // ['Đúng giờ', 'Xe sạch sẽ', 'Lái xe an toàn', 'Nhân viên nhiệt tình']
  final String createdAt;

  const ReviewModel({
    required this.rating,
    required this.comment,
    this.tags = const [],
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      rating: json['rating'] as int? ?? 5,
      comment: json['comment'] as String? ?? '',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  factory ReviewModel.fromServerJson(
    Map<String, dynamic> json, {
    required int tripId,
  }) {
    final rating = json['rating'];
    final createdAt = json['createdAt'];
    if (tripId <= 0 ||
        json['tripId'] != tripId ||
        json['reviewId'] is! int ||
        (json['reviewId'] as int) <= 0 ||
        rating is! int ||
        rating < 1 ||
        rating > 5 ||
        (json['comment'] != null && json['comment'] is! String) ||
        createdAt is! String ||
        DateTime.tryParse(createdAt) == null) {
      throw const FormatException('Máy chủ chưa xác nhận đánh giá hợp lệ.');
    }
    return ReviewModel(
      rating: rating,
      comment: json['comment'] as String? ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'rating': rating,
    'comment': comment,
    'tags': tags,
    'createdAt': createdAt,
  };

  @override
  List<Object?> get props => [rating, comment, tags, createdAt];
}
