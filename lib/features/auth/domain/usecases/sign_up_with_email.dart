import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Creates a new account and the corresponding Firestore profile document.
class SignUpWithEmail {
  final AuthRepository _repository;

  const SignUpWithEmail(this._repository);

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) {
    return _repository.signUpWithEmail(
      email: email,
      password: password,
      username: username,
      displayName: displayName,
    );
  }
}
