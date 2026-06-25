import '../../../../core/utils/result.dart';
import '../repositories/post_repository.dart';

class RemoveRepost {
  final PostRepository _repository;

  const RemoveRepost(this._repository);

  Future<Result<void>> call(String postId) {
    return _repository.removeRepost(postId);
  }
}
