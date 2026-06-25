import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../entities/comment_entity.dart';

abstract class CommentRepository {
  /// One page of comments, newest first. Pass [before] (the last comment's
  /// `createdAt` from the previous page) to fetch the next page.
  Future<Result<List<CommentEntity>>> fetchComments(
    String postId, {
    int limit = AppConstants.commentsPageSize,
    DateTime? before,
  });

  Future<Result<CommentEntity>> addComment({
    required String postId,
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    required String text,
  });
}
