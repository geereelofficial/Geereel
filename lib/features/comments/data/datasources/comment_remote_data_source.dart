import '../../../../core/network/api_client.dart';
import '../models/comment_model.dart';

abstract class CommentRemoteDataSource {
  /// One page of comments, newest first. Pass [before] (the last comment's
  /// `createdAt` from the previous page) to fetch the next page.
  Future<List<CommentModel>> getComments(String postId, {required int limit, DateTime? before});

  /// Returns the server-created comment (with its real id/timestamp) so the
  /// caller can insert it locally without refetching the whole list.
  Future<CommentModel> addComment({
    required String postId,
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    required String text,
  });
}

class ApiCommentRemoteDataSource implements CommentRemoteDataSource {
  final ApiClient _apiClient;

  ApiCommentRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<CommentModel>> getComments(
    String postId, {
    required int limit,
    DateTime? before,
  }) async {
    final response = await _apiClient.get(
      '/posts/$postId/comments',
      query: {
        'limit': limit,
        if (before != null) 'cursor': before.toIso8601String(),
      },
    );
    return (response.data as List)
        .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CommentModel> addComment({
    required String postId,
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    required String text,
  }) async {
    final response = await _apiClient.post('/posts/$postId/comments', data: {'text': text});
    return CommentModel.fromJson(response.data as Map<String, dynamic>);
  }
}
