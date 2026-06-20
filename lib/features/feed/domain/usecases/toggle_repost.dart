import '../../../../core/utils/result.dart';
import '../repositories/post_repository.dart';

class ToggleRepost {
  final PostRepository _repository;

  const ToggleRepost(this._repository);

  Future<Result<void>> call({required String postId, required String uid}) {
    return _repository.toggleRepost(postId: postId, uid: uid);
  }
}
