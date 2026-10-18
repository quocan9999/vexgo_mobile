import '../../models/notification_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<List<NotificationModel>> getMyNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  });

  Future<bool> markAsRead(dynamic id);
  Future<bool> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient client;

  NotificationRemoteDataSourceImpl({required this.client});

  @override
  Future<List<NotificationModel>> getNotifications() => getMyNotifications();

  @override
  Future<List<NotificationModel>> getMyNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'unreadOnly': unreadOnly,
      'page': page,
      'pageSize': pageSize,
    };

    final items = <NotificationModel>[];
    var currentPage = page;
    while (true) {
      query['page'] = currentPage;
      final res = await client.get(
        ApiConfig.notifications,
        queryParams: query,
        requiresAuth: true,
      );
      final data = res is Map<String, dynamic> ? res['data'] : res;
      if (data is! List) {
        throw const FormatException('Danh sách từ máy chủ không hợp lệ.');
      }
      items.addAll(
        data.map(
          (item) => NotificationModel.fromJson(item as Map<String, dynamic>),
        ),
      );
      final meta = res is Map<String, dynamic> ? res['meta'] : null;
      final totalPages = meta is Map
          ? (meta['totalPages'] as num?)?.toInt()
          : null;
      if (totalPages == null || currentPage >= totalPages || data.isEmpty) {
        break;
      }
      currentPage++;
    }
    return items;
  }

  @override
  Future<bool> markAsRead(dynamic id) async {
    final res = await client.patch(
      ApiConfig.notificationRead(id),
      requiresAuth: true,
    );
    return res != null;
  }

  @override
  Future<bool> markAllAsRead() async {
    final res = await client.patch(
      ApiConfig.notificationReadAll,
      requiresAuth: true,
    );
    return res != null;
  }
}
