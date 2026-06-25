import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetFollowing {
  final AuthRepository _repository;

  const GetFollowing(this._repository);

  Future<Result<List<UserEntity>>> call(
    String uid, {
    required int page,
    int limit = AppConstants.followListPageSize,
  }) {
    return _repository.getFollowing(uid, page: page, limit: limit);
  }
}
