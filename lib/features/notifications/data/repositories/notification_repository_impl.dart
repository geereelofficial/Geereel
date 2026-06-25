import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remote;

  const NotificationRepositoryImpl(this._remote);

  @override
  Future<Result<List<NotificationEntity>>> fetchNotifications({
    NotificationType? type,
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  }) async {
    try {
      final models = await _remote.fetchNotifications(
        type: type,
        startAfterCreatedAt: startAfterCreatedAt,
        limit: limit,
      );
      return Ok(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<int>> fetchUnreadCount() async {
    try {
      return Ok(await _remote.fetchUnreadCount());
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> markAllRead() async {
    try {
      await _remote.markAllRead();
      return const Ok(null);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  Failure _mapToFailure(Object error) {
    if (error is AuthException) return AuthFailure(error.message);
    if (error is NotFoundException) return NotFoundFailure(error.message);
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is ServerException) return ServerFailure(error.message);
    return ServerFailure('Notification error (${error.runtimeType}): $error');
  }
}
