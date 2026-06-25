import '../../../../core/utils/result.dart';
import '../repositories/notification_repository.dart';

class GetUnreadNotificationCount {
  final NotificationRepository _repository;

  const GetUnreadNotificationCount(this._repository);

  Future<Result<int>> call() => _repository.fetchUnreadCount();
}
