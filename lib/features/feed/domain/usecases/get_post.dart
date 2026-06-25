import '../../../../core/utils/result.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class GetPost {
  final PostRepository _repository;

  const GetPost(this._repository);

  Future<Result<PostEntity>> call(String postId) {
    return _repository.fetchPost(postId);
  }
}
