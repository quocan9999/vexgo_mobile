import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/data/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;

  NotificationBloc({required this.notificationRepository})
      : super(const NotificationState()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<ChangeNotificationTabEvent>(_onChangeNotificationTab);
    on<MarkNotificationAsReadEvent>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsReadEvent>(_onMarkAllNotificationsAsRead);
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));
    try {
      final list = await notificationRepository.getNotifications();
      emit(state.copyWith(
        status: NotificationStatus.loaded,
        notifications: list,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onChangeNotificationTab(
    ChangeNotificationTabEvent event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(activeTabIndex: event.tabIndex));
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    await notificationRepository.markAsRead(event.notificationId);
    final updated = state.notifications.map((n) {
      if (n.id == event.notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    emit(state.copyWith(notifications: updated));
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    await notificationRepository.markAllAsRead();
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(state.copyWith(notifications: updated));
  }
}
