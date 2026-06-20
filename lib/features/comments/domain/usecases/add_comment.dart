import '../../../../core/utils/result.dart';
import '../repositories/comment_repository.dart';

class AddComment {
  final CommentRepository _repository;

  const AddComment(this._repository);

  Future<Result<void>> call({
    required String postId,
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    required String text,
  }) {
    return _repository.addComment(
      postId: postId,
      authorId: authorId,
      authorUsername: authorUsername,
      authorPhotoUrl: authorPhotoUrl,
      text: text,
    );
  }
}
