import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../entities/notification_entity.dart';

/// Contract for reading the signed-in user's notifications.
abstract class NotificationRepository {
  /// One reverse-chronological page, optionally filtered to [type].
  ///
  /// Pass [startAfterCreatedAt] (the last item of the previous page) to
  /// fetch the next page; omit it for the first page.
  Future<Result<List<NotificationEntity>>> fetchNotifications({
    NotificationType? type,
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  });

  Future<Result<int>> fetchUnreadCount();

  Future<Result<void>> markAllRead();
}
