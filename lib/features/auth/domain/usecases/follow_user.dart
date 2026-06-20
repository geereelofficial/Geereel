import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

class FollowUser {
  final AuthRepository _repository;

  const FollowUser(this._repository);

  Future<Result<void>> call(String targetUid) => _repository.followUser(targetUid);
}
