import 'dart:io';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../domain/entities/status_entity.dart';
import '../../domain/entities/status_viewer_entity.dart';
import '../../domain/repositories/status_repository.dart';
import '../datasources/status_remote_data_source.dart';
import '../models/status_group_model.dart';
import '../models/status_model.dart';
import '../models/status_viewer_model.dart';

class StatusRepositoryImpl implements StatusRepository {
  final StatusRemoteDataSource _remote;

  const StatusRepositoryImpl(this._remote);

  @override
  Future<Result<List<StatusGroupEntity>>> fetchTray() async {
    try {
      final models = await _remote.fetchTray();
      return Ok(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<List<StatusEntity>>> fetchUserStatuses(String authorId) async {
    try {
      final models = await _remote.fetchUserStatuses(authorId);
      return Ok(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<String>> createStatus({
    required File mediaFile,
    required MediaType mediaType,
    double? durationSeconds,
    int? width,
    int? height,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final statusId = await _remote.createStatus(
        mediaFile: mediaFile,
        mediaType: mediaType,
        durationSeconds: durationSeconds,
        width: width,
        height: height,
        onProgress: onProgress,
      );
      return Ok(statusId);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> markViewed(String statusId) async {
    try {
      await _remote.markViewed(statusId);
      return const Ok(null);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<List<StatusViewerEntity>>> fetchViewers(String statusId) async {
    try {
      final List<StatusViewerModel> models = await _remote.fetchViewers(statusId);
      return Ok(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteStatus(String statusId) async {
    try {
      await _remote.deleteStatus(statusId);
      return const Ok(null);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  Failure _mapToFailure(Object error) {
    if (error is StorageException) return StorageFailure(error.message);
    if (error is AuthException) return AuthFailure(error.message);
    if (error is NotFoundException) return NotFoundFailure(error.message);
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is ServerException) return ServerFailure(error.message);
    return ServerFailure('Status error (${error.runtimeType}): $error');
  }
}
