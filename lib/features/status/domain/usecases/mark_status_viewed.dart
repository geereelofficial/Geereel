import '../../../../core/utils/result.dart';
import '../repositories/status_repository.dart';

class MarkStatusViewed {
  final StatusRepository _repository;

  const MarkStatusViewed(this._repository);

  Future<Result<void>> call(String statusId) => _repository.markViewed(statusId);
}
