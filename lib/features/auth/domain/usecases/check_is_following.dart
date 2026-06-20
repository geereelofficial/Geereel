import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

class CheckIsFollowing {
  final AuthRepository _repository;

  const CheckIsFollowing(this._repository);

  Future<Result<bool>> call(String targetUid) => _repository.isFollowing(targetUid);
}
