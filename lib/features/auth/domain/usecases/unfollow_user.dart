import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

class UnfollowUser {
  final AuthRepository _repository;

  const UnfollowUser(this._repository);

  Future<Result<void>> call(String targetUid) => _repository.unfollowUser(targetUid);
}
