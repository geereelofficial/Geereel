import 'dart:io';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_remote_data_source.dart';
import '../models/post_model.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource _remote;

  const PostRepositoryImpl(this._remote);

  @override
  Future<Result<List<PostEntity>>> fetchFeedPage({
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  }) async {
    try {
      final models = await _remote.fetchFeedPage(
        startAfterCreatedAt: startAfterCreatedAt,
        limit: limit,
      );
      return Ok(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<List<PostEntity>>> fetchFollowingFeedPage({
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  }) async {
    try {
      final models = await _remote.fetchFollowingFeedPage(
        startAfterCreatedAt: startAfterCreatedAt,
        limit: limit,
      );
      return Ok(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<List<PostEntity>>> fetchUserPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  }) async {
    try {
      final models = await _remote.fetchUserPosts(
        authorId: authorId,
        startAfterCreatedAt: startAfterCreatedAt,
        limit: limit,
      );
      return Ok(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Stream<bool> watchIsLiked({required String postId, required String uid}) {
    return _remote.watchIsLiked(postId: postId, uid: uid);
  }

  @override
  Future<Result<void>> toggleLike({required String postId, required String uid}) async {
    try {
      await _remote.toggleLike(postId: postId, uid: uid);
      return const Ok(null);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Stream<bool> watchIsBookmarked({required String postId, required String uid}) {
    return _remote.watchIsBookmarked(postId: postId, uid: uid);
  }

  @override
  Future<Result<void>> toggleBookmark({required String postId, required String uid}) async {
    try {
      await _remote.toggleBookmark(postId: postId, uid: uid);
      return const Ok(null);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Stream<bool> watchIsReposted({required String postId, required String uid}) {
    return _remote.watchIsReposted(postId: postId, uid: uid);
  }

  @override
  Future<Result<void>> toggleRepost({required String postId, required String uid}) async {
    try {
      await _remote.toggleRepost(postId: postId, uid: uid);
      return const Ok(null);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> incrementShareCount(String postId) async {
    try {
      await _remote.incrementShareCount(postId);
      return const Ok(null);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> incrementViewCount(String postId) async {
    try {
      await _remote.incrementViewCount(postId);
      return const Ok(null);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<String>> createPost({
    required File mediaFile,
    required MediaType mediaType,
    required String caption,
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    double? durationSeconds,
    int? width,
    int? height,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final postId = await _remote.createPost(
        mediaFile: mediaFile,
        mediaType: mediaType,
        caption: caption,
        authorId: authorId,
        authorUsername: authorUsername,
        authorPhotoUrl: authorPhotoUrl,
        durationSeconds: durationSeconds,
        width: width,
        height: height,
        onProgress: onProgress,
      );
      return Ok(postId);
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
    // ignore: avoid_print
    print('DEBUG PostRepo unhandled: ${error.runtimeType}: $error');
    return ServerFailure('Post error (${error.runtimeType}): $error');
  }
}
