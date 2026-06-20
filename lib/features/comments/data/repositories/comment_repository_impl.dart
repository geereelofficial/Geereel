import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasources/comment_remote_data_source.dart';
import '../models/comment_model.dart';

class CommentRepositoryImpl implements CommentRepository {
  final CommentRemoteDataSource _remote;

  const CommentRepositoryImpl(this._remote);

  @override
  Stream<List<CommentEntity>> watchComments(
    String postId, {
    int limit = AppConstants.commentsPageSize,
  }) {
    return _remote
        .watchComments(postId, limit: limit)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Result<void>> addComment({
    required String postId,
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    required String text,
  }) async {
    try {
      await _remote.addComment(
        postId: postId,
        authorId: authorId,
        authorUsername: authorUsername,
        authorPhotoUrl: authorPhotoUrl,
        text: text,
      );
      return const Ok(null);
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }
}
