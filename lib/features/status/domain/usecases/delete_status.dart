import '../../../../core/utils/result.dart';
import '../repositories/status_repository.dart';

class DeleteStatus {
  final StatusRepository _repository;

  const DeleteStatus(this._repository);

  Future<Result<void>> call(String statusId) => _repository.deleteStatus(statusId);
}
