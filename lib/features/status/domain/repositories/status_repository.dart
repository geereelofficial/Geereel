import 'dart:io';
import '../../../../core/utils/result.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../entities/status_entity.dart';
import '../entities/status_viewer_entity.dart';

/// Contract for reading, creating, and viewing 24h-ephemeral statuses.
abstract class StatusRepository {
  /// The tray: the caller's own active statuses plus those of everyone
  /// they follow, grouped by author.
  Future<Result<List<StatusGroupEntity>>> fetchTray();

  /// One author's active statuses, for the full-screen viewer. Fails with
  /// an [AuthFailure]-mapped error if the caller doesn't follow them.
  Future<Result<List<StatusEntity>>> fetchUserStatuses(String authorId);

  Future<Result<String>> createStatus({
    required File mediaFile,
    required MediaType mediaType,
    double? durationSeconds,
    int? width,
    int? height,
    void Function(double progress)? onProgress,
  });

  Future<Result<void>> markViewed(String statusId);

  /// Owner-only — who has viewed this status, most recent first.
  Future<Result<List<StatusViewerEntity>>> fetchViewers(String statusId);

  Future<Result<void>> deleteStatus(String statusId);
}
