import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_entity.freezed.dart';

enum NotificationType { follow, like, comment, repost }

/// Domain representation of one notification: someone followed you, liked,
/// commented on, or reposted your content.
@freezed
abstract class NotificationEntity with _$NotificationEntity {
  const factory NotificationEntity({
    required String notificationId,
    required NotificationType type,
    required String actorId,
    required String actorUsername,
    String? actorPhotoUrl,
    String? postId,
    @Default(false) bool read,
    required DateTime createdAt,
    // Only meaningful for [NotificationType.follow] — whether the signed-in
    // viewer already follows the actor back, so the tile can show
    // "Follow back" vs "Following".
    bool? isFollowingActor,
  }) = _NotificationEntity;
}
