import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/data/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;
  int _generation = 0;
  String? _sessionKey;
  bool _sessionInitialized = false;
  bool _authenticated;

  void setSession(String? key) {
    if (_sessionInitialized &&
        _sessionKey == key &&
        _authenticated == (key != null)) {
      return;
    }
    _sessionInitialized = true;
    _sessionKey = key;
    _authenticated = key != null;
    _generation++;
    // Clear synchronously before pending account requests can complete.
    // ignore: invalid_use_of_visible_for_testing_member
    emit(NotificationState(requiresLogin: !_authenticated));
    if (_authenticated) add(const LoadNotificationsEvent());
  }

  NotificationBloc({
    required this.notificationRepository,
    bool authenticated = true,
  }) : _authenticated = authenticated,
       super(const NotificationState()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<ChangeNotificationTabEvent>(_onChangeNotificationTab);
    on<MarkNotificationAsReadEvent>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsReadEvent>(_onMarkAllNotificationsAsRead);
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (!_authenticated) return;
    final generation = _generation;
    emit(state.copyWith(status: NotificationStatus.loading, clearError: true));
    try {
      final list = await notificationRepository.getNotifications();
      if (generation != _generation) return;
      emit(
        state.copyWith(status: NotificationStatus.loaded, notifications: list),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: NotificationStatus.failure,
          errorMessage: e.toString(),
        ),
      );
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
    if (!_authenticated) return;
    final generation = _generation;
    try {
      await notificationRepository.markAsRead(event.notificationId);
      if (generation != _generation) return;
      final updated = state.notifications.map((n) {
        if (n.id == event.notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      emit(state.copyWith(notifications: updated, clearError: true));
    } catch (e) {
      if (generation != _generation) return;
      emit(state.copyWith(errorMessage: 'Không thể đánh dấu đã đọc: $e'));
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (!_authenticated) return;
    final generation = _generation;
    try {
      await notificationRepository.markAllAsRead();
      if (generation != _generation) return;
      final updated = state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      emit(state.copyWith(notifications: updated, clearError: true));
    } catch (e) {
      if (generation != _generation) return;
      emit(state.copyWith(errorMessage: 'Không thể đánh dấu đã đọc: $e'));
    }
  }
}
