import 'package:equatable/equatable.dart';

enum NotificationCategory { trip, promo, system }

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final DateTime createdAt;
  final bool isRead;
  final String? ticketCode;
  final String? voucherCode;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    this.isRead = false,
    this.ticketCode,
    this.voucherCode,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationCategory? category,
    DateTime? createdAt,
    bool? isRead,
    String? ticketCode,
    String? voucherCode,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      ticketCode: ticketCode ?? this.ticketCode,
      voucherCode: voucherCode ?? this.voucherCode,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationCategory parseCategory(String? cat) {
      switch (cat?.toUpperCase()) {
        case 'TRIP':
          return NotificationCategory.trip;
        case 'PROMO':
          return NotificationCategory.promo;
        case 'SYSTEM':
        default:
          return NotificationCategory.system;
      }
    }

    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      category: parseCategory(json['category'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      ticketCode: json['ticketCode'] as String?,
      voucherCode: json['voucherCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    String catStr;
    switch (category) {
      case NotificationCategory.trip:
        catStr = 'TRIP';
        break;
      case NotificationCategory.promo:
        catStr = 'PROMO';
        break;
      case NotificationCategory.system:
        catStr = 'SYSTEM';
        break;
    }

    return {
      'id': id,
      'title': title,
      'message': message,
      'category': catStr,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      if (ticketCode != null) 'ticketCode': ticketCode,
      if (voucherCode != null) 'voucherCode': voucherCode,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        category,
        createdAt,
        isRead,
        ticketCode,
        voucherCode,
      ];
}
