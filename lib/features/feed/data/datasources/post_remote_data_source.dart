import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/cloudinary_uploader.dart';
import '../../domain/entities/post_entity.dart';
import '../models/post_model.dart';

abstract class PostRemoteDataSource {
  Future<PostModel> fetchPost(String postId);

  Future<List<PostModel>> fetchFeedPage({DateTime? startAfterCreatedAt, required int limit});

  Future<List<PostModel>> fetchFollowingFeedPage({DateTime? startAfterCreatedAt, required int limit});

  Future<List<PostModel>> fetchUserPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    required int limit,
  });

  Future<List<PostModel>> fetchUserLikedPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    required int limit,
  });

  Future<List<PostModel>> fetchUserRepostedPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    required int limit,
  });

  Future<List<PostModel>> fetchUserBookmarkedPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    required int limit,
  });

  Future<List<PostModel>> fetchUserSharedPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    required int limit,
  });

  Future<void> toggleLike({required String postId, required String uid});

  Future<void> toggleBookmark({required String postId, required String uid});

  Future<void> addRepost({required String postId, String? comment});

  Future<void> removeRepost(String postId);

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
  Future<PostModel> fetchPost(String postId) async {
    final response = await _apiClient.get('/posts/$postId');
    return PostModel.fromJson(response.data as Map<String, dynamic>);
  }

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
  Future<List<PostModel>> fetchUserLikedPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    required int limit,
  }) async {
    final response = await _apiClient.get(
      '/posts/user/$authorId/liked',
      query: {
        'limit': limit,
        if (startAfterCreatedAt != null) 'cursor': startAfterCreatedAt.toIso8601String(),
      },
    );
    return (response.data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<PostModel>> fetchUserRepostedPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    required int limit,
  }) async {
    final response = await _apiClient.get(
      '/posts/user/$authorId/reposted',
      query: {
        'limit': limit,
        if (startAfterCreatedAt != null) 'cursor': startAfterCreatedAt.toIso8601String(),
      },
    );
    return (response.data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<PostModel>> fetchUserBookmarkedPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    required int limit,
  }) async {
    final response = await _apiClient.get(
      '/posts/user/$authorId/bookmarked',
      query: {
        'limit': limit,
        if (startAfterCreatedAt != null) 'cursor': startAfterCreatedAt.toIso8601String(),
      },
    );
    return (response.data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<PostModel>> fetchUserSharedPosts({
    required String authorId,
    DateTime? startAfterCreatedAt,
    required int limit,
  }) async {
    final response = await _apiClient.get(
      '/posts/user/$authorId/shared',
      query: {
        'limit': limit,
        if (startAfterCreatedAt != null) 'cursor': startAfterCreatedAt.toIso8601String(),
      },
    );
    return (response.data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
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
  Future<void> addRepost({required String postId, String? comment}) async {
    await _apiClient.post(
      '/posts/$postId/repost',
      data: comment != null && comment.isNotEmpty ? {'comment': comment} : null,
    );
  }

  @override
  Future<void> removeRepost(String postId) async {
    await _apiClient.delete('/posts/$postId/repost');
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
