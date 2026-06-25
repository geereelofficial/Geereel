import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../entities/comment_entity.dart';
import '../repositories/comment_repository.dart';

class GetComments {
  final CommentRepository _repository;

  const GetComments(this._repository);

  Future<Result<List<CommentEntity>>> call(
    String postId, {
    int limit = AppConstants.commentsPageSize,
    DateTime? before,
  }) {
    return _repository.fetchComments(postId, limit: limit, before: before);
  }
}
