import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/timestamp_converter.dart';
import '../../domain/entities/post_entity.dart';

part 'post_model.freezed.dart';
part 'post_model.g.dart';

/// Data-layer shape of a `/api/posts/:postId` response.
@freezed
abstract class PostModel with _$PostModel {
  const factory PostModel({
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
    @TimestampConverter() required DateTime createdAt,
    @Default(false) bool liked,
    @Default(false) bool bookmarked,
    @Default(false) bool reposted,
    @Default(false) bool isFollowingAuthor,
    String? repostComment,
  }) = _PostModel;

  factory PostModel.fromJson(Map<String, dynamic> json) => _$PostModelFromJson(json);
}

extension PostModelMapper on PostModel {
  PostEntity toEntity() => PostEntity(
    postId: postId,
    authorId: authorId,
    authorUsername: authorUsername,
    authorPhotoUrl: authorPhotoUrl,
    mediaType: mediaType,
    mediaUrl: mediaUrl,
    thumbnailUrl: thumbnailUrl,
    caption: caption,
    likesCount: likesCount,
    commentsCount: commentsCount,
    sharesCount: sharesCount,
    viewsCount: viewsCount,
    bookmarksCount: bookmarksCount,
    repostsCount: repostsCount,
    durationSeconds: durationSeconds,
    width: width,
    height: height,
    status: status,
    createdAt: createdAt,
    liked: liked,
    bookmarked: bookmarked,
    reposted: reposted,
    isFollowingAuthor: isFollowingAuthor,
    repostComment: repostComment,
  );
}
