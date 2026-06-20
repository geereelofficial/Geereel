import '../../../../core/utils/result.dart';
import '../repositories/post_repository.dart';

class ToggleBookmark {
  final PostRepository _repository;

  const ToggleBookmark(this._repository);

  Future<Result<void>> call({required String postId, required String uid}) {
    return _repository.toggleBookmark(postId: postId, uid: uid);
  }
}
