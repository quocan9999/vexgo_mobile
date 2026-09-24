import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final int rating; // 1 to 5
  final String comment;
  final List<String> tags; // ['Đúng giờ', 'Xe sạch sẽ', 'Lái xe an toàn', 'Nhân viên nhiệt tình']
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
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] as String? ?? '',
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
