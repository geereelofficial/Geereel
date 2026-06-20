import '../../../../core/utils/result.dart';
import '../repositories/post_repository.dart';

class ToggleLike {
  final PostRepository _repository;

  const ToggleLike(this._repository);

  Future<Result<void>> call({required String postId, required String uid}) {
    return _repository.toggleLike(postId: postId, uid: uid);
  }
}
