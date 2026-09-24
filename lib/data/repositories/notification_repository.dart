import 'package:vexgo_app/core/utils/json_loader.dart';
import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class MockNotificationRepository implements NotificationRepository {
  List<NotificationModel>? _cachedNotifications;

  @override
  Future<List<NotificationModel>> getNotifications() async {
    if (_cachedNotifications != null) return _cachedNotifications!;
    try {
      final rawList = await JsonLoader.loadJsonList('assets/mock_data/notifications.json');
      _cachedNotifications = rawList.map((item) => NotificationModel.fromJson(item)).toList();
      return _cachedNotifications!;
    } catch (_) {
      _cachedNotifications = [];
      return _cachedNotifications!;
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    final list = await getNotifications();
    _cachedNotifications = list.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
  }

  @override
  Future<void> markAllAsRead() async {
    final list = await getNotifications();
    _cachedNotifications = list.map((n) => n.copyWith(isRead: true)).toList();
  }
}
