import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment_entity.freezed.dart';

/// Domain representation of a comment on a post.
///
/// [parentCommentId] is unused by the MVP flat comment list, but is
/// present now so nested replies don't require a schema migration later.
@freezed
abstract class CommentEntity with _$CommentEntity {
  const factory CommentEntity({
    required String commentId,
    required String postId,
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    required String text,
    @Default(0) int likesCount,
    String? parentCommentId,
    required DateTime createdAt,
  }) = _CommentEntity;
}
