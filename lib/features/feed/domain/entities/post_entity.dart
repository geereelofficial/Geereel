import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_entity.freezed.dart';

enum MediaType { video, image }

enum PostStatus { processing, published, failed }

/// Domain representation of a single feed post (video or image).
@freezed
abstract class PostEntity with _$PostEntity {
  const factory PostEntity({
    required String postId,
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    required MediaType mediaType,
    required String mediaUrl,
    String? thumbnailUrl,
    @Default('') String caption,
    @Default(0) int likesCount,
    @Default(0) int commentsCount,
    @Default(0) int sharesCount,
    @Default(0) int viewsCount,
    @Default(0) int bookmarksCount,
    @Default(0) int repostsCount,
    double? durationSeconds,
    int? width,
    int? height,
    @Default(PostStatus.published) PostStatus status,
    required DateTime createdAt,
  }) = _PostEntity;
}
