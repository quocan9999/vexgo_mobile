import 'package:equatable/equatable.dart';

class OperatorModel extends Equatable {
  final String id;
  final String name;
  final String shortName;
  final String hotline;
  final double rating;
  final int reviewCount;
  final String logoUrl;
  final String policy;

  const OperatorModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.hotline,
    required this.rating,
    required this.reviewCount,
    required this.logoUrl,
    required this.policy,
  });

  factory OperatorModel.fromJson(Map<String, dynamic> json) {
    return OperatorModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      shortName: json['shortName'] as String? ?? '',
      hotline: json['hotline'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      logoUrl: json['logoUrl'] as String? ?? '',
      policy: json['policy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortName': shortName,
    'hotline': hotline,
    'rating': rating,
    'reviewCount': reviewCount,
    'logoUrl': logoUrl,
    'policy': policy,
  };

  @override
  List<Object?> get props => [id, name, rating];
}
