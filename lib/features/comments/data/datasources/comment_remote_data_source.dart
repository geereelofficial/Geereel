import '../../../../core/network/api_client.dart';
import '../models/comment_model.dart';

abstract class CommentRemoteDataSource {
  Stream<List<CommentModel>> watchComments(String postId, {required int limit});

  Future<void> addComment({
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
  Stream<List<CommentModel>> watchComments(String postId, {required int limit}) {
    return Stream.fromFuture(_fetchComments(postId, limit: limit));
  }

  Future<List<CommentModel>> _fetchComments(String postId, {required int limit}) async {
    final response = await _apiClient.get('/posts/$postId/comments', query: {'limit': limit});
    return (response.data as List)
        .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    required String text,
  }) async {
    await _apiClient.post('/posts/$postId/comments', data: {'text': text});
  }
}
