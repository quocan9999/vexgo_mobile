import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final int? reviewId, tripId;
  final bool? isEditable;
  final bool isEdited;
  final String? replyContent, responderName, replyCreatedAt;
  final int rating; // 1 to 5
  final String comment;
  final List<String>
  tags; // ['Đúng giờ', 'Xe sạch sẽ', 'Lái xe an toàn', 'Nhân viên nhiệt tình']
  final String createdAt;

  const ReviewModel({
    required this.rating,
    this.reviewId,
    this.tripId,
    this.isEditable,
    this.isEdited = false,
    this.replyContent,
    this.responderName,
    this.replyCreatedAt,
    required this.comment,
    this.tags = const [],
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: (json['reviewId'] ?? json['id']) as int?,
      tripId: json['tripId'] as int?,
      isEditable: json['isEditable'] as bool?,
      isEdited: json['isEdited'] == true,
      replyContent: (json['reply'] as Map?)?['content'] as String?,
      responderName: (json['reply'] as Map?)?['responderName'] as String?,
      replyCreatedAt: (json['reply'] as Map?)?['createdAt'] as String?,
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
        (json['reviewId'] ?? json['id']) is! int ||
        ((json['reviewId'] ?? json['id']) as int) <= 0 ||
        rating is! int ||
        rating < 1 ||
        rating > 5 ||
        (json['comment'] != null && json['comment'] is! String) ||
        createdAt is! String ||
        DateTime.tryParse(createdAt) == null) {
      throw const FormatException('Máy chủ chưa xác nhận đánh giá hợp lệ.');
    }
    final reply = json['reply'];
    if ((json['isEditable'] != null && json['isEditable'] is! bool) ||
        (json['isEdited'] != null && json['isEdited'] is! bool) ||
        (reply != null &&
            (reply is! Map ||
                reply['content'] is! String ||
                (reply['content'] as String).trim().isEmpty ||
                (reply['responderName'] != null &&
                    reply['responderName'] is! String) ||
                (reply['createdAt'] != null &&
                    (reply['createdAt'] is! String ||
                        DateTime.tryParse(reply['createdAt']) == null))))) {
      throw const FormatException('Dữ liệu đánh giá/phản hồi chưa hợp lệ.');
    }
    return ReviewModel(
      reviewId: (json['reviewId'] ?? json['id']) as int,
      tripId: tripId,
      rating: rating,
      comment: json['comment'] as String? ?? '',
      createdAt: createdAt,
      isEditable: json['isEditable'] as bool?,
      isEdited: json['isEdited'] == true,
      replyContent: reply?['content'] as String?,
      responderName: reply?['responderName'] as String?,
      replyCreatedAt: reply?['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (reviewId != null) 'reviewId': reviewId,
    if (tripId != null) 'tripId': tripId,
    if (isEditable != null) 'isEditable': isEditable,
    'isEdited': isEdited,
    if (replyContent != null)
      'reply': {
        'content': replyContent,
        'responderName': responderName,
        'createdAt': replyCreatedAt,
      },
    'rating': rating,
    'comment': comment,
    'tags': tags,
    'createdAt': createdAt,
  };

  @override
  List<Object?> get props => [
    reviewId,
    tripId,
    rating,
    comment,
    tags,
    createdAt,
    isEditable,
    isEdited,
    replyContent,
    responderName,
    replyCreatedAt,
  ];
}
