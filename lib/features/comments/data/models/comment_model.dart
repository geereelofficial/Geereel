import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/timestamp_converter.dart';
import '../../domain/entities/comment_entity.dart';

part 'comment_model.freezed.dart';
part 'comment_model.g.dart';

@freezed
abstract class CommentModel with _$CommentModel {
  const factory CommentModel({
    required String commentId,
    required String postId,
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    required String text,
    @Default(0) int likesCount,
    String? parentCommentId,
    @TimestampConverter() required DateTime createdAt,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) => _$CommentModelFromJson(json);
}

extension CommentModelMapper on CommentModel {
  CommentEntity toEntity() => CommentEntity(
    commentId: commentId,
    postId: postId,
    authorId: authorId,
    authorUsername: authorUsername,
    authorPhotoUrl: authorPhotoUrl,
    text: text,
    likesCount: likesCount,
    parentCommentId: parentCommentId,
    createdAt: createdAt,
  );
}
