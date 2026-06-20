import 'dart:io';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../entities/post_entity.dart';

/// Contract for reading, creating, and interacting with posts.
///
/// Shared by the feed feature (reading/liking) and the upload feature
/// (creating), since both operate on the same `posts` collection.
abstract class PostRepository {
  /// Fetches one reverse-chronological page of the global feed.
  ///
  /// Pass [startAfterCreatedAt] (the last item of the previous page) to
  /// fetch the next page; omit it for the first page.
  Future<Result<List<PostEntity>>> fetchFeedPage({
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  });

  /// One reverse-chronological page of posts from accounts the caller
  /// follows. Empty when following no one.
  Future<Result<List<PostEntity>>> fetchFollowingFeedPage({
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  });

  /// All posts by [authorId], newest first, for the profile grid.
  Future<Result<List<PostEntity>>> fetchUserPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  });

  /// Live like state of [postId] for [uid], used by the like button.
  Stream<bool> watchIsLiked({required String postId, required String uid});

  Future<Result<void>> toggleLike({required String postId, required String uid});

  /// Live bookmark state of [postId] for [uid], used by the bookmark button.
  Stream<bool> watchIsBookmarked({required String postId, required String uid});

  Future<Result<void>> toggleBookmark({required String postId, required String uid});

  /// Live repost state of [postId] for [uid], used by the repost button.
  Stream<bool> watchIsReposted({required String postId, required String uid});

  Future<Result<void>> toggleRepost({required String postId, required String uid});

  Future<Result<void>> incrementShareCount(String postId);

  Future<Result<void>> incrementViewCount(String postId);

  /// Uploads [mediaFile] to Storage and creates the Firestore post
  /// document. Returns the created post's id.
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
  });
}
