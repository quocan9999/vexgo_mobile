import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationEvent {
  const LoadNotificationsEvent();
}

class ChangeNotificationTabEvent extends NotificationEvent {
  final int tabIndex; // 0: Tất cả, 1: Chuyến đi, 2: Khuyến mại

  const ChangeNotificationTabEvent(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class MarkNotificationAsReadEvent extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsReadEvent(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsAsReadEvent extends NotificationEvent {
  const MarkAllNotificationsAsReadEvent();
}
