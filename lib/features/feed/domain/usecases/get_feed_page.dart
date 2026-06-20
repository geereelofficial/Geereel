import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class GetFeedPage {
  final PostRepository _repository;

  const GetFeedPage(this._repository);

  Future<Result<List<PostEntity>>> call({
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  }) {
    return _repository.fetchFeedPage(startAfterCreatedAt: startAfterCreatedAt, limit: limit);
  }
}
