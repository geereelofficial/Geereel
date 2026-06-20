import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

class UpdateProfile {
  final AuthRepository _repository;

  const UpdateProfile(this._repository);

  Future<Result<void>> call({required String uid, String? displayName, String? bio}) {
    return _repository.updateProfile(uid: uid, displayName: displayName, bio: bio);
  }
}
