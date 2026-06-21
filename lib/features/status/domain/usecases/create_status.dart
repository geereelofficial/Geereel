import 'dart:io';
import '../../../../core/utils/result.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../repositories/status_repository.dart';

class CreateStatus {
  final StatusRepository _repository;

  const CreateStatus(this._repository);

  Future<Result<String>> call({
    required File mediaFile,
    required MediaType mediaType,
    double? durationSeconds,
    int? width,
    int? height,
    void Function(double progress)? onProgress,
  }) {
    return _repository.createStatus(
      mediaFile: mediaFile,
      mediaType: mediaType,
      durationSeconds: durationSeconds,
      width: width,
      height: height,
      onProgress: onProgress,
    );
  }
}
