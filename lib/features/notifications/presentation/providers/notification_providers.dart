import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/get_unread_notification_count.dart';
import '../../domain/usecases/mark_notifications_read.dart';

part 'notification_providers.g.dart';

@riverpod
NotificationRemoteDataSource notificationRemoteDataSource(Ref ref) {
  return ApiNotificationRemoteDataSource(apiClient: ref.watch(apiClientProvider));
}

@riverpod
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRepositoryImpl(ref.watch(notificationRemoteDataSourceProvider));
}

@riverpod
GetNotifications getNotificationsUseCase(Ref ref) =>
    GetNotifications(ref.watch(notificationRepositoryProvider));

@riverpod
GetUnreadNotificationCount getUnreadNotificationCountUseCase(Ref ref) =>
    GetUnreadNotificationCount(ref.watch(notificationRepositoryProvider));

@riverpod
MarkNotificationsRead markNotificationsReadUseCase(Ref ref) =>
    MarkNotificationsRead(ref.watch(notificationRepositoryProvider));

/// Unread count for the bottom-nav badge. Invalidated by
/// [NotificationsController.markAllRead] so the badge clears as soon as the
/// notifications screen has been opened.
@riverpod
Future<int> unreadNotificationCount(Ref ref) async {
  final result = await ref.watch(getUnreadNotificationCountUseCaseProvider).call();
  return switch (result) {
    Ok(value: final count) => count,
    Err() => 0,
  };
}

/// `null` means the "All" tab; otherwise the single type that tab filters to.
typedef NotificationFilter = NotificationType?;

/// Paginated notifications for one tab, keyed by filter so switching tabs
/// keeps each one's pagination/scroll state independent — mirrors
/// [ProfilePostsController].
@riverpod
class NotificationsController extends _$NotificationsController {
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<Result<List<NotificationEntity>>> _fetchPage(
    NotificationFilter filter, {
    DateTime? startAfterCreatedAt,
  }) {
    return ref
        .read(getNotificationsUseCaseProvider)
        .call(type: filter, startAfterCreatedAt: startAfterCreatedAt);
  }

  @override
  Future<List<NotificationEntity>> build(NotificationFilter filter) async {
    _hasMore = true;
    final result = await _fetchPage(filter);
    return switch (result) {
      Ok(value: final notifications) => notifications,
      Err(failure: final failure) => throw failure,
    };
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final current = state.value;
    if (current == null || current.isEmpty) return;

    _isLoadingMore = true;
    final result = await _fetchPage(filter, startAfterCreatedAt: current.last.createdAt);
    _isLoadingMore = false;

    switch (result) {
      case Ok(value: final newNotifications):
        if (newNotifications.length < AppConstants.feedPageSize) _hasMore = false;
        state = AsyncData([...current, ...newNotifications]);
      case Err():
        break;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Marks every notification read on the backend and clears the unread-count
/// badge. A standalone action rather than a method on
/// [NotificationsController] since it isn't scoped to one tab's pagination
/// state — it's a single global "I've seen these" call the screen makes
/// once on open.
@riverpod
class MarkNotificationsReadController extends _$MarkNotificationsReadController {
  @override
  FutureOr<void> build() {}

  Future<void> call() async {
    await ref.read(markNotificationsReadUseCaseProvider).call();
    ref.invalidate(unreadNotificationCountProvider);
  }
}
