import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

class SignOut {
  final AuthRepository _repository;

  const SignOut(this._repository);

  Future<Result<void>> call() => _repository.signOut();
}
