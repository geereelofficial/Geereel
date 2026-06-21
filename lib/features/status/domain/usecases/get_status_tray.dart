import '../../../../core/utils/result.dart';
import '../entities/status_entity.dart';
import '../repositories/status_repository.dart';

class GetStatusTray {
  final StatusRepository _repository;

  const GetStatusTray(this._repository);

  Future<Result<List<StatusGroupEntity>>> call() => _repository.fetchTray();
}
