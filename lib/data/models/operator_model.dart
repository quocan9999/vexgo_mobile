import 'package:equatable/equatable.dart';

class OperatorModel extends Equatable {
  final String id;
  final String name;
  final String shortName;
  final String? hotline;
  final double? rating;
  final int? reviewCount;
  final String? logoUrl;
  final String? policy;

  const OperatorModel({
    required this.id,
    required this.name,
    required this.shortName,
    this.hotline,
    this.rating,
    this.reviewCount,
    this.logoUrl,
    this.policy,
  });

  factory OperatorModel.fromJson(Map<String, dynamic> json) {
    final id = json['busCompanyId']?.toString() ?? json['id']?.toString() ?? '';
    final name = json['name'] as String? ?? json['tenNhaXe'] as String? ?? '';
    final shortName =
        json['shortName'] as String? ?? json['code'] as String? ?? name;
    final hotline =
        json['hotline'] as String? ??
        json['contactInfo'] as String? ??
        json['thongTinLienHe'] as String?;
    final rating = (json['rating'] as num?)?.toDouble();
    final reviewCount = json['reviewCount'] as int?;
    final logoUrl = json['logoUrl'] as String?;
    final policy = json['policy'] as String?;

    return OperatorModel(
      id: id,
      name: name,
      shortName: shortName,
      hotline: hotline,
      rating: rating,
      reviewCount: reviewCount,
      logoUrl: logoUrl,
      policy: policy,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortName': shortName,
    if (hotline != null) 'hotline': hotline,
    if (rating != null) 'rating': rating,
    if (reviewCount != null) 'reviewCount': reviewCount,
    if (logoUrl != null) 'logoUrl': logoUrl,
    if (policy != null) 'policy': policy,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    shortName,
    hotline,
    rating,
    reviewCount,
    logoUrl,
    policy,
  ];
}
