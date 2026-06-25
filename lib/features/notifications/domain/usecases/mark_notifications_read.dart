import '../../../../core/utils/result.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationsRead {
  final NotificationRepository _repository;

  const MarkNotificationsRead(this._repository);

  Future<Result<void>> call() => _repository.markAllRead();
}
