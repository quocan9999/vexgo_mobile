import 'package:equatable/equatable.dart';

enum PointTransactionType { earn, redeem, bonus }

class PointTransactionModel extends Equatable {
  final String id;
  final String title;
  final int points;
  final PointTransactionType type;
  final DateTime createdAt;

  const PointTransactionModel({
    required this.id,
    required this.title,
    required this.points,
    required this.type,
    required this.createdAt,
  });

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) {
    PointTransactionType parseType(String typeStr) {
      switch (typeStr.toUpperCase()) {
        case 'REDEEM':
          return PointTransactionType.redeem;
        case 'BONUS':
          return PointTransactionType.bonus;
        case 'EARN':
        default:
          return PointTransactionType.earn;
      }
    }

    return PointTransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      points: json['points'] as int,
      type: parseType(json['type'] as String? ?? 'EARN'),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    String typeStr;
    switch (type) {
      case PointTransactionType.redeem:
        typeStr = 'REDEEM';
        break;
      case PointTransactionType.bonus:
        typeStr = 'BONUS';
        break;
      case PointTransactionType.earn:
        typeStr = 'EARN';
        break;
    }

    return {
      'id': id,
      'title': title,
      'points': points,
      'type': typeStr,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, points, type, createdAt];
}
