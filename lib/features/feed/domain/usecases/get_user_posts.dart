import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class GetUserPosts {
  final PostRepository _repository;

  const GetUserPosts(this._repository);

  Future<Result<List<PostEntity>>> call({
    required String authorId,
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  }) {
    return _repository.fetchUserPosts(
      authorId: authorId,
      startAfterCreatedAt: startAfterCreatedAt,
      limit: limit,
    );
  }
}
