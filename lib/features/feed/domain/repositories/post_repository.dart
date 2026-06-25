import 'dart:io';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../entities/post_entity.dart';

/// Contract for reading, creating, and interacting with posts.
///
/// Shared by the feed feature (reading/liking) and the upload feature
/// (creating), since both operate on the same `posts` collection.
abstract class PostRepository {
  /// Fetches a single post by id, e.g. for opening a shared post link.
  Future<Result<PostEntity>> fetchPost(String postId);

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

  /// Posts [authorId] has liked, newest-post-first. Only the signed-in
  /// caller can fetch their own liked posts (backend enforces this).
  Future<Result<List<PostEntity>>> fetchUserLikedPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  });

  /// Posts [authorId] has reposted, newest-post-first.
  Future<Result<List<PostEntity>>> fetchUserRepostedPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  });

  /// Posts [authorId] has bookmarked/marked, newest-post-first. Only the
  /// signed-in caller can fetch their own marked posts (backend enforces this).
  Future<Result<List<PostEntity>>> fetchUserBookmarkedPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  });

  /// Posts [authorId] has shared, newest-post-first. Only the signed-in
  /// caller can fetch their own shared posts (backend enforces this).
  Future<Result<List<PostEntity>>> fetchUserSharedPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    int limit = AppConstants.feedPageSize,
  });

  Future<Result<void>> toggleLike({required String postId, required String uid});

  Future<Result<void>> toggleBookmark({required String postId, required String uid});

  /// Reposts [postId], optionally with [comment] attached as a quote-repost.
  /// Reposting again while already reposted updates the comment instead of
  /// erroring, so this also covers "edit your quote".
  Future<Result<void>> addRepost({required String postId, String? comment});

  Future<Result<void>> removeRepost(String postId);

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
