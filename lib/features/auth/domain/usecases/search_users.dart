import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SearchUsers {
  final AuthRepository _repository;

  const SearchUsers(this._repository);

  Future<Result<List<UserEntity>>> call(String query) => _repository.searchUsers(query);
}
