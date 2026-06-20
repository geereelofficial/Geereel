import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../entities/comment_entity.dart';

abstract class CommentRepository {
  /// Live, newest-first comment list for [postId].
  Stream<List<CommentEntity>> watchComments(
    String postId, {
    int limit = AppConstants.commentsPageSize,
  });

  Future<Result<void>> addComment({
    required String postId,
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    required String text,
  });
}
