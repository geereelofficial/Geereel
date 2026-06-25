import '../../../../core/network/api_client.dart';
import '../../domain/entities/notification_entity.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> fetchNotifications({
    NotificationType? type,
    DateTime? startAfterCreatedAt,
    required int limit,
  });

  Future<int> fetchUnreadCount();

  Future<void> markAllRead();
}

class ApiNotificationRemoteDataSource implements NotificationRemoteDataSource {
  final ApiClient _apiClient;

  const ApiNotificationRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<NotificationModel>> fetchNotifications({
    NotificationType? type,
    DateTime? startAfterCreatedAt,
    required int limit,
  }) async {
    final response = await _apiClient.get(
      '/notifications',
      query: {
        'limit': limit,
        if (type != null) 'type': type.name,
        if (startAfterCreatedAt != null) 'cursor': startAfterCreatedAt.toIso8601String(),
      },
    );
    return (response.data as List)
        .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> fetchUnreadCount() async {
    final response = await _apiClient.get('/notifications/unread-count');
    return (response.data as Map<String, dynamic>)['count'] as int;
  }

  @override
  Future<void> markAllRead() async {
    await _apiClient.post('/notifications/read');
  }
}
