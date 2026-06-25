import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class GetUserBookmarkedPosts {
  final PostRepository _repository;

  const GetUserBookmarkedPosts(this._repository);

  Future<Result<List<PostEntity>>> call({
    required String authorId,
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  }) {
    return _repository.fetchUserBookmarkedPosts(
      authorId: authorId,
      startAfterCreatedAt: startAfterCreatedAt,
      limit: limit,
    );
  }
}
