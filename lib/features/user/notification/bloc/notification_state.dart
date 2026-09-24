import 'package:equatable/equatable.dart';
import '../../../../data/models/notification_model.dart';

enum NotificationStatus { initial, loading, loaded, failure }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<NotificationModel> notifications;
  final int activeTabIndex;
  final String? errorMessage;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.activeTabIndex = 0,
    this.errorMessage,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get filteredNotifications {
    switch (activeTabIndex) {
      case 1:
        return notifications.where((n) => n.category == NotificationCategory.trip).toList();
      case 2:
        return notifications.where((n) => n.category == NotificationCategory.promo).toList();
      case 3:
        return notifications.where((n) => n.category == NotificationCategory.system).toList();
      case 0:
      default:
        return notifications;
    }
  }

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationModel>? notifications,
    int? activeTabIndex,
    String? errorMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        notifications,
        activeTabIndex,
        errorMessage,
      ];
}
