import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/cloudinary_uploader.dart';
import '../../domain/entities/post_entity.dart';
import '../models/post_model.dart';

abstract class PostRemoteDataSource {
  Future<List<PostModel>> fetchFeedPage({DateTime? startAfterCreatedAt, required int limit});

  Future<List<PostModel>> fetchFollowingFeedPage({DateTime? startAfterCreatedAt, required int limit});

  Future<List<PostModel>> fetchUserPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    required int limit,
  });

  Stream<bool> watchIsLiked({required String postId, required String uid});

  Future<void> toggleLike({required String postId, required String uid});

  Stream<bool> watchIsBookmarked({required String postId, required String uid});

  Future<void> toggleBookmark({required String postId, required String uid});

  Stream<bool> watchIsReposted({required String postId, required String uid});

  Future<void> toggleRepost({required String postId, required String uid});

  Future<void> incrementShareCount(String postId);

  Future<void> incrementViewCount(String postId);

  Future<String> createPost({
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

class ApiPostRemoteDataSource implements PostRemoteDataSource {
  final ApiClient _apiClient;
  final CloudinaryUploader _cloudinaryUploader;

  ApiPostRemoteDataSource({required ApiClient apiClient, required CloudinaryUploader cloudinaryUploader})
    : _apiClient = apiClient,
      _cloudinaryUploader = cloudinaryUploader;

  @override
  Future<List<PostModel>> fetchFeedPage({
    DateTime? startAfterCreatedAt,
    required int limit,
  }) async {
    final response = await _apiClient.get(
      '/posts/feed',
      query: {
        'limit': limit,
        if (startAfterCreatedAt != null) 'cursor': startAfterCreatedAt.toIso8601String(),
      },
    );
    return (response.data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<PostModel>> fetchFollowingFeedPage({
    DateTime? startAfterCreatedAt,
    required int limit,
  }) async {
    final response = await _apiClient.get(
      '/posts/following',
      query: {
        'limit': limit,
        if (startAfterCreatedAt != null) 'cursor': startAfterCreatedAt.toIso8601String(),
      },
    );
    return (response.data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<PostModel>> fetchUserPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    required int limit,
  }) async {
    final response = await _apiClient.get(
      '/posts/user/$authorId',
      query: {
        'limit': limit,
        if (startAfterCreatedAt != null) 'cursor': startAfterCreatedAt.toIso8601String(),
      },
    );
    return (response.data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Stream<bool> watchIsLiked({required String postId, required String uid}) {
    return Stream.fromFuture(_fetchIsLiked(postId));
  }

  Future<bool> _fetchIsLiked(String postId) async {
    final response = await _apiClient.get('/posts/$postId/liked');
    return (response.data as Map<String, dynamic>)['liked'] as bool;
  }

  @override
  Future<void> toggleLike({required String postId, required String uid}) async {
    final liked = await _fetchIsLiked(postId);
    if (liked) {
      await _apiClient.delete('/posts/$postId/like');
    } else {
      await _apiClient.post('/posts/$postId/like');
    }
  }

  @override
  Stream<bool> watchIsBookmarked({required String postId, required String uid}) {
    return Stream.fromFuture(_fetchIsBookmarked(postId));
  }

  Future<bool> _fetchIsBookmarked(String postId) async {
    final response = await _apiClient.get('/posts/$postId/bookmarked');
    return (response.data as Map<String, dynamic>)['bookmarked'] as bool;
  }

  @override
  Future<void> toggleBookmark({required String postId, required String uid}) async {
    final bookmarked = await _fetchIsBookmarked(postId);
    if (bookmarked) {
      await _apiClient.delete('/posts/$postId/bookmark');
    } else {
      await _apiClient.post('/posts/$postId/bookmark');
    }
  }

  @override
  Stream<bool> watchIsReposted({required String postId, required String uid}) {
    return Stream.fromFuture(_fetchIsReposted(postId));
  }

  Future<bool> _fetchIsReposted(String postId) async {
    final response = await _apiClient.get('/posts/$postId/reposted');
    return (response.data as Map<String, dynamic>)['reposted'] as bool;
  }

  @override
  Future<void> toggleRepost({required String postId, required String uid}) async {
    final reposted = await _fetchIsReposted(postId);
    if (reposted) {
      await _apiClient.delete('/posts/$postId/repost');
    } else {
      await _apiClient.post('/posts/$postId/repost');
    }
  }

  @override
  Future<void> incrementShareCount(String postId) async {
    await _apiClient.post('/posts/$postId/share');
  }

  @override
  Future<void> incrementViewCount(String postId) async {
    await _apiClient.post('/posts/$postId/view');
  }

  @override
  Future<String> createPost({
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
    final mediaUrl = await _cloudinaryUploader.upload(
      file: mediaFile,
      folder: 'posts',
      onProgress: onProgress,
    );

    final response = await _apiClient.post(
      '/posts',
      data: {
        'mediaType': mediaType.name,
        'mediaUrl': mediaUrl,
        'caption': caption,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      },
    );

    return (response.data as Map<String, dynamic>)['postId'] as String;
  }
}
