import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmail {
  final AuthRepository _repository;

  const SignInWithEmail(this._repository);

  Future<Result<UserEntity>> call({required String email, required String password}) {
    return _repository.signInWithEmail(email: email, password: password);
  }
}
