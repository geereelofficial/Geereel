import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/utils/result.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../data/datasources/status_remote_data_source.dart';
import '../../data/repositories/status_repository_impl.dart';
import '../../domain/entities/status_entity.dart';
import '../../domain/entities/status_viewer_entity.dart';
import '../../domain/repositories/status_repository.dart';
import '../../domain/usecases/create_status.dart';
import '../../domain/usecases/delete_status.dart';
import '../../domain/usecases/get_status_tray.dart';
import '../../domain/usecases/get_status_viewers.dart';
import '../../domain/usecases/get_user_statuses.dart';
import '../../domain/usecases/mark_status_viewed.dart';

part 'status_providers.g.dart';

@riverpod
StatusRemoteDataSource statusRemoteDataSource(Ref ref) {
  return ApiStatusRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
    cloudinaryUploader: ref.watch(cloudinaryUploaderProvider),
  );
}

@riverpod
StatusRepository statusRepository(Ref ref) {
  return StatusRepositoryImpl(ref.watch(statusRemoteDataSourceProvider));
}

@riverpod
GetStatusTray getStatusTrayUseCase(Ref ref) => GetStatusTray(ref.watch(statusRepositoryProvider));

@riverpod
GetUserStatuses getUserStatusesUseCase(Ref ref) => GetUserStatuses(ref.watch(statusRepositoryProvider));

@riverpod
CreateStatus createStatusUseCase(Ref ref) => CreateStatus(ref.watch(statusRepositoryProvider));

@riverpod
MarkStatusViewed markStatusViewedUseCase(Ref ref) => MarkStatusViewed(ref.watch(statusRepositoryProvider));

@riverpod
GetStatusViewers getStatusViewersUseCase(Ref ref) => GetStatusViewers(ref.watch(statusRepositoryProvider));

@riverpod
DeleteStatus deleteStatusUseCase(Ref ref) => DeleteStatus(ref.watch(statusRepositoryProvider));

/// The status tray: the caller's own active statuses plus everyone they
/// follow's, grouped by author. Refreshed on pull-to-refresh and after
/// creating/finishing a viewing session.
@riverpod
Future<List<StatusGroupEntity>> statusTray(Ref ref) async {
  final result = await ref.watch(getStatusTrayUseCaseProvider).call();
  return switch (result) {
    Ok(value: final groups) => groups,
    Err(failure: final failure) => throw failure,
  };
}

/// One author's active statuses, for the full-screen viewer.
@riverpod
Future<List<StatusEntity>> userStatuses(Ref ref, String authorId) async {
  final result = await ref.watch(getUserStatusesUseCaseProvider).call(authorId);
  return switch (result) {
    Ok(value: final statuses) => statuses,
    Err(failure: final failure) => throw failure,
  };
}

/// Owner-only viewer list for one status.
@riverpod
Future<List<StatusViewerEntity>> statusViewers(Ref ref, String statusId) async {
  final result = await ref.watch(getStatusViewersUseCaseProvider).call(statusId);
  return switch (result) {
    Ok(value: final viewers) => viewers,
    Err(failure: final failure) => throw failure,
  };
}

/// 0.0-1.0 upload progress for [StatusUploadController], observed
/// separately so the progress bar can rebuild without re-triggering the
/// whole create flow.
@riverpod
class StatusUploadProgress extends _$StatusUploadProgress {
  @override
  double build() => 0;

  void update(double value) => state = value;
}

@riverpod
class StatusUploadController extends _$StatusUploadController {
  @override
  FutureOr<void> build() {}

  Future<bool> postStatus({
    required File mediaFile,
    required MediaType mediaType,
    double? durationSeconds,
    int? width,
    int? height,
  }) async {
    state = const AsyncLoading();
    ref.read(statusUploadProgressProvider.notifier).update(0);

    final result = await ref.read(createStatusUseCaseProvider).call(
      mediaFile: mediaFile,
      mediaType: mediaType,
      durationSeconds: durationSeconds,
      width: width,
      height: height,
      onProgress: (progress) => ref.read(statusUploadProgressProvider.notifier).update(progress),
    );

    switch (result) {
      case Ok():
        state = const AsyncData(null);
        ref.invalidate(statusTrayProvider);
        return true;
      case Err(failure: final failure):
        state = AsyncError(failure, StackTrace.current);
        return false;
    }
  }
}

/// Marks statuses viewed and deletes the caller's own statuses; kept
/// separate from [StatusUploadController] since neither needs the other's
/// loading/error state surfaced.
@riverpod
class StatusViewController extends _$StatusViewController {
  @override
  FutureOr<void> build() {}

  Future<void> markViewed(String statusId) async {
    await ref.read(markStatusViewedUseCaseProvider).call(statusId);
  }

  /// Call once the viewer session for an author closes, so the tray's
  /// unviewed ring updates without refetching on every single advance.
  void refreshTray() => ref.invalidate(statusTrayProvider);

  Future<Result<void>> deleteStatus(String statusId) async {
    final result = await ref.read(deleteStatusUseCaseProvider).call(statusId);
    if (result case Ok()) ref.invalidate(statusTrayProvider);
    return result;
  }
}
