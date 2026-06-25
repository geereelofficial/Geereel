import '../../../../core/utils/result.dart';
import '../repositories/post_repository.dart';

class AddRepost {
  final PostRepository _repository;

  const AddRepost(this._repository);

  Future<Result<void>> call({required String postId, String? comment}) {
    return _repository.addRepost(postId: postId, comment: comment);
  }
}
