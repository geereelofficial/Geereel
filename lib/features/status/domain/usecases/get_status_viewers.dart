import '../../../../core/utils/result.dart';
import '../entities/status_viewer_entity.dart';
import '../repositories/status_repository.dart';

class GetStatusViewers {
  final StatusRepository _repository;

  const GetStatusViewers(this._repository);

  Future<Result<List<StatusViewerEntity>>> call(String statusId) => _repository.fetchViewers(statusId);
}
