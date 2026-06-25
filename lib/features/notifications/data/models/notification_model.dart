import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/timestamp_converter.dart';
import '../../domain/entities/notification_entity.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

/// Data-layer shape of a `/api/notifications` list item.
@freezed
abstract class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String notificationId,
    required NotificationType type,
    required String actorId,
    required String actorUsername,
    String? actorPhotoUrl,
    String? postId,
    @Default(false) bool read,
    @TimestampConverter() required DateTime createdAt,
    bool? isFollowingActor,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) => _$NotificationModelFromJson(json);
}

extension NotificationModelMapper on NotificationModel {
  NotificationEntity toEntity() => NotificationEntity(
    notificationId: notificationId,
    type: type,
    actorId: actorId,
    actorUsername: actorUsername,
    actorPhotoUrl: actorPhotoUrl,
    postId: postId,
    read: read,
    createdAt: createdAt,
    isFollowingActor: isFollowingActor,
  );
}
