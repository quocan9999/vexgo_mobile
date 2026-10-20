import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/utils/json_loader.dart';
import '../datasources/remote/notification_remote_data_source.dart';
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
      final rawList = await JsonLoader.loadJsonList(
        'assets/mock_data/notifications.json',
      );
      _cachedNotifications = rawList
          .map((item) => NotificationModel.fromJson(item))
          .toList();
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

class HybridNotificationRepository implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final MockNotificationRepository mockFallback;

  HybridNotificationRepository({
    NotificationRemoteDataSource? remoteDataSource,
    MockNotificationRepository? mockFallback,
  }) : remoteDataSource =
           remoteDataSource ??
           NotificationRemoteDataSourceImpl(client: ApiClient()),
       mockFallback = mockFallback ?? MockNotificationRepository();

  @override
  Future<List<NotificationModel>> getNotifications() async {
    if (ApiConfig.isDemoMode) {
      return await mockFallback.getNotifications();
    }
    return await remoteDataSource.getNotifications();
  }

  @override
  Future<void> markAsRead(String id) async {
    if (ApiConfig.isDemoMode) {
      await mockFallback.markAsRead(id);
      return;
    }
    await remoteDataSource.markAsRead(id);
  }

  @override
  Future<void> markAllAsRead() async {
    if (ApiConfig.isDemoMode) {
      await mockFallback.markAllAsRead();
      return;
    }
    await remoteDataSource.markAllAsRead();
  }
}

/// Real notification repository: 100% real mode using NotificationRemoteDataSource.
class RealNotificationRepository implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  RealNotificationRepository({NotificationRemoteDataSource? remoteDataSource})
    : remoteDataSource =
          remoteDataSource ??
          NotificationRemoteDataSourceImpl(client: ApiClient());

  @override
  Future<List<NotificationModel>> getNotifications() async {
    return await remoteDataSource.getNotifications();
  }

  @override
  Future<void> markAsRead(String id) async {
    await remoteDataSource.markAsRead(id);
  }

  @override
  Future<void> markAllAsRead() async {
    await remoteDataSource.markAllAsRead();
  }
}
