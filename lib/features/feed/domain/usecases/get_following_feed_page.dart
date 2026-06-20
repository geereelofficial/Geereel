import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class GetFollowingFeedPage {
  final PostRepository _repository;

  const GetFollowingFeedPage(this._repository);

  Future<Result<List<PostEntity>>> call({
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  }) {
    return _repository.fetchFollowingFeedPage(startAfterCreatedAt: startAfterCreatedAt, limit: limit);
  }
}
