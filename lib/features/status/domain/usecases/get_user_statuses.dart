import '../../../../core/utils/result.dart';
import '../entities/status_entity.dart';
import '../repositories/status_repository.dart';

class GetUserStatuses {
  final StatusRepository _repository;

  const GetUserStatuses(this._repository);

  Future<Result<List<StatusEntity>>> call(String authorId) => _repository.fetchUserStatuses(authorId);
}
