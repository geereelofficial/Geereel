import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../feed/domain/entities/post_entity.dart';

part 'status_entity.freezed.dart';

/// A single 24h-ephemeral story post.
@freezed
abstract class StatusEntity with _$StatusEntity {
  const factory StatusEntity({
    required String statusId,
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    required MediaType mediaType,
    required String mediaUrl,
    String? thumbnailUrl,
    double? durationSeconds,
    int? width,
    int? height,
    @Default(0) int viewsCount,
    required DateTime createdAt,
    required DateTime expiresAt,
    @Default(false) bool viewed,
  }) = _StatusEntity;
}

/// One author's active statuses, as shown as a single avatar in the tray.
@freezed
abstract class StatusGroupEntity with _$StatusGroupEntity {
  const factory StatusGroupEntity({
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    required List<StatusEntity> statuses,
    @Default(false) bool hasUnviewed,
  }) = _StatusGroupEntity;
}
