import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class GetUserLikedPosts {
  final PostRepository _repository;

  const GetUserLikedPosts(this._repository);

  Future<Result<List<PostEntity>>> call({
    required String authorId,
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  }) {
    return _repository.fetchUserLikedPosts(
      authorId: authorId,
      startAfterCreatedAt: startAfterCreatedAt,
      limit: limit,
    );
  }
}
