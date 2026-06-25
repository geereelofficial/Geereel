import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class GetNotifications {
  final NotificationRepository _repository;

  const GetNotifications(this._repository);

  Future<Result<List<NotificationEntity>>> call({
    NotificationType? type,
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  }) {
    return _repository.fetchNotifications(
      type: type,
      startAfterCreatedAt: startAfterCreatedAt,
      limit: limit,
    );
  }
}
