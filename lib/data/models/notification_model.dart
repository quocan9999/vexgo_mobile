import 'package:equatable/equatable.dart';

enum NotificationCategory { trip, promo, system, unknown }

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
      final s = cat?.toUpperCase() ?? '';
      if (s == 'TRIP' || s == 'CHUYEN_XE') {
        return NotificationCategory.trip;
      }
      if (s == 'PROMO' || s == 'KHUYEN_MAI') {
        return NotificationCategory.promo;
      }
      if (s == 'SYSTEM') return NotificationCategory.system;
      return NotificationCategory.unknown;
    }

    final id =
        json['id']?.toString() ?? json['notificationId']?.toString() ?? '';
    final title = json['title'] as String? ?? json['tieuDe'] as String? ?? '';
    final message =
        json['message'] as String? ??
        json['content'] as String? ??
        json['noiDung'] as String? ??
        '';
    final isRead = json['isRead'] as bool? ?? json['daDoc'] as bool? ?? false;
    final createdAtStr =
        json['createdAt'] as String? ?? json['thoiGian'] as String?;
    final createdAt = createdAtStr != null
        ? (DateTime.tryParse(createdAtStr) ?? DateTime.now())
        : DateTime.now();

    return NotificationModel(
      id: id,
      title: title,
      message: message,
      // Backend `type`/`trangThai` describe delivery, not content category.
      category: parseCategory(json['category'] as String?),
      createdAt: createdAt,
      isRead: isRead,
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
      case NotificationCategory.unknown:
        catStr = 'UNKNOWN';
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
