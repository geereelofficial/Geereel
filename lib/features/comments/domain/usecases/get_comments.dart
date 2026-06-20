import '../../../../core/constants/app_constants.dart';
import '../entities/comment_entity.dart';
import '../repositories/comment_repository.dart';

class GetComments {
  final CommentRepository _repository;

  const GetComments(this._repository);

  Stream<List<CommentEntity>> call(
    String postId, {
    int limit = AppConstants.commentsPageSize,
  }) {
    return _repository.watchComments(postId, limit: limit);
  }
}
